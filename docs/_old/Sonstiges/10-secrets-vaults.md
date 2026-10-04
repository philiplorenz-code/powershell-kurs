---
id: secrets-vaults
title: "PowerShell Secret Vault nutzen"
sidebar_position: 10
---

# Installiere Module
```pwsh
Install-Module -Name Microsoft.PowerShell.SecretManagement
Install-Module -Name Microsoft.PowerShell.SecretStore
```

# Setup Vault
```pwsh
# Register Vault
Register-SecretVault -Name LocalStore -ModuleName Microsoft.PowerShell.SecretStore -DefaultVault

## Disable Auth
Set-SecretStoreConfiguration -Authentication None -Interaction None
```

# Secret Erstellen
```pwsh
Set-Secret -Name Password -Secret "Pass@word1"
```

# Secret Auslesen
```pwsh
Get-Secret -Name Password
Get-Secret -Name Password -AsPlainText
```


# Sicherheit: Einordnung
- Das Entfernen des Passwortprompts schmälert die Sicherheit des Vaults:
  - Vault kann nur vom Benutzer oder von Prozessen im Kontext des Benutzer geöffnet werden (Die SecretStore-Scope ist auf User-Ebene)
  - Secrets sind Encrypted at Rest
  - Bei Non-Auth wir der Schlüssel mitgespeichert
- Für eine Automatisierung ist die manuelle Passworteingabe hinderlich - es gibt zwei Optionen:
  - Passwort lokale speichern und damit auf den Vault zugreifen: https://www.windowspro.de/script/passwoerter-powershell-speichern
  Vault für Zeitraum entsperren: "Unlock-SecretStore -Password "P@ssw0rd" -PasswordTimeout 600" 