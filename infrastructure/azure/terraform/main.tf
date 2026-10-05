locals {
  subnet_cidr = "10.50.1.0/24"
  dc_ip       = cidrhost(local.subnet_cidr, 4)
  students    = { for i in range(1, var.student_count + 1) : format("%02d", i) => i }
  base_dn     = join(",", [for p in split(".", var.domain_name) : "DC=${p}"])
  tags        = var.tags
  admin_user  = "labadmin"
}

resource "azurerm_resource_group" "lab" {
  name     = "rg-${var.name_prefix}"
  location = var.location
  tags     = local.tags
}

# ---------------- Passwörter (nur im Terraform-State, nie im Git) ----------------

resource "random_password" "admin" {
  length           = 20
  special          = true
  override_special = "-_!"
  min_upper        = 3
  min_lower        = 3
  min_numeric      = 3
  min_special      = 1
}

resource "random_password" "dsrm" {
  length           = 20
  special          = true
  override_special = "-_!"
  min_upper        = 3
  min_lower        = 3
  min_numeric      = 3
  min_special      = 1
}

resource "random_password" "student" {
  for_each         = local.students
  length           = 16
  special          = true
  override_special = "-_!"
  min_upper        = 3
  min_lower        = 3
  min_numeric      = 3
  min_special      = 1
}

# ---------------- Netzwerk ----------------

resource "random_string" "dns_suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_virtual_network" "lab" {
  name                = "vnet-${var.name_prefix}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  address_space       = ["10.50.0.0/16"]
  # Ab hier lösen alle VMs über den DC auf (Domänenbeitritt benötigt AD-DNS).
  dns_servers = [local.dc_ip]
  tags        = local.tags
}

resource "azurerm_subnet" "lab" {
  name                 = "snet-lab"
  resource_group_name  = azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = [local.subnet_cidr]
}

resource "azurerm_network_security_group" "lab" {
  name                = "nsg-${var.name_prefix}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags

  security_rule {
    name                       = "AllowRdpFromTrainerAndParticipants"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = var.rdp_open_to_internet ? "*" : null
    source_address_prefixes    = var.rdp_open_to_internet ? null : var.allowed_rdp_cidrs
    destination_address_prefix = "*"
  }
  # Hinweis: Mit rdp_open_to_internet = true ist 3389 weltweit erreichbar. Siehe Variablenbeschreibung.
  # Verkehr innerhalb des VNets (WinRM, AD, DNS, SMB) erlaubt die Azure-Standardregel AllowVnetInBound.
  # Alles andere von außen wird durch DenyAllInBound verworfen.
}

resource "azurerm_subnet_network_security_group_association" "lab" {
  subnet_id                 = azurerm_subnet.lab.id
  network_security_group_id = azurerm_network_security_group.lab.id
}

resource "azurerm_public_ip" "dc" {
  name                = "pip-dc01"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  domain_name_label   = "${var.name_prefix}-dc01-${random_string.dns_suffix.result}"
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_public_ip" "student" {
  for_each            = local.students
  name                = "pip-pslab-${each.key}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  domain_name_label   = "${var.name_prefix}-${each.key}-${random_string.dns_suffix.result}"
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "dc" {
  name                = "nic-dc01"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  dns_servers         = [local.dc_ip]
  tags                = local.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.lab.id
    private_ip_address_allocation = "Static"
    private_ip_address            = local.dc_ip
    public_ip_address_id          = azurerm_public_ip.dc.id
  }
}

resource "azurerm_network_interface" "student" {
  for_each            = local.students
  name                = "nic-pslab-${each.key}"
  location            = azurerm_resource_group.lab.location
  resource_group_name = azurerm_resource_group.lab.name
  tags                = local.tags

  ip_configuration {
    name      = "ipconfig1"
    subnet_id = azurerm_subnet.lab.id
    # Feste Adressen: sonst kann ein Teilnehmer-NIC die DC-Adresse (.4) zuerst belegen
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(local.subnet_cidr, 10 + each.value)
    public_ip_address_id          = azurerm_public_ip.student[each.key].id
  }
}
