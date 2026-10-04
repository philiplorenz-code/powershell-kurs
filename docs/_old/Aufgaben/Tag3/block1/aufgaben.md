---  
id: aufgabenblock-1-tag-3  
title: Tag 3 - Aufgabenblock 1 – Skriptstruktur, Funktionen, Fehlerbehandlung & Debugging  
sidebar_position: 10  
---

## 🧩 Aufgaben-Checkliste  
1. Skriptheader & Struktur aufbauen  
2. Funktionen mit Parametern erstellen  
3. Fehlerbehandlung mit try/catch umsetzen  
4. Debugging einsetzen  
5. Anmeldeinformationen sicher verwenden  

---

# 🧠 Aufgabe 1 – Skriptheader & Struktur  
1. Lege eine neue Datei `DemoScript.ps1` an.  
2. Erstelle einen Skriptheader mit **Zweck**, **Autor**, **Datum** und **Version**.  
3. Implementiere eine Funktion `Show-DateTime`, die das aktuelle Datum und die Uhrzeit anzeigt.  

> **Ziel:** Eine saubere Grundstruktur für PowerShell-Skripte aufbauen.  

---

# 🧠 Aufgabe 2 – Funktionen & Parameterblöcke  
1. Erstelle eine Funktion `Get-Greeting` mit den Parametern `$Name` und `$Language`.  
2. Verwende `[ValidateSet("DE","EN","FR")]` für `$Language`.  
3. Gib eine Begrüßung in der gewählten Sprache aus.  
4. Teste die Funktion mit verschiedenen Parametern.  

> **Ziel:** Umgang mit Parametern und Validierungen festigen.  

---

# 🧠 Aufgabe 3 – Fehlerbehandlung mit try/catch  
1. Schreibe eine Funktion `Read-FileSafe`, die versucht, eine Datei mit `Get-Content` zu lesen.  
2. Verwende einen `try/catch`-Block, um Fehler abzufangen.  
3. Gib im Fehlerfall eine verständliche Meldung aus.  
4. Teste die Funktion mit einem existierenden und einem nicht existierenden Dateipfad.  

> **Ziel:** Robuste Fehlerbehandlung in Funktionen anwenden.  


---

# 🧠 Aufgabe 4 – Anmeldeinformationen sicher speichern  
1. Erstelle mit `Get-Credential` ein Anmeldeobjekt `$cred`.  
2. Zeige nur den Benutzernamen an.  
3. Wandle ein Beispielpasswort in einen SecureString um.  
4. Erstelle manuell ein neues PSCredential-Objekt mit `New-Object`.  

> **Ziel:** Sichere Speicherung und Verarbeitung von Zugangsdaten verstehen.  

