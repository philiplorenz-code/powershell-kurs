# ---------------- Trainer-VM (optional) ----------------
# Eigene Arbeitsumgebung für den Dozenten: Domänenmitglied, PowerShell 7, VS Code, RSAT.
# Teilnehmer haben darauf keine Rechte (ParticipantAccess = false). Aktivieren mit trainer_vm_enabled = true.

locals {
  trainer = var.trainer_vm_enabled ? toset(["trainer"]) : toset([])
}

resource "azurerm_public_ip" "trainer" {
  for_each            = local.trainer
  name                = "pip-pslab-trainer"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  domain_name_label   = "${var.name_prefix}-trainer-${random_string.dns_suffix.result}"
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "trainer" {
  for_each            = local.trainer
  name                = "nic-pslab-trainer"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.lab.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(local.subnet_cidr, 20)
    public_ip_address_id          = azurerm_public_ip.trainer["trainer"].id
  }
}

resource "azurerm_windows_virtual_machine" "trainer" {
  for_each              = local.trainer
  name                  = "PSLAB-TRAINER"
  computer_name         = "PSLAB-TRAINER"
  location              = azurerm_resource_group.lab.location
  resource_group_name   = azurerm_resource_group.lab.name
  size                  = var.student_vm_size
  admin_username        = local.admin_user
  admin_password        = random_password.admin.result
  network_interface_ids = [azurerm_network_interface.trainer["trainer"].id]
  timezone              = "W. Europe Standard Time"
  patch_mode            = "AutomaticByOS"
  tags                  = merge(local.tags, { role = "trainer" })

  os_disk {
    name                 = "osdisk-pslab-trainer"
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

  depends_on = [azurerm_virtual_machine_run_command.dc_populate]
}

resource "azurerm_virtual_machine_extension" "trainer_join" {
  for_each             = local.trainer
  name                 = "domain-join"
  virtual_machine_id   = azurerm_windows_virtual_machine.trainer["trainer"].id
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

resource "time_sleep" "trainer_after_join" {
  for_each        = local.trainer
  depends_on      = [azurerm_virtual_machine_extension.trainer_join]
  create_duration = "120s"
}

resource "azurerm_virtual_machine_run_command" "trainer_config" {
  for_each           = local.trainer
  name               = "student-config"
  location           = azurerm_resource_group.lab.location
  virtual_machine_id = azurerm_windows_virtual_machine.trainer["trainer"].id
  depends_on         = [time_sleep.trainer_after_join]

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
  parameter {
    name  = "ParticipantAccess"
    value = "false"
  }

  timeouts {
    create = "50m"
    update = "50m"
  }
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "trainer" {
  for_each              = var.autoshutdown_enabled ? local.trainer : toset([])
  virtual_machine_id    = azurerm_windows_virtual_machine.trainer["trainer"].id
  location              = azurerm_resource_group.lab.location
  enabled               = true
  daily_recurrence_time = var.autoshutdown_time
  timezone              = "W. Europe Standard Time"
  notification_settings {
    enabled = false
  }
  tags = local.tags
}
