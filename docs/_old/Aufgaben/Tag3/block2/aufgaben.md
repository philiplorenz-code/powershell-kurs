---  
id: aufgabenblock-2-tag-3  
title: Tag 3 - Aufgabenblock 2 – Web-APIs, WMI / CIM, Scheduling & Logging  
sidebar_position: 10  
---

## 🧩 Aufgaben-Checkliste  
1. Mit öffentlichen Web-APIs über Invoke-RestMethod arbeiten  
2. System-Infos über Get-CimInstance abrufen  
3. Eine Remote-CIM-Abfrage testen  
4. Ein Skript per Task Scheduler planen  
5. Eine Skriptausführung mit Start-Transcript protokollieren  

---

# 🧠 Aufgabe 1 – GitHub-API abfragen  
1. Sende mit `Invoke-RestMethod` eine GET-Anfrage an `https://api.github.com/users/octocat`.  
2. Gib die Felder **login**, **name** und **public_repos** formatiert aus.  
3. Speichere das Ergebnis als JSON in `C:\API\octocat.json`.  

> **Ziel:** Erste eigene API-Abfrage durchführen und Daten weiterverarbeiten.  

---

# 🧠 Aufgabe 2 – Fehlerbehandlung bei API-Zugriff  
1. Erstelle ein kleines Skript, das versucht, `https://api.github.com/users/falscherBenutzer` abzurufen.  
2. Verwende `try / catch`, um Fehler abzufangen.  
3. Gib im Fehlerfall eine verständliche Meldung aus.  

> **Ziel:** Sicherer Umgang mit API-Fehlern.  

---

# 🧠 Aufgabe 3 – Systeminformationen mit CIM  
1. Rufe mit `Get-CimInstance` Informationen zu Betriebssystem und Computersystem ab.  
2. Gib folgende Felder aus:  
   - OS: Caption, Version  
   - System: Manufacturer, Model  
3. Speichere beide Ergebnisse in separaten CSV-Dateien unter `C:\CIM\`.  

> **Ziel:** Lokale CIM-Abfragen verstehen und auswerten.  

---

# 🧠 Aufgabe 5 – Logging mit Start-Transcript  
1. Erstelle ein Skript `C:\Scripts\LogDemo.ps1`.  
2. Starte die Transkription am Anfang und speichere sie in `C:\Logs\LogDemo.log`.  
3. Gib mehrere Befehle aus (`Get-Date`, `Get-Process | Select -First 3` …).  
4. Beende die Transkription am Ende.  
5. Öffne die Log-Datei und prüfe, ob alle Ausgaben protokolliert wurden.  

> **Ziel:** Transkription eines kompletten Skripts nachvollziehen.  
