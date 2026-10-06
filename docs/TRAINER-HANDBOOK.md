# Trainer-Handbuch: PowerShell in 3 Tagen

Nur für den Trainer. Einmal komplett vor dem Kurs lesen, danach als Nachschlagewerk nutzen.
Dieses Dokument enthält Teilnehmerdaten und gehört **nicht** auf die öffentliche Kursseite.

Ergänzende Dokumente: [`TRAINER.md`](../TRAINER.md) (Lab-Betrieb, Befehle), [`LAB-HOWTO.md`](LAB-HOWTO.md) (Lab für Teilnehmer), [`ARCHITECTURE.md`](../ARCHITECTURE.md) (Entscheidungen).

## Inhalt

- [A. Kursüberblick](#a-kursüberblick) · [B. Vorbereitung](#b-vorbereitung-vor-dem-kurs) · [C. Trainer-Guide je Tag](#c-trainer-guide-für-jeden-tag)
- [D. Themenblöcke im Detail](#d-themenblöcke-im-detail) · [E. Troubleshooting](#e-troubleshooting) · [F. Moderation](#f-moderationshinweise)
- [G. Side Quests](#g-side-quests) · [H. KI-Session](#h-ki-session-optional) · [I. Referenzen](#i-referenzen-und-fundorte) · [J. Annahmen](#j-annahmen-und-offene-punkte)

**Kurzschreibweise für Verweise**

| Kürzel | Bedeutung |
|---|---|
| **Folie n** | Folie n der Präsentation (`slides/index.html`, live: `…/slides/`) |
| **Kap.** | Kapitelseite der Kursseite, Datei unter `website/src/content/docs/tag-N/…` |
| **Ü n.m** | Übung auf den Seiten unter `website/src/content/docs/uebungen/` (siehe Tabelle I.2) |
| Kursseite | `https://powershell-kurs.philiplorenz.com` |

---

## A. Kursüberblick

### Zielgruppe und Teilnehmer

Anfänger und Windows-/M365-Administratoren mit teilweise ersten PowerShell-Erfahrungen. Drei Teilnehmer (aus der Anmeldeliste; Angaben zu den Firmen aus öffentlichen Quellen):

| # | Teilnehmer | Firma | Was man über die Firma weiß | Lab-Konto |
|---|---|---|---|---|
| 1 | Florian Wastl | qualido GmbH | Softwarehersteller (Aschau im Chiemgau, gegründet 2005), Produkt „qualido manager" für Qualitätsmanagement (Dokumentenlenkung, Audits, Schulungen), ursprünglich fürs Gesundheitswesen. Eher Entwicklungs- und Hosting-Umfeld. | `teilnehmer01` → `PSLAB-01` |
| 2 | Michael Hasse | Lafim-Diakonie | Großer Sozialträger in Brandenburg (Potsdam), rund 3.250 Mitarbeitende, über 40 Standorte (Senioren-, Behinderten-, Jugendhilfe). Viele verteilte Standorte, Fachanwendungen (z. B. Leistungsabrechnung). | `teilnehmer02` → `PSLAB-02` |
| 3 | Matthes Lummer | Neuwoba | Wohnungsbaugenossenschaft Neubrandenburg (1954), rund 54 Beschäftigte, 2026 geplante Investitionen ca. 30 Mio. €. Kleine IT in einem Immobilienunternehmen. | `teilnehmer03` → `PSLAB-03` |

Quellen: [Bayern International](https://bayern-international.de/en/company-database/company-details/qualido-gmbh-1040290), [Softguide](https://www.softguide.de/firma/qualido-gmbh), [devjobs.de](https://en.devjobs.de/job/edfd265c692665951d51d38c0c15a7f4), [Nordkurier](https://www.nordkurier.de/regional/neubrandenburg/diese-mega-projekte-stehen-in-den-naechsten-monaten-an-4235603).

### Zu den Personen selbst

**Recherche-Ergebnis (06.10.2026):** Eine gezielte Websuche je Person (Name plus Firma) hat **nichts Belastbares** ergeben. Es gab nur Treffer zu anderen Menschen mit ähnlichen Namen, die ich verworfen habe, um niemanden zu verwechseln. LinkedIn-Profile sind ohne Anmeldung nicht auswertbar. Ich habe bewusst nur nach beruflich öffentlich Sichtbarem gesucht und nichts Privates aufgenommen. Deshalb gilt: **Über die Personen weiß ich nur, was in der Anmeldeliste steht** (Name, Firma, Firmen-Mailadresse).

**Hypothesen (nicht belegt, nur zur Vorbereitung):** Sie leiten sich ausschließlich aus Firmentyp und Mail-Domain ab. Am Montag nicht als Wahrheit behandeln, sondern in der Vorstellungsrunde bestätigen oder verwerfen (Folie 4).

| # | Firmentyp | Mögliche Rolle (Hypothese) | Mögliche Anknüpfungspunkte (Hypothese) |
|---|---|---|---|
| 1 | Softwarehersteller (Qualitätsmanagement-Software) | eher Entwicklung, Betrieb oder Hosting | Deployment- und Betriebsautomatisierung, Konfigurationsprüfung, Lab als Infrastruktur-as-Code (Folie 16) |
| 2 | Großer Sozialträger, viele Standorte | Systemadministration für verteilte Standorte | Remoting auf viele Rechner (Tag 2), Inventarisierung (Abschlussprojekt), AD-Pflege (Tag 2) |
| 3 | Kleine IT in einer Wohnungsgenossenschaft | vermutlich Generalist, Server, Clients, Benutzerverwaltung | Benutzer- und Gruppenpflege per CSV/AD, wiederkehrende Berichte, Zeitpläne (Tag 3) |

**Fragen für den Einstieg, um die Hypothesen zu prüfen:** Welche Windows-Server-Versionen und welches Active Directory (lokal, Entra ID, hybrid)? Wie viele Server und Clients betreust du allein? Welche Aufgabe wiederholst du pro Woche am häufigsten? Gibt es schon Skripte (von wem, wo liegen sie)? Microsoft 365 im Einsatz, und wer verwaltet es?

**Was ich über die IT der Firmen nicht weiß** (am ersten Morgen erfragen, Folie 4 und 5): Windows-Server-Versionen, Active Directory oder Entra ID oder Hybrid, Microsoft 365, vorhandene Skripte, Wer administriert wie viele Server.

**Kontext** (Annahme): Der Kurs läuft im Rahmen einer Heise-Academy-Schulung „PowerShell für Systemadministratoren – Effiziente Automatisierung und Verwaltung", drei Tage. Das Datum in der Anmeldeliste lautet 7.–9. Oktober, ich gehe von 2026 aus.

### Lernziele

Nach drei Tagen können die Teilnehmer:

1. PowerShell als **objektorientierte Shell** erklären und die Pipeline sicher einsetzen.
2. Cmdlets selbst **finden und verstehen** (Hilfesystem, `Get-Command`, `Get-Member`).
3. Typische **Admin-Aufgaben** lösen: Dateien, Dienste, Prozesse, CSV, Active Directory, Remoting, CIM.
4. **Skripte** strukturieren (Funktionen, Parameter), Fehler behandeln, debuggen, Geheimnisse sicher behandeln, zeitgesteuert ausführen und protokollieren.
5. Code kritisch lesen und beurteilen (Grundlage für den Einsatz von KI).

### Voraussetzungen und erwartetes Wissensniveau

Windows-Administrationsgrundlagen, Netzwerkbegriffe. **Keine** Programmierkenntnisse nötig. Einige haben schon Skripte ausgeführt oder angepasst. Das Niveau ist am ersten Morgen abzufragen (Folie 4). Meine Annahme: Alle drei kennen `Get-Service`/`Get-Process` oder Ähnliches, aber keine sicher aufgebaute Pipeline.

### Kursphilosophie

- **Orientierung statt Programm** (Folie 6): Die Gruppe ist klein, deshalb Raum für reale Probleme.
- **Verstehen vor Delegieren**: Übungen ohne KI (Folie 7 und 9). KI-Block optional.
- **Ergebnisse mitnehmen**: Jede Person verlässt den Kurs mit etwas Konkretem für den Alltag (Ziel: ein eigenes kleines Skript für eine reale Aufgabe).
- **Theorie → Beispiel → Übung → Anwendung** (Folie 14).

### Wichtigste Outcomes

1. Sicherer Umgang mit Pipeline und Objekten (Tag 1).
2. Abfragen und Änderungen in AD und auf mehreren Rechnern (Tag 2).
3. Ein eigenes, sauber aufgebautes Skript (`Get-ServerInventar.ps1` oder ein Teilnehmerproblem) (Tag 3).
4. Das Lab als wiederverwendbare Übungsumgebung (Folie 16).

---

## B. Vorbereitung vor dem Kurs

### B.1 Checkliste (am Vortag, ca. 60 Minuten)

| ☐ | Prüfpunkt | Wie | Erwartung |
|---|---|---|---|
| ☐ | Azure-Login | `az account show` | Subscription `1cea4233…` |
| ☐ | Lab läuft | `./lab.ps1 start`, dann `./lab.ps1 status` | 4 × „VM running", DC-Dienste `Running` |
| ☐ | VMs erreichbar | RDP auf `PSLAB-01` mit Zugang aus `./lab.ps1 credentials` | Anmeldung klappt |
| ☐ | DC erreichbar | `Test-WSMan DC01` von einer VM | Antwort |
| ☐ | Accounts vorhanden | `./lab.ps1 test` | alle PASS |
| ☐ | Übungen funktionieren | `./lab.ps1 test-exercises` | nur erwartete Fehler (siehe TRAINER.md) |
| ☐ | Auto-Shutdown beachtet | Standard 20:00 Uhr (täglich) | Morgens `./lab.ps1 start` |
| ☐ | RDP von überall | `./lab.ps1 status` zeigt Adressen | Teilnehmer-IPs unbekannt → offen (bewusst) |
| ☐ | Kursseite erreichbar | `https://powershell-kurs.philiplorenz.com` | 200, Zertifikat gültig |
| ☐ | Slides getestet | `…/slides/`, alle 18 Folien durchklicken, `F` für Vollbild | keine abgeschnittenen Elemente |
| ☐ | Hyperlinks getestet | Trainer-Folie (3) und Kontakt (18): Links anklicken | `me.philiplorenz.com`, LinkedIn öffnen |
| ☐ | QR-Codes getestet | Mit dem Handy scannen (Folie 3 und 18) | führen auf Website und LinkedIn |
| ☐ | Zugangsfolien | `./lab.ps1 slides` | `.secrets/slides/index.html` enthält pro Teilnehmer eine Folie |
| ☐ | Tools lokal | `pwsh`, `az`, `terraform`, Beamer-Adapter | vorhanden |
| ☐ | Zugangsdaten bereit | Chat-Nachricht je Teilnehmer vorbereiten | Passwörter **nicht** in den öffentlichen Folien |

### B.2 Fallback-Szenarien

| Szenario | Plan B |
|---|---|
| Azure/Lab nicht erreichbar | Lokale PowerShell 7 auf dem Teilnehmer-Laptop: Tag 1 funktioniert komplett lokal (außer Kap. 5 `C:\Kurs`-Ordner: lokal anlegen). Tag 2 AD und Remoting entfallen oder werden vorgeführt. |
| Eine VM kaputt | `./lab.ps1 reset-student N` (15–20 Min.), in der Zeit zu zweit arbeiten |
| RDP blockiert (Firmennetz) | Anderes Netz/Hotspot. Ersatz: Trainer-Maschine, Teilnehmer arbeiten zu zweit |
| Kursseite nicht erreichbar | Lokal: `cd website && npm ci && npm run dev`; Notfall: Kapiteltexte als Markdown im Repository |
| Slides nicht erreichbar | `cd slides && npm ci && npm start` (lokal, offline) |
| Internet im Raum schlecht | PSGallery- und API-Übungen (Ü Tag 2 Block 3 Nr. 3.9, Tag 3 Block 3 Nr. 3.1) überspringen |

### B.3 Vorab klären (Gruppe)

Wer bringt eigenen Laptop mit? RDP-fähig? Firmenproxy? Wunsch-Themen vorab per Mail abfragen (Teilnehmer-Probleme sammeln, Folie 5).

---

## C. Trainer-Guide für jeden Tag

Zeiten sind Orientierung (Annahme: 09:00 bis 17:00, ca. 15 Minuten Pause am Vor- und Nachmittag, 60 Minuten Mittag). **Puffer bewusst nutzen**, nicht jede Minute verplanen.

### Tag 1: Fundament

**Tagesziel:** Konsole sicher bedienen, Hilfe selbst finden, Pipeline und Objekte verstehen, Variablen und Datenstrukturen nutzen.
**Slides:** 1–10, danach Folie 11 (Tagesplan), Folie 17 (erster Befehl).
**Lab:** nur eigene VM (kein Domänenzugriff nötig).

| Zeit | Inhalt | Typ | Slides / Kap. / Ü |
|---|---|---|---|
| 09:00–10:00 | Willkommen, Vorstellung, Erwartungen, KI-Frage, Lab-Zugang | Diskussion | Folien 1–9, 17; Zugangsfolien (privat) |
| 10:00–10:30 | PowerShell 5.1 vs. 7, VS Code, erster Start | Live-Demo | Kap. `tag-1/01-powershell-vs-cmd`, `02-terminal-ise-vscode` |
| 10:30–10:45 | Pause | | |
| 10:45–11:30 | Hilfesystem, Verb-Noun | Demo + eigene Übung | Kap. `03-hilfesystem`, `04-verb-noun`; **Ü 1.1–1.3** (Seite *Tag 1 · Block 1*) |
| 11:30–12:30 | Navigation, Dateien, Aliase | Demo + eigene Übung | Kap. `05-navigation-provider`, `06-aliase-shortcuts`; **Ü 1.4–1.7** |
| 12:30–13:30 | Mittag | | |
| 13:30–14:45 | Pipeline und Objekte | Theorie/Demo + Übung | Kap. `07-pipeline`; **Ü 2.1–2.5** (*Block 2*, Teil Pipeline) |
| 14:45–15:00 | Pause | | |
| 15:00–16:15 | Variablen, Datentypen, Rechnen, Strings, Datenstrukturen, Objekte | Demo + Übung | Kap. `08-variablen` bis `13-denke-in-objekten`; **Ü 2.6–2.10** |
| 16:15–16:45 | Execution Policy, Profil (optional) | Gemeinsam | Kap. `15-execution-policies`, `14-profil`; **Ü 3.1–3.2** (*Block 3*) |
| 16:45–17:00 | Puffer; optional Mini-Inventar | Diskussion | **Ü 3.3** (Challenge) |

**Typische Verständnisprobleme**
- „Objekt statt Text": Warum sieht `Get-Service` aus wie Text, ist aber mehr? → `| Get-Member` zeigen.
- `Format-Table` mitten in der Pipeline (Daten gehen verloren). Kap. `07-pipeline`, Abschnitt 4.
- `"5" + 5` vs. `5 + "5"` (linker Operand entscheidet).
- Unterschied Array/Hashtable/`PSCustomObject`.

**Typische Fragen:** „Warum `$_`?", „Wann `Select-Object` und wann `Get-Member`?", „Was ist der Unterschied zwischen PowerShell 5.1 und 7?", „Brauche ich die ISE?".

**Langsamer machen:** Pipeline (13:30–14:45). Hier entscheidet sich der Kurs. Lieber 15 Minuten Zugabe aus dem Puffer.
**Optional vertiefen:** `Group-Object`, berechnete Eigenschaften (Kap. `tag-2/02-where-sort-select` Abschnitt 5), Aliase im Detail.
**Kürzen bei Zeitmangel:** Profil (Kap. 14, Optional), Strings (Kap. 11, nur Kernoperationen), Mathematik-Kapitel (nur `KB/MB/GB` zeigen).

### Tag 2: Logik und Administration

**Tagesziel:** Entscheidungen und Schleifen, Daten filtern und exportieren, Dienste steuern, Active Directory abfragen, Remoting.
**Slides:** Folie 12 (Tagesplan). **Lab:** `DC01` und alle `PSLAB-0x`.

| Zeit | Inhalt | Typ | Kap. / Ü |
|---|---|---|---|
| 09:00–09:20 | Rückblick, Fragen, Teilnehmerprobleme sichten | Diskussion | Folie 5 |
| 09:20–10:20 | Vergleiche, Where/Sort/Select | Demo + Übung | Kap. `tag-2/01-vergleichsoperatoren`, `02-where-sort-select`; **Ü 1.1–1.2** (*Tag 2 · Block 1*) |
| 10:20–10:35 | Pause | | |
| 10:35–11:45 | if/switch, Schleifen | Demo + Übung | Kap. `03-verzweigungen`, `04-schleifen`; **Ü 1.3–1.6** |
| 11:45–12:30 | CSV | Demo + Übung | Kap. `05-csv`; **Ü 2.1–2.2** (*Block 2*) |
| 12:30–13:30 | Mittag | | |
| 13:30–14:30 | Prozesse und Dienste | Lab | Kap. `06-prozesse-dienste`; **Ü 2.3–2.5** |
| 14:30–14:45 | Pause | | |
| 14:45–15:45 | Active Directory | Lab (DC01) | Kap. `07-active-directory`; **Ü 3.1–3.5** (*Block 3*) |
| 15:45–16:45 | Remoting | Lab (3 VMs) | Kap. `08-remoting`; **Ü 3.6–3.8** |
| 16:45–17:00 | Module (Ü 3.9), Abstimmung KI-Block | Diskussion | Kap. `09-module-verwenden`; Folie 15 |

**Typische Verständnisprobleme:** `-contains` vs. `-in` (Seite der Sammlung), `>` ist Umleitung, CSV liefert Strings (Sortierung!), `-Filter` bei AD ist kein PowerShell-Ausdruck, `$using:` bei Remoting, deserialisierte Objekte ohne Methoden.
**Typische Fragen:** „Warum `-Filter` und nicht `Where-Object` bei AD?" (Server-seitig, schneller), „Muss ich Admin sein für Remoting?" (Gruppe *Remote Management Users*, im Lab hat das nur DC01).
**Langsamer machen:** Remoting (Kerberos, Computername statt IP) und AD-Filter.
**Optional vertiefen:** `-ConfigurationName PowerShell.7`, Sessions (`New-PSSession`, Ü 3.8), `ForEach-Object -Parallel`.
**Kürzen:** Module-Kapitel, `switch` mit Regex, Challenge 1.6.
**Wichtig:** Spätestens mittags die **Teilnehmerprobleme** sichten (Folie 5) und entscheiden, was Tag 3 einfließt.

### Tag 3: Skripte und Praxis

**Tagesziel:** Wiederverwendbare Skripte bauen, robust machen (Fehler, Debugging, Secrets), automatisieren (Planen, Logging), Transfer in den Alltag.
**Slides:** Folie 13, ggf. 15. **Lab:** Internetzugang, Kursrechner.

| Zeit | Inhalt | Typ | Kap. / Ü |
|---|---|---|---|
| 09:00–09:20 | Rückblick, Fragen | Diskussion | |
| 09:20–10:30 | Funktionen, Skripte aufbauen | Demo + Übung | Kap. `tag-3/01-funktionen`, `02-skripte-aufbauen`; **Ü 1.1–1.4** (*Tag 3 · Block 1*), Bonus 1.5 (Modul, Kap. `03-eigene-module`) |
| 10:30–10:45 | Pause | | |
| 10:45–11:45 | Fehlerbehandlung, Debugging | Demo + Übung | Kap. `04-fehlerbehandlung`, `05-debugging`; **Ü 2.1–2.4** (*Block 2*) |
| 11:45–12:30 | Anmeldeinformationen und Secrets | Gemeinsam | Kap. `06-credentials-secrets`; **Ü 2.5–2.6** |
| 12:30–13:30 | Mittag | | |
| 13:30–14:15 | CIM, Zeitpläne, Logging | Lab | Kap. `08-cim`, `09-planen`, `10-logging`; **Ü 3.2–3.4** (*Block 3*); Web-APIs (Kap. `07-web-apis`, Ü 3.1) optional |
| 14:15–14:30 | Pause | | |
| 14:30–16:30 | **Wahlblock (gemeinsam entscheiden):** A) Abschlussprojekt oder B) PowerShell + AI | Lab / Gemeinsam | A: **Ü P.1** (Seite *Abschlussprojekt*), B: Kapitel H |
| 16:30–17:00 | Rückblick, Transfer in den Alltag, Feedback | Diskussion | Folie 18 |

**Typische Verständnisprobleme:** `try/catch` fängt nur terminierende Fehler (`-ErrorAction Stop`), Ausgabe aus Funktionen (alles ohne Zuweisung wird ausgegeben), `SecretStore` verlangt ein Passwort, geplanter Task läuft nur bei angemeldetem Benutzer.
**Typische Fragen:** „Wie speichere ich Credentials sicher?" (SecretManagement, Kap. 06), „Wo logge ich?" (Transcript vs. eigenes Log).
**Langsamer machen:** Fehlerbehandlung (der Aha-Moment liegt in `-ErrorAction Stop`).
**Kürzen bei Zeitmangel:** Web-APIs (Optional), eigene Module (Optional), Debugging-Breakpoints (VS Code reicht), CIM-Klassenliste.
**Wahlblock A** (Abschlussprojekt): ca. 90 Minuten eigenständig plus 30 Minuten Besprechung. Teilnehmerprobleme können das Projekt ersetzen.
**Wahlblock B** (KI): bis zu einem halben Tag, siehe H. Dann CIM/Planen/Logging auf 30 Minuten kürzen und das Abschlussprojekt als Hausaufgabe mitgeben.

---

## D. Themenblöcke im Detail

Pro Thema: **Verstehen** · **Erklären** · **Demo** · **Typische Fehler** · **Kontrollfragen** · **Übung**.

### D.1 Hilfesystem und Verb-Noun (Tag 1)

- **Verstehen:** Jeder Cmdlet-Name verrät, was er tut; Hilfe ist lokal und online verfügbar.
- **Erklären:** „Du musst nichts auswendig lernen. Du musst wissen, wo du nachschaust."
- **Demo:** `Get-Command -Noun Service`, `Get-Help Get-Service -Examples`, Syntaxzeile lesen (`[ ]` = optional).
- **Fehler:** Hilfe nie aktualisiert (`Update-Help` als Admin; im Lab hilft es ggf. vorab), `Get-Help` nur am Anfang gelesen.
- **Fragen:** „Wie findest du das Cmdlet zum Neustarten eines Dienstes?" (`Get-Command -Noun Service -Verb Restart`)
- **Übung:** Ü 1.2 und 1.3 (Seite *Tag 1 · Block 1*).

### D.2 Navigation, Dateien, `-WhatIf` (Tag 1)

- **Verstehen:** Provider machen Registry, Env, Zertifikate zu „Laufwerken". Verändernde Cmdlets kennen `-WhatIf`.
- **Demo:** `Set-Location HKLM:\`, `Remove-Item … -WhatIf`.
- **Fehler:** Vergessener `-Recurse`, Pfade mit Leerzeichen ohne Anführungszeichen.
- **Fragen:** „Was passiert bei diesem Befehl, bevor du ihn ausführst?"
- **Übung:** Ü 1.4, 1.5, 1.7.

### D.3 Pipeline und Objekte (Tag 1) ⭐

- **Verstehen:** Objekte statt Text; `Get-Member` zeigt Eigenschaften; `Format-*` nur am Ende.
- **Erklären:** Fließband mit Kisten. Jede Kiste hat Etikett (Typ) und Inhalt (Eigenschaften).
- **Demo:** Erst `Get-Service`, dann `| Get-Member`, dann `| Where-Object Status -eq 'Running' | Sort-Object DisplayName | Select-Object Name, Status`, dann das Gegenbeispiel `Format-Table | Export-Csv`.
- **Fehler:** `Format-Table` zu früh; `Select-Object Name` und danach Methoden erwarten; `$_` ohne Skriptblock.
- **Fragen:** „Welchen Typ hat das, was gerade durch die Pipeline läuft?", „Warum ist die CSV leer/kaputt?"
- **Übung:** Ü 2.1–2.5. **Nicht** die Lösung zeigen, solange jemand arbeitet; Ü 2.4 (Anzeige vs. Daten) gemeinsam auflösen.

### D.4 Variablen, Typen, Datenstrukturen (Tag 1)

- **Verstehen:** Variable = benannter Wert; Typ bestimmt Verhalten; Hashtable = Schlüssel/Wert; `PSCustomObject` = eigenes Objekt.
- **Demo:** `"5" + 5`, `.GetType()`, `$env:KURS`, `[PSCustomObject]@{…} | Format-Table`.
- **Fehler:** `$i:` in Strings (Scope-Fehler, `${i}` nutzen), `+=` bei großen Arrays, Hashtable-Schlüssel mit Leerzeichen.
- **Fragen:** „Was ergibt `5 + "5"` und warum?"
- **Übung:** Ü 2.6–2.10; Challenge 2.10 (freier Speicher in GB) als Brücke zu „Denke in Objekten".

### D.5 Operatoren, Filter, Schleifen (Tag 2)

- **Verstehen:** Vergleiche liefern True/False; `Where-Object` filtert Objekte; `foreach` wiederholt.
- **Demo:** `-like` vs. `-match`, `-contains` vs. `-in`, `foreach` über `Get-ChildItem`.
- **Fehler:** `>` statt `-gt`, `$null` rechts, Endlosschleife (`while` ohne Inkrement), `-eq` mit Platzhaltern.
- **Fragen:** „Wie viele Dateien sind größer als 10 KB, in einer Zeile?"
- **Übung:** Ü Tag 2 · Block 1; Challenge 1.6 (Städte) als Transfer.

### D.6 CSV, Prozesse und Dienste (Tag 2)

- **Verstehen:** Alles aus CSV ist Text. Steuern erst nach `-WhatIf`.
- **Demo:** `Import-Csv … | Sort-Object { [int]$_.Alter }`; `Stop-Service Spooler -WhatIf`.
- **Fehler:** Trennzeichen (`;` in Deutschland), `Stop-Process -Name *`, Admin-Rechte fehlen.
- **Fragen:** „Warum steht 9 hinter 30?"
- **Übung:** Ü 2.1–2.5 (*Tag 2 · Block 2*). Ü 2.5 (Monitoring) ist ein guter Anknüpfungspunkt für Teilnehmerprobleme.

### D.7 Active Directory (Tag 2) ⭐

- **Verstehen:** `-Filter` filtert auf dem Server; `-Properties` holt zusätzliche Attribute; Änderungen immer mit `-WhatIf`.
- **Demo:** `Get-ADUser -Filter "Department -eq 'IT'" -Properties Department`; `Search-ADAccount -AccountExpired -UsersOnly`; Zugriff verweigert in `GRP-IT` zeigen (Delegierung).
- **Fehler:** `Where-Object` statt `-Filter` (langsam), vergessene `-Properties`, Umlaute in `SamAccountName`.
- **Fragen:** „Wie findest du Benutzer ohne Abteilung?"
- **Übung:** Ü 3.1–3.5 (*Tag 2 · Block 3*). Teilnehmer arbeiten in ihrer OU `OU=T0N,OU=Uebung,OU=Kurs`.
- **Bezug zur Praxis:** Lafim-Diakonie und Neuwoba haben vermutlich AD mit Standortstrukturen. Fragen: „Wie viele OUs? Wer legt Benutzer an?".

### D.8 Remoting (Tag 2) ⭐

- **Verstehen:** Befehle laufen auf dem Ziel; Ergebnisse sind Kopien; Kerberos braucht den Computernamen.
- **Demo:** `Test-WSMan PSLAB-02`, `Invoke-Command PSLAB-02,PSLAB-03 { hostname }`, `$using:`, PS7-Endpunkt.
- **Fehler:** IP-Adresse statt Name, Double-Hop, `Get-Service -ComputerName` (gibt es in 7 nicht).
- **Fragen:** „Auf welchem Rechner läuft dieser Skriptblock?"
- **Übung:** Ü 3.6–3.8.

### D.9 Funktionen und Skripte (Tag 3)

- **Verstehen:** Funktion = benannter Skriptblock; `param()` macht ihn flexibel; Rückgabe ist alles, was nicht zugewiesen wird.
- **Demo:** `Show-Hallo` mit `Mandatory`, `ValidateSet`, `[CmdletBinding()]` + `-Verbose`.
- **Fehler:** Ausgabe-Pollution (`.Add()` ohne `$null =`), unerlaubte Verben (`Get-Verb`).
- **Fragen:** „Was gibt diese Funktion zurück?"
- **Übung:** Ü 1.1–1.4 (*Tag 3 · Block 1*).

### D.10 Fehlerbehandlung und Debugging (Tag 3) ⭐

- **Verstehen:** Zwei Fehlerarten; `-ErrorAction Stop` macht Fehler fangbar.
- **Demo:** Erst `try/catch` ohne `Stop` (`catch` läuft nicht!), dann mit `Stop`; Breakpoint in `Summe.ps1` (Ü 2.4).
- **Fehler:** `catch` leer lassen, `SilentlyContinue` überall, falscher Ausnahmetyp (`ItemNotFoundException`, nicht `FileNotFoundException`).
- **Fragen:** „Warum läuft der catch-Block nicht?"
- **Übung:** Ü 2.1–2.4.

### D.11 Secrets (Tag 3)

- **Verstehen:** `SecureString` verhindert Zufallsausgabe, ist kein Tresor; SecretManagement ist der Standard.
- **Demo:** `Set-Secret`, `Get-Secret`; Warnung bei `-AsPlainText -Force`.
- **Fehler:** Passwörter in Skripten und Logs; `Authentication None` ohne Verständnis.
- **Fragen:** „Wo liegt das Passwort im Skript?" (Nirgends.)
- **Übung:** Ü 2.5–2.6.

### D.12 CIM, Planen, Logging (Tag 3)

- **Verstehen:** `Get-CimInstance` ersetzt `Get-WmiObject`; Aufgabenplanung = Aktion + Trigger + Konto; Logging macht Läufe nachvollziehbar.
- **Demo:** `Get-CimInstance Win32_LogicalDisk`, `Register-ScheduledTask`, `Start-ScheduledTask`, `Get-ScheduledTaskInfo` (Ergebnis 0 = ok; 267009 läuft, 267011 noch nicht gelaufen).
- **Fehler:** Relative Pfade im Task, Konto ohne Rechte, `Register-ScheduledJob` (nur 5.1).
- **Übung:** Ü 3.2–3.4 (*Tag 3 · Block 3*).

---

## E. Troubleshooting

Nur Themen, die im Kurs vorkommen.

| Thema | Symptom | Ursache und Lösung |
|---|---|---|
| Version | `Get-ADUser` o. Ä. verhält sich anders | `powershell.exe` (5.1) statt `pwsh` (7) gestartet. `$PSVersionTable.PSVersion` prüfen |
| Execution Policy | „Skriptausführung ist deaktiviert" | `Get-ExecutionPolicy -List`; im Lab `RemoteSigned`. Für die Sitzung: `Set-ExecutionPolicy RemoteSigned -Scope Process`. Auf Servern prüfen, ob Gruppenrichtlinie überschreibt |
| Berechtigungen | `Stop-Service`: Zugriff verweigert | PowerShell **als Administrator** starten (Ü 2.4 *Tag 2 · Block 2*) |
| AD-Rechte | „Insufficient access rights" | Gewollt außerhalb der eigenen OU (Ü 3.4 *Tag 2 · Block 3*) |
| Remoting | „Kerberos … Cannot find the computer" | Name falsch/nicht im DNS; keine IP verwenden; `Test-WSMan` |
| Remoting | Zugriff verweigert | Teilnehmer ist nur auf `PSLAB-0x` Admin, nicht auf `DC01` |
| Variablen | `$i:` → Fehler | Scope-Syntax. `${i}:` oder `$($i):` |
| Arrays | `+=` langsam/Typfehler | Fester Array. `[System.Collections.Generic.List]` nur auf Nachfrage |
| Pipeline | Export leer/komisch | `Format-*` vor `Export-Csv` (Ü 2.4) |
| Objekte | Methode fehlt nach Remoting | Deserialisiert. Aktion im Skriptblock ausführen |
| Properties | `Select-Object Name` zeigt leer | Eigenschaft heißt anders → `Get-Member` |
| Cmdlets | `Get-WmiObject` unbekannt | Gibt es in PS 7 nicht. `Get-CimInstance` |
| Module | `Install-PSResource` schlägt fehl | Internet/Proxy; erstes Mal Vertrauensfrage bestätigen; `-Scope CurrentUser` |
| Fehlerbehandlung | `catch` läuft nicht | `-ErrorAction Stop` fehlt |
| SecretStore | Hängt/fragt Passwort | Beim ersten `Set-Secret` ein Tresorpasswort setzen |
| Task Scheduler | Aufgabe läuft nicht | Nur bei angemeldetem Benutzer; 267011 = noch nicht gelaufen, kurz warten |
| Lab | RDP verbindet nicht | `./lab.ps1 status`; `open-rdp`; Firmennetz sperrt 3389 |
| Lab | Konto gesperrt | 10 Fehlversuche → 15 Min. Sperre |
| Lab | AD antwortet nicht | DC braucht nach Start 2–5 Min. |
| Lab | VM weg/deallokiert | Auto-Shutdown 20:00 → `./lab.ps1 start` |

---

## F. Moderationshinweise

**Fragen stellen:** Vor jedem Demo-Befehl „Was erwartet ihr?" (Vorhersage). Nach jeder Demo „Warum?". Pipeline- und Fehlerbehandlungs-Demos leben davon.
**Selbst ausprobieren lassen:** Sofort nach jedem Konzept 5–10 Minuten (Ü der jeweiligen Seite). Teilnehmer tippen selbst, nicht Copy-and-Paste.
**Live Coding:** Pipeline aufbauen (Schritt für Schritt), Fehlerbehandlung (erst falsch, dann richtig), `Get-Help` im Gebrauch, Debugging mit F8/Breakpoint, AD-Filter.
**Nicht direkt die Lösung zeigen:** Pipeline-Übungen, Fehlerbehandlung, die Challenges. Erst Tipp („Was sagt `Get-Member`?"), dann nächster Schritt.
**Pair-/Gruppenarbeit:** Challenge-Aufgaben (Ü 2.5 Speicherfresser, Mini-Inventar, Abschlussprojekt). Bei drei Personen gern zu zweit plus einer mit dem Trainer.
**Teilnehmerprobleme aufgreifen:** Folie 5 am Montag, mittags Tag 2 priorisieren, Tag 3 vormittags einbauen. Reale Daten **nicht** ins Lab kopieren; Beispieldaten nachbauen.
**Moderation allgemein:** Alle 60–90 Minuten kurz fragen: „Zu schnell? Zu langsam? Fehlt etwas?". Die Gruppe ist klein, nutze das.
**Erwartungsmanagement (Folie 6):** Nicht jede Frage ist in fünf Minuten beantwortbar. Notieren (Parkplatz), in der Pause nacharbeiten, nachreichen.

---

## G. Side Quests

Kleine reale Admin-Aufgaben für schnelle Teilnehmer. **Vor dem Kurs im Lab probieren, sie sind nicht automatisch getestet.**

| # | Aufgabe | Cmdlets | Passt nach |
|---|---|---|---|
| 1 | Dateien älter als 30 Tage in `C:\Kurs\Daten\Logs` zählen, Gesamtgröße in MB | `Get-ChildItem`, `Where-Object`, `Measure-Object` | Tag 1 Pipeline |
| 2 | Die 10 größten Ordner unter `C:\Windows` (Größe in MB) | `Get-ChildItem -Recurse`, `Group-Object`, `Measure-Object` | Tag 2 |
| 3 | Welche Dienste laufen unter einem anderen Konto als `LocalSystem`? | `Get-CimInstance Win32_Service` | Tag 3 CIM |
| 4 | Installierte Hotfixes auf allen Kursrechnern, letzte 3 | `Get-HotFix`, `Invoke-Command` | Tag 2 Remoting |
| 5 | Mitglieder der lokalen Gruppe *Administratoren* auf allen drei VMs | `Invoke-Command`, `Get-LocalGroupMember` | Tag 2 Remoting |
| 6 | Letzte 10 Fehler im Systemprotokoll | `Get-WinEvent -FilterHashtable @{LogName='System'; Level=2}` | Tag 2 |
| 7 | Benutzer **ohne** Abteilung im AD | `Get-ADUser -Filter *`, `Where-Object` | Tag 2 AD |
| 8 | Alle Gruppenmitglieder als CSV mit Spalten *Gruppe, Name* | `Get-ADGroup`, `Get-ADGroupMember`, `Export-Csv` | Tag 2 AD |
| 9 | Ordnerstruktur aus einer CSV anlegen (`Abteilung`, `Projekt`) | `Import-Csv`, `New-Item` | Tag 2 CSV |
| 10 | Einfacher HTML-Report der laufenden Dienste | `ConvertTo-Html`, `Out-File` | Tag 2/3 |
| 11 | Zertifikate, die in 60 Tagen ablaufen | `Get-ChildItem Cert:\LocalMachine\My` | Tag 1 Provider |
| 12 | Ein Passwort-Generator als Funktion mit Parametern | `Get-Random`, `-join` | Tag 3 |
| 13 | Freien Speicher aller Kursrechner in einer Tabelle | `Invoke-Command`, `Get-PSDrive` | Tag 2/3 |
| 14 | Teilnehmerproblem als Mini-Projekt (aus Folie 5) | | Tag 3 |

---

## H. KI-Session (optional)

Nur wenn die Gruppe zustimmt (Folie 7 und 15, Abstimmung spätestens Tag 2, 16:45). Kursseite: `/ki/` (Seiten *Skripte erklären und prüfen*, *Gute Prompts*, *Halluzinationen und Validierung*, *Datenschutz und Sicherheit*, *Dokumentation und Tests*, *KI-Übungen*). Repository: `website/src/content/docs/ki/`.

**Lernziel:** KI als Werkzeug einsetzen, das PowerShell-Kompetenz **verstärkt**: erklären, prüfen, verbessern, absichern. Nicht „KI schreibt alles".

### H.1 Ablauf (bis zu halber Tag, ca. 3 Stunden)

| Dauer | Baustein | Typ | Material |
|---|---|---|---|
| 15 Min. | Einstieg: Wo hilft KI, wo nicht? Eure Erfahrungen | Diskussion | Folie 15 |
| 30 Min. | **Code verstehen**: Fremdes Skript erklären lassen und prüfen | Demo + Ü | Seite `ki/01-erklaeren-und-reviewen`; **Ü K.1** |
| 30 Min. | **Review und Refactoring** | Ü | **Ü K.2** |
| 15 Min. | Pause | | |
| 30 Min. | **Halluzinationen** entlarven | Demo + Ü | Seite `ki/03-validieren`; **Ü K.3** |
| 30 Min. | **Gute vs. schlechte Prompts**, Entwurf erzeugen | Gemeinsam + Ü | Seite `ki/02-prompts`; **Ü K.5** |
| 20 Min. | **Sicherheit und Datenschutz** | Diskussion + Ü | Seite `ki/04-daten-und-sicherheit`; **Ü K.4** |
| 20 Min. | **Doku und Tests** (Bonus) | Demo | Seite `ki/05-doku-und-tests`; **Ü K.6** |
| 15 Min. | Eigene Regeln formulieren | Ü | **Ü K.7** |

**Kurzfassung (90 Minuten):** Prompts (K.5), Halluzinationen (K.3), Datenschutz (K.4).

### H.2 Demos

1. **Erklären:** Das Skript `C:\Kurs\KI\altes-skript.ps1` (frei erfundenes Passwort) von der KI zeilenweise erklären lassen. Parallel Teilstücke in PowerShell ausführen und vergleichen.
2. **Fehlermeldung:** Absichtlich `Get-Content C:\gibtsnicht.txt -ErrorAction Stop` provozieren, `$Error[0] | Format-List * -Force` kopieren und analysieren lassen.
3. **Halluzination live:** Die KI nach einem Cmdlet für „letzte Anmeldung aller AD-Benutzer" fragen. Jedes Cmdlet mit `Get-Command` prüfen.
4. **Pair Programming:** Das Skript aus Ü P.1 (Inventar) gemeinsam schrittweise erweitern: Zuerst Anforderung formulieren, dann Entwurf, dann Review.

### H.3 Beispielprompts

**Bewusst schlecht:**

> schreib mir ein powershell script für inaktive benutzer

Probleme: Kein System (AD/Entra?), „inaktiv" undefiniert, keine Ausgabe, keine Sicherheitsvorgaben.

**Verbessert:**

> Ich bin Windows-Administrator (PowerShell-Grundkenntnisse) und arbeite mit PowerShell 7 in einer Active-Directory-Domäne. Schreibe ein Skript mit Parameter `-Tage` (Standard 90), das alle **aktivierten** Benutzer findet, deren `LastLogonDate` älter ist, und als CSV nach `C:\Kurs\Ausgabe\inaktiv.csv` exportiert. Nur lesender Zugriff, nur das ActiveDirectory-Modul. Erkläre danach kurz, warum `LastLogonDate` ungenau sein kann.

**Review-Prompt:**

> Prüfe dieses Skript auf (1) Sicherheitsprobleme, (2) fehlende Fehlerbehandlung, (3) Aliase und veraltete Cmdlets. Nenne zu jedem Befund Zeile, Risiko (hoch/mittel/niedrig) und einen Korrekturvorschlag. Ändere den Code nicht.

**Debugging-Prompt:**

> Der folgende Befehl liefert den Fehler unten. PowerShell 7.6, Windows Server 2025. Erkläre die Ursache, nenne zwei mögliche Korrekturen und woran ich erkenne, welche stimmt. Befehl: … Fehler: …

**Prompt gegen Halluzinationen:**

> Wenn du dir bei einem Cmdlet oder Parameter nicht sicher bist, sage das ausdrücklich und nenne, wie ich es mit `Get-Command`/`Get-Help` prüfe.

### H.4 Code Review und Debugging

Gemeinsam an `altes-skript.ps1` (Ü K.1/K.2): erst **eigene** Liste der Probleme (2 Minuten), dann KI-Review. Vergleichen: Was hat die KI übersehen? Was hat sie falsch beurteilt?
Debugging: Fehlerhaftes Skript (`Summe.ps1`, Ü Tag 3 Block 2, 2.4) der KI geben; erst nachvollziehen, dann Fix mit Breakpoint verifizieren.

### H.5 Grenzen von KI-generiertem Code

Erfundene Cmdlets/Parameter, falsche PowerShell-Version (5.1 vs. 7), veraltete Praxis (`-NoTypeInformation`, `Register-ScheduledJob`, Klartextpasswörter), zu breite Rechte (`-Force`, `Remove-Item -Recurse`), Logikfehler, die syntaktisch sauber sind. **Immer:** lesen, `-WhatIf`, Testumgebung, unabhängig prüfen. **Nie:** Passwörter, Kundendaten, vertrauliche Skripte in externe Dienste (Seite `ki/04-daten-und-sicherheit`).

---

## I. Referenzen und Fundorte

### I.1 Folien

| Folie | Inhalt |
|---|---|
| 1 | Titel |
| 2 | Was erwartet uns? |
| 3 | Trainer (Foto, Links, QR) |
| 4 | Wer seid ihr? (Leitfragen, drei Teilnehmerbereiche) |
| 5 | Was soll am Ende rauskommen? (Erwartungen, echte Probleme) |
| 6 | Wie wir arbeiten (Zeitplan = Orientierung) |
| 7 | PowerShell lernen im Zeitalter von KI? (Frage: KI-Block?) |
| 8 | Lab-Architektur (Diagramm) |
| 9 | So arbeiten wir mit Übungen (KI-frei) |
| 10 | Drei Tage im Überblick |
| 11 / 12 / 13 | Tagesplan Tag 1 / 2 / 3 |
| 14 | Wie ein Block abläuft (Legende) |
| 15 | Optional: PowerShell + AI |
| 16 | Das Lab gehört euch |
| 17 | Los geht’s: dein erster Befehl |
| 18 | Kontakt, QR-Codes |

In der privaten Version (`./lab.ps1 slides`) folgen nach Folie 8 die **Zugangsfolien** (Trainer-Übersicht und eine Folie pro Teilnehmer).

### I.2 Übungsseiten

| Kürzel | Datei | Kursseite |
|---|---|---|
| Tag 1 · Block 1 | `uebungen/tag-1-block-1.mdx` | `/uebungen/tag-1-block-1/` |
| Tag 1 · Block 2 | `uebungen/tag-1-block-2.mdx` | `/uebungen/tag-1-block-2/` |
| Tag 1 · Block 3 | `uebungen/tag-1-block-3.mdx` | `/uebungen/tag-1-block-3/` |
| Tag 2 · Block 1–3 | `uebungen/tag-2-block-{1,2,3}.mdx` | `/uebungen/tag-2-block-N/` |
| Tag 3 · Block 1–3 | `uebungen/tag-3-block-{1,2,3}.mdx` | `/uebungen/tag-3-block-N/` |
| Abschlussprojekt | `uebungen/abschlussprojekt.mdx` | `/uebungen/abschlussprojekt/` |
| KI-Übungen | `ki/uebungen.mdx` | `/ki/uebungen/` |

### I.3 Labs und Übungen pro Einheit

| Einheit | Lab-Anteil | Übung |
|---|---|---|
| Tag 1, alle Blöcke | eigene VM | Block 1 (Ü 1.1–1.7), Block 2 (Ü 2.1–2.10), Block 3 (Ü 3.1–3.3) |
| Tag 2, Prozesse und Dienste | eigene VM (Admin) | Block 2 (Ü 2.3–2.5) |
| Tag 2, Active Directory | `DC01`, eigene OU | Block 3 (Ü 3.1–3.5) |
| Tag 2, Remoting | alle `PSLAB-0x`, `DC01` | Block 3 (Ü 3.6–3.8) |
| Tag 3, Funktionen/Skripte | eigene VM, VS Code | Block 1 |
| Tag 3, CIM/Planen/Logging | eigene und fremde VM | Block 3 (Ü 3.2–3.4) |
| Tag 3, Abschlussprojekt | alle VMs | `abschlussprojekt` (Ü P.1) |
| KI-Block | Internet | `ki/uebungen` (Ü K.1–K.7) |

### I.4 Lab-Ressourcen

| Was | Wo |
|---|---|
| Lab bedienen | `lab.ps1`, [`TRAINER.md`](../TRAINER.md) |
| Lab für Teilnehmer | [`LAB-HOWTO.md`](LAB-HOWTO.md), Kursseite `/kurs/lab-selbst-deployen/` |
| Terraform | `infrastructure/azure/terraform/` |
| Windows-Konfiguration | `infrastructure/azure/configuration/` |
| Tests | `infrastructure/azure/tests/` (`./lab.ps1 test`, `test-exercises`) |

---

## J. Annahmen und offene Punkte

1. **Format:** Die Präsentation ist ein HTML-Foliensatz (reveal.js) statt PowerPoint, passend zur Kursseite, mit anklickbaren Links und lokal eingebettetem Code. PDF-Export: Folien öffnen, `?print-pdf` anhängen, drucken. Ein `.pptx` ist nicht enthalten.
2. **Zeiten:** 09:00–17:00 angenommen. Bei anderen Zeiten die Tagesplan-Folien (11–13) anpassen.
3. **Name:** Auf Folien und in Dokumenten steht „Philip Lorenz" (so auf me.philiplorenz.com und in LinkedIn-URL). Falls „Philipp" gewünscht ist, in `slides/index.html` ersetzen.
4. **Trainer-Vita:** nur Angaben von me.philiplorenz.com (Schwerpunkte, Fachautor für it-administrator/iX/heise).
5. **Teilnehmernamen** stehen nur in diesem Handbuch, nicht in den öffentlichen Folien.
6. **Lab-Repository für Teilnehmer:** Zugriff muss separat gewährt werden (Repository ist privat).
7. **Side Quests** sind nicht automatisiert getestet.
8. **Wahlblock Tag 3:** KI-Block bis zu einem halben Tag möglich, dann kürzt man CIM/Planen/Logging.
