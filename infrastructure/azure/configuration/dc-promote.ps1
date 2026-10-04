<#
.SYNOPSIS
    Installiert AD DS und DNS und erstellt den Forest. Läuft über Azure Run Command (als SYSTEM).
    Idempotent: Ist der Server bereits Domain Controller, passiert nichts.
#>
param(
    [Parameter(Mandatory)][string]$DomainName,
    [Parameter(Mandatory)][string]$NetbiosName,
    [Parameter(Mandatory)][string]$SafeModePassword
)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# DomainRole 4 oder 5 = Domain Controller
if ((Get-CimInstance Win32_ComputerSystem).DomainRole -ge 4) {
    Write-Output 'DC01 ist bereits Domain Controller. Nichts zu tun.'
    exit 0
}

Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools | Out-Null

$secure = ConvertTo-SecureString $SafeModePassword -AsPlainText -Force
Install-ADDSForest `
    -DomainName $DomainName `
    -DomainNetbiosName $NetbiosName `
    -SafeModeAdministratorPassword $secure `
    -InstallDns `
    -Force `
    -NoRebootOnCompletion | Out-Null

# Neustart verzögert auslösen, damit Run Command noch erfolgreich zurückmelden kann
shutdown.exe /r /t 30 /c "AD DS Promotion abgeschlossen"
Write-Output 'Forest erstellt, Neustart in 30 Sekunden.'
