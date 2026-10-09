#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Bedienoberfläche für das PowerShell-Kurs-Lab in Azure (Terraform + Azure CLI).

.DESCRIPTION
    Der Trainer muss keine einzelnen Azure-Kommandos kennen:

      ./lab.ps1 deploy [-Students 1]   Plan anzeigen (inkl. Kostenschätzung), nach Bestätigung alles erstellen
      ./lab.ps1 start             DC starten, auf AD warten, dann Teilnehmer-VMs starten
      ./lab.ps1 stop              alle VMs deallokieren (keine Compute-Kosten)
      ./lab.ps1 end-of-day        wie stop, plus Kontrolle und Hinweis auf weiterlaufende Kosten
      ./lab.ps1 status            Zustand der VMs, IPs, AD, geschätzte Kosten pro Stunde
      ./lab.ps1 credentials       Zugangsdaten anzeigen (-Export: in .secrets/ speichern)
      ./lab.ps1 test              Smoke-Tests gegen die laufende Umgebung
      ./lab.ps1 test-exercises    alle Musterlösungen der Übungen im Lab ausführen (optional: Seitenfilter, z. B. tag-2)
      ./lab.ps1 reset-student 2   Teilnehmerumgebung 2 auf Ausgangszustand zurücksetzen
      ./lab.ps1 reset-all         ALLES auf den Ursprung: alle Teilnehmer-VMs neu, AD-Inhalt neu, Passwörter wie bei deploy
      ./lab.ps1 allow-ip 203.0.113.5/32   weitere RDP-Quelladresse freischalten (nur im eingeschränkten Modus)
      ./lab.ps1 open-rdp / close-rdp      RDP von überall erlauben bzw. auf freigegebene IPs beschränken
      ./lab.ps1 rdp [all|trainer|participants] [-Open] [-OutDir <Ordner>]   RDP-Dateien erzeugen (ohne Passwort)
      ./lab.ps1 slides            Folien mit Zugangsdaten je Teilnehmer erzeugen (nur lokal, .secrets/slides/)
      ./lab.ps1 cost              Kostenschätzung
      ./lab.ps1 destroy           komplettes Lab entfernen
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory)]
    [ValidateSet('deploy', 'start', 'stop', 'end-of-day', 'status', 'credentials', 'test', 'test-exercises', 'reset-student', 'reset-all', 'allow-ip', 'open-rdp', 'close-rdp', 'rdp', 'slides', 'cost', 'destroy', 'help')]
    [string]$Command,

    [Parameter(Position = 1)]
    [string]$Argument,

    [string]$SubscriptionId = $env:LAB_SUBSCRIPTION_ID,
    [switch]$Force,
    [switch]$RestrictRdp,
    [switch]$Open,
    [string]$OutDir,
    [ValidateRange(1, 10)][int]$Students = 0,
    [switch]$Export
)

$ErrorActionPreference = 'Stop'
$Root      = $PSScriptRoot
$TfDir     = Join-Path $Root 'infrastructure/azure/terraform'
$TestDir   = Join-Path $Root 'infrastructure/azure/tests'
$SecretDir = Join-Path $Root '.secrets'
$LocalVars = Join-Path $TfDir 'lab.auto.tfvars.json'
$Rg        = 'rg-pslab'

# Preise in EUR/Stunde (Azure Retail Prices, Germany West Central, Stand 10/2026). Nur für Schätzungen.
$Price = @{ 'Standard_B2s' = 0.0493; 'Standard_B2ms' = 0.0915 }
$DiskEurPerMonth = 8.45     # Standard SSD E10 (128 GiB)
$PipEurPerHour   = 0.0045   # Standard Static Public IPv4

function Say($m, $c = 'Gray') { Write-Host $m -ForegroundColor $c }
function Fail($m) { Write-Host "FEHLER: $m" -ForegroundColor Red; exit 1 }

function Require-Tools {
    foreach ($t in 'az', 'terraform') {
        if (-not (Get-Command $t -ErrorAction SilentlyContinue)) { Fail "'$t' nicht gefunden. Bitte installieren." }
    }
    $null = az account show 2>$null
    if ($LASTEXITCODE -ne 0) { Fail "Nicht bei Azure angemeldet. Bitte 'az login' ausführen und erneut starten." }
}

