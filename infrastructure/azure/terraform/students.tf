# ---------------- Teilnehmer-VMs ----------------

resource "azurerm_windows_virtual_machine" "student" {
  for_each              = local.students
  name                  = "PSLAB-${each.key}"
  computer_name         = "PSLAB-${each.key}"
  location              = azurerm_resource_group.lab.location
  resource_group_name   = azurerm_resource_group.lab.name
  size                  = var.student_vm_size
  admin_username        = local.admin_user
  admin_password        = random_password.admin.result
  network_interface_ids = [azurerm_network_interface.student[each.key].id]
  timezone              = "W. Europe Standard Time"
  patch_mode            = "AutomaticByOS"
  tags                  = merge(local.tags, { role = "student", student = each.key })

  os_disk {
    name                 = "osdisk-pslab-${each.key}"
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

  # Der DC muss fertig sein (AD und DNS), bevor ein Student-Rechner beitritt.
  depends_on = [azurerm_virtual_machine_run_command.dc_populate]
}

# Domänenbeitritt über die offizielle Azure-Erweiterung (inklusive Neustart)
resource "azurerm_virtual_machine_extension" "join" {
  for_each             = local.students
  name                 = "domain-join"
  virtual_machine_id   = azurerm_windows_virtual_machine.student[each.key].id
  publisher            = "Microsoft.Compute"
  type                 = "JsonADDomainExtension"
  type_handler_version = "1.3"

  settings = jsonencode({
    Name    = var.domain_name
    OUPath  = "OU=Computer,OU=Kurs,${local.base_dn}"
    User    = "${var.domain_netbios}\\${local.admin_user}"
    Restart = "true"
    Options = "3"
  })

  protected_settings = jsonencode({
    Password = random_password.admin.result
  })

  tags = local.tags
}

resource "time_sleep" "after_join" {
  for_each        = local.students
  depends_on      = [azurerm_virtual_machine_extension.join]
  create_duration = "120s"
}

# Konfiguration der Kursrechner: PowerShell 7, VS Code, RSAT, Remoting, Kursordner
resource "azurerm_virtual_machine_run_command" "student_config" {
  for_each           = local.students
  name               = "student-config"
  location           = azurerm_resource_group.lab.location
  virtual_machine_id = azurerm_windows_virtual_machine.student[each.key].id
  depends_on         = [time_sleep.after_join]

  source {
    script = file("${path.module}/../configuration/student-config.ps1")
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
    name  = "PwshVersion"
    value = var.pwsh_version
  }
  parameter {
    name  = "CourseSiteUrl"
    value = var.course_site_url
  }

  timeouts {
    create = "50m"
    update = "50m"
  }
}
