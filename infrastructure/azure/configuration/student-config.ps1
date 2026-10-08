<#
.SYNOPSIS
    Konfiguriert einen Kursrechner: PowerShell 7, VS Code, RSAT-AD, Remoting, Kursordner mit Beispieldaten.
    Läuft über Azure Run Command (als SYSTEM) nach dem Domänenbeitritt. Idempotent.
#>
param(
    [Parameter(Mandatory)][string]$DomainName,
    [Parameter(Mandatory)][string]$NetbiosName,
    [string]$PwshVersion = '7.6.6',
    [string]$CourseSiteUrl = 'https://powershell-kurs.philiplorenz.com',
    # 'false' für die Trainer-VM: Teilnehmer bekommen dort weder Admin- noch RDP-Rechte noch Schreibrechte
    [string]$ParticipantAccess = 'true'
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

function Step($t) { Write-Output "== $t" }

# ---- Warten auf Domänenmitgliedschaft (Beitritt und Neustart laufen asynchron) ----
$deadline = (Get-Date).AddMinutes(15)
while (-not (Get-CimInstance Win32_ComputerSystem).PartOfDomain -and (Get-Date) -lt $deadline) { Start-Sleep -Seconds 15 }
if (-not (Get-CimInstance Win32_ComputerSystem).PartOfDomain) { throw 'Rechner ist nach 15 Minuten nicht in der Domäne.' }

Step 'Deutsche Region/Kultur'
Set-TimeZone -Id 'W. Europe Standard Time'
Set-Culture de-DE
Set-WinHomeLocation -GeoId 94      # Deutschland
Set-WinSystemLocale de-DE
Set-WinUserLanguageList de-DE -Force

Step 'Internet Explorer Enhanced Security aus (Browser auf Server)'
foreach ($k in '{A509B1A7-37EF-4b3f-8CFC-4F3A74704073}', '{A509B1A8-37EF-4b3f-8CFC-4F3A74704073}') {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\$k" -Name IsInstalled -Value 0 -ErrorAction SilentlyContinue
}
# Server Manager nicht automatisch starten
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\ServerManager' -Name DoNotOpenServerManagerAtLogon -Value 1 -Type DWord -Force

Step 'RSAT Active Directory PowerShell'
Install-WindowsFeature -Name RSAT-AD-PowerShell | Out-Null

Step "PowerShell $PwshVersion"
$pwsh = 'C:\Program Files\PowerShell\7\pwsh.exe'
$installedOk = (Test-Path $pwsh) -and ((& $pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()') -eq $PwshVersion)
if (-not $installedOk) {
    $msi = Join-Path $env:TEMP "pwsh-$PwshVersion.msi"
    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/PowerShell/PowerShell/releases/download/v$PwshVersion/PowerShell-$PwshVersion-win-x64.msi" -OutFile $msi
    $p = Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /qn ADD_PATH=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1 USE_MU=0 ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1" -Wait -PassThru
    if ($p.ExitCode -notin 0, 3010) { throw "PowerShell-MSI Exit-Code $($p.ExitCode)" }
}

Step 'Remoting (Windows PowerShell und PowerShell 7)'
Enable-PSRemoting -Force -SkipNetworkProfileCheck | Out-Null
& $pwsh -NoProfile -Command 'Enable-PSRemoting -Force -SkipNetworkProfileCheck | Out-Null'

Step 'Lokale Gruppen: Kursteilnehmer = Administratoren und RDP-Nutzer'
$grp = "$NetbiosName\GG-Kurs-Teilnehmer"
if ($ParticipantAccess -eq 'true') {
    foreach ($local in 'Administrators', 'Remote Desktop Users') {
        $members = (Get-LocalGroupMember -Group $local -ErrorAction SilentlyContinue).Name
        if ($members -notcontains $grp) { Add-LocalGroupMember -Group $local -Member $grp }
    }
} else { Write-Output 'Trainer-VM: keine Teilnehmerrechte.' }

Step 'VS Code (systemweit) mit PowerShell-Erweiterung'
$code = 'C:\Program Files\Microsoft VS Code\bin\code.cmd'
if (-not (Test-Path $code)) {
    $exe = Join-Path $env:TEMP 'vscode-setup.exe'
    Invoke-WebRequest -UseBasicParsing -Uri 'https://update.code.visualstudio.com/latest/win32-x64/stable' -OutFile $exe
    Start-Process $exe -ArgumentList '/VERYSILENT /NORESTART /MERGETASKS=!runcode,addcontextmenufiles,addcontextmenufolders,addtopath' -Wait
}
$extDir = 'C:\ProgramData\vscode-extensions'
New-Item -ItemType Directory -Path $extDir -Force | Out-Null
[Environment]::SetEnvironmentVariable('VSCODE_EXTENSIONS', $extDir, 'Machine')
if (-not (Get-ChildItem $extDir -Filter 'ms-vscode.powershell*' -ErrorAction SilentlyContinue)) {
    & $code --extensions-dir $extDir --install-extension ms-vscode.PowerShell --force | Out-Null
}
icacls.exe $extDir /grant 'Users:(OI)(CI)RX' /T | Out-Null

Step 'Module (Pester)'
# Als Text übergeben: ein Scriptblock würde an pwsh.exe nur als Zeichenkette weitergereicht und nie ausgeführt.
& $pwsh -NoProfile -Command @'
$ErrorActionPreference = 'Stop'
Set-PSResourceRepository -Name PSGallery -Trusted -ErrorAction SilentlyContinue
if (-not (Get-PSResource -Name Pester -ErrorAction SilentlyContinue | Where-Object { $_.Version -ge [version]'5.0' })) {
    Install-PSResource -Name Pester -Scope AllUsers -TrustRepository -Reinstall
}
'@
if ($LASTEXITCODE -ne 0) { throw "Pester-Installation fehlgeschlagen ($LASTEXITCODE)" }

Step 'Kursordner und Beispieldaten'
$root = 'C:\Kurs'
foreach ($d in 'Daten', 'Daten\Logs', 'Daten\Berichte', 'Ausgabe', 'Logs', 'Skripte', 'KI') {
    New-Item -ItemType Directory -Path (Join-Path $root $d) -Force | Out-Null
}

# Mitarbeiter.csv
@'
Name,Abteilung,Alter
Alena,IT,30
Bob,HR,35
Charlie,Finanzen,28
Dora,IT,41
Emil,Vertrieb,9
Fiona,IT,26
Gerd,HR,52
Hanna,Finanzen,33
Ingo,Vertrieb,45
Jana,IT,38
Kai,Vertrieb,29
Lena,HR,47
'@ | Set-Content -Path "$root\Daten\Mitarbeiter.csv" -Encoding utf8

# Neue-Mitarbeiter.csv (nur ASCII, für Übung Tag 2 Block 3)
@'
Vorname,Nachname,Abteilung
Max,Mustermann,IT
Erika,Musterfrau,HR
Paula,Probe,Finanzen
Tim,Test,Vertrieb
'@ | Set-Content -Path "$root\Daten\Neue-Mitarbeiter.csv" -Encoding utf8

# 12 Logdateien mit unterschiedlicher Größe und verschiedenen Änderungsdaten (deterministisch)
$rnd = [System.Random]::new(42)
for ($i = 1; $i -le 12; $i++) {
    $f = "$root\Daten\Logs\app-{0:d2}.log" -f $i
    if (-not (Test-Path $f)) {
        $lines = 20 + $rnd.Next(0, 380)
        $content = 1..$lines | ForEach-Object { '{0:yyyy-MM-dd HH:mm:ss} INFO Ereignis {1} verarbeitet' -f (Get-Date).AddMinutes(-$_), $_ }
        Set-Content -Path $f -Value $content
        (Get-Item $f).LastWriteTime = (Get-Date).AddDays(-($i * 5 - 3))
    }
}
# Berichte
1..4 | ForEach-Object {
    $f = "$root\Daten\Berichte\bericht-2026-{0:d2}.txt" -f $_
    if (-not (Test-Path $f)) { Set-Content -Path $f -Value "Monatsbericht $_`nStatus: erledigt" }
}

# KI-Beispiele (alle Daten frei erfunden)
@'
$s = gwmi win32_service | ? {$_.StartMode -eq "Auto" -and $_.State -ne "Running"}
foreach($x in $s){ write-host $x.Name $x.State }
$pw = "Sommer2024!"
$c = New-Object System.Management.Automation.PSCredential("PSLAB\svc-backup",(ConvertTo-SecureString $pw -AsPlainText -Force))
Invoke-Expression ("net use Z: \\dc01\Kursdaten /user:PSLAB\svc-backup " + $pw)
gci C:\Kurs\Daten\Logs | ? {$_.LastWriteTime -lt (get-date).AddDays(-30)} | del
'@ | Set-Content -Path "$root\KI\altes-skript.ps1" -Encoding utf8

@'
Get-ADUser -Filter * | Get-ADUserLastLogon -Days 90 -Format Table
Get-ChildItem C:\Kurs\Daten -Recurse -OlderThan 30d | Remove-Item -Force
Get-Service -Name Spooler -ComputerName PSLAB-02
Invoke-Parallel -ComputerName PSLAB-02 -ScriptBlock { Get-Process }
Set-ExecutionPolicy -Scope Everything -ExecutionPolicy Unrestricted
'@ | Set-Content -Path "$root\KI\ki-antwort-mit-fehlern.txt" -Encoding utf8

# Schreibrechte: Teilnehmer dürfen Ausgabe/Logs/Skripte beschreiben (Daten bleibt lesbar)
if ($ParticipantAccess -eq 'true') { icacls.exe $root /grant "${NetbiosName}\GG-Kurs-Teilnehmer:(OI)(CI)M" /T | Out-Null }

Step 'Desktop-Verknüpfungen'
$pub = [Environment]::GetFolderPath('CommonDesktopDirectory')
Set-Content -Path "$pub\Kursseite.url" -Value "[InternetShortcut]`nURL=$CourseSiteUrl"
Set-Content -Path "$pub\Folien.url" -Value "[InternetShortcut]`nURL=$CourseSiteUrl/slides/"
$shell = New-Object -ComObject WScript.Shell
$lnk = $shell.CreateShortcut("$pub\PowerShell 7.lnk"); $lnk.TargetPath = $pwsh; $lnk.WorkingDirectory = 'C:\Kurs'; $lnk.Save()
if (Test-Path 'C:\Program Files\Microsoft VS Code\Code.exe') {
    $lnk = $shell.CreateShortcut("$pub\VS Code.lnk"); $lnk.TargetPath = 'C:\Program Files\Microsoft VS Code\Code.exe'; $lnk.WorkingDirectory = 'C:\Kurs\Skripte'; $lnk.Save()
}

Write-Output "Student-Konfiguration abgeschlossen auf $env:COMPUTERNAME."
