<#
.SYNOPSIS
    Führt alle Musterlösungen der Übungsseiten auf PSLAB-01 als teilnehmer01 aus (erhöht, echte Anmeldung)
    und meldet pro Codeblock OK/ERR. Aufruf: ./lab.ps1 test-exercises
.PARAMETER Page
    Optional: nur Seiten, deren Name dieses Muster enthält (z. B. 'tag-2').
#>
param(
    [Parameter(Mandatory)][string]$ResourceGroup,
    [Parameter(Mandatory)][string]$TerraformDir,
    [string]$Page = '',
    [string]$Vm = 'PSLAB-01'
)
$ErrorActionPreference = 'Stop'
function ConvertTo-B64([string]$text) { [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($text)) }

$outputs = & terraform "-chdir=$TerraformDir" output -json | ConvertFrom-Json
$nn = $Vm -replace 'PSLAB-', ''
$cred = $outputs.student_credentials.value.$nn
$scripts = & (Join-Path $PSScriptRoot 'Build-ExerciseTests.ps1')
$helper = ConvertTo-B64 (Get-Content (Join-Path $PSScriptRoot 'run-as-user.ps1') -Raw)

$failed = 0; $total = 0
foreach ($key in $scripts.Keys | Where-Object { $_ -like "*$Page*" }) {
    $pageScript = "`$LabUser = '$($cred.user)'`n`$LabPassword = '$($cred.password)'`n" + $scripts[$key]
    $b64 = ConvertTo-B64 $pageScript
    $remote = @"
`$dec = { param(`$b) [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String(`$b)) }
. ([scriptblock]::Create((& `$dec '$helper')))
`$path = 'C:\Windows\Temp\exercise-page.ps1'
[IO.File]::WriteAllText(`$path, (& `$dec '$b64'), (New-Object Text.UTF8Encoding(`$true)))
`$cred = [pscredential]::new('$($cred.user)', (ConvertTo-SecureString '$($cred.password)' -AsPlainText -Force))
`$r = Invoke-AsUser -Credential `$cred -ScriptPath `$path -OutputPath 'C:\Windows\Temp\exercise-page.out' -TimeoutSeconds 1500
if (`$r.TimedOut) { 'RESULT`tERR`tTIMEOUT`tSeite hat das Zeitlimit überschritten' }
`$r.Output
Remove-Item `$path -ErrorAction SilentlyContinue
"@
    $tmp = New-TemporaryFile
    Set-Content -Path $tmp -Value $remote -Encoding utf8
    Write-Host "`n=== $key ===" -ForegroundColor Cyan
    $raw = az vm run-command invoke -g $ResourceGroup -n $Vm --command-id RunPowerShellScript --scripts "@$tmp" --query 'value[0].message' -o tsv
    Remove-Item $tmp -Force
    foreach ($line in ($raw -split "`n")) {
        if ($line -match '^RESULT\t(?<s>[^\t]+)\t(?<id>[^\t]+)\t?(?<m>.*)$') {
            $total++
            $ok = $Matches.s -in 'OK', 'OK*', 'LIMIT'
            if (-not $ok) { $failed++ }
            $color = if ($Matches.s -eq 'LIMIT') { 'Yellow' } elseif ($ok) { 'Green' } else { 'Red' }
            Write-Host ("{0,-5} {1}  {2}" -f $Matches.s, $Matches.id, $Matches.m.Trim()) -ForegroundColor $color
        } elseif ($line.Trim()) {
            Write-Host "      $($line.Trim())" -ForegroundColor DarkGray
        }
    }
}
Write-Host "`n$total Codeblöcke ausgeführt, $failed mit Fehler." -ForegroundColor ($failed ? 'Yellow' : 'Green')
exit ($failed ? 1 : 0)
