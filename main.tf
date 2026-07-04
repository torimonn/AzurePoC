resource "azurerm_resource_group" "this" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

module "network" {
  source = "./modules/network"

  resource_group_name            = azurerm_resource_group.this.name
  location                       = var.location
  tags                           = var.tags
  vnet_name                      = var.vnet_name
  vnet_address_space             = var.vnet_address_space
  dns_servers                    = var.dns_servers
  snet_aca_infra_name            = var.snet_aca_infra_name
  snet_aca_infra_prefixes        = var.snet_aca_infra_prefixes
  snet_private_endpoint_name     = var.snet_private_endpoint_name
  snet_private_endpoint_prefixes = var.snet_private_endpoint_prefixes
  create_admin_vm                = var.create_admin_vm
  snet_admin_name                = var.snet_admin_name
  snet_admin_prefixes            = var.snet_admin_prefixes
}

module "private_dns" {
  source = "./modules/private_dns"

  resource_group_name    = azurerm_resource_group.this.name
  tags                   = var.tags
  name_prefix            = var.name_prefix
  env                    = var.env
  vnet_id                = module.network.vnet_id
  create_storage_account = var.create_storage_account
  create_key_vault       = var.create_key_vault
}

module "log_analytics" {
  source = "./modules/log_analytics"

  resource_group_name          = azurerm_resource_group.this.name
  location                     = var.location
  tags                         = var.tags
  workspace_name               = var.log_analytics_workspace_name
  workspace_retention_in_days  = var.log_analytics_retention_days
}

module "ai_foundry" {
  source = "./modules/ai_foundry"

  resource_group_name              = azurerm_resource_group.this.name
  location                         = var.ai_location
  tags                             = var.tags
  ai_account_name                  = var.ai_name
  ai_sku_name                      = var.ai_sku_name
  ai_project_name                  = var.ai_project_name
  enable_ai_private_only_access    = var.enable_ai_private_only_access
  ai_public_network_access_enabled = var.ai_public_network_access_enabled
  ai_network_default_action        = var.ai_network_default_action
  private_endpoint_subnet_id       = module.network.private_endpoint_subnet_id
  ai_private_dns_zone_ids          = module.private_dns.ai_private_dns_zone_ids
}

module "storage" {
  source = "./modules/storage"

  resource_group_name                         = azurerm_resource_group.this.name
  location                                    = var.location
  tags                                        = var.tags
  create_storage_account                      = var.create_storage_account
  storage_account_name                        = var.storage_account_name
  storage_account_tier                        = var.storage_account_tier
  storage_account_replication_type            = var.storage_account_replication_type
  storage_account_access_tier                 = var.storage_account_access_tier
  enable_storage_private_only_access          = var.enable_storage_private_only_access
  storage_public_network_access_enabled       = var.storage_public_network_access_enabled
  storage_network_default_action              = var.storage_network_default_action
  storage_network_bypass                      = var.storage_network_bypass
  storage_shared_access_key_enabled           = var.storage_shared_access_key_enabled
  create_blob_container                       = var.create_blob_container
  blob_container_name                         = var.blob_container_name
  private_endpoint_subnet_id                  = module.network.private_endpoint_subnet_id
  blob_private_dns_zone_id                    = module.private_dns.blob_private_dns_zone_id
}

module "key_vault" {
  source = "./modules/key_vault"

  resource_group_name                            = azurerm_resource_group.this.name
  location                                       = var.location
  tags                                           = var.tags
  create_key_vault                               = var.create_key_vault
  key_vault_name                                 = var.key_vault_name
  key_vault_sku_name                             = var.key_vault_sku_name
  enable_key_vault_private_only_access           = var.enable_key_vault_private_only_access
  key_vault_public_network_access_enabled        = var.key_vault_public_network_access_enabled
  key_vault_network_default_action               = var.key_vault_network_default_action
  key_vault_network_bypass                       = var.key_vault_network_bypass
  key_vault_soft_delete_retention_days           = var.key_vault_soft_delete_retention_days
  key_vault_purge_protection_enabled             = var.key_vault_purge_protection_enabled
  private_endpoint_subnet_id                     = module.network.private_endpoint_subnet_id
  key_vault_private_dns_zone_id                  = module.private_dns.key_vault_private_dns_zone_id
}

module "admin_vm" {
  source = "./modules/admin_vm"

  resource_group_name              = azurerm_resource_group.this.name
  location                         = var.location
  tags                             = var.tags
  create_admin_vm                  = var.create_admin_vm
  snet_admin_name                  = var.snet_admin_name
  admin_subnet_id                  = module.network.admin_subnet_id
  admin_vm_name                    = var.admin_vm_name
  admin_vm_size                    = var.admin_vm_size
  admin_username                   = var.admin_username
  admin_private_ip_address         = var.admin_private_ip_address
  admin_ssh_public_key             = var.admin_ssh_public_key
  hub_azure_bastion_subnet_prefix  = var.hub_azure_bastion_subnet_prefix
}

module "udr" {
  source = "./modules/udr"

  resource_group_name          = azurerm_resource_group.this.name
  location                     = var.location
  tags                         = var.tags
  name_prefix                  = var.name_prefix
  env                          = var.env
  enable_udr_to_hub_firewall   = var.enable_udr_to_hub_firewall
  hub_firewall_private_ip      = var.hub_firewall_private_ip
  aca_infra_subnet_id          = module.network.aca_infra_subnet_id
  create_admin_vm              = var.create_admin_vm
  admin_subnet_id              = module.network.admin_subnet_id
}
