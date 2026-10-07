variable "subscription_id" {
  description = "Azure-Subscription, in der das Lab entsteht."
  type        = string
}

variable "location" {
  description = "Azure-Region. Germany West Central (Frankfurt) hat kurze Wege und liegt in der EU."
  type        = string
  default     = "germanywestcentral"
}

variable "name_prefix" {
  description = "Präfix für Azure-Ressourcen."
  type        = string
  default     = "pslab"
}

variable "student_count" {
  description = "Anzahl der Teilnehmer-VMs."
  type        = number
  default     = 3
  validation {
    condition     = var.student_count >= 1 && var.student_count <= 10
    error_message = "student_count muss zwischen 1 und 10 liegen."
  }
}

variable "domain_name" {
  description = "AD-Domäne. '.internal' ist von der ICANN für private Nutzung reserviert (kollidiert nie mit echten Domains)."
  type        = string
  default     = "pslab.internal"
}

variable "domain_netbios" {
  type    = string
  default = "PSLAB"
}

variable "rdp_open_to_internet" {
  description = "true = RDP (TCP 3389) von jeder IP erlaubt. Bequem, wenn die Teilnehmer-IPs unbekannt sind. Schutz dann: lange Zufallspasswörter, NLA, Domänen-Kontosperre. Nur für die Kursdauer verwenden."
  type        = bool
  default     = false
}

variable "allowed_rdp_cidrs" {
  description = "Quell-Adressen (CIDR) für RDP, wenn rdp_open_to_internet = false. Beispiel: [\"203.0.113.7/32\"]."
  type        = list(string)
  default     = []
  validation {
    condition     = !contains(var.allowed_rdp_cidrs, "0.0.0.0/0") && !contains(var.allowed_rdp_cidrs, "*")
    error_message = "Für RDP von überall bitte rdp_open_to_internet = true setzen (bewusste Entscheidung)."
  }
}

variable "participants" {
  description = "Teilnehmer (Zuordnung zu teilnehmer01..NN): name, email, company. Gehört in lab.auto.tfvars.json (nicht in Git)."
  type = list(object({
    name    = string
    email   = optional(string, "")
    company = optional(string, "")
  }))
  default = []
}

variable "dc_vm_size" {
  description = "Domain Controller: 2 vCPU, 4 GiB. Für eine Mini-Domäne ausreichend."
  type        = string
  default     = "Standard_B2s"
}

variable "student_vm_size" {
  description = "Teilnehmer-VMs: 2 vCPU, 8 GiB. 4 GiB wären mit VS Code, Browser und Server-GUI zäh."
  type        = string
  default     = "Standard_B2ms"
}

variable "os_disk_type" {
  type    = string
  default = "StandardSSD_LRS"
}

variable "os_disk_size_gb" {
  type    = number
  default = 128
}

variable "image_sku" {
  description = "Windows-Server-Image. Alternativ: 2022-datacenter-g2."
  type        = string
  default     = "2025-datacenter-g2"
}

variable "pwsh_version" {
  description = "PowerShell-7-Version (MSI von GitHub). 7.6.x ist die aktuelle LTS."
  type        = string
  default     = "7.6.6"
}

variable "course_site_url" {
  description = "Adresse der Kurswebsite (Verknüpfung auf dem Desktop)."
  type        = string
  default     = "https://powershell-kurs.philiplorenz.com"
}

variable "autoshutdown_enabled" {
  description = "Sicherheitsnetz gegen vergessenes Herunterfahren: alle VMs werden täglich deallokiert."
  type        = bool
  default     = true
}

variable "autoshutdown_time" {
  description = "Uhrzeit (HHmm, Zeitzone W. Europe Standard Time) für das automatische Deallokieren."
  type        = string
  default     = "2000"
}

variable "budget_amount_eur" {
  description = "Monatsbudget für die Resource Group (Warnung per Mail bei 80 % und 100 %). 0 = aus."
  type        = number
  default     = 60
}

variable "budget_alert_email" {
  description = "Empfänger für Budgetwarnungen. Leer = keine Budgetwarnung."
  type        = string
  default     = ""
}

variable "budget_start_date" {
  description = "Erster Tag eines Monats (YYYY-MM-01), ab dem das Budget gilt."
  type        = string
  default     = "2026-10-01"
}

variable "tags" {
  type = map(string)
  default = {
    project = "powershell-in-3-tagen"
    purpose = "training-lab"
  }
}
