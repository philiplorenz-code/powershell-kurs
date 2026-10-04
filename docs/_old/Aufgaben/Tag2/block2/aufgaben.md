---  
id: aufgabenblock-2-tag-2  
title: Tag 2 - Aufgabenblock 2 – CSV, Prozesse, Remoting & Module  
sidebar_position: 10  
---

## 🧩 Aufgaben-Checkliste  
1. CSV-Dateien importieren, filtern und exportieren  
2. Prozesse und Dienste analysieren  
3. Remote-Befehle ausführen  
4. Ein eigenes PowerShell-Modul erstellen  
5. Modul importieren und testen  

---

# 🧠 Aufgabe 1 – CSV-Dateien analysieren und exportieren  
1. Erstelle eine Datei `Mitarbeiter.csv` mit den Spalten `Name, Abteilung, Alter`.  
2. Importiere sie mit `Import-Csv`.  
3. Filtere nur Mitarbeiter der Abteilung "IT".  
4. Sortiere die Ergebnisse nach `Alter`.  
5. Exportiere die gefilterten Daten in eine neue Datei `Mitarbeiter_IT.csv`.  

> **Ziel:** CSV-Import, Filterung, Sortierung und Export praktisch anwenden.  

---

# 🧠 Aufgabe 2 – Prozesse analysieren  
1. Zeige alle Prozesse mit `Get-Process` an.  
2. Filtere Prozesse, die mehr als 150 MB RAM nutzen.  
3. Sortiere sie nach CPU-Zeit absteigend.  
4. Speichere die Ergebnisliste als CSV-Datei `TopProzesse.csv`.  

> **Ziel:** Prozessdaten auswerten und dokumentieren.  

---

# 🧠 Aufgabe 3 – Dienste verwalten  
1. Liste alle gestarteten Dienste auf.  
2. Filtere nur Dienste, deren Name mit „W“ beginnt.  
3. Exportiere das Ergebnis nach `Dienste_W.csv`.  
4. Ergänze einen Kommentar, der erklärt, wie du diesen Export in einem täglichen Monitoring verwenden könntest.  

> **Ziel:** Filterung und Automatisierung mit Dienstinformationen.  

---

# 🧠 Aufgabe 4 – PowerShell-Remoting simulieren (ohne echten Remote-PC)  
> Hinweis: Wenn du kein Remoting aktiv hast, führe die Befehle mit `localhost` aus.  

1. Teste die Verbindung mit `Test-WSMan localhost`.  
2. Führe mit `Invoke-Command` auf `localhost` den Befehl `Get-Service | Select-Object -First 3` aus.  
3. Leite die Ausgabe in eine Datei `Remote_Services.txt` um.  
4. Ergänze im Skript eine Ausgabe, die bestätigt, dass der Befehl erfolgreich war.  

> **Ziel:** Verständnis der Remoting-Grundlagen.  

---

# 🧠 Aufgabe 5 – Eigenes Modul erstellen und verwenden  
1. Erstelle den Ordner `C:\PSModuleDemo\MyTools`.  
2. Lege darin die Datei `MyTools.psm1` an mit einer Funktion `Get-Hello`, die „Hallo PowerShell!“ ausgibt.  
3. Erstelle ein Manifest mit `New-ModuleManifest`.  
4. Lade das Modul mit `Import-Module`.  
5. Teste die Funktion.  

> **Ziel:** Modulaufbau und Import verstehen.  

---

✅ **Validierung:**  
Alle Aufgaben orientieren sich an den praktischen Beispielen der Kapitel und fördern das eigenständige Arbeiten mit CSV-Dateien, Prozessen, Diensten, Remoting und Modulen.  
