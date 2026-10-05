# ---------------- Kostenschutz: Auto-Shutdown und Budget ----------------

resource "azurerm_dev_test_global_vm_shutdown_schedule" "dc" {
  count                 = var.autoshutdown_enabled ? 1 : 0
  virtual_machine_id    = azurerm_windows_virtual_machine.dc.id
  location              = azurerm_resource_group.lab.location
  enabled               = true
  daily_recurrence_time = var.autoshutdown_time
  timezone              = "W. Europe Standard Time"
  notification_settings {
    enabled = false
  }
  tags = local.tags
}

resource "azurerm_dev_test_global_vm_shutdown_schedule" "student" {
  for_each              = var.autoshutdown_enabled ? local.students : {}
  virtual_machine_id    = azurerm_windows_virtual_machine.student[each.key].id
  location              = azurerm_resource_group.lab.location
  enabled               = true
  daily_recurrence_time = var.autoshutdown_time
  timezone              = "W. Europe Standard Time"
  notification_settings {
    enabled = false
  }
  tags = local.tags
}

resource "azurerm_consumption_budget_resource_group" "lab" {
  count             = var.budget_alert_email != "" && var.budget_amount_eur > 0 ? 1 : 0
  name              = "budget-${var.name_prefix}"
  resource_group_id = azurerm_resource_group.lab.id
  amount            = var.budget_amount_eur
  time_grain        = "Monthly"

  time_period {
    start_date = "${var.budget_start_date}T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"
    contact_emails = [var.budget_alert_email]
  }
  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Forecasted"
    contact_emails = [var.budget_alert_email]
  }
}
