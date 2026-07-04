locals {
  public_network_access_enabled = var.enable_ai_private_only_access ? false : var.ai_public_network_access_enabled
  network_default_action        = var.enable_ai_private_only_access ? "Deny" : var.ai_network_default_action
}

resource "azurerm_cognitive_account" "this" {
  name                          = var.ai_account_name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "AIServices"
  sku_name                      = var.ai_sku_name
  custom_subdomain_name         = var.ai_account_name
  project_management_enabled    = true
  public_network_access_enabled = local.public_network_access_enabled
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }

  network_acls {
    default_action = local.network_default_action
  }
}

resource "azurerm_cognitive_account_project" "default" {
  name                 = var.ai_project_name
  cognitive_account_id = azurerm_cognitive_account.this.id
  location             = azurerm_cognitive_account.this.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_endpoint" "ai" {
  name                = "pe-${var.ai_account_name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.ai_account_name}"
    private_connection_resource_id = azurerm_cognitive_account.this.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = values(var.ai_private_dns_zone_ids)
  }
}
