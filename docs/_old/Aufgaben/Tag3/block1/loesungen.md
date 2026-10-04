---  
id: loesungen-aufgabenblock-1-tag-3  
title: Lösungen – Tag 3 - Aufgabenblock 1 – Skriptstruktur, Funktionen, Fehlerbehandlung & Debugging  
sidebar_position: 20  
---

# 💡 Lösung zu Aufgabe 1 – Skriptheader & Struktur  
```powershell
<# 
    Skript: DemoScript.ps1
    Zweck: Beispiel für strukturiertes PowerShell-Skript
    Autor: Workshop-Teilnehmer
    Datum: 2025-11-02
    Version: 1.0
#>

function Show-DateTime {
    Write-Output ("Aktuelles Datum und Uhrzeit: " + (Get-Date))
}

function Main {
    Show-DateTime
}

Main
```
> Struktur: Header → Funktionen → Main-Block → Aufruf.  

---

# 💡 Lösung zu Aufgabe 2 – Funktionen & Parameterblöcke  
```powershell
function Get-Greeting {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        [ValidateSet("DE","EN","FR")]
        [string]$Language
    )

    switch ($Language) {
        "DE" { "Hallo, $Name!" }
        "EN" { "Hello, $Name!" }
        "FR" { "Bonjour, $Name!" }
    }
}

Get-Greeting -Name "Max" -Language "DE"
```
> Demonstriert Parametertypen, Validierung und Mehrsprachigkeit.  

---

# 💡 Lösung zu Aufgabe 3 – Fehlerbehandlung mit try/catch  
```powershell
function Read-FileSafe {
    param([string]$Path)

    try {
        $content = Get-Content -Path $Path -ErrorAction Stop
        Write-Output "Datei erfolgreich gelesen:"
        Write-Output $content
    }
    catch {
        Write-Error "Fehler beim Lesen der Datei: $Path – $_"
    }
}

# Tests
Read-FileSafe -Path "C:\Windows\win.ini"
Read-FileSafe -Path "C:\nichtda.txt"
```
> `-ErrorAction Stop` sorgt dafür, dass try/catch greift.  

---

# 💡 Lösung zu Aufgabe 4 – Anmeldeinformationen sicher speichern  
```powershell
# 1. Eingabe über Dialog
$cred = Get-Credential
Write-Output "Benutzername: $($cred.UserName)"

# 2. Beispielhafte Erstellung
$secure = ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ("User1", $secure)
Write-Output "Credential erstellt für: $($credential.UserName)"
```
> Ergebnis: Passwörter werden als SecureString im Speicher gehalten – keine Klartext-Ausgabe.

