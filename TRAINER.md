# Trainer-Handbuch

Alles, was du brauchst, um den Kurs durchzuführen, auch Monate später noch.

## Überblick

- **Website** mit allen Kapiteln und Übungen: `https://powershell-kurs.philiplorenz.com`
- **Folien**: `https://powershell-kurs.philiplorenz.com/slides/` (lokal: `cd slides && npm ci && npm start`). PDF-Export: Folien öffnen, `?print-pdf` an die Adresse hängen, drucken.
- **Lab**: `./lab.ps1 <befehl>` im Repository-Hauptordner.
- Der **KI-Block** (`/ki/`) ist optional und vom restlichen Kurs unabhängig.

## Vor der Schulung (ca. 2 bis 3 Tage vorher)

1. **Repository aktualisieren**: `git pull` auf `main`.
2. **Website prüfen**: `https://powershell-kurs.philiplorenz.com` öffnen. Stichprobe: Tagesübersichten, eine Übung mit eingeklappter Lösung, Suche.
3. **Azure anmelden**: `az login`, dann `az account show` (richtige Subscription?).
4. **Lab erstellen**: `./lab.ps1 deploy`. Der Befehl zeigt den Plan und die **Kostenschätzung** und fragt nach. Dauer: ca. 30 bis 45 Minuten (Domäne wird aufgebaut, Software installiert).
5. **Zugangsdaten ansehen**: `./lab.ps1 credentials`. Mit `-Export` landen sie in `.secrets/teilnehmer-zugaenge.csv` (nicht in Git). Nach dem Ausdrucken oder Übergeben löschen.
6. **Smoke-Tests**: `./lab.ps1 test`. Alles muss grün sein (Domäne, PowerShell 7, Remoting, AD-Objekte, Übungsrechte).
7. **Verbindungstest**: Mit RDP auf eine Teilnehmer-VM (Adresse aus `credentials`), Kursseite im Browser, PowerShell 7 starten.
8. **RDP-Freigabe**: RDP ist nur von **deiner** IP erlaubt. Sitzen die Teilnehmer woanders, gib ihre IPs frei: `./lab.ps1 allow-ip 203.0.113.5/32` (pro Standort einmal).
9. **Abends nach den Tests**: `./lab.ps1 end-of-day`, damit bis zum Kurs keine Kosten durch laufende VMs entstehen.

## Morgens

```powershell
./lab.ps1 start      # DC startet zuerst, wartet auf AD, dann die Teilnehmer-VMs (ca. 5 Minuten)
./lab.ps1 status     # alle "VM running"? DC-Dienste ADWS/DNS/NTDS/Netlogon Running?
./lab.ps1 test       # optional, ca. 3 Minuten
```

Dann: Folien öffnen, Teilnehmern ihre Zugangsdaten geben (persönlich, nicht per Mail), gemeinsam einloggen und `$PSVersionTable.PSVersion` prüfen.

## Während des Tages

| Problem | Lösung |
|---|---|
| Teilnehmer kann sich nicht per RDP verbinden | `./lab.ps1 status` (läuft die VM?). Dann `allow-ip` für seine IP. Auto-Shutdown um 20:00 beachten. |
| Passwort vergessen | `./lab.ps1 credentials` |
| Teilnehmer-VM kaputt | `./lab.ps1 reset-student 2` baut `PSLAB-02` neu auf (ca. 15 bis 20 Minuten, Dateien gehen verloren). In der Zeit zu zweit arbeiten. |
| Teilnehmer hat AD-Objekte durcheinandergebracht | `reset-student` leert auch seine OU `OU=TNN,OU=Uebung`. Nur die OU leeren: auf DC01 `Get-ADObject -SearchBase "OU=T02,OU=Uebung,OU=Kurs,DC=pslab,DC=internal" -SearchScope OneLevel -Filter * \| Remove-ADObject -Recursive` |
| AD antwortet nicht | `./lab.ps1 status` zeigt die DC-Dienste. Notfalls DC01 im Portal neu starten. |
| Zugriff auf DC01 als Administrator | `./lab.ps1 credentials` (Konto `PSLAB\labadmin`), RDP auf die DC01-Adresse. |

