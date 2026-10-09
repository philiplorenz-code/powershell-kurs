output "resource_group" {
  value = azurerm_resource_group.lab.name
}

output "dc_private_ip" {
  value = local.dc_ip
}

output "dc_public_ip" {
  value = azurerm_public_ip.dc.ip_address
}

output "student_public_ips" {
  value = { for k, v in azurerm_public_ip.student : "PSLAB-${k}" => v.ip_address }
}

output "student_fqdns" {
  value = { for k, v in azurerm_public_ip.student : "PSLAB-${k}" => v.fqdn }
}

output "dc_fqdn" {
  value = azurerm_public_ip.dc.fqdn
}

output "rdp_open_to_internet" {
  value = var.rdp_open_to_internet
}

output "domain" {
  value = var.domain_name
}

# Sensible Ausgaben: nur über `./lab.ps1 credentials` oder `terraform output -json` sichtbar
output "admin_username" {
  value = "${var.domain_netbios}\\${local.admin_user}"
}

output "admin_password" {
  value     = random_password.admin.result
  sensitive = true
}

output "dsrm_password" {
  value     = random_password.dsrm.result
  sensitive = true
}

output "student_credentials" {
  value = {
    for k, v in random_password.student : k => {
      vm       = "PSLAB-${k}"
      user     = "${var.domain_netbios}\\teilnehmer${k}"
      password = v.result
      rdp      = azurerm_public_ip.student[k].ip_address
      fqdn     = azurerm_public_ip.student[k].fqdn
      name     = try(var.participants[tonumber(k) - 1].name, "")
      company  = try(var.participants[tonumber(k) - 1].company, "")
      email    = try(var.participants[tonumber(k) - 1].email, "")
    }
  }
  sensitive = true
}

output "trainer_fqdn" {
  description = "RDP-Adresse der Trainer-VM (leer, wenn trainer_vm_enabled = false)"
  value       = var.trainer_vm_enabled ? azurerm_public_ip.trainer["trainer"].fqdn : ""
}
