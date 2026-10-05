# Architektur und Entscheidungen

Kurz und bewusst ohne ADR-Sammlung. Leitlinie: **einfach, robust, reproduzierbar, günstig**.

## Website: Astro Starlight statt Docusaurus

Docusaurus lief, aber das Projekt nutzte nur das Standard-Template (React, mehrere hundert Pakete, Build mit Webpack). Starlight erfüllt die Kriterien mit weniger Aufwand:

| Kriterium | Starlight |
|---|---|
| Wartung | Markdown/MDX in `src/content/docs`, wenige Abhängigkeiten, Sidebar per Ordnerstruktur |
| Code-Darstellung | Expressive Code (Shiki): PowerShell-Highlighting, Kopieren-Button, Terminal-Rahmen, Hell/Dunkel |
| Navigation und Suche | eingebaut, Pagefind-Suche ohne Server |
| Responsiv, Dark Mode | eingebaut |
| Übungen und Lösungen | eigene kleine Astro-Komponenten (`Uebung`, `Loesung`, `Stufe`, `Lernziele`, `Trainer`), Lösungen als `<details>` |
| Qualitätssicherung | `starlight-links-validator` bricht den Build bei toten internen Links ab |
| Build | ca. 8 Sekunden |
| Container | rein statisch: nginx genügt |

## Container

Mehrstufiger Build (`node:22-alpine` für Website und Folien) und Laufzeit `nginxinc/nginx-unprivileged` (läuft ohne root, Port 8080, ca. 96 MB). `GET /healthz` für Kubernetes. Website liegt unter `/`, Folien unter `/slides/`. Gehashte Assets werden ein Jahr gecacht.

## Folien: reveal.js

Ein einzelnes statisches HTML-Dokument mit lokal eingebettetem reveal.js (kein CDN, funktioniert im Schulungsraum ohne Internet). Dunkles Farbschema wie die Website. Trainer-Vita als klar markierter Platzhalter in `slides/index.html`.

## Kubernetes

Das Cluster (k3s auf Hetzner, Traefik, cert-manager `letsencrypt-prod`, external-dns/Cloudflare) wird per **GitOps mit Flux** aus dem Repository `3kshetzner` gepflegt, dessen `AGENTS.md` ein direktes `kubectl apply` verbietet. Daher: Manifeste `apps/powershell-kurs/` per Pull Request, Pull-Secret SOPS-verschlüsselt, Namespace in Velero und Homer ergänzt. Hostname `powershell-kurs.philiplorenz.com`, weil der bisherige Name `powershell.philiplorenz.com` auf einen anderen Host (MyFritz) zeigt und nicht ohne Absprache übernommen wird. Eine Referenzkopie liegt in `kubernetes/`.

## Azure-Lab

```
rg-pslab (Germany West Central)
└── vnet-pslab 10.50.0.0/16 · snet-lab 10.50.1.0/24 · nsg-pslab
    ├── DC01       B2s,  10.50.1.4 (statisch), Public IP
    └── PSLAB-01..03  B2ms, Public IP je VM
```

