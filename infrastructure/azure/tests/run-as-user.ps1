<#
.SYNOPSIS
    Hilfsfunktion (läuft auf den VMs als SYSTEM): führt ein Skript als Domänenbenutzer **erhöht** und
    **mit echter Anmeldung** aus, über eine einmalige geplante Aufgabe. Erhöht, weil Administratoren sonst ein
    gefiltertes Token bekommen (Stop-Service würde scheitern). Echte Anmeldung, weil AD-Abfragen sonst am
    Double-Hop scheitern. Das entspricht dem, was Teilnehmer per RDP erleben (PowerShell als Administrator).
#>
function Invoke-AsUser {
    param(
        [Parameter(Mandatory)][pscredential]$Credential,
        [Parameter(Mandatory)][string]$ScriptPath,
        [string]$OutputPath = 'C:\Windows\Temp\as-user.out',
        [int]$TimeoutSeconds = 1500
    )
    $pwsh = 'C:\Program Files\PowerShell\7\pwsh.exe'
    $name = 'KursTest-' + [guid]::NewGuid().ToString('N').Substring(0, 8)
    Remove-Item $OutputPath -ErrorAction SilentlyContinue
    # Ausgabedatei vorab anlegen, damit der Benutzer schreiben darf
    New-Item -ItemType File -Path $OutputPath -Force | Out-Null
    icacls.exe $OutputPath /grant "$($Credential.UserName):(M)" | Out-Null
    icacls.exe $ScriptPath /grant "$($Credential.UserName):(RX)" | Out-Null
    $action = New-ScheduledTaskAction -Execute $pwsh -WorkingDirectory 'C:\Kurs' `
        -Argument "-NoProfile -NonInteractive -Command `"& '$ScriptPath' *>&1 | Out-File -FilePath '$OutputPath' -Encoding utf8`""
    $principal = New-ScheduledTaskPrincipal -UserId $Credential.UserName -LogonType Password -RunLevel Highest
    $settings = New-ScheduledTaskSettingsSet -ExecutionTimeLimit ([TimeSpan]::FromSeconds($TimeoutSeconds + 60)) -StartWhenAvailable
    Register-ScheduledTask -TaskName $name -Action $action -Principal $principal -Settings $settings `
        -User $Credential.UserName -Password $Credential.GetNetworkCredential().Password -Force | Out-Null
    Start-ScheduledTask -TaskName $name
    $deadline = (Get-Date).AddSeconds($TimeoutSeconds)
    do { Start-Sleep -Seconds 3 } while ((Get-ScheduledTask -TaskName $name).State -eq 'Running' -and (Get-Date) -lt $deadline)
    $timedOut = (Get-ScheduledTask -TaskName $name).State -eq 'Running'
    $result = (Get-ScheduledTaskInfo -TaskName $name).LastTaskResult
    if ($timedOut) { Stop-ScheduledTask -TaskName $name }
    Unregister-ScheduledTask -TaskName $name -Confirm:$false
    [pscustomobject]@{
        TimedOut = $timedOut
        ExitCode = $result
        Output   = (Get-Content $OutputPath -Raw -ErrorAction SilentlyContinue)
    }
}
