<#
.SYNOPSIS
    Führt smoke.ps1 auf DC01 und allen Teilnehmer-VMs aus und fasst das Ergebnis zusammen.
    Aufruf über: ./lab.ps1 test
#>
param(
    [Parameter(Mandatory)][string]$ResourceGroup,
    [Parameter(Mandatory)][string]$TerraformDir
)
$ErrorActionPreference = 'Stop'
$smoke = Join-Path $PSScriptRoot 'smoke.ps1'
$outputs = & terraform "-chdir=$TerraformDir" output -json | ConvertFrom-Json
$domain = $outputs.domain.value
$creds = $outputs.student_credentials.value.PSObject.Properties | ForEach-Object { $_.Value }

$vms = az vm list -g $ResourceGroup -d --query "[].{name:name,state:powerState}" -o json | ConvertFrom-Json
$notRunning = $vms | Where-Object state -ne 'VM running'
if ($notRunning) { Write-Host "Nicht alle VMs laufen: $($notRunning.name -join ', '). Bitte './lab.ps1 start'." -ForegroundColor Yellow; exit 2 }

$failed = 0
function Invoke-Smoke($vm, $params) {
    # Parameter über temporäre Datei, damit Passwörter nicht in der Prozessliste landen
    $tmp = New-TemporaryFile
    try {
        $header = '$__p = @{' + (($params.GetEnumerator() | ForEach-Object { "'$($_.Key)' = " + ($_.Value -is [array] ? "@('" + ($_.Value -join "','") + "')" : "'$($_.Value)'") }) -join '; ') + '}' + "`n"
        $body = (Get-Content $smoke -Raw)
        # smoke.ps1 beginnt mit param(); Aufruf als Skriptblock mit Splatting
        $script = $header + '& ([scriptblock]::Create(@''' + "`n" + $body + "`n" + '''@)) @__p'
        Set-Content -Path $tmp -Value $script -Encoding utf8
        $raw = az vm run-command invoke -g $ResourceGroup -n $vm --command-id RunPowerShellScript --scripts "@$tmp" --query 'value[0].message' -o tsv
    } finally { Remove-Item $tmp -Force -ErrorAction SilentlyContinue }
    $raw -split "`n" | Where-Object { $_ -match '^(PASS|FAIL) ' }
}

Write-Host "`n=== DC01 ===" -ForegroundColor Cyan
$lines = Invoke-Smoke 'DC01' @{ Role = 'Dc'; DomainName = $domain }
$lines | ForEach-Object { Write-Host $_ -ForegroundColor ($_ -like 'PASS*' ? 'Green' : 'Red') }
$failed += @($lines | Where-Object { $_ -like 'FAIL*' }).Count

foreach ($c in ($creds | Sort-Object vm)) {
    $nn = $c.vm -replace 'PSLAB-', ''
    $peers = @($creds | Where-Object vm -ne $c.vm | ForEach-Object vm)
    $ou = "OU=T$nn,OU=Uebung,OU=Kurs," + (($domain -split '\.' | ForEach-Object { "DC=$_" }) -join ',')
    Write-Host "`n=== $($c.vm) ===" -ForegroundColor Cyan
    $lines = Invoke-Smoke $c.vm @{ Role = 'Student'; DomainName = $domain; StudentUser = $c.user; StudentPassword = $c.password; PeerComputers = $peers; OwnOu = $ou }
    $lines | ForEach-Object { Write-Host $_ -ForegroundColor ($_ -like 'PASS*' ? 'Green' : 'Red') }
    $failed += @($lines | Where-Object { $_ -like 'FAIL*' }).Count
}
Write-Host ''
if ($failed) { Write-Host "$failed Prüfung(en) fehlgeschlagen." -ForegroundColor Red; exit 1 }
Write-Host 'Alle Smoke-Tests bestanden.' -ForegroundColor Green
