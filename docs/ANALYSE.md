# Bestandsaufnahme: „PowerShell in 3 Tagen"

Ausgangsmaterial: Repository `philiplorenz-code/powershell-in-3-days` (Docusaurus). Dieses Repo ist die modernisierte Neufassung.

Stand der Analyse: 2026-10-04, Branch `modernize-course-2026`, Ausgangsstand `main` @ `3dd975d`.
Grundlage ist der komplette Inhalt von `/docs` (rund 19.400 Wörter, 38 Markdown-Dateien).

## 1. Inventar

| Bereich | Umfang |
|---|---|
| Tag 1 | 15 Kapitel (Shell-Grundlagen, Hilfe, Variablen, Datentypen, Pipeline, Objekte) |
| Tag 2 | 8 Kapitel (Operatoren, if/switch, Schleifen, Where/Sort/Select, CSV, Prozesse/Dienste, Remoting, Module) |
| Tag 3 | 9 Kapitel (Skriptaufbau, Funktionen, Fehlerbehandlung, Debugging, Credentials, Web-APIs, CIM, Scheduling, Logging) |
| Sonstiges | 2 Kapitel (SecretManagement, Offline-Module) |
| Aufgaben | 6 Blöcke, 5 mit Lösungen. Tag 1 Block 1 hat keine Lösungen. |
| Website | Docusaurus 3.7, Standard-Template, Footer und Logo verweisen auf Hotlinks |
| Container | `Dockerfile` nutzt `node:lts` und `serve`. `bkp/Dockerfile` und `docker-compose.yaml` sind Reste und verweisen auf ein nicht vorhandenes `dev`-Target. |
| CI | GitHub Action baut bei Push auf `main` ein Image nach GHCR |

### Verwendete Cmdlets und Technologien

- **Grundlagen:** `Get-Help`, `Update-Help`, `Get-Command`, `Get-Member`, `Get-Alias`, `Set-Alias`, `Write-Output`, `Get-ChildItem`, `Get-Item`, `Get-Location`, `Set-Location`, `Push-Location`, `Pop-Location`, `New-Item`, `Test-Path`
- **Pipeline:** `Where-Object`, `Sort-Object`, `Select-Object`, `ForEach-Object`, `Format-Table`, `Format-List`, `Out-File`
- **Daten:** `Import-Csv`, `Export-Csv`, `ConvertTo-Json`, `ConvertTo-SecureString`, `Get-Credential`, `[PSCustomObject]`, Hashtables, Arrays
- **Administration:** `Get-Process`, `Get-Service`, `Get-CimInstance`, `Invoke-Command`, `Enter-PSSession`, `Enable-PSRemoting`, `Test-WSMan`, `Register-ScheduledJob`, `schtasks.exe`, `Start-Transcript`
- **Module und Skripte:** `Install-Module`, `Find-Module`, `Import-Module`, `New-ModuleManifest`, `Register-SecretVault`, `Set-Secret`, `Register-PSRepository`, `Set-PSBreakpoint`, `Write-Debug`
- **Windows-spezifisch:** Registry-Provider (`HKLM:`), `Cert:`, `Env:`, ISE, Task Scheduler, WinRM/WSMan, WMI/CIM, Execution Policy
- **Nicht vorhanden:** Active Directory, Dateisystem-Verwaltung über Kopieren und Löschen, NTFS/SMB, Event Logs, `-WhatIf`/`-Confirm`, `Start-Service` und `Stop-Service`. Alle Praxisübungen laufen gegen lokale Daten, `localhost` oder GitHub.
- **Versionen:** Der Kurs nennt PowerShell 7 nur beim Task Scheduler (`pwsh.exe`). Sonst ist unklar, ob 5.1 oder 7 gemeint ist.
- **Externe Abhängigkeiten:** `api.github.com`, PSGallery, `docs.microsoft.com` (veraltete Domain), Marketplace-Links, Hotlinks auf eine private Domain für Favicon und Logo
- **Implizit vorausgesetzte Pfade:** `C:\Daten`, `C:\API`, `C:\CIM`, `C:\Logs`, `C:\Scripts`, `C:\PSModuleDemo`. Nirgends wird erklärt, dass die Ordner angelegt werden müssen.

