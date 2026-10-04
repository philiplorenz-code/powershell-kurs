<#
.SYNOPSIS
    Erzeugt aus den Übungsseiten der Website ausführbare Testskripte: pro Seite ein Skript, das alle
    Lösungen (und die Ausgangsdaten der Aufgaben) in der Reihenfolge der Seite ausführt.

.DESCRIPTION
    Dadurch wird geprüft, dass jede Musterlösung auf der Website tatsächlich im Lab läuft.
    Interaktive Befehle werden ersetzt (Read-Host, Get-Credential) oder übersprungen (Enter-PSSession, code, Update-Help).
#>
param(
    [string]$DocsRoot = (Join-Path $PSScriptRoot '../../../website/src/content/docs'),
    [string]$OutDir
)
$ErrorActionPreference = 'Stop'

$pages = @(
    'uebungen/tag-1-block-1', 'uebungen/tag-1-block-2', 'uebungen/tag-1-block-3',
    'uebungen/tag-2-block-1', 'uebungen/tag-2-block-2', 'uebungen/tag-2-block-3',
    'uebungen/tag-3-block-1', 'uebungen/tag-3-block-2', 'uebungen/tag-3-block-3',
    'uebungen/abschlussprojekt', 'ki/uebungen'
)

# Befehle, die nicht automatisch laufen können. Sie werden auskommentiert und im Bericht als SKIP gezählt.
$skipPatterns = @(
    '^\s*Enter-PSSession\b', '^\s*Exit-PSSession\b', '^\s*code\s', '^\s*Update-Help\b', '^\s*notepad\b'
)

# Preamble: ersetzt interaktive Eingaben. $LabUser/$LabPassword stellt der Aufrufer bereit.
$preamble = @'
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'
function Read-Host { param([string]$Prompt, [switch]$AsSecureString) if ($AsSecureString) { ConvertTo-SecureString 'Lab-Test-Passw0rd-12!' -AsPlainText -Force } else { 'test' } }
function Get-Credential { param($UserName, $Message, $Credential) [pscredential]::new($LabUser, (ConvertTo-SecureString $LabPassword -AsPlainText -Force)) }
function Report([string]$id, [string]$status, [string]$msg) { "RESULT`t$status`t$id`t$($msg -replace '\s+', ' ')" }
Set-Location C:\Kurs
'@

function Get-Exercises([string]$text) {
    foreach ($m in [regex]::Matches($text, '(?s)<Uebung\s+([^>]*?)>(.*?)</Uebung>')) {
        $attrs = $m.Groups[1].Value
        $nr = if ($attrs -match 'nr="([^"]*)"') { $Matches[1] } else { '?' }
        $body = $m.Groups[2].Value
        $loes = [regex]::Match($body, '(?s)<Loesung[^>]*>(.*?)</Loesung>')
        $task = if ($loes.Success) { $body.Substring(0, $loes.Index) } else { $body }
        [pscustomobject]@{ Nr = $nr; Task = $task; Solution = if ($loes.Success) { $loes.Groups[1].Value } else { '' } }
    }
}
function Get-CodeBlocks([string]$text) {
    foreach ($m in [regex]::Matches($text, '(?s)```(?:powershell|pwsh)\r?\n(.*?)```')) { $m.Groups[1].Value }
}

$result = [ordered]@{}
foreach ($page in $pages) {
    $file = Join-Path $DocsRoot "$page.mdx"
    $text = Get-Content $file -Raw
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine($preamble)
    $count = 0
    foreach ($ex in Get-Exercises $text) {
        $id = "$($page.Split('/')[-1]) $($ex.Nr)"
        # Ausgangsdaten der Aufgabe (z. B. $zeile = ...) nur, wenn sie als Code in der Aufgabe stehen
        # und keine Datei-Inhalte sind. Dateiinhalte (Summe.ps1) legt die Lösung bzw. der Test selbst an.
        $blocks = @()
        foreach ($b in Get-CodeBlocks $ex.Task) { $blocks += [pscustomobject]@{ Kind = 'Aufgabe'; Code = $b } }
        foreach ($b in Get-CodeBlocks $ex.Solution) { $blocks += [pscustomobject]@{ Kind = 'Lösung'; Code = $b } }
        # Spezialfall Debugging-Übung: Summe.ps1 liegt als Codeblock in der Aufgabe und soll als Datei existieren
        if ($id -eq 'tag-3-block-2 2.4') {
            $summe = ($blocks | Where-Object { $_.Kind -eq 'Aufgabe' -and $_.Code -match '\$summe = 0' } | Select-Object -First 1).Code
            $blocks = @([pscustomobject]@{ Kind = 'Setup'; Code = "@'`n$summe'@ | Set-Content C:\Kurs\Skripte\Summe.ps1" }) + @($blocks | Where-Object { $_.Code -notmatch '\$summe = 0' })
        }
        $i = 0
        foreach ($b in $blocks) {
            $i++
            $lines = $b.Code -split "`r?`n"
            $skipped = 0
            $lines = $lines | ForEach-Object {
                $l = $_
                foreach ($pat in $skipPatterns) { if ($l -match $pat) { $skipped++; return "# SKIP: $l" } }
                $l
            }
            $code = $lines -join "`n"
            # Syntaxprüfung beim Erzeugen
            $err = $null
            [void][System.Management.Automation.Language.Parser]::ParseInput($code, [ref]$null, [ref]$err)
            $blockId = "$id #$i ($($b.Kind))"
            if ($err.Count) {
                [void]$sb.AppendLine("Report '$blockId' 'SYNTAX' '$($err[0].Message -replace "'", "''")'")
                continue
            }
            [void]$sb.AppendLine('$Error.Clear(); $__s = ''OK''; $__m = ''''')
            [void]$sb.AppendLine('try { . {')
            [void]$sb.AppendLine($code)
            [void]$sb.AppendLine('} *> $null } catch { $__s = ''ERR''; $__m = $_.Exception.Message }')
            [void]$sb.AppendLine('if ($__s -eq ''OK'' -and $Error.Count) { $__s = ''ERR''; $__m = (($Error | ForEach-Object { $_.Exception.Message }) | Select-Object -First 2) -join '' | '' }')
            [void]$sb.AppendLine("if (`$__s -eq 'OK' -and $skipped -gt 0) { `$__m = 'teilweise übersprungen' ; `$__s = 'OK*' }")
            [void]$sb.AppendLine("Report '$blockId' `$__s `$__m")
            $count++
        }
    }
    $result[$page] = $sb.ToString()
}

if ($OutDir) {
    New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
    foreach ($k in $result.Keys) { Set-Content -Path (Join-Path $OutDir (($k -replace '/', '_') + '.ps1')) -Value $result[$k] -Encoding utf8 }
}
$result
