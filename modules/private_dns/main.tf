locals {
  ai_private_dns_zone_names = toset([
    "privatelink.cognitiveservices.azure.com",
    "privatelink.openai.azure.com",
    "privatelink.services.ai.azure.com",
  ])
}

resource "azurerm_private_dns_zone" "ai" {
  for_each = local.ai_private_dns_zone_names

  name                = each.value
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "ai" {
  for_each = azurerm_private_dns_zone.ai

  name                  = "${var.name_prefix}-${var.env}-${replace(replace(each.key, "privatelink.", ""), ".", "-")}-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = each.value.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone" "blob" {
  count = var.create_storage_account ? 1 : 0

  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  count = var.create_storage_account ? 1 : 0

  name                  = "${var.name_prefix}-${var.env}-blob-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_dns_zone" "key_vault" {
  count = var.create_key_vault ? 1 : 0

  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  count = var.create_key_vault ? 1 : 0

  name                  = "${var.name_prefix}-${var.env}-keyvault-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault[0].name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false
  tags                  = var.tags
}
