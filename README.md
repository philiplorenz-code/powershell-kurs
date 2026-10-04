# PowerShell in 3 Tagen

Dreitägige PowerShell-Schulung für Windows-Administratoren: Kurswebsite, Folien, Container-Image und ein
reproduzierbares Azure-Lab (Domain Controller und eine VM pro Teilnehmer).

| Was | Wo |
|---|---|
| Kurswebsite (Astro Starlight) | [`website/`](website/) |
| Folien (reveal.js) | [`slides/`](slides/) |
| Azure-Lab (Terraform und PowerShell) | [`infrastructure/azure/`](infrastructure/azure/) |
| Bedienung des Labs | [`lab.ps1`](lab.ps1) |
| Kubernetes (Referenzkopie, GitOps liegt in `3kshetzner`) | [`kubernetes/`](kubernetes/) |
| Für Trainer | [`TRAINER.md`](TRAINER.md) |
| Technische Entscheidungen | [`ARCHITECTURE.md`](ARCHITECTURE.md) |
| Bestandsaufnahme des ursprünglichen Kurses | [`docs/ANALYSE.md`](docs/ANALYSE.md) |

## Schnellstart

```bash
# Website lokal ansehen
cd website && npm ci && npm run dev          # http://localhost:4321

# Folien lokal ansehen
cd slides && npm ci && npm start             # http://localhost:8081

# Alles als Container (Website unter /, Folien unter /slides/)
docker build -t powershell-kurs . && docker run --rm -p 8080:8080 powershell-kurs
```

## Lab in einem Befehl

Voraussetzungen: PowerShell 7, Azure CLI (`az login`), Terraform ≥ 1.6.

```powershell
./lab.ps1 deploy          # zeigt Plan und Kosten, fragt nach, erstellt dann alles
./lab.ps1 start           # morgens
./lab.ps1 end-of-day      # abends: alle VMs deallokieren
./lab.ps1 reset-all       # alles auf Ursprung (VMs neu, AD neu)
./lab.ps1 destroy         # nach dem Kurs
```

Alle Befehle: `./lab.ps1 help`. Ablauf Schritt für Schritt: [`TRAINER.md`](TRAINER.md).

## Kosten (grobe Schätzung, EUR, Region Germany West Central)

Konfiguration: 1 × DC (B2s) + 3 × Teilnehmer-VM (B2ms), Windows-Lizenz inklusive, Standard SSD 128 GiB, Standard-Public-IPs.

| Zustand | Kosten |
|---|---|
| Alle 4 VMs laufen | ca. **0,32 € pro Stunde** |
| Ein Kurstag (9 Stunden) | ca. 3 € |
| Drei Kurstage | ca. **9 €** |
| **Alle VMs deallokiert** | ca. **1,9 € pro Tag** (nur Disks und öffentliche IPs) |
| Aufbau, Tests und Puffer (ca. 10 Stunden) | ca. 3 € |

Realistisch für eine Kurswoche (deploy am Vortag, destroy am Tag nach dem Kurs): **ca. 20 bis 25 €**.

### Was auch im gestoppten Zustand Geld kostet

| Ressource | Kosten gestoppt | Anmerkung |
|---|---|---|
| Managed Disks (4 × 128 GiB Standard SSD) | ca. 34 € pro Monat | Bleiben nach `stop` bestehen |
| Öffentliche IPv4-Adressen (4 × Standard, statisch) | ca. 13 € pro Monat | Werden auch ohne laufende VM berechnet |
| VNet, NSG, Auto-Shutdown, Budget | 0 € | |
| Snapshots, Backups, Log Analytics, Bastion, Key Vault | **nicht vorhanden** | bewusst weggelassen |

**Regel:** Nach dem Kurs `./lab.ps1 destroy`. Gestoppt kostet das Lab ca. 57 € pro Monat.

Preise: Azure Retail Prices API (Stand Oktober 2026), ohne Steuern und Datenverkehr. `./lab.ps1 cost` zeigt dieselbe Rechnung.

## Branch und Workflow

Entwicklung auf Feature-Branches, Änderungen per Pull Request. Die GitHub Action baut bei Push auf `main` und auf
`modernize-course-*` ein `linux/amd64`-Image nach `ghcr.io/philiplorenz-code/powershell-kurs`.
