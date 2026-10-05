terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.12"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id
  # DevTestLab wird für den kostenlosen Auto-Shutdown benötigt.
  resource_providers_to_register = ["Microsoft.DevTestLab"]
  features {
    resource_group {
      # Beim destroy auch Ressourcen löschen, die Azure automatisch angelegt hat (z. B. NetworkWatcher-Reste)
      prevent_deletion_if_contains_resources = false
    }
  }
}
