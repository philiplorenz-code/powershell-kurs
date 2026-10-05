# ---------------- Domain Controller ----------------

resource "azurerm_windows_virtual_machine" "dc" {
  name                  = "DC01"
  computer_name         = "DC01"
  location              = azurerm_resource_group.lab.location
  resource_group_name   = azurerm_resource_group.lab.name
  size                  = var.dc_vm_size
  admin_username        = local.admin_user
  admin_password        = random_password.admin.result
  network_interface_ids = [azurerm_network_interface.dc.id]
  timezone              = "W. Europe Standard Time"
  patch_mode            = "AutomaticByOS"
  tags                  = merge(local.tags, { role = "dc" })

  os_disk {
    name                 = "osdisk-dc01"
    caching              = "ReadWrite"
    storage_account_type = var.os_disk_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.image_sku
    version   = "latest"
  }
}

# Schritt 1: AD DS installieren und Forest erstellen. Das Skript plant den Neustart selbst ein.
resource "azurerm_virtual_machine_run_command" "dc_promote" {
  name               = "dc-promote"
  location           = azurerm_resource_group.lab.location
  virtual_machine_id = azurerm_windows_virtual_machine.dc.id

  source {
    script = file("${path.module}/../configuration/dc-promote.ps1")
  }

  parameter {
    name  = "DomainName"
    value = var.domain_name
  }
  parameter {
    name  = "NetbiosName"
    value = var.domain_netbios
  }
  protected_parameter {
    name  = "SafeModePassword"
    value = random_password.dsrm.result
  }

  timeouts {
    create = "30m"
    update = "30m"
  }
}

# Der DC startet nach der Promotion neu. Erst danach läuft Schritt 2.
resource "time_sleep" "dc_reboot" {
  depends_on      = [azurerm_virtual_machine_run_command.dc_promote]
  create_duration = "240s"
}

# Schritt 2: OUs, Gruppen, Benutzer, Delegierung, Demoobjekte.
resource "azurerm_virtual_machine_run_command" "dc_populate" {
  name               = "dc-populate"
  location           = azurerm_resource_group.lab.location
  virtual_machine_id = azurerm_windows_virtual_machine.dc.id
  depends_on         = [time_sleep.dc_reboot]

  source {
    script = file("${path.module}/../configuration/dc-populate.ps1")
  }

  parameter {
    name  = "DomainName"
    value = var.domain_name
  }
  parameter {
    name  = "NetbiosName"
    value = var.domain_netbios
  }
  parameter {
    name  = "AdminUser"
    value = local.admin_user
  }
  parameter {
    name  = "StudentCount"
    value = tostring(var.student_count)
  }
  parameter {
    name  = "PwshVersion"
    value = var.pwsh_version
  }
  protected_parameter {
    name  = "AdminPassword"
    value = random_password.admin.result
  }
  protected_parameter {
    name  = "StudentPasswordsJson"
    value = jsonencode({ for k, v in random_password.student : k => v.result })
  }

  timeouts {
    create = "50m"
    update = "50m"
  }
}