function Resolve-Subscription {
    $current = (az account show --query id -o tsv)
    if (-not $SubscriptionId) {
        if (Test-Path $LocalVars) { $script:SubscriptionId = (Get-Content $LocalVars -Raw | ConvertFrom-Json).subscription_id }
    }
    if (-not $SubscriptionId) { $script:SubscriptionId = $current }
    if ($current -ne $SubscriptionId) { az account set --subscription $SubscriptionId | Out-Null }
    $name = az account show --query name -o tsv
    Say "Azure-Subscription: $name ($SubscriptionId)" Cyan
}

function Read-LocalVars {
    if (Test-Path $LocalVars) { return Get-Content $LocalVars -Raw | ConvertFrom-Json -AsHashtable }
    return @{}
}
function Write-LocalVars($v) { $v | ConvertTo-Json -Depth 5 | Set-Content $LocalVars -Encoding utf8 }

function Get-MyPublicIp {
    try { (Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 10).Trim() } catch { $null }
}

function Tf { & terraform "-chdir=$TfDir" @args; if ($LASTEXITCODE -ne 0) { Fail "terraform $($args[0]) ist fehlgeschlagen." } }

function Get-Vms {
    $json = az vm list -g $Rg -d --query "[].{name:name, state:powerState, pub:publicIps, priv:privateIps, size:hardwareProfile.vmSize}" -o json 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $json) { return @() }
    $json | ConvertFrom-Json | Sort-Object { if ($_.name -eq 'DC01') { '0' } else { $_.name } }
}

function Confirm-Action($prompt) {
    if ($Force) { return $true }
    $a = Read-Host "$prompt (yes/no)"
    return $a -eq 'yes'
}

function Get-CostEstimate {
    param([int]$Students = 3, [string]$DcSize = 'Standard_B2s', [string]$StudentSize = 'Standard_B2ms', [switch]$Trainer)
    $vmCount = $Students + 1 + [int]$Trainer.IsPresent
    $perHour = $Price[$DcSize] + ($Students + [int]$Trainer.IsPresent) * $Price[$StudentSize]
    $idleDay = (($vmCount * $DiskEurPerMonth) / 30) + ($vmCount * $PipEurPerHour * 24)
    [pscustomobject]@{
        LaufendProStunde = [math]::Round($perHour, 3)
        KursTagEUR       = [math]::Round($perHour * 9, 2)      # 9 Stunden aktiv
        DreiKursTageEUR  = [math]::Round($perHour * 9 * 3, 2)
        GestopptProTag   = [math]::Round($idleDay, 2)           # Disks und öffentliche IPs laufen weiter
        GestopptProMonat = [math]::Round($idleDay * 30, 2)
    }
}

function Show-Cost {
    $lv = Read-LocalVars
    $n = $lv.student_count
    $tr = [bool]$lv.trainer_vm_enabled
    $e = if ($n) { Get-CostEstimate -Students $n -Trainer:$tr } else { Get-CostEstimate -Trainer:$tr }
    Say "`nKostenschätzung (Germany West Central, 1 DC B2s + $(if ($n) { $n } else { 3 }) Teilnehmer B2ms$(if ($tr) { ' + Trainer-VM B2ms' }), Windows-Lizenz enthalten):" Yellow
    Say ("  Laufend:        {0} EUR pro Stunde (alle VMs an)" -f $e.LaufendProStunde)
    Say ("  Ein Kurstag:    ca. {0} EUR (9 Stunden)   Drei Kurstage: ca. {1} EUR" -f $e.KursTagEUR, $e.DreiKursTageEUR)
    Say ("  Gestoppt:       ca. {0} EUR pro Tag / {1} EUR pro Monat (nur Disks und öffentliche IPs)" -f $e.GestopptProTag, $e.GestopptProMonat)
    Say "  -> Lab nach dem Kurs mit './lab.ps1 destroy' entfernen. Die Beträge sind Schätzungen ohne Steuern und ohne Datenverkehr." Yellow
}

