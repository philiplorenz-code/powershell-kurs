---  
id: loesungen-aufgabenblock-2-tag-3  
title: Lösungen – Tag 3 - Aufgabenblock 2 – Web-APIs, WMI / CIM, Scheduling & Logging  
sidebar_position: 20  
---

# 💡 Lösung 1 – GitHub-API  
```powershell
$user = Invoke-RestMethod -Uri "https://api.github.com/users/octocat"
Write-Output "Login: $($user.login)"
Write-Output "Name: $($user.name)"
Write-Output "Repos: $($user.public_repos)"
$user | ConvertTo-Json | Out-File "C:\API\octocat.json"
```
> JSON-Antwort wird automatisch in ein PowerShell-Objekt konvertiert.  

---

# 💡 Lösung 2 – API-Fehlerbehandlung  
```powershell
try {
    $data = Invoke-RestMethod -Uri "https://api.github.com/users/falscherBenutzer"
}
catch {
    Write-Error "Fehler beim Abrufen der Daten: $_"
}
```
> Mit `try/catch` lassen sich Netzwerk- oder 404-Fehler elegant behandeln.  

---

# 💡 Lösung 3 – Systeminformationen mit CIM  
```powershell
$os  = Get-CimInstance -ClassName Win32_OperatingSystem |
       Select-Object Caption, Version
$sys = Get-CimInstance -ClassName Win32_ComputerSystem |
       Select-Object Manufacturer, Model

$os  | Export-Csv "C:\CIM\OS.csv"  -NoTypeInformation
$sys | Export-Csv "C:\CIM\System.csv" -NoTypeInformation
```
> `Get-CimInstance` ersetzt `Get-WmiObject` und ist WS-Man-basiert.  

---

# 💡 Lösung 5 – Logging mit Start-Transcript  
```powershell
Start-Transcript -Path "C:\Logs\LogDemo.log" -Append

Write-Output "Skriptstart: $(Get-Date)"
Get-Process | Select-Object -First 3
Write-Output "Skriptende: $(Get-Date)"

Stop-Transcript
```
> Die gesamte Konsolenausgabe wird in `C:\Logs\LogDemo.log` gespeichert.  