## 2. Lernzielmodell und Abhängigkeitsprobleme

Legende: **K** = Konzept im Kapitel eingeführt, **U** = Konzept vorausgesetzt oder verwendet.

### Reihenfolgefehler (Konzept vor Stoff)

| # | Stelle | Problem | Maßnahme |
|---|---|---|---|
| D1 | Tag 1, Pipeline-Kapitel (110) und Tag-1-Block-2-Aufgaben 4 und 7 | Nutzen `Where-Object { $_ … -eq … }`, `$_`, Vergleichsoperatoren. Die Einführung kommt erst an Tag 2 (Kapitel 10 und 40). | Kurze Einführung von `$_` und `Where-Object` in das Pipeline-Kapitel. Aufgaben vereinfachen. Vertiefung bleibt an Tag 2. |
| D2 | Tag 1, Profil (70) und Block-1-Aufgabe 6 | `Set-Alias` wird erst im Alias-Kapitel (100) erklärt. Das Beispielprofil nutzt `function`, `param` und `if`, die erst an Tag 2 und 3 kommen. | Alias-Kapitel vor das Profil ziehen. Profilbeispiel auf Alias, Variable und eine Zeile Text kürzen. |
| D3 | Tag 1, Variablen (60) | Zeigt Hashtable, Array und Funktions-Scope vor Datentypen (120) und Datenstrukturen (140). | Reihenfolge ändern: Variablen → Datentypen → Mathe → Strings → Datenstrukturen. Funktionsbeispiel im Scope-Abschnitt entfernen und auf Tag 3 verweisen. |
| D4 | Tag 2, Module (80) und Block-2-Aufgabe 5 | Eigene Module bestehen aus Funktionen. `function` und `param` werden erst an Tag 3 (Kapitel 20) erklärt. | Kapitel teilen: „Module verwenden" (PSGallery, `Import-Module`, `Get-Module`) bleibt an Tag 2. „Eigene Module bauen" wandert hinter „Funktionen" an Tag 3. |
| D5 | Tag 3, Block 1 | Checkliste verspricht „Debugging einsetzen", aber es gibt keine Aufgabe. | Debugging-Aufgabe ergänzen (`Write-Verbose`, `Set-PSBreakpoint` auf eine Datei, die im Lab liegt). |
| D6 | Tag 3, Block 2 | Aufgabennummerierung springt von 3 auf 5. Aufgabe 4 (Task Scheduler) und die Remote-CIM-Abfrage aus der Checkliste fehlen. | Aufgaben ergänzen und neu nummerieren. |
| D7 | Tag 2, Block 1, Aufgabe 6 | Führt `Where-Object` und `Sort-Object` zusammen mit Operatoren, Verzweigungen und Schleifen auf. Das Kapitel dazu (40) steht aber hinter Schleifen (30) und die Aufgabe kommt davor in der Checkliste. | Kapitelreihenfolge Tag 2: Operatoren → Where/Sort/Select → if/switch → Schleifen. Die Pipeline-Filterung baut so direkt auf den Operatoren auf. |
| D8 | Tag 3, Fehlerbehandlung (30) | Beispiel 1.1 fängt einen nicht-terminierenden Fehler ohne `-ErrorAction Stop`. Der `catch`-Block läuft dadurch nie. Das Gegenbeispiel mit `$ErrorActionPreference` kommt erst danach. | Reihenfolge und Text korrigieren: erst zeigen, dass der Fehler durchläuft, dann `-ErrorAction Stop`. |
| D9 | Tag 3, Credentials (50) und Block-1-Aufgabe 4 | Aufgabe verlangt „sicher speichern", zeigt aber nur `ConvertTo-SecureString -AsPlainText -Force` mit festem Passwort. Dazu fehlt die Einordnung, was SecureString leistet und was nicht. | Kapitel um SecretManagement als Standardweg ergänzen und die Einordnung zu SecureString korrigieren (siehe unten). Aufgabe an Lab-Konto anpassen. |