switch ($Command) {

    'help' { Get-Help $PSCommandPath -Detailed; break }

    'cost' { Show-Cost; break }

    'deploy' {
        Require-Tools; Resolve-Subscription
        $vars = Read-LocalVars
        $vars.subscription_id = $SubscriptionId
        if ($Students -gt 0) { $vars.student_count = $Students }
        if (-not $RestrictRdp -and -not $vars.ContainsKey('rdp_open_to_internet')) { $vars.rdp_open_to_internet = $true }
        if ($vars.rdp_open_to_internet) {
            Say 'RDP ist von jeder IP erreichbar (Teilnehmer-IPs unbekannt). Schutz: lange Zufallspasswörter, NLA, Kontosperre. Nach dem Kurs destroy!' Yellow
        } elseif (-not $vars.allowed_rdp_cidrs) {
            $ip = Get-MyPublicIp
            if (-not $ip) { Fail "Öffentliche IP nicht ermittelbar. Mit 'allow-ip' oder in $LocalVars selbst eintragen." }
            $vars.allowed_rdp_cidrs = @("$ip/32")
            Say "RDP wird nur von deiner aktuellen IP erlaubt: $ip" Cyan
        }
        Write-LocalVars $vars
        Tf init -input=false
        Tf plan -input=false -out=tfplan
        Show-Cost
        Say "`nDas erstellt kostenpflichtige Ressourcen in der Subscription $SubscriptionId." Yellow
        if (-not (Confirm-Action 'Jetzt erstellen?')) { Say 'Abgebrochen. Es wurde nichts erstellt.'; break }
        Tf apply -input=false tfplan
        Remove-Item (Join-Path $TfDir 'tfplan') -Force -ErrorAction SilentlyContinue   # Plan-Datei kann Geheimnisse enthalten
        Say "`nFertig. Zugangsdaten: ./lab.ps1 credentials   Prüfen: ./lab.ps1 test" Green
        Say 'Hinweis: Die Konfiguration der VMs (Domäne, Software) läuft in der Deployment-Phase ab; das dauert insgesamt ca. 30-45 Minuten.' Gray
        break
    }

    'status' {
        Require-Tools; Resolve-Subscription
        $vms = Get-Vms
        if (-not $vms) { Say "Keine VMs in $Rg gefunden. (Nicht deployed?)" Yellow; break }
        $vms | Select-Object @{n = 'VM'; e = { $_.name } }, @{n = 'Zustand'; e = { $_.state } }, @{n = 'Öffentliche IP (RDP)'; e = { $_.pub } }, @{n = 'Private IP'; e = { $_.priv } }, @{n = 'Größe'; e = { $_.size } } | Format-Table -AutoSize
        $running = @($vms | Where-Object { $_.state -eq 'VM running' })
        $rate = ($running | ForEach-Object { $Price[$_.size] } | Measure-Object -Sum).Sum
        if ($running.Count) { Say ("{0} VM(s) laufen: ca. {1:N3} EUR pro Stunde." -f $running.Count, $rate) Yellow }
        else { Say 'Alle VMs deallokiert: keine Compute-Kosten. Disks und öffentliche IPs kosten weiter (ca. 1-2 EUR pro Tag).' Green }
        $dc = $vms | Where-Object name -eq 'DC01'
        if ($dc.state -eq 'VM running') {
            $out = az vm run-command invoke -g $Rg -n DC01 --command-id RunPowerShellScript --scripts "(Get-Service ADWS,DNS,NTDS,Netlogon | ForEach-Object { '{0}={1}' -f `$_.Name, `$_.Status }) -join ';'" --query 'value[0].message' -o tsv 2>$null
            Say "Domain Controller: $out"
        }
        break
    }

    'start' {
        Require-Tools; Resolve-Subscription
        $vms = Get-Vms; if (-not $vms) { Fail 'Keine VMs gefunden. Zuerst ./lab.ps1 deploy.' }
        Say 'Starte DC01 ...' Cyan
        az vm start -g $Rg -n DC01 | Out-Null
        Say 'Warte, bis Active Directory antwortet ...' Cyan
        $ok = $false
        for ($i = 0; $i -lt 30 -and -not $ok; $i++) {
            $r = az vm run-command invoke -g $Rg -n DC01 --command-id RunPowerShellScript --scripts "try { Import-Module ActiveDirectory; (Get-ADDomain).DNSRoot } catch { 'NOTREADY' }" --query 'value[0].message' -o tsv 2>$null
            if ($r -and $r -notmatch 'NOTREADY' -and $r -match '\w') { $ok = $true; Say "AD bereit: $($r.Trim())" Green } else { Start-Sleep -Seconds 20 }
        }
        if (-not $ok) { Say 'AD antwortet noch nicht. Starte die Teilnehmer-VMs trotzdem; Anmeldungen können kurz scheitern.' Yellow }
        Say 'Starte Teilnehmer-VMs ...' Cyan
        $studentVms = $vms | Where-Object name -ne 'DC01' | ForEach-Object name
        if ($studentVms) { az vm start -g $Rg --ids (@($studentVms) | ForEach-Object { az vm show -g $Rg -n $_ --query id -o tsv }) | Out-Null }
        & $PSCommandPath status
        break
    }

    { $_ -in 'stop', 'end-of-day' } {
        Require-Tools; Resolve-Subscription
        $vms = Get-Vms; if (-not $vms) { Fail 'Keine VMs gefunden.' }
        Say 'Deallokiere alle VMs (das dauert 1-3 Minuten) ...' Cyan
        $ids = $vms | ForEach-Object { az vm show -g $Rg -n $_.name --query id -o tsv }
        az vm deallocate -g $Rg --ids $ids | Out-Null
        $left = @(Get-Vms | Where-Object { $_.state -ne 'VM deallocated' })
        if ($left.Count) { Say "WARNUNG: Noch nicht deallokiert: $($left.name -join ', ')" Red; exit 2 }
        Say 'Alle VMs sind deallokiert. Es laufen keine Compute-Kosten mehr.' Green
        if ($Command -eq 'end-of-day') {
            $e = Get-CostEstimate
            Say ("Weiterhin kostenpflichtig: 4 Disks und 4 öffentliche IPs, ca. {0} EUR pro Tag." -f $e.GestopptProTag) Yellow
            Say 'Morgen früh: ./lab.ps1 start    Nach dem letzten Tag: ./lab.ps1 destroy' Gray
            az vm list -g $Rg -d --query "[].{VM:name, Zustand:powerState}" -o table
        }
        break
    }

    'credentials' {
        Require-Tools
        $json = & terraform "-chdir=$TfDir" output -json 2>$null | ConvertFrom-Json
        if (-not $json -or -not $json.student_credentials) { Fail 'Keine Terraform-Ausgaben gefunden. Ist das Lab deployed?' }
        Say "`nTrainer / Domänen-Admin" Cyan
        Say ("  Benutzer:  {0}" -f $json.admin_username.value)
        Say ("  Passwort:  {0}" -f $json.admin_password.value)
        Say ("  DC01 (RDP): {0} ({1})   Domäne: {2}" -f $json.dc_fqdn.value, $json.dc_public_ip.value, $json.domain.value)
        Say ("  DSRM-Passwort: {0}" -f $json.dsrm_password.value)
        if ($json.trainer_fqdn.value) { Say ("  Trainer-VM (RDP): {0}   Benutzer: {1}   (gleiches Passwort wie oben)" -f $json.trainer_fqdn.value, $json.admin_username.value) }
        Say "`nTeilnehmer" Cyan
        $rows = $json.student_credentials.value.PSObject.Properties | ForEach-Object { $_.Value } | Sort-Object vm
        $rows | Select-Object name, company, vm, user, password, fqdn, rdp | Format-Table -AutoSize
        if ($Export) {
            New-Item -ItemType Directory -Path $SecretDir -Force | Out-Null
            $file = Join-Path $SecretDir 'teilnehmer-zugaenge.csv'
            $rows | Select-Object name, company, vm, user, password, fqdn, rdp | Export-Csv $file -Delimiter ';'
            Say "Gespeichert in $file (liegt in .secrets/, wird nicht committet). Nach der Übergabe löschen!" Yellow
        }
        break
    }

    'allow-ip' {
        Require-Tools; Resolve-Subscription
        if (-not $Argument) { $ip = Get-MyPublicIp; $Argument = "$ip/32"; Say "Keine Adresse angegeben, nutze deine aktuelle: $Argument" Cyan }
        if ($Argument -notmatch '^\d{1,3}(\.\d{1,3}){3}(/\d{1,2})?$') { Fail 'Format: 203.0.113.5/32' }
        if ($Argument -notmatch '/') { $Argument += '/32' }
        if ($Argument -eq '0.0.0.0/0') { Fail 'RDP für die ganze Welt ist nicht erlaubt.' }
        $vars = Read-LocalVars
        $vars.subscription_id = $SubscriptionId
        $list = @($vars.allowed_rdp_cidrs) + $Argument | Where-Object { $_ } | Select-Object -Unique
        $vars.allowed_rdp_cidrs = @($list)
        Write-LocalVars $vars
        Tf apply -input=false -auto-approve -target=azurerm_network_security_group.lab
        Say "RDP erlaubt von: $($vars.allowed_rdp_cidrs -join ', ')" Green
        break
    }

    { $_ -in 'open-rdp', 'close-rdp' } {
        Require-Tools; Resolve-Subscription
        $vars = Read-LocalVars
        $vars.subscription_id = $SubscriptionId
        $vars.rdp_open_to_internet = ($Command -eq 'open-rdp')
        if (-not $vars.rdp_open_to_internet -and -not $vars.allowed_rdp_cidrs) {
            $vars.allowed_rdp_cidrs = @("$(Get-MyPublicIp)/32")
        }
        Write-LocalVars $vars
        Tf apply -input=false -auto-approve -target=azurerm_network_security_group.lab
        if ($vars.rdp_open_to_internet) { Say 'RDP (3389) ist jetzt von überall erreichbar. Nach dem Kurs: ./lab.ps1 close-rdp oder destroy.' Yellow }
        else { Say "RDP nur noch von: $($vars.allowed_rdp_cidrs -join ', ')" Green }
        break
    }

    'rdp' {
        Require-Tools
        $json = & terraform "-chdir=$TfDir" output -json 2>$null | ConvertFrom-Json
        if (-not $json -or -not $json.student_credentials) { Fail 'Keine Terraform-Ausgaben gefunden. Ist das Lab deployed?' }
        $mode = if ($Argument) { $Argument.ToLower() } else { 'all' }
        if ($mode -notin 'all', 'trainer', 'participants') { Fail "Verwendung: ./lab.ps1 rdp [all|trainer|participants] [-Open]" }
        $dir = if ($OutDir) { $OutDir } else { Join-Path $SecretDir 'rdp' }
        $rows = $json.student_credentials.value.PSObject.Properties | ForEach-Object { $_.Value } | Sort-Object vm
        $domainNb = ($json.admin_username.value -split '\\')[0]

        function New-RdpContent([string]$address, [string]$user) {
            @(
                "full address:s:$address"
                "username:s:$user"
                'prompt for credentials:i:1'            # Passwort wird beim Verbinden abgefragt (RDP-Dateien speichern keins)
                'enablecredsspsupport:i:1'
                'authentication level:i:2'              # Zertifikatswarnung bei selbstsignierten VM-Zertifikaten erwartbar
                'screen mode id:i:2'
                'use multimon:i:0'
                'smart sizing:i:1'
                'dynamic resolution:i:1'
                'session bpp:i:32'
                'redirectclipboard:i:1'
                'audiomode:i:2'
                'keyboardhook:i:2'
                'networkautodetect:i:1'
                'compression:i:1'
            ) -join "`r`n"
        }
        $written = @()
        if ($mode -in 'all', 'trainer') {
            $tDir = Join-Path $dir 'trainer'; New-Item -ItemType Directory -Path $tDir -Force | Out-Null
            $adminUser = $json.admin_username.value
            Set-Content -Path (Join-Path $tDir 'DC01.rdp') -Value (New-RdpContent $json.dc_fqdn.value $adminUser) -Encoding ascii
            $written += 'trainer/DC01.rdp'
            if ($json.trainer_fqdn.value) {
                Set-Content -Path (Join-Path $tDir 'PSLAB-TRAINER.rdp') -Value (New-RdpContent $json.trainer_fqdn.value $adminUser) -Encoding ascii
                $written += 'trainer/PSLAB-TRAINER.rdp'
            }
            foreach ($r in $rows) {
                Set-Content -Path (Join-Path $tDir "$($r.vm).rdp") -Value (New-RdpContent $r.fqdn $adminUser) -Encoding ascii
                $written += "trainer/$($r.vm).rdp"
            }
        }
        if ($mode -in 'all', 'participants') {
            $pDir = Join-Path $dir 'teilnehmer'; New-Item -ItemType Directory -Path $pDir -Force | Out-Null
            foreach ($r in $rows) {
                $label = if ($r.name) { '-' + (($r.name -replace '[^\p{L}\p{N}]+', '-').Trim('-')) } else { '' }
                $file = "$($r.vm)$label.rdp"
                Set-Content -Path (Join-Path $pDir $file) -Value (New-RdpContent $r.fqdn $r.user) -Encoding ascii
                $written += "teilnehmer/$file"
            }
        }
        Say "RDP-Dateien in $dir :" Green
        $written | ForEach-Object { Say "  $_" }
        Say 'Enthalten: Adresse und Benutzername, KEIN Passwort (wird beim Verbinden abgefragt; Passwörter: ./lab.ps1 credentials).' Yellow
        Say 'trainer/ = Domänen-Admin (PSLAB\labadmin) für alle VMs, teilnehmer/ = je ein Konto, zum Weitergeben. Beim ersten Verbinden Zertifikatswarnung bestätigen.' Gray
        if ($Open) {
            $files = Get-ChildItem $dir -Recurse -Filter *.rdp | Where-Object { $mode -eq 'all' -or $_.DirectoryName -match $(if ($mode -eq 'trainer') { 'trainer$' } else { 'teilnehmer$' }) }
            foreach ($f in $files) { if ($IsMacOS) { & open $f.FullName } elseif ($IsWindows) { Start-Process $f.FullName } else { Say "Bitte manuell öffnen: $($f.FullName)" } }
        }
        break
    }

    'slides' {
        Require-Tools
        $json = & terraform "-chdir=$TfDir" output -json 2>$null | ConvertFrom-Json
        if (-not $json -or -not $json.student_credentials) { Fail 'Keine Terraform-Ausgaben gefunden. Ist das Lab deployed?' }
        $rows = $json.student_credentials.value.PSObject.Properties | ForEach-Object { $_.Value } | Sort-Object vm
        $slidesDir = Join-Path $Root 'slides'
        $src = Join-Path $slidesDir 'out'
        if (-not (Test-Path $src)) {
            Say 'Baue Folien (npm ci, node build.mjs) ...' Cyan
            Push-Location $slidesDir; try { npm ci --silent; node build.mjs } finally { Pop-Location }
        }
        $dst = Join-Path $SecretDir 'slides'
        Remove-Item $dst -Recurse -Force -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Path $SecretDir -Force | Out-Null
        Copy-Item $src $dst -Recurse
        $enc = { param($s) [System.Net.WebUtility]::HtmlEncode([string]$s) }
        $site = 'https://powershell-kurs.philiplorenz.com'
        $html = New-Object System.Text.StringBuilder
        # Übersicht (nur für den Trainer)
        [void]$html.AppendLine('<section><h2>Zugänge (Trainer-Übersicht)</h2><table><tr><th>Name</th><th>VM</th><th>Benutzer</th><th>Passwort</th><th>RDP-Adresse</th></tr>')
        foreach ($r in $rows) {
            $n = if ($r.name) { $r.name } else { $r.vm }
            [void]$html.AppendLine("<tr><td>$(& $enc $n)</td><td>$(& $enc $r.vm)</td><td><code>$(& $enc $r.user)</code></td><td><code>$(& $enc $r.password)</code></td><td><code>$(& $enc $r.fqdn)</code></td></tr>")
        }
        [void]$html.AppendLine('</table><p class="small muted">Nur für den Trainer. Nicht projizieren.</p></section>')
        # Eine Folie pro Teilnehmer
        foreach ($r in $rows) {
            $n = if ($r.name) { $r.name } else { $r.vm }
            $c = if ($r.company) { " · $(& $enc $r.company)" } else { '' }
            [void]$html.AppendLine(@"
<section>
  <h2>Dein Zugang: $(& $enc $n)</h2>
  <p class="muted small">$(& $enc $r.vm)$c</p>
  <div class="cols">
    <div class="card"><h3>Remotedesktop (RDP)</h3><ul>
      <li>Computer: <code>$(& $enc $r.fqdn)</code></li>
      <li>Benutzer: <code>$(& $enc $r.user)</code></li>
      <li>Passwort: <code>$(& $enc $r.password)</code></li></ul></div>
    <div class="card"><h3>Erste Schritte</h3><ul>
      <li>PowerShell 7 starten (<code>pwsh</code>)</li>
      <li><code>\$PSVersionTable.PSVersion</code></li>
      <li>Kursseite: <code>$(& $enc $site)</code></li>
      <li>Ordner: <code>C:\Kurs</code></li></ul></div>
  </div>
</section>
"@)
        }
        $index = Join-Path $dst 'index.html'
        $page = (Get-Content $index -Raw).Replace('<!-- ZUGAENGE -->', $html.ToString())
        Set-Content -Path $index -Value $page -Encoding utf8
        Say "Folien mit Zugangsdaten: $index" Green
        Say 'Enthält Passwörter. Liegt in .secrets/ (nicht in Git). Öffnen: im Browser per Doppelklick. PDF: Adresse mit ?print-pdf öffnen und drucken. Nach dem Kurs löschen.' Yellow
        break
    }

    'test' {
        Require-Tools; Resolve-Subscription
        & (Join-Path $TestDir 'run-smoke-tests.ps1') -ResourceGroup $Rg -TerraformDir $TfDir
        exit $LASTEXITCODE
    }

    'test-exercises' {
        Require-Tools; Resolve-Subscription
        & (Join-Path $TestDir 'run-exercise-tests.ps1') -ResourceGroup $Rg -TerraformDir $TfDir -Page $Argument
        exit $LASTEXITCODE
    }

    'reset-student' {
        Require-Tools; Resolve-Subscription
        if ($Argument -notmatch '^\d+$') { Fail 'Verwendung: ./lab.ps1 reset-student <Nummer>   (z. B. 2)' }
        $nn = '{0:d2}' -f [int]$Argument
        $vm = "PSLAB-$nn"
        if (-not (Get-Vms | Where-Object name -eq $vm)) { Fail "$vm existiert nicht." }
        Say "Zurücksetzen von ${vm}: VM wird neu aufgebaut (Domänenbeitritt, Software, Kursordner), AD-Objekte in OU=T$nn werden geleert." Yellow
        Say 'Dateien auf der VM gehen verloren. Dauer: ca. 15-20 Minuten.' Yellow
        if (-not (Confirm-Action "$vm wirklich zurücksetzen?")) { Say 'Abgebrochen.'; break }
        Say 'Stelle sicher, dass DC01 läuft ...' Cyan
        az vm start -g $Rg -n DC01 | Out-Null
        $clean = @"
Import-Module ActiveDirectory
`$base = (Get-ADDomain).DistinguishedName
Get-ADComputer -Filter "Name -eq '$vm'" | Remove-ADObject -Recursive -Confirm:`$false
Get-ADObject -SearchBase "OU=T$nn,OU=Uebung,OU=Kurs,`$base" -SearchScope OneLevel -Filter * | Remove-ADObject -Recursive -Confirm:`$false
Write-Output 'AD bereinigt'
"@
        az vm run-command invoke -g $Rg -n DC01 --command-id RunPowerShellScript --scripts $clean --query 'value[0].message' -o tsv
        Tf apply -input=false -auto-approve "-replace=azurerm_windows_virtual_machine.student[`"$nn`"]"
        Say "$vm wurde neu aufgebaut. Test: ./lab.ps1 test" Green
        break
    }

    'reset-all' {
        Require-Tools; Resolve-Subscription
        $vms = Get-Vms
        if (-not $vms) { Fail 'Keine VMs gefunden. Zuerst ./lab.ps1 deploy.' }
        $keys = & terraform "-chdir=$TfDir" output -json student_credentials 2>$null | ConvertFrom-Json
        if (-not $keys) { Fail 'Terraform-Ausgaben fehlen (State vorhanden?).' }
        $nns = @($keys.PSObject.Properties.Name | Sort-Object)
        Say "Setzt das gesamte Lab auf den Ursprungszustand zurück:" Yellow
        Say "  - alle Teilnehmer-VMs ($($nns | ForEach-Object { "PSLAB-$_" } | Join-String -Separator ', ')) werden NEU aufgebaut (alle Dateien dort gehen verloren)" Yellow
        Say '  - Active Directory: Demoobjekte, Übungs-OUs, Teilnehmerkonten und Computerobjekte werden gelöscht und neu angelegt' Yellow
        Say '  - Passwörter entsprechen wieder denen aus ./lab.ps1 credentials. DC01 selbst bleibt bestehen.' Yellow
        Say '  Dauer: ca. 20-30 Minuten. Compute-Kosten während der Zeit: alle VMs laufen.' Yellow
        if (-not (Confirm-Action 'Alles zurücksetzen?')) { Say 'Abgebrochen.'; break }
        Say 'Starte DC01 und warte auf AD ...' Cyan
        az vm start -g $Rg -n DC01 | Out-Null
        $clean = @'
Import-Module ActiveDirectory
$ErrorActionPreference = 'Stop'
$base = (Get-ADDomain).DistinguishedName
$kurs = "OU=Kurs,$base"
function Clear-Ou($dn) { Get-ADObject -SearchBase $dn -SearchScope OneLevel -Filter * | Remove-ADObject -Recursive -Confirm:$false }
Get-ADComputer -Filter "Name -like 'PSLAB-0*'" | Remove-ADObject -Recursive -Confirm:$false
foreach ($ou in 'Benutzer', 'Teilnehmer', 'Gruppen') { Clear-Ou "OU=$ou,$kurs" }   # OU Computer bleibt: dort liegt auch PSLAB-TRAINER
Get-ADOrganizationalUnit -SearchBase "OU=Uebung,$kurs" -SearchScope OneLevel -Filter * | ForEach-Object { Set-ADOrganizationalUnit $_ -ProtectedFromAccidentalDeletion $false; Remove-ADObject $_ -Recursive -Confirm:$false }
Get-ADGroupMember 'Remote Management Users' | Where-Object Name -like 'GG-Kurs*' | ForEach-Object { Remove-ADGroupMember 'Remote Management Users' $_ -Confirm:$false }
Write-Output 'AD bereinigt'
'@
        $ready = $false
        for ($i = 0; $i -lt 30 -and -not $ready; $i++) {
            $r = az vm run-command invoke -g $Rg -n DC01 --command-id RunPowerShellScript --scripts $clean --query 'value[0].message' -o tsv 2>$null
            if ($r -match 'AD bereinigt') { $ready = $true; Say 'AD bereinigt.' Green } else { Start-Sleep -Seconds 20 }
        }
        if (-not $ready) { Fail 'AD konnte nicht bereinigt werden (DC01 nicht bereit?).' }
        $replace = @('-replace=azurerm_virtual_machine_run_command.dc_populate')
        foreach ($nn in $nns) { $replace += "-replace=azurerm_windows_virtual_machine.student[`"$nn`"]" }
        Say 'Baue AD-Inhalt und Teilnehmer-VMs neu auf (terraform apply) ...' Cyan
        Tf apply -input=false -auto-approve @replace
        Say 'Fertig. Prüfen: ./lab.ps1 test' Green
        break
    }

    'destroy' {
        Require-Tools; Resolve-Subscription
        Tf init -input=false
        Say "`nDas entfernt die komplette Lab-Umgebung ($Rg mit allen VMs, Disks, IPs). Passwörter und Domäne gehen verloren." Yellow
        if (-not $Force) {
            $a = Read-Host "Zur Bestätigung den Namen der Resource Group eintippen ($Rg)"
            if ($a -ne $Rg) { Say 'Abgebrochen. Es wurde nichts gelöscht.'; break }
        }
        Tf destroy -input=false -auto-approve
        $exists = az group exists -n $Rg
        if ($exists -eq 'true') { Say "WARNUNG: $Rg existiert noch. Bitte im Portal prüfen." Red; exit 2 }
        Say "$Rg ist gelöscht. Restressourcen-Prüfung:" Green
        az resource list --query "[?contains(name,'pslab') || contains(name,'PSLAB')].{Name:name,Typ:type,RG:resourceGroup}" -o table
        Say 'Leere Liste = nichts übrig.' Gray
        break
    }
}
