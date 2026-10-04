---  
id: loesungen-aufgabenblock-2-tag-1  
title: Lösungen – Tag 1 - Aufgabenblock 2 – Navigation, Provider & Aliases  
sidebar_position: 20  
---

# 💡 Lösung zu Aufgabe 1 – Navigation im Dateisystem  
```powershell
Get-Location
Set-Location C:\Windows
Push-Location
Set-Location C:\Temp
Pop-Location
pwd
```
> `pwd` ist der Alias für `Get-Location`. Beide zeigen das aktuelle Verzeichnis.

---

# 💡 Lösung zu Aufgabe 2 – Arbeiten mit Providern  
```powershell
Set-Location Env:
Get-ChildItem
$env:USERNAME
Set-Location C:\
```
> Der **Environment-Provider** zeigt Variablen wie `USERNAME`, `TEMP`, `PATH` an.

---

# 💡 Lösung zu Aufgabe 3 – Aliases nutzen und eigene erstellen  
```powershell
Get-Alias
Get-Alias -Name ls
Set-Alias ll Get-ChildItem
ll
Remove-Item alias:ll
```
> Aliases erleichtern die Arbeit, sollten aber in Skripten vermieden werden.

---

# 💡 Lösung zu Aufgabe 4 – Erste Pipeline-Schritte  
```powershell
Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 | Format-Table -AutoSize
```
> Sortiert Prozesse nach CPU-Nutzung und zeigt die Top 5 übersichtlich an.

---

# 💡 Lösung zu Aufgabe 5 – Variablen & einfache Datentypen  
```powershell
$name = "Max"
$age = 30
$os = "Windows 11"
Write-Output "Hallo, ich bin $name, $age Jahre alt und nutze $os."
$age = 31
Write-Output "Hallo, ich bin $name, $age Jahre alt und nutze $os."
```
> String-Interpolation vereinfacht die dynamische Ausgabe von Variablenwerten.

---

# 💡 Lösung zu Aufgabe 6 – Arrays und Hashtables  
```powershell
$fruits = @("Apfel", "Banane", "Kirsche")
$fruits[1]

$car = @{
    Marke = "VW"
    Modell = "Golf"
    Baujahr = 2020
}
Write-Output "Auto: $($car.Marke) $($car.Modell) ($($car.Baujahr))"
```
> Arrays sind Listen, Hashtables speichern Schlüssel-Wert-Paare.

---

# 💡 Lösung zu Aufgabe 7 – Denke in Objekten  
```powershell
Get-Service | Get-Member
Get-Service | Select-Object Name, Status | Where-Object { $_.Status -eq "Running" } | Sort-Object Name

# Optional: In PSCustomObject umwandeln
$services = Get-Service | Where-Object { $_.Status -eq "Running" } | 
Select-Object -Property Name, Status |
ForEach-Object {
    [PSCustomObject]@{
        ServiceName = $_.Name
        ServiceStatus = $_.Status
    }
}
$services | Format-Table -AutoSize
```
> Arbeiten mit Objekten vermeidet Textparsing und erleichtert strukturierte Verarbeitung.  