---  
id: loesungen-aufgabenblock-1-tag-2  
title: Lösungen – Tag 2 - Aufgabenblock 1 – Vergleichsoperatoren, Verzweigungen & Schleifen  
sidebar_position: 20  
---

# 💡 Lösung zu Aufgabe 1 – Vergleichsoperatoren  
```powershell
$zahl1 = 5
$zahl2 = 10

if ($zahl1 -lt $zahl2) { Write-Output "Zahl1 ist kleiner als Zahl2." }
if ($zahl1 -eq $zahl2) { Write-Output "Beide Zahlen sind gleich." }
if ($zahl2 -ge 10) { Write-Output "Zahl2 ist größer oder gleich 10." }

$text = "PowerShell"
if ($text -like "*Shell") { Write-Output "Treffer!" }
```

---

# 💡 Lösung zu Aufgabe 2 – Logische Ausdrücke  
```powershell
$alter = 25
$stadt = "Berlin"

if ( ($alter -gt 18) -and ($alter -lt 65) -and ($stadt -eq "Berlin") ) {
    Write-Output "Erwachsener in Berlin"
}
elseif (-not ($stadt -eq "Berlin")) {
    Write-Output "Nicht in Berlin wohnhaft"
}
else {
    Write-Output "Außerhalb des gültigen Bereichs"
}
```

---

# 💡 Lösung zu Aufgabe 3 – if/elseif/else-Struktur  
```powershell
$temperatur = 15

if ($temperatur -gt 25) {
    Write-Output "Es ist heiß."
}
elseif ($temperatur -ge 15 -and $temperatur -le 25) {
    Write-Output "Angenehm."
}
else {
    Write-Output "Kühl."
}
```

---

# 💡 Lösung zu Aufgabe 4 – switch mit Wildcards  
```powershell
$datei = "bericht_2025.csv"

switch -Wildcard ($datei) {
    "*.txt" { Write-Output "Textdatei erkannt."; break }
    "*.csv" { Write-Output "CSV-Datei erkannt."; break }
    default { Write-Output "Unbekannter Dateityp." }
}
```

---

# 💡 Lösung zu Aufgabe 5 – Schleifenarten im Vergleich  
```powershell
$zahlen = 1..5

# foreach
foreach ($z in $zahlen) { Write-Output "foreach: $z" }

# for
for ($i = 0; $i -lt $zahlen.Count; $i++) { Write-Output "for: $($zahlen[$i])" }

# while
$count = 0
while ($count -lt $zahlen.Count) {
    Write-Output "while: $($zahlen[$count])"
    $count++
}
```

---

# 💡 Lösung zu Aufgabe 6 – Where-, Sort- und Select-Object  
```powershell
Get-Process |
    Where-Object { $_.CPU -gt 10 } |
    Sort-Object CPU -Descending |
    Select-Object Name, CPU, Id
```
> Filtert und sortiert Prozesse nach CPU-Auslastung und zeigt relevante Spalten an.  

---

# 💡 Lösung zu Aufgabe 7 – Komplexes Beispiel  
```powershell
$staedte = @("Berlin", "München", "Hamburg", "Köln", "Leipzig")

foreach ($stadt in $staedte) {
    if ($stadt -eq "Berlin") {
        Write-Output "Hauptstadt gefunden!"
    }
    elseif ($stadt -like "L*") {
        Write-Output "Stadt mit L gefunden: $stadt"
    }
    else {
        Write-Output "Andere Stadt: $stadt"
    }
}
```
> Demonstriert kombinierte Nutzung von Vergleichsoperatoren, Schleifen und logischen Ausdrücken.  