### Weitere implizite Voraussetzungen

- **Ordner und Dateien:** Fast jede Praxisübung braucht einen Ordner (`C:\Daten` und weitere). Die Lösungen enthalten kein `New-Item`. Die Aufgabe „Mitarbeiter.csv" verlangt, die Datei zu erstellen, ohne dass vorher `Set-Content` oder `Out-File` vorkommen. → Das Lab legt `C:\Kurs\{Daten,Ausgabe,Logs,Skripte}` an und stellt Beispieldateien bereit.
- **Admin-Rechte:** `Enable-PSRemoting`, `Update-Help`, `Set-ExecutionPolicy -Scope LocalMachine`. Das Lab stellt jedem Teilnehmer ein lokales Admin-Konto (Domänenkonto in der lokalen Admin-Gruppe) bereit.
- **Internetzugang:** GitHub-API, PSGallery. Im Lab erlaubt.
- **Remoting-Aufgabe:** Läuft gegen `localhost` („simulieren"). Mit echtem Lab entfällt die Notwendigkeit. Aufgabe wird zu echtem Remoting gegen den Domain Controller und den Nachbarrechner.

## 3. Technisch veraltet oder falsch

| Stelle | Befund | Korrektur |
|---|---|---|
| `Register-ScheduledJob`, `New-JobTrigger` (Tag 3, 80) | Modul `PSScheduledJob` gibt es nur in Windows PowerShell 5.1, nicht in PowerShell 7. Das Beispiel schlägt in `pwsh` fehl. | Ersetzen durch `New-ScheduledTaskAction`, `New-ScheduledTaskTrigger`, `Register-ScheduledTask`. Lernziel „Skript zeitgesteuert ausführen" bleibt gleich. |
| `-NoTypeInformation` (Tag 2, CSV) | In PowerShell 7 ist das Verhalten Standard, der Parameter ist wirkungslos. In 5.1 ist er nötig. | Hinweis mit Versionsunterschied. In Lösungen weglassen und Hinweis auf 5.1 geben. |
| `Export-Csv -Encoding UTF8` | In 5.1 schreibt das ein BOM, in 7 nicht. Excel mit deutschem Gebietsschema erwartet `;` und BOM. | Hinweis ergänzen: `Export-Csv -Delimiter ';'` und `-UseCulture`. |
| `catch [System.IO.FileNotFoundException]` für `Get-Item` | `Get-Item` wirft `ItemNotFoundException`. Der spezifische Catch greift nie. | Beispiel mit `System.Management.Automation.ItemNotFoundException` und `$_.Exception.GetType().FullName` zur Ermittlung. |
| Verben `Say-Hello`, `Process-Data`, `Process-UserData`, `Calculate-Sum`, `Read-FileSafe` | Kapitel 40 lehrt genehmigte Verben (`Get-Verb`), die Beispiele verstoßen selbst dagegen. | Umbenennen in `Show-Greeting`, `Convert-…`, `Get-…`. |
| Funktionen mit `return` und `Write-Output` gemischt, `Main`-Funktion | Verwirrt Einsteiger über den Ausgabestrom. | Kurzer Abschnitt „Ausgabe ist alles, was nicht zugewiesen wird". `Main` entfernen, wenn kein Mehrwert. |
| `Write-Error` im `catch` als Standardreaktion | Erzeugt weiteren Fehler und macht das Skript schwer testbar. | Neben `Write-Warning` auch `throw` und `$PSCmdlet.ThrowTerminatingError` kurz erwähnen. |
| `SecureString` „speichert verschlüsselt" | Nur unter Windows (DPAPI) bei Export mit `ConvertFrom-SecureString`. Im Speicher ist er nur obfuskiert und unter Linux und macOS gar nicht geschützt. Microsoft rät von neuen Verwendungen ab. | Einordnung korrigieren, SecretManagement als Hauptweg. |
| Hinweis „ISE … voll funktionsfähig" | ISE ist Windows-PowerShell-5.1-only, nur noch im Wartungsmodus und läuft nicht mit PowerShell 7. | Als Legacy markieren, VS Code als Standard. |
| Extension „Bracket Pair Colorizer" | Eingestellt, in VS Code seit 1.60 eingebaut. | Entfernen, `Bracket Pair Colorization` als eingebaute Funktion nennen. |
| `docs.microsoft.com/de-de/powershell` | Domain umgeleitet auf `learn.microsoft.com`. | Link aktualisieren. |
| Tabelle PowerShell vs. CMD: „Sprache: Komplex", „ISE voll funktionsfähig" | Unscharf bis veraltet. | Neu fassen und Windows PowerShell 5.1 vs. PowerShell 7 ergänzen. |
| Execution Policy: „Restricted ist Standard auf Windows" | Gilt für Windows-Clients. Windows Server hat standardmäßig `RemoteSigned`. Auf Linux und macOS gibt es keine Execution Policy. | Präzisieren. |
| Remoting-Kapitel | Kein Hinweis auf PowerShell-7-Endpunkte (`PowerShell.7`), `Invoke-Command -Session`, SSH-Remoting, Double-Hop. | Ergänzen, knapp halten. |
| `Get-Process | Where CPU -ne $null` | Funktioniert. Aber die Vereinfachte Syntax (`Where-Object CPU -gt 10`) wird nicht gezeigt. | In Pipeline-Kapitel mit aufnehmen. |
| `Update-Help -Force` im Kurs „braucht Admin" | Stimmt für die Windows-PowerShell-Module in `System32`. Hilfe für PowerShell 7 liegt unter `$PSHOME`. Auch dafür sind Admin-Rechte nötig, wenn PowerShell 7 systemweit installiert ist. | Hinweis ergänzen, Befehl bleibt. |
| Repo: Hotlinks für Logo und Favicon | Abhängigkeit von einer privaten Domain. | Lokale Assets. |

### Links und Medien

- Offensichtlich tote oder veraltete Links: `docs.microsoft.com`, Bracket-Pair-Colorizer-Marketplace-Link.
- Screenshots gibt es nicht. Es sind nur Memes und Illustrationen eingebunden (`psmeme-*`, `array.webp`, `KeyValue.png`, `verbnoun-explain.png`). Mehrere Kapitel enthalten Platzhalter „Tipp zur Visualisierung: Eine begleitende Grafik könnte …" ohne Grafik. → Entweder durch Mermaid-Diagramme ersetzen oder entfernen.
- Docusaurus-Reste: `static/img/undraw_docusaurus_*`, `docusaurus.png`, `docusaurus-social-card.jpg`, `docs/Tag 2/img/docsVersionDropdown.png` und `localeDropdown.png` (Tag 2 und Tag 3).

## 4. Auffälligkeit im Repository (Datenschutz)

Das **öffentliche** Repository enthält unter `static/img/` fünf PDFs, die nicht zum Kurs gehören und nach den Dateinamen wie Rechnungen oder Dokumente aussehen:

`DE43TKO3HAEUI.pdf`, `DS-AEU-INV-DE-2024-222223025.pdf`, `LU45Y0CWPAEUI.pdf`, `LU47AMN4EAEUI.pdf`, `Secure_PDF_2024-01-10_ohnepwpdf.pdf`

Diese Dateien werden mit der Website ausgeliefert. Ich habe sie **nicht** geöffnet oder verarbeitet. In der neuen Website sind sie nicht enthalten. Sie bleiben aber in der Git-Historie von `main` erreichbar. Falls sie vertraulich sind: Dateien aus der Historie entfernen (`git filter-repo`) und die Dokumente als kompromittiert betrachten. Das entscheidest du.

## 5. Zielstruktur (Reihenfolge nach Lernlogik)

Die drei Tage bleiben erhalten. Verschoben werden nur Kapitel, die gegen die Regel „Übung nie vor Stoff" verstoßen.

**Tag 1 – Fundament und Shell**
1. PowerShell vs. CMD (mit 5.1 vs. 7)
2. Terminal, ISE und VS Code
3. Hilfesystem
4. Verb-Noun-Konvention
5. Navigation, Provider und Dateien (erweitert um `New-Item`, `Copy-Item`, `Remove-Item`, `-WhatIf`)
6. Aliase und Shortcuts *(vorgezogen)*
7. Pipeline und `Get-Member` (inklusive `Where-Object` Kurzfassung und Formatierung vs. Daten)
8. Variablen und Umgebungsvariablen *(nachgezogen)*
9. Datentypen und Formatierung
10. Mathematische Operationen
11. String-Manipulation
12. Datenstrukturen
13. „Denke in Objekten"
14. Profil
15. Execution Policies

**Tag 2 – Logik und Administration**
1. Vergleichsoperatoren
2. Where-Object, Sort-Object, Select-Object *(vorgezogen)*
3. Verzweigungen
4. Schleifen
5. CSV Import und Export
6. Prozess- und Dienstverwaltung (erweitert um `Start-Service`, `Stop-Service`, `Restart-Service`, `-WhatIf`)
7. Active Directory Einstieg *(neu, Core, klein)*
8. PowerShell-Remoting (echtes Remoting im Lab)
9. Module verwenden

**Tag 3 – Skripte und Praxis**
1. Funktionen und Parameter *(vor „Skripte aufbauen" gezogen, weil dieses Kapitel Funktionen nutzt)*
2. Skripte strukturiert aufbauen
3. Eigene Module bauen *(von Tag 2 verschoben, Optional)*
4. Fehlerbehandlung
5. Debugging
6. Anmeldeinformationen und Geheimnisse (SecretManagement)
7. Web-APIs (Optional)
8. WMI/CIM
9. Skripte planen (ScheduledTasks statt ScheduledJob)
10. Logging und Transcripts
11. Abschlussprojekt
12. **Optional: PowerShell im Zeitalter von KI** (ca. halber Tag, vollständig abkoppelbar)

## 6. Lab-Bedarf (abgeleitet aus den Übungen)

| Anforderung aus dem Kurs | Lab-Komponente |
|---|---|
| `Get-ChildItem C:\Users`, `C:\Windows`, `C:\Temp` | Standard-Windows |
| Beispiel-CSV, Arbeitsordner, Logs, Skripte | `C:\Kurs\{Daten,Ausgabe,Logs,Skripte}`, Beispieldateien `Mitarbeiter.csv` |
| Dienste mit „W…" und Start/Stop-Übungen | Standarddienste. Zusätzlich harmloser Übungsdienst oder Übungsdienst über `Spooler`/`BITS` (Beschränkung auf sichere Dienste) |
| Prozesse | Standard. Optional ein Lastprozess für `Stop-Process`-Übung (Notepad) |
| Remoting, CIM remote | Domänenmitgliedschaft, WinRM aktiv, Kerberos, Firewall-Regel |
| Active Directory | OUs, Benutzer, Gruppen, Demoobjekte |
| Task Scheduler | Standard-Windows (Rechte: lokaler Admin) |
| `Install-Module` (PSGallery), Web-API | Ausgehender Internetzugang |
| PowerShell 7 und VS Code | Installiert auf Teilnehmer-VMs |
| SecretManagement | Module `Microsoft.PowerShell.SecretManagement` und `SecretStore` vorinstalliert |
| Fehlerbehandlung, Debugging | Beispielskript-Ordner im Lab |

Nicht benötigt, bewusst weggelassen: IIS, DNS-Verwaltung, SMB-Freigaben mit NTFS-Rechten, Event-Log-Spezialfälle. Falls Übungen in Tag 2 den Dateizugriff über das Netzwerk benötigen (UNC), reicht eine einzelne Freigabe `\\DC01\Kursdaten`.

## 7. Hinweis zu inhaltlichem Stil

Die Kapitel sind durchgehend im Stil „Überblick, Beispiele, Zusammenfassung" geschrieben und wiederholen sich stellenweise (z. B. die Addition `5 + 5` vs. `"5" + "5"` steht in vier Kapiteln). Ich kürze Redundanz, wo sie die Lernkurve nicht trägt, schreibe aber keine Kapitel neu.
