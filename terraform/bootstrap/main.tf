module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name             = var.state_resource_group_name
  location         = var.location
  tags             = var.tags
  enable_telemetry = false
}

module "state_storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.7.3"

  name                            = var.state_storage_account_name
  location                        = var.location
  parent_id                       = module.resource_group.resource_id
  account_kind                    = "StorageV2"
  account_sku_name                = var.state_storage_account_sku_name
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  default_to_oauth_authentication = true
  public_network_access_enabled   = var.state_public_network_access_enabled
  shared_access_key_enabled       = false
  enable_telemetry                = false
  tags                            = var.tags

  network_rules = {
    default_action = var.state_network_default_action
    bypass         = var.state_network_bypass
  }

  containers = {
    tfstate = {
      name          = var.state_container_name
      public_access = "None"
    }
  }

  role_assignments = var.grant_current_principal_blob_data_contributor ? {
    current_principal = {
      role_definition_id_or_name = "Storage Blob Data Contributor"
      principal_id               = var.state_admin_principal_id
      principal_type             = null
    }
  } : {}
}
