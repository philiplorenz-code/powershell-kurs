<#
.SYNOPSIS
    Füllt die frisch erstellte Domäne: OUs, Gruppen, Benutzer, Delegierung, Demoobjekte.
    Komplett idempotent (jede Zeile prüft, ob das Objekt schon existiert).
#>
param(
    [Parameter(Mandatory)][string]$DomainName,
    [Parameter(Mandatory)][string]$NetbiosName,
    [Parameter(Mandatory)][string]$AdminUser,
    [Parameter(Mandatory)][string]$AdminPassword,
    [Parameter(Mandatory)][string]$StudentPasswordsB64,
    [Parameter(Mandatory)][string]$DsrmPassword,
    [int]$StudentCount = 3,
    [string]$PwshVersion = '7.6.6',
    [string]$ParticipantsB64 = 'W10='
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# ---- Warten, bis AD nach dem Neustart bereit ist ----
$deadline = (Get-Date).AddMinutes(25)
do {
    try {
        Import-Module ActiveDirectory -ErrorAction Stop
        $null = Get-ADDomain -ErrorAction Stop
        $ready = $true
    } catch {
        $ready = $false
        Start-Sleep -Seconds 15
    }
} until ($ready -or (Get-Date) -gt $deadline)
if (-not $ready) { throw 'Active Directory ist nach 25 Minuten nicht bereit.' }
Start-Sleep -Seconds 30   # SYSVOL/Netlogon und DNS-Registrierung nachlaufen lassen

$base = (Get-ADDomain).DistinguishedName
# JSON-Parameter kommen Base64-kodiert an (Run Command zerlegt sonst Leerzeichen und Anführungszeichen)
$fromB64 = { param($b) [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($b)) }
$studentPw = (& $fromB64 $StudentPasswordsB64) | ConvertFrom-Json
# Windows PowerShell 5.1 liefert ein JSON-Array als EIN Objekt; ForEach-Object rollt es in einzelne Teilnehmer aus
$participants = @((& $fromB64 $ParticipantsB64) | ConvertFrom-Json | ForEach-Object { $_ })
$sec = { param($p) ConvertTo-SecureString $p -AsPlainText -Force }

# ---- DSRM-Passwort (Verzeichnisdienst-Wiederherstellungsmodus) auf den Terraform-Wert setzen (idempotent, ermöglicht Rotation) ----
# ntdsutil liest Befehle von der Standardeingabe (mit Argumenten wartet es auf eine Konsole und hängt)
$null = @('set dsrm password', 'reset password on server null', $DsrmPassword, 'q', 'q') | & ntdsutil.exe

# ---- DNS: Weiterleitung an Azure-DNS, damit die Kurs-VMs ins Internet auflösen können ----
try {
    if (-not (Get-DnsServerForwarder).IPAddress) { Add-DnsServerForwarder -IPAddress 168.63.129.16 }
} catch { Write-Warning "DNS-Forwarder: $_" }

# ---- Kennwortrichtlinie (Übung 3.4 verweist auf 12 Zeichen) ----
Set-ADDefaultDomainPasswordPolicy -Identity $DomainName -MinPasswordLength 12 -ComplexityEnabled $true `
    -MaxPasswordAge (New-TimeSpan -Days 365) `
    -LockoutThreshold 10 -LockoutDuration (New-TimeSpan -Minutes 15) -LockoutObservationWindow (New-TimeSpan -Minutes 15)   # Schutz gegen Rate-Guessing bei offenem RDP

# ---- OUs ----
function Ensure-OU($name, $path) {
    $dn = "OU=$name,$path"
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$dn'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name $name -Path $path -ProtectedFromAccidentalDeletion $false
    }
    $dn
}
$kurs        = Ensure-OU 'Kurs' $base
$ouBenutzer  = Ensure-OU 'Benutzer' $kurs
$ouGruppen   = Ensure-OU 'Gruppen' $kurs
$ouComputer  = Ensure-OU 'Computer' $kurs
$ouTeiln     = Ensure-OU 'Teilnehmer' $kurs
$ouUebung    = Ensure-OU 'Uebung' $kurs

# ---- Gruppen ----
function Ensure-Group($name, $path) {
    if (-not (Get-ADGroup -Filter "Name -eq '$name'")) { New-ADGroup -Name $name -GroupScope Global -Path $path }
}
foreach ($g in 'GRP-IT', 'GRP-HR', 'GRP-Finanzen', 'GRP-Vertrieb', 'GG-Kurs-Teilnehmer') { Ensure-Group $g $ouGruppen }

