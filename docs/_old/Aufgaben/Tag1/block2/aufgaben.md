---  
id: aufgabenblock-2-tag-1  
title: Tag 1 - Aufgabenblock 2 – Navigation, Provider & Aliases  
sidebar_position: 10  
---

# 🧠 Aufgabe 1 – Navigation im Dateisystem  
1. Zeige dein aktuelles Verzeichnis mit `Get-Location` an.  
2. Wechsle in ein anderes Verzeichnis deiner Wahl mit `Set-Location`.  
3. Speichere dein aktuelles Verzeichnis mit `Push-Location`, gehe in `C:\Windows`, und kehre mit `Pop-Location` zurück.  
4. Überprüfe den Unterschied zwischen `pwd` und `Get-Location`.  

---

# 🧠 Aufgabe 2 – Arbeiten mit Providern  
1. Wechsle in den **Environment-Provider** mit `Set-Location Env:`.  
2. Liste alle Umgebungsvariablen mit `Get-ChildItem` auf.  
3. Zeige den Wert der Variablen `USERNAME` an.  
4. Wechsle zurück ins Dateisystem mit `Set-Location C:\`.  

---

# 🧠 Aufgabe 3 – Aliases nutzen und eigene erstellen  
1. Liste alle verfügbaren Aliases mit `Get-Alias` auf.  
2. Finde heraus, welcher Befehl hinter `ls` steckt.  
3. Erstelle einen eigenen Alias `ll` für `Get-ChildItem`.  
4. Teste ihn und lösche ihn anschließend mit `Remove-Item alias:ll`.    

---

# 🧠 Aufgabe 4 – Erste Pipeline-Schritte  
1. Führe `Get-Process | Sort-Object CPU -Descending` aus.  
2. Ergänze: Zeige nur die ersten 5 Prozesse mit `Select-Object -First 5`.  
3. Verwende `Format-Table -AutoSize` für eine saubere Darstellung.  

---

# 🧠 Aufgabe 5 – Variablen & einfache Datentypen  
1. Lege Variablen für deinen Namen, dein Alter und dein Lieblingsbetriebssystem an.  
2. Verwende String-Interpolation, um eine Ausgabe wie folgt zu erzeugen:  
   `"Hallo, ich bin Max, 30 Jahre alt und nutze Windows 11."`  
3. Wandle dein Alter testweise in eine andere Zahl um und zeige die neue Ausgabe.  

---

# 🧠 Aufgabe 6 – Arrays und Hashtables  
1. Erstelle ein Array `$fruits` mit drei Obstsorten.  
2. Gib das zweite Element aus.  
3. Erstelle eine Hashtable `$car` mit den Schlüsseln *Marke*, *Modell* und *Baujahr*.  
4. Gib die Werte der Hashtable formatiert aus.  

---

# 🧠 Aufgabe 7 – Denke in Objekten  
1. Führe `Get-Service` aus und untersuche das Ergebnis mit `Get-Member`.  
2. Gib nur die Eigenschaften *Name* und *Status* aus.  
3. Filtere nur aktive Services (`Status -eq "Running"`) und sortiere sie alphabetisch.  

---