<#
.SYNOPSIS
    Smoke-Tests, die ÜBER Azure Run Command auf den VMs laufen (als SYSTEM).
    Rolle wird als Parameter übergeben: Dc | Student.
    Gibt pro Prüfung eine Zeile "PASS|FAIL <Name> :: <Detail>" aus.
#>
param(
    [Parameter(Mandatory)][ValidateSet('Dc', 'Student')][string]$Role,
    [string]$DomainName = 'pslab.internal',
    [string]$NetbiosName = 'PSLAB',
    [string]$StudentUser,
    [string]$StudentPassword,
    [string[]]$PeerComputers = @(),
    [string]$OwnOu
)
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
$results = [System.Collections.Generic.List[string]]::new()
function T([string]$name, [scriptblock]$test) {
    try {
        $r = & $test
        if ($r -eq $false) { $results.Add("FAIL $name :: Bedingung nicht erfüllt") }
        else { $results.Add("PASS $name :: $r") }
    } catch { $results.Add("FAIL $name :: $($_.Exception.Message)") }
}
$pwsh = 'C:\Program Files\PowerShell\7\pwsh.exe'

T 'Domänenmitglied/Controller' {
    $cs = Get-CimInstance Win32_ComputerSystem
    if ($cs.Domain -ne $DomainName) { throw "Domäne ist '$($cs.Domain)'" }
    "Domäne $($cs.Domain), Rolle $($cs.DomainRole)"
}
T 'PowerShell 7 installiert' { (& $pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()') }
T 'PowerShell-7-Remoting-Endpunkt' { (& $pwsh -NoProfile -Command '(Get-PSSessionConfiguration -Name PowerShell.7).Name') }
T 'WinRM lauscht (5985)' { if (Test-NetConnection -ComputerName localhost -Port 5985 -InformationLevel Quiet) { 'ja' } else { $false } }
T 'DNS: Domäne auflösbar' { (Resolve-DnsName $DomainName -ErrorAction Stop | Select-Object -First 1).IPAddress }
T 'DNS: Internet auflösbar' { (Resolve-DnsName 'github.com' -ErrorAction Stop | Select-Object -First 1).IPAddress }
T 'Internetzugang (GitHub-API)' { (Invoke-RestMethod -Uri 'https://api.github.com/users/octocat' -TimeoutSec 15).login }

if ($Role -eq 'Dc') {
    T 'AD-Dienste' { $s = Get-Service ADWS, DNS, NTDS, Netlogon; if ($s.Where{ $_.Status -ne 'Running' }) { throw ($s | Out-String) }; 'ADWS, DNS, NTDS, Netlogon laufen' }
    Import-Module ActiveDirectory -ErrorAction SilentlyContinue
    T 'OU-Struktur' { $n = (Get-ADOrganizationalUnit -Filter 'Name -like "*"' -SearchBase "OU=Kurs,$((Get-ADDomain).DistinguishedName)" | Measure-Object).Count; if ($n -lt 5) { throw "nur $n OUs" } ; "$n OUs unter Kurs" }
    T 'Demobenutzer (24)' { $n = (Get-ADUser -Filter * -SearchBase "OU=Benutzer,OU=Kurs,$((Get-ADDomain).DistinguishedName)" | Measure-Object).Count; if ($n -ne 24) { throw "$n Benutzer" } ; "$n Benutzer" }
    T 'Deaktivierte Konten vorhanden' { $n = (Get-ADUser -Filter 'Enabled -eq $false' | Where-Object DistinguishedName -like '*OU=Benutzer*' | Measure-Object).Count; if ($n -ne 3) { throw "$n deaktivierte" } ; "$n" }
    T 'Abgelaufene Passwörter vorhanden' { $n = (Search-ADAccount -PasswordExpired | Measure-Object).Count; if ($n -lt 2) { throw "$n" } ; "$n" }
    T 'Gruppen GRP-*' { $g = Get-ADGroup -Filter 'Name -like "GRP-*"'; if ($g.Count -ne 4) { throw "$($g.Count) Gruppen" }; (Get-ADGroupMember GRP-IT | Measure-Object).Count.ToString() + ' Mitglieder in GRP-IT' }
    T 'Teilnehmerkonten und Gruppe' { (Get-ADGroupMember 'GG-Kurs-Teilnehmer' | Measure-Object).Count.ToString() + ' Mitglieder' }
    T 'Remote Management Users enthält Teilnehmer' { if (-not (Get-ADGroupMember 'Remote Management Users' | Where-Object Name -eq 'GG-Kurs-Teilnehmer')) { $false } else { 'ja' } }
    T 'Passwortrichtlinie (12 Zeichen)' { $p = Get-ADDefaultDomainPasswordPolicy; if ($p.MinPasswordLength -ne 12) { throw "$($p.MinPasswordLength)" } ; '12' }
}

if ($Role -eq 'Student') {
    T 'AD-Modul' { Import-Module ActiveDirectory -ErrorAction Stop; (Get-ADDomain).DNSRoot }
    T 'Kursordner' { foreach ($d in 'Daten', 'Daten\Logs', 'Ausgabe', 'Logs', 'Skripte', 'KI') { if (-not (Test-Path "C:\Kurs\$d")) { throw "C:\Kurs\$d fehlt" } }; 'vollständig' }
    T 'Beispieldaten' { $n = (Import-Csv C:\Kurs\Daten\Mitarbeiter.csv | Measure-Object).Count; $l = (Get-ChildItem C:\Kurs\Daten\Logs | Measure-Object).Count; if ($n -ne 12 -or $l -ne 12) { throw "csv=$n logs=$l" }; "12 Mitarbeiter, 12 Logs" }
    T 'VS Code + PowerShell-Erweiterung' { if (-not (Test-Path 'C:\Program Files\Microsoft VS Code\Code.exe')) { throw 'VS Code fehlt' }; if (-not (Get-ChildItem C:\ProgramData\vscode-extensions -Filter 'ms-vscode.powershell*')) { throw 'Erweiterung fehlt' }; 'ok' }
    T 'Pester 5' { (& $pwsh -NoProfile -Command '(Get-Module Pester -ListAvailable | Sort-Object Version -Descending | Select-Object -First 1).Version.ToString()') }
    T 'Lokale Admins: GG-Kurs-Teilnehmer' { if ((Get-LocalGroupMember Administrators).Name -notcontains "$NetbiosName\GG-Kurs-Teilnehmer") { $false } else { 'ja' } }

    if ($StudentUser -and $StudentPassword) {
        $cred = [pscredential]::new($StudentUser, (ConvertTo-SecureString $StudentPassword -AsPlainText -Force))
        # --- Tests aus Sicht des Teilnehmers (Remoting gegen sich selbst als Teilnehmerkonto) ---
        foreach ($peer in $PeerComputers) {
            T "Remoting als Teilnehmer -> $peer" { (Invoke-Command -ComputerName $peer -Credential $cred -ScriptBlock { $env:COMPUTERNAME } -ErrorAction Stop) }
            T "Remoting PS7-Endpunkt -> $peer" { (Invoke-Command -ComputerName $peer -Credential $cred -ConfigurationName PowerShell.7 -ScriptBlock { $PSVersionTable.PSVersion.ToString() } -ErrorAction Stop) }
            T "CIM remote -> $peer" { (Get-CimInstance Win32_OperatingSystem -ComputerName $peer -Credential $cred -ErrorAction Stop).CSName }
        }
        T 'Remoting zum DC (eingeschränkt)' { (Invoke-Command -ComputerName DC01 -Credential $cred -ScriptBlock { $env:COMPUTERNAME } -ErrorAction Stop) }
        T 'Kein Administrator auf DC01' {
            $isAdmin = Invoke-Command -ComputerName DC01 -Credential $cred -ScriptBlock { ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) } -ErrorAction Stop
            if ($isAdmin) { throw 'Teilnehmer ist Administrator auf dem DC' } else { 'korrekt (nur Remote Management Users)' }
        }
        # Der Übungs-Check läuft als echter Anmeldevorgang des Teilnehmers (nicht per Remoting auf localhost),
        # weil AD-Abfragen sonst am Double-Hop scheitern würden. Genau das erleben auch die Teilnehmer per RDP.
        T 'Übungs-Check als Teilnehmer (AD, Dienste, Task, CSV)' {
            $check = 'C:\Windows\Temp\uebungs-check.ps1'
            $outF  = 'C:\Windows\Temp\uebungs-check.out'
            $errF  = 'C:\Windows\Temp\uebungs-check.err'
            Set-Content -Path $check -Encoding utf8 -Value @"
`$ErrorActionPreference = 'Stop'
`$ou = '$OwnOu'
Import-Module ActiveDirectory
`$log = @()
`$log += 'IT=' + (Get-ADUser -Filter "Department -eq 'IT'" | Measure-Object).Count
`$pw = ConvertTo-SecureString ('Tmp-' + [guid]::NewGuid().ToString('N').Substring(0, 12) + '!Aa1') -AsPlainText -Force
New-ADUser -Name 'Smoke Test' -SamAccountName smoke.test -Path `$ou -AccountPassword `$pw -Enabled `$true
`$log += 'create=ok'
Set-ADUser -Identity smoke.test -Department IT
Remove-ADUser -Identity smoke.test -Confirm:`$false
`$log += 'delete=ok'
try { Add-ADGroupMember -Identity GRP-IT -Members teilnehmer01 -ErrorAction Stop; `$log += 'GRP-IT=FALSCH_SCHREIBBAR' } catch { `$log += 'GRP-IT=readonly' }
Stop-Service Spooler; Start-Service Spooler; `$log += 'Spooler=' + (Get-Service Spooler).Status
`$log += 'csv=' + (Import-Csv C:\Kurs\Daten\Mitarbeiter.csv | Where-Object Abteilung -eq 'IT' | Measure-Object).Count
`$a = New-ScheduledTaskAction -Execute 'C:\Program Files\PowerShell\7\pwsh.exe' -Argument '-NoProfile -Command "Get-Date | Add-Content C:\Kurs\Logs\smoke.log"'
`$t = New-ScheduledTaskTrigger -Daily -At 09:00
Register-ScheduledTask -TaskName 'Kurs-Smoke' -Action `$a -Trigger `$t -Force | Out-Null
Start-ScheduledTask -TaskName 'Kurs-Smoke'; Start-Sleep 6
`$log += 'task=' + (Get-ScheduledTaskInfo -TaskName 'Kurs-Smoke').LastTaskResult
Unregister-ScheduledTask -TaskName 'Kurs-Smoke' -Confirm:`$false
`$log += 'cim=' + (Get-CimInstance Win32_OperatingSystem).Caption
`$log += 'peer-remoting=' + (Invoke-Command -ComputerName '$($PeerComputers[0])' -ScriptBlock { `$env:COMPUTERNAME })
`$log -join '; '
"@
            Remove-Item $outF, $errF -ErrorAction SilentlyContinue
            Start-Process -FilePath $pwsh -Credential $cred -WorkingDirectory 'C:\Windows\Temp' -Wait -WindowStyle Hidden `
                -ArgumentList '-NoProfile', '-File', $check -RedirectStandardOutput $outF -RedirectStandardError $errF
            $out = (Get-Content $outF -Raw -ErrorAction SilentlyContinue)
            $err = (Get-Content $errF -Raw -ErrorAction SilentlyContinue)
            Remove-Item $check -ErrorAction SilentlyContinue
            if (-not $out) { throw "keine Ausgabe. Fehler: $err" }
            if ($out -match 'GRP-IT=FALSCH_SCHREIBBAR') { throw "Delegierung zu weit: $out" }
            if ($out -notmatch 'task=0') { throw "Task-Ergebnis nicht 0: $out $err" }
            $out.Trim()
        }
    }
}

$results | ForEach-Object { $_ }