| Thema | Entscheidung | Begründung |
|---|---|---|
| IaC | **Terraform** (`azurerm` 4.x) | Bekannt, deklarativ, `plan` zeigt vorab, was entsteht. Keine Module-Hierarchie: ein Verzeichnis mit fünf kleinen Dateien |
| Windows-Konfiguration | **PowerShell-Skripte per Azure Run Command** | Kein zusätzliches Werkzeug (kein Ansible, kein DSC-Pull-Server). Skripte sind selbst idempotent (prüfen vor dem Anlegen) und lassen sich auch von Hand auf einer VM starten. Der Domänenbeitritt läuft über die offizielle Erweiterung `JsonADDomainExtension` |
| Reihenfolge | DC promote → Pause für den Neustart → DC füllen → VMs anlegen → Domänenbeitritt → Software | Terraform-Abhängigkeiten (`depends_on`) plus `time_sleep` für die Neustarts |
| Betriebssystem | Windows Server 2025 für alle VMs | Windows-11-Clients bräuchten eine Client-Lizenz (in Azure nur mit Visual-Studio- oder M365-Lizenz). Server-GUI verhält sich für den Kurs wie ein Admin-Arbeitsplatz |
| Größen | DC B2s (4 GiB), Teilnehmer B2ms (8 GiB) | VS Code, Browser und Server-GUI laufen mit 4 GiB zäh. Der DC verwaltet nur ein Dutzend Objekte |
| Domäne | `pslab.internal` | `.internal` ist von der ICANN für private Netze reserviert, keine Kollision mit echten Domains |
| Zugriff | **RDP über Public IPs, per NSG auf Trainer-IP (und freigegebene Adressen) beschränkt** | Siehe unten |
| Geheimnisse | Zufällige Passwörter in Terraform (`random_password`), nur im lokalen State. Ausgabe über `terraform output` als `sensitive`, bequem über `./lab.ps1 credentials`. Übergabe an die Skripte als *protected parameter* | Für 4 Wegwerf-VMs ist Key Vault unverhältnismäßig. State und `.secrets/` stehen in `.gitignore` |
| Rechte-Modell | Teilnehmer: lokaler Admin auf allen `PSLAB-0x`, **nicht** auf DC01 (nur *Remote Management Users*); Schreibrechte in AD nur in der eigenen OU (`dsacls`) | Remoting-Übungen brauchen Admin auf dem Ziel. Der DC bleibt geschützt. Das Rechte-Modell ist Teil der Lernerfahrung |
| Auto-Shutdown | `azurerm_dev_test_global_vm_shutdown_schedule` (kostenlos), täglich 20:00 | Schutz vor vergessenem `end-of-day` |
| Budget | Optionale Budgetwarnung per Mail (`budget_alert_email`) | Wird nur angelegt, wenn eine Mail angegeben ist |
| Reset | `reset-student N`: AD-Computerobjekt und OU leeren, dann `terraform apply -replace` für die VM | Sauberer Neuaufbau statt Snapshot (Snapshots kosten und sind bei AD heikel) |
| Statuskommandos | `lab.ps1` ruft nur `az` und `terraform` auf | Eine Datei, die ein Trainer lesen kann |

### Zugriffsmethode und Kosten

| Option | Kosten | Bewertung |
|---|---|---|
| **Public IP + RDP, NSG auf IPs beschränkt** | ca. 3,2 € pro Monat je IP (4 IPs) | **Gewählt.** Einfach, jeder nutzt seinen gewohnten RDP-Client. Das Risiko ist durch die IP-Beschränkung und Wegwerf-Passwörter klein, das Lab existiert nur wenige Tage |
| Azure Bastion Basic | ca. 0,19 USD pro Stunde (ca. 135 USD pro Monat) | Unverhältnismäßig teuer für 3 Personen. Die Developer-SKU ist kostenlos, erlaubt aber nur eine Sitzung pro Nutzer ohne Dateiübertragung und hat Einschränkungen |
| Point-to-Site-VPN | Gateway ca. 25 bis 30 € pro Monat plus Einrichtung | Sicherste Variante, aber Zertifikate und VPN-Clients für alle Teilnehmer sind zu viel Aufwand für einen Dreitageskurs |

Wenn Teilnehmer von wechselnden Netzen arbeiten, `./lab.ps1 allow-ip` nutzen. `0.0.0.0/0` wird von Terraform (Validierung) und `lab.ps1` abgelehnt.

### Start/Stop-Konzept

- `stop`/`end-of-day` rufen `az vm deallocate` für **alle** VMs auf. Nur deallokierte VMs verursachen keine Compute-Kosten.
- Ein Domain Controller in einem Single-DC-Lab verträgt Deallokieren. USN-Rollback tritt nur bei Snapshots oder Wiederherstellungen auf, nicht beim normalen Herunterfahren.
- `start` startet **zuerst** den DC, wartet, bis `Get-ADDomain` antwortet, und startet dann die Teilnehmer-VMs, sonst scheitern Anmeldungen.
- Weiterlaufende Kosten im gestoppten Zustand: Disks und statische Public IPs (siehe README).

### Kostenoptimierung

Keine Bastion, kein Log Analytics, kein Backup, keine Snapshots, keine Managed Disks außer den 4 OS-Disks, Standard SSD statt Premium, Burstable-VMs, ein einziges Subnetz, Auto-Shutdown, Budgetwarnung.

## Qualitätssicherung

- Website: `npm run build` inklusive Link-Validierung. Alle 268 PowerShell-Codeblöcke werden mit dem PowerShell-Parser geprüft.
- Container: Build, Start, `/healthz`, Routen, 404.
- Lab: `terraform validate`/`plan`; `./lab.ps1 test` führt Smoke-Tests auf allen VMs aus (Domäne, PowerShell 7, Remoting, AD-Objekte, Rechte und ein Übungs-Check aus Teilnehmersicht).
