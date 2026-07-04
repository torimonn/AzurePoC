locals {
  public_network_access_enabled = var.enable_storage_private_only_access ? false : var.storage_public_network_access_enabled
  network_default_action        = var.enable_storage_private_only_access ? "Deny" : var.storage_network_default_action
}

resource "azurerm_storage_account" "this" {
  count = var.create_storage_account ? 1 : 0

  name                            = var.storage_account_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  account_kind                    = "StorageV2"
  account_tier                    = var.storage_account_tier
  account_replication_type        = var.storage_account_replication_type
  access_tier                     = var.storage_account_access_tier
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = local.public_network_access_enabled
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = var.storage_shared_access_key_enabled
  tags                            = var.tags

  network_rules {
    default_action = local.network_default_action
    bypass         = var.storage_network_bypass
  }
}

resource "azurerm_private_endpoint" "blob" {
  count = var.create_storage_account ? 1 : 0

  name                = "pe-${var.storage_account_name}-blob"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_endpoint_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.storage_account_name}-blob"
    private_connection_resource_id = azurerm_storage_account.this[0].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [var.blob_private_dns_zone_id]
  }
}

resource "azurerm_storage_container" "documents" {
  count = var.create_storage_account && var.create_blob_container ? 1 : 0

  name                  = var.blob_container_name
  storage_account_id    = azurerm_storage_account.this[0].id
  container_access_type = "private"
}
