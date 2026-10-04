---  
id: aufgabenblock-1-tag-1  
title: Tag 1 - Aufgabenblock 1 – Grundlagen und Umgebung  
sidebar_position: 10  
---

# 🧠 Aufgabe 1 – PowerShell vs. CMD
Ermittle, wie PowerShell und CMD unterschiedliche Ergebnisse liefern:  
1. Öffne **CMD** und führe `dir C:\Users` aus.  
2. Öffne **PowerShell** und führe `Get-ChildItem -Path C:\Users` aus.  
3. Vergleiche die Ergebnisse:  
   - Wie unterscheiden sich Formatierung und Zusatzinformationen?  
   - Welche Variante liefert strukturiertere Daten?  

---

# 🧠 Aufgabe 2 – Hilfesystem entdecken
1. Führe `Get-Help Get-Process` aus.  
2. Zeige nur die Beispiele an (`Get-Help Get-Process -Examples`).  
3. Suche nach einem **about_-Thema** deiner Wahl, z. B. `Get-Help about_Aliases`.  
4. Liste alle verfügbaren Themen mit `Get-Help about_*`.  
5. Optional: Rufe die Online-Hilfe für `Get-Service` auf.  

---

# 🧠 Aufgabe 3 – Verb-Noun-Konvention verstehen
1. Führe `Get-Command -Verb Get` aus.  
2. Suche ein weiteres Verb, z. B. `New` oder `Set`, und liste alle Cmdlets dazu auf.  
3. Überlege: Welche Aktion beschreibt das Verb? Welches Objekt (Noun) wird angesprochen?   

---

# 🧠 Aufgabe 4 – Mathematische Berechnungen
1. Berechne in PowerShell:  
   - 12 + 8  
   - 15 / 3  
   - 17 % 4  
2. Speichere die Ergebnisse in Variablen und gib sie mit `Write-Output` aus.  
3. Berechne die Fläche eines Rechtecks mit Länge = 7 und Breite = 5.  
4. Wandle 5MB in Kilobyte um, indem du PowerShells Einheiten nutzt.  

---

# 🧠 Aufgabe 5 – Variablen & Umgebungsvariablen
1. Lege eine Variable `$userName` mit deinem Namen an.  
2. Erstelle eine Hashtable `$person` mit den Schlüsseln *Name* und *Alter*.  
3. Gib den TEMP-Pfad deines Systems mit `$env:TEMP` aus.  
4. Setze eine neue Umgebungsvariable `$env:Workshop = "PowerShell-Training"`.  
5. Prüfe mit `Get-ChildItem Env:`, ob sie erscheint.  

> **Ziel:** Mit normalen und Umgebungsvariablen sicher umgehen.

---

# 🧠 Aufgabe 6 – PowerShell Profile & Execution Policy
1. Zeige den Pfad zu deinem aktuellen PowerShell-Profil an (`$PROFILE`).  
2. Prüfe, ob die Datei existiert, und lege sie ggf. mit `New-Item` an.  
3. Öffne sie mit Notepad und füge am Ende hinzu:  
   ```powershell
   Set-Alias ll Get-ChildItem
   Write-Output "Willkommen in deinem personalisierten PowerShell-Profil!"
   ```  

---