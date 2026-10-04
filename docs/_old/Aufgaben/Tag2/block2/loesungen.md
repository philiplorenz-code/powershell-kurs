---  
id: loesungen-aufgabenblock-2-tag-2  
title: Lösungen – Tag 2 - Aufgabenblock 2 – CSV, Prozesse, Remoting & Module  
sidebar_position: 20  
---

# 💡 Lösung zu Aufgabe 1 – CSV-Dateien analysieren  
```powershell
# Import
$mitarbeiter = Import-Csv -Path "C:\Daten\Mitarbeiter.csv"

# Filter
$it = $mitarbeiter | Where-Object { $_.Abteilung -eq "IT" }

# Sortierung
$sortiert = $it | Sort-Object Alter

# Export
$sortiert | Export-Csv -Path "C:\Daten\Mitarbeiter_IT.csv" -NoTypeInformation
```
> Ergebnis: Eine sortierte CSV-Datei mit allen IT-Mitarbeitern.

---

# 💡 Lösung zu Aufgabe 2 – Prozesse analysieren  
```powershell
$prozesse = Get-Process | Where-Object { $_.WorkingSet -gt 150MB } | Sort-Object CPU -Descending
$prozesse | Export-Csv -Path "C:\Daten\TopProzesse.csv" -NoTypeInformation
```
> Tipp: Die Spalte `WorkingSet` zeigt den aktuell belegten Arbeitsspeicher an.

---

# 💡 Lösung zu Aufgabe 3 – Dienste verwalten  
```powershell
$dienste = Get-Service | Where-Object { $_.Status -eq "Running" -and $_.Name -like "W*" }
$dienste | Export-Csv -Path "C:\Daten\Dienste_W.csv" -NoTypeInformation

# Kommentarbeispiel:
# Diese Datei könnte täglich generiert werden, um bestimmte Dienste im Monitoring zu verfolgen.
```
> Durch Filterung und Export kannst du so einen täglichen Report erstellen.

---

# 💡 Lösung zu Aufgabe 4 – PowerShell-Remoting  
```powershell
Test-WSMan localhost

Invoke-Command -ComputerName localhost -ScriptBlock {
    Get-Service | Select-Object -First 3
} | Out-File "C:\Daten\Remote_Services.txt"

Write-Output "Remote-Befehl erfolgreich ausgeführt und gespeichert."
```
> Wenn `Test-WSMan` erfolgreich antwortet, funktioniert WinRM lokal.  

---

# 💡 Lösung zu Aufgabe 5 – Eigenes Modul  
```powershell
# 1. Modulstruktur
New-Item -Path "C:\PSModuleDemo\MyTools" -ItemType Directory

# 2. PSM1-Datei
@"
function Get-Hello {
    Write-Output 'Hallo PowerShell!'
}
Export-ModuleMember -Function Get-Hello
"@ | Out-File "C:\PSModuleDemo\MyTools\MyTools.psm1" -Encoding UTF8

# 3. Manifest
New-ModuleManifest -Path "C:\PSModuleDemo\MyTools\MyTools.psd1" `
    -ModuleVersion "1.0.0" `
    -Author "WorkshopTeilnehmer" `
    -Description "Ein einfaches PowerShell-Demomodul" `
    -FunctionsToExport "Get-Hello"

# 4. Modul importieren
Import-Module "C:\PSModuleDemo\MyTools"

# 5. Funktion testen
Get-Hello
```
> Ausgabe: `Hallo PowerShell!`  

---