## Abends

```powershell
./lab.ps1 end-of-day
```

- Deallokiert **alle** VMs (Teilnehmer und DC) und prüft, dass keine mehr läuft.
- Zeigt, was weiter kostet (Disks, öffentliche IPs, ca. 1,9 € pro Tag).
- **Sicherheitsnetz:** Die VMs haben zusätzlich einen Auto-Shutdown um 20:00 Uhr (deallokiert). Das ersetzt `end-of-day` nicht, schützt aber vor Vergessen. Soll der Kurs länger gehen, `autoshutdown_time` in `lab.auto.tfvars.json` anpassen und `terraform apply` oder `deploy` erneut ausführen.
- Am nächsten Morgen: `./lab.ps1 start`.

## Nach der Schulung

1. **Daten sichern, falls nötig**: Teilnehmer kopieren Skripte aus `C:\Kurs\Skripte` auf einen USB-Stick oder in ein Git-Repository. Danach sind die VMs weg.
2. **Zugangsdaten-Datei löschen**: `Remove-Item .secrets -Recurse`.
3. **Lab entfernen**: `./lab.ps1 destroy` (fragt nach dem Namen der Resource Group).
4. **Restressourcen prüfen**: Der Befehl listet am Ende `pslab*`-Ressourcen. Zusätzlich im Portal die Kostenanalyse für die Subscription ansehen. Leere Liste und Resource Group `rg-pslab` verschwunden = sauber.

## Kursablauf und Flexibilität

- Tagesübersichten mit Lernzielen, Themen, Lab-Bedarf und grober Zeit: `/tag-1/`, `/tag-2/`, `/tag-3/`.
- Stufen: **Core** (fest), **Optional**, **Bonus**, **Reserve**. Wer Zeit braucht, überspringt Challenge und Bonus.
- Reguläre Übungen sind als **KI-frei** markiert und tragen den Hinweis. Der KI-Block ist als einziger mit KI erlaubt.
- KI-Block kürzen oder ersetzen: Hinweise im Trainer-Kasten auf `/ki/`.
- Lösungen sind eingeklappt. Für die Besprechung am Beamer einfach aufklappen.

## Das Lab im Detail

| | |
|---|---|
| Domäne | `pslab.internal` (NetBIOS `PSLAB`) |
| Rechner | `DC01` (Server 2025, B2s), `PSLAB-01..03` (Server 2025, B2ms) |
| Konten | `PSLAB\labadmin` (Domänen-Admin, Trainer), `PSLAB\teilnehmer01..03` (jeder lokaler Admin auf allen `PSLAB-0x`, Schreibrechte nur in der eigenen OU) |
| Demo-Daten AD | OU `Kurs` mit `Benutzer` (24 Konten, 3 deaktiviert, 2 mit abgelaufenem Passwort), `Gruppen` (`GRP-IT`, `GRP-HR`, `GRP-Finanzen`, `GRP-Vertrieb`, `GG-Kurs-Teilnehmer`), `Computer`, `Teilnehmer`, `Uebung\T01..T03` |
| Kursdaten | `C:\Kurs\{Daten,Ausgabe,Logs,Skripte,KI}`, `Mitarbeiter.csv`, 12 Logdateien |
| Software | PowerShell 7.6 (LTS), VS Code mit PowerShell-Erweiterung, RSAT-AD, Pester 5 |

Passwörter werden von Terraform erzeugt und liegen **nur** im lokalen State (`infrastructure/azure/terraform/terraform.tfstate`, nicht in Git). Dieses Verzeichnis ist dein Backup-Punkt: ohne State kannst du das Lab nicht mehr sauber per `destroy` entfernen (dann Resource Group `rg-pslab` im Portal löschen).