# ---- Domänen-Admin für den Trainer ----
if (-not (Get-ADUser -Filter "SamAccountName -eq '$AdminUser'")) {
    New-ADUser -Name $AdminUser -SamAccountName $AdminUser -UserPrincipalName "$AdminUser@$DomainName" `
        -AccountPassword (& $sec $AdminPassword) -Enabled $true -PasswordNeverExpires $true -Path "CN=Users,$base"
} else {
    Set-ADAccountPassword -Identity $AdminUser -Reset -NewPassword (& $sec $AdminPassword)
    Enable-ADAccount -Identity $AdminUser
}
foreach ($grp in 'Domain Admins', 'Enterprise Admins', 'Schema Admins') {
    Add-ADGroupMember -Identity $grp -Members $AdminUser -ErrorAction SilentlyContinue
}

# ---- Teilnehmer ----
for ($i = 1; $i -le $StudentCount; $i++) {
    $nn   = '{0:d2}' -f $i
    $sam  = "teilnehmer$nn"
    $pw   = $studentPw.$nn
    $person = if ($participants.Count -ge $i) { $participants[$i - 1] } else { $null }
    $display = if ($person -and $person.name) { $person.name } else { "Teilnehmer $nn" }
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$sam'")) {
        New-ADUser -Name "Teilnehmer $nn" -GivenName 'Teilnehmer' -Surname $nn -SamAccountName $sam `
            -UserPrincipalName "$sam@$DomainName" -Department 'Kurs' -Title 'Kursteilnehmer' `
            -AccountPassword (& $sec $pw) -Enabled $true -PasswordNeverExpires $true -Path $ouTeiln
    } else {
        Set-ADAccountPassword -Identity $sam -Reset -NewPassword (& $sec $pw)
    }
    # Zuordnung Teilnehmer -> Konto (Anzeigename, Firma, Mail, Beschreibung mit VM-Nummer)
    $attrs = @{ DisplayName = $display; Description = "$display (PSLAB-$nn)" }
    if ($person -and $person.company) { $attrs.Company = $person.company }
    if ($person -and $person.email)   { $attrs.EmailAddress = $person.email }
    Set-ADUser -Identity $sam @attrs
    Add-ADGroupMember -Identity 'GG-Kurs-Teilnehmer' -Members $sam -ErrorAction SilentlyContinue

    # Eigene Übungs-OU mit voller Kontrolle nur für den jeweiligen Teilnehmer
    $ouT = Ensure-OU "T$nn" $ouUebung
    & dsacls.exe $ouT /I:T /G "${NetbiosName}\${sam}:GA" | Out-Null
}
# Teilnehmer dürfen den DC per PowerShell-Remoting erreichen (ohne Administratorrechte)
Add-ADGroupMember -Identity 'Remote Management Users' -Members 'GG-Kurs-Teilnehmer' -ErrorAction SilentlyContinue

# ---- Demobenutzer (ASCII-Namen, deterministisch) ----
$demo = @'
Vorname,Nachname,Abteilung,Titel,Status
Anna,Berger,IT,Systemadministratorin,aktiv
Bernd,Koch,IT,Netzwerkadministrator,aktiv
Clara,Lange,IT,Helpdesk,aktiv
David,Roth,IT,DevOps Engineer,deaktiviert
Eva,Winter,HR,Personalreferentin,aktiv
Felix,Brandt,HR,Recruiter,aktiv
Greta,Hahn,HR,Leitung HR,aktiv
Hans,Vogel,Finanzen,Buchhalter,aktiv
Ida,Schulz,Finanzen,Controllerin,aktiv
Jonas,Keller,Finanzen,Leitung Finanzen,abgelaufen
Karla,Neumann,Vertrieb,Vertriebsleiterin,aktiv
Lukas,Fuchs,Vertrieb,Account Manager,aktiv
Mia,Schreiber,Vertrieb,Innendienst,aktiv
Noah,Kraus,Vertrieb,Account Manager,deaktiviert
Olga,Peters,IT,Entwicklerin,aktiv
Paul,Simon,IT,Datenbankadministrator,aktiv
Quinn,Arnold,Finanzen,Sachbearbeiter,aktiv
Rita,Busch,HR,Sachbearbeiterin,aktiv
Sven,Albrecht,Vertrieb,Außendienst,aktiv
Tina,Wolf,IT,Praktikantin,abgelaufen
Uwe,Seidel,Finanzen,Einkäufer,aktiv
Vera,Ott,Vertrieb,Marketing,aktiv
Willi,Ziegler,HR,Auszubildender,deaktiviert
Xenia,Graf,IT,Security Analystin,aktiv
'@ | ConvertFrom-Csv

$demoPw = & $sec ('Demo-' + [guid]::NewGuid().ToString('N').Substring(0, 14) + '!Aa1')
foreach ($d in $demo) {
    $sam = ('{0}.{1}' -f $d.Vorname, $d.Nachname).ToLower()
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$sam'")) {
        New-ADUser -Name "$($d.Vorname) $($d.Nachname)" -GivenName $d.Vorname -Surname $d.Nachname `
            -SamAccountName $sam -UserPrincipalName "$sam@$DomainName" -Department $d.Abteilung -Title $d.Titel `
            -AccountPassword $demoPw -Enabled ($d.Status -ne 'deaktiviert') -Path $ouBenutzer
        if ($d.Status -eq 'abgelaufen') { Set-ADUser -Identity $sam -AccountExpirationDate (Get-Date).AddDays(-10) }
        Add-ADGroupMember -Identity ("GRP-" + $d.Abteilung) -Members $sam
    }
}

# Computer-OU: Beitrittsziel der Kurs-VMs (existiert schon über Ensure-OU)

Write-Output ("AD bereit: {0} Benutzer in {1}" -f (Get-ADUser -Filter * -SearchBase $ouBenutzer | Measure-Object).Count, $ouBenutzer)

# ---- PowerShell 7 auf dem DC (für den Trainer) ----
if (-not (Test-Path 'C:\Program Files\PowerShell\7\pwsh.exe')) {
    $msi = Join-Path $env:TEMP "pwsh-$PwshVersion.msi"
    Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/PowerShell/PowerShell/releases/download/v$PwshVersion/PowerShell-$PwshVersion-win-x64.msi" -OutFile $msi
    Start-Process msiexec.exe -ArgumentList "/i `"$msi`" /qn ADD_PATH=1 ENABLE_PSREMOTING=1 REGISTER_MANIFEST=1" -Wait
}
Write-Output 'DC01 fertig.'
