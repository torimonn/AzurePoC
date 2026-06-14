resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

locals {
  ai_private_dns_zone_names = toset([
    "privatelink.cognitiveservices.azure.com",
    "privatelink.openai.azure.com",
    "privatelink.services.ai.azure.com",
  ])

  ai_public_network_access_enabled = var.enable_ai_private_only_access ? false : var.ai_public_network_access_enabled
  ai_network_default_action        = var.enable_ai_private_only_access ? "Deny" : var.ai_network_default_action

  storage_public_network_access_enabled = var.enable_storage_private_only_access ? false : var.storage_public_network_access_enabled
  storage_network_default_action        = var.enable_storage_private_only_access ? "Deny" : var.storage_network_default_action

  key_vault_public_network_access_enabled = var.enable_key_vault_private_only_access ? false : var.key_vault_public_network_access_enabled
  key_vault_network_default_action        = var.enable_key_vault_private_only_access ? "Deny" : var.key_vault_network_default_action
}

data "azurerm_client_config" "current" {}

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = var.vnet_address_space
  dns_servers         = var.dns_servers
  tags                = var.tags
}

resource "azurerm_subnet" "aca_infra" {
  name                 = var.snet_aca_infra_name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.snet_aca_infra_prefixes

  delegation {
    name = "delegation-container-apps"

    service_delegation {
      name = "Microsoft.App/environments"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet" "private_endpoint" {
  name                 = var.snet_private_endpoint_name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.snet_private_endpoint_prefixes
}

resource "azurerm_subnet" "admin" {
  count = var.create_admin_vm ? 1 : 0

  name                 = var.snet_admin_name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.snet_admin_prefixes
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.log_analytics_workspace_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_analytics_retention_days
  tags                = var.tags
}

resource "azurerm_cognitive_account" "ai" {
  name                          = var.ai_name
  location                      = var.ai_location
  resource_group_name           = azurerm_resource_group.this.name
  kind                          = "AIServices"
  sku_name                      = var.ai_sku_name
  custom_subdomain_name         = var.ai_name
  project_management_enabled    = true
  public_network_access_enabled = local.ai_public_network_access_enabled
  tags                          = var.tags

  identity {
    type = "SystemAssigned"
  }

  network_acls {
    default_action = local.ai_network_default_action
  }
}

resource "azurerm_cognitive_account_project" "default" {
  name                 = var.ai_project_name
  cognitive_account_id = azurerm_cognitive_account.ai.id
  location             = azurerm_cognitive_account.ai.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_private_dns_zone" "ai" {
  for_each = local.ai_private_dns_zone_names

  name                = each.value
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "ai" {
  for_each = azurerm_private_dns_zone.ai

  name                  = "${var.name_prefix}-${var.env}-${replace(replace(each.key, "privatelink.", ""), ".", "-")}-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = each.value.name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "ai" {
  name                = "pe-${var.ai_name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoint.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.ai_name}"
    private_connection_resource_id = azurerm_cognitive_account.ai.id
    subresource_names              = ["account"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [for zone in azurerm_private_dns_zone.ai : zone.id]
  }
}

resource "azurerm_storage_account" "blob" {
  count = var.create_storage_account ? 1 : 0

  name                            = var.storage_account_name
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  account_kind                    = "StorageV2"
  account_tier                    = var.storage_account_tier
  account_replication_type        = var.storage_account_replication_type
  access_tier                     = var.storage_account_access_tier
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = local.storage_public_network_access_enabled
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = var.storage_shared_access_key_enabled
  tags                            = var.tags

  network_rules {
    default_action = local.storage_network_default_action
    bypass         = var.storage_network_bypass
  }
}

resource "azurerm_private_dns_zone" "blob" {
  count = var.create_storage_account ? 1 : 0

  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  count = var.create_storage_account ? 1 : 0

  name                  = "${var.name_prefix}-${var.env}-blob-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.blob[0].name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "blob" {
  count = var.create_storage_account ? 1 : 0

  name                = "pe-${var.storage_account_name}-blob"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoint.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.storage_account_name}-blob"
    private_connection_resource_id = azurerm_storage_account.blob[0].id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob[0].id]
  }
}

resource "azurerm_storage_container" "documents" {
  count = var.create_storage_account && var.create_blob_container ? 1 : 0

  name                  = var.blob_container_name
  storage_account_id    = azurerm_storage_account.blob[0].id
  container_access_type = "private"
}

resource "azurerm_key_vault" "this" {
  count = var.create_key_vault ? 1 : 0

  name                          = var.key_vault_name
  location                      = azurerm_resource_group.this.location
  resource_group_name           = azurerm_resource_group.this.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.key_vault_sku_name
  rbac_authorization_enabled    = true
  public_network_access_enabled = local.key_vault_public_network_access_enabled
  soft_delete_retention_days    = var.key_vault_soft_delete_retention_days
  purge_protection_enabled      = var.key_vault_purge_protection_enabled
  tags                          = var.tags

  network_acls {
    bypass         = var.key_vault_network_bypass
    default_action = local.key_vault_network_default_action
  }
}

resource "azurerm_private_dns_zone" "key_vault" {
  count = var.create_key_vault ? 1 : 0

  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  count = var.create_key_vault ? 1 : 0

  name                  = "${var.name_prefix}-${var.env}-keyvault-link"
  resource_group_name   = azurerm_resource_group.this.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault[0].name
  virtual_network_id    = azurerm_virtual_network.this.id
  registration_enabled  = false
  tags                  = var.tags
}

resource "azurerm_private_endpoint" "key_vault" {
  count = var.create_key_vault ? 1 : 0

  name                = "pe-${var.key_vault_name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  subnet_id           = azurerm_subnet.private_endpoint.id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.key_vault_name}"
    private_connection_resource_id = azurerm_key_vault.this[0].id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault[0].id]
  }
}

resource "azurerm_network_security_group" "admin" {
  count = var.create_admin_vm ? 1 : 0

  name                = "nsg-${var.snet_admin_name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  security_rule {
    name                       = "Allow-SSH-From-Hub-Bastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.hub_azure_bastion_subnet_prefix
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "admin" {
  count = var.create_admin_vm ? 1 : 0

  subnet_id                 = azurerm_subnet.admin[0].id
  network_security_group_id = azurerm_network_security_group.admin[0].id
}

resource "azurerm_network_interface" "admin" {
  count = var.create_admin_vm ? 1 : 0

  name                = "nic-${var.admin_vm_name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags                = var.tags

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.admin[0].id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.admin_private_ip_address
  }
}

resource "azurerm_linux_virtual_machine" "admin" {
  count = var.create_admin_vm ? 1 : 0

  name                            = var.admin_vm_name
  location                        = azurerm_resource_group.this.location
  resource_group_name             = azurerm_resource_group.this.name
  size                            = var.admin_vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.admin[0].id]
  tags                            = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  lifecycle {
    precondition {
      condition     = !var.create_admin_vm || var.admin_ssh_public_key != null
      error_message = "admin_ssh_public_key is required when create_admin_vm is true."
    }

    precondition {
      condition     = !var.create_admin_vm || var.hub_azure_bastion_subnet_prefix != null
      error_message = "hub_azure_bastion_subnet_prefix is required when create_admin_vm is true."
    }
  }
}
