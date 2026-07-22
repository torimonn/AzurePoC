data "azurerm_client_config" "current" {}

# 1. Resource Group
module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.4.0"

  name             = var.resource_group_name
  location         = var.location
  tags             = var.tags
  enable_telemetry = false

  # Microsoft Learnの推奨に従い、VMログインRoleは専用Resource Groupへ付与します。
  # principal_idがnullの場合、Role Assignmentは共通基盤側などで別途付与します。
  role_assignments = var.create_admin_vm && var.enable_admin_vm_entra_id_login && var.admin_vm_login_principal_id != null ? {
    admin_vm_entra_login = {
      role_definition_id_or_name = "Virtual Machine Administrator Login"
      principal_id               = var.admin_vm_login_principal_id
      principal_type             = var.admin_vm_login_principal_type
      description                = "OCR-Demo管理VMへのMicrosoft Entra ID管理者ログイン"
    }
  } : {}
}

# 2. Log Analytics Workspace
module "log_analytics" {
  source  = "Azure/avm-res-operationalinsights-workspace/azurerm"
  version = "0.5.1"

  name                                      = var.log_analytics_workspace_name
  location                                  = var.location
  resource_group_name                       = module.resource_group.name
  log_analytics_workspace_retention_in_days = var.log_analytics_retention_days
  enable_telemetry                          = false
  tags                                      = var.tags
}

# 3. 管理VM用NSG。Hub Bastion CIDRがnullの場合、NSG本体だけを作成します。
module "admin_nsg" {
  count = var.create_admin_vm ? 1 : 0

  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.1"

  name                = "nsg-${var.snet_admin_name}"
  location            = var.location
  resource_group_name = module.resource_group.name
  enable_telemetry    = false
  tags                = var.tags

  security_rules = var.hub_azure_bastion_subnet_prefix == null ? {} : {
    ssh_from_hub_bastion = {
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
}

# 4. Hub Firewall向けRoute Table。初期基盤ではcount=0です。
module "route_table" {
  count = var.enable_udr_to_hub_firewall ? 1 : 0

  source  = "Azure/avm-res-network-routetable/azurerm"
  version = "0.5.0"

  name                = "rt-${var.name_prefix}-${var.env}-to-hub-fw"
  location            = var.location
  resource_group_name = module.resource_group.name
  enable_telemetry    = false
  tags                = var.tags

  routes = {
    default_to_hub_firewall = {
      name                   = "default-to-hub-firewall"
      address_prefix         = "0.0.0.0/0"
      next_hop_type          = "VirtualAppliance"
      next_hop_in_ip_address = var.hub_firewall_private_ip
    }
  }
}

# 5. VNet・Subnet。Private Endpoint用SubnetにはRoute Tableを関連付けません。
module "virtual_network" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.19.0"

  name          = var.vnet_name
  location      = var.location
  parent_id     = module.resource_group.resource_id
  address_space = var.vnet_address_space
  dns_servers = length(var.dns_servers) == 0 ? null : {
    dns_servers = var.dns_servers
  }
  subnets          = merge(local.base_subnets, local.admin_subnet)
  enable_telemetry = false
  tags             = var.tags
}

# 6. AI系3つ、Blob、Key VaultのPrivate DNS ZoneとSpoke VNet Link。
module "private_dns_zones" {
  for_each = local.private_dns_zones

  source  = "Azure/avm-res-network-privatednszone/azurerm"
  version = "0.5.0"

  domain_name      = each.value
  parent_id        = module.resource_group.resource_id
  enable_telemetry = false
  tags             = var.tags

  virtual_network_links = {
    spoke = {
      name                 = "${var.name_prefix}-${var.env}-${each.key}-link"
      virtual_network_id   = module.virtual_network.resource_id
      registration_enabled = false
      tags                 = var.tags
    }
  }
}

# 7. Blob用途のStorage Account。Blob Containerは初期基盤では作成しません。
module "storage_account" {
  count = var.create_storage_account ? 1 : 0

  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.7.3"

  name                            = var.storage_account_name
  location                        = var.location
  parent_id                       = module.resource_group.resource_id
  account_kind                    = "StorageV2"
  account_sku_name                = "${var.storage_account_tier}_${var.storage_account_replication_type}"
  access_tier                     = var.storage_account_access_tier
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false
  # アプリ用PaaSは閉域基盤の固定要件としてPrivate接続だけを許可します。
  public_network_access_enabled = false

  # Storage AVMはAzAPIとEntra IDで管理するため、Shared Keyは使用しません。
  default_to_oauth_authentication = true
  shared_access_key_enabled       = false

  network_rules = {
    default_action = "Deny"
    bypass         = var.storage_network_bypass
  }

  containers       = {}
  enable_telemetry = false
  tags             = var.tags

  private_endpoints = {
    blob = {
      name                            = "pe-${var.storage_account_name}-blob"
      private_service_connection_name = "psc-${var.storage_account_name}-blob"
      subnet_resource_id              = module.virtual_network.subnets["private_endpoint"].resource_id
      subresource_name                = "blob"
      private_dns_zone_resource_ids = toset([
        module.private_dns_zones["blob"].resource_id,
      ])
    }
  }
}

# 8. State Storage用Private Endpoint。管理VMからbackendへ到達できる段階でだけ有効化します。
module "state_storage_private_endpoint" {
  count = var.enable_state_storage_private_endpoint ? 1 : 0

  source  = "Azure/avm-res-network-privateendpoint/azurerm"
  version = "0.2.0"

  name                            = "pe-${var.state_storage_account_name}-blob"
  network_interface_name          = "nic-pe-${var.state_storage_account_name}-blob"
  location                        = var.location
  resource_group_name             = module.resource_group.name
  subnet_resource_id              = module.virtual_network.subnets["private_endpoint"].resource_id
  private_connection_resource_id  = var.state_storage_account_id
  private_service_connection_name = "psc-${var.state_storage_account_name}-blob"
  subresource_names               = ["blob"]
  private_dns_zone_group_name     = "default"
  private_dns_zone_resource_ids = [
    module.private_dns_zones["blob"].resource_id,
  ]
  enable_telemetry = false
  tags             = var.tags
}

# 9. Key Vault。Secret、Key、Certificateは初期基盤では作成しません。
module "key_vault" {
  count = var.create_key_vault ? 1 : 0

  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  name                           = var.key_vault_name
  location                       = var.location
  resource_group_name            = module.resource_group.name
  tenant_id                      = data.azurerm_client_config.current.tenant_id
  sku_name                       = var.key_vault_sku_name
  legacy_access_policies_enabled = false
  public_network_access_enabled  = false
  soft_delete_retention_days     = var.key_vault_soft_delete_retention_days
  purge_protection_enabled       = var.key_vault_purge_protection_enabled
  enable_telemetry               = false
  tags                           = var.tags

  network_acls = {
    bypass         = var.key_vault_network_bypass
    default_action = "Deny"
  }

  keys          = {}
  secrets       = {}
  secrets_value = null

  private_endpoints = {
    vault = {
      name                            = "pe-${var.key_vault_name}"
      private_service_connection_name = "psc-${var.key_vault_name}"
      subnet_resource_id              = module.virtual_network.subnets["private_endpoint"].resource_id
      private_dns_zone_resource_ids = toset([
        module.private_dns_zones["key_vault"].resource_id,
      ])
    }
  }
}

# 10. Azure AI Services。Project ManagementとSystem Assigned IdentityがProject作成の前提です。
module "ai_services" {
  source  = "Azure/avm-res-cognitiveservices-account/azurerm"
  version = "0.11.1"

  name                          = var.ai_name
  location                      = var.ai_location
  parent_id                     = module.resource_group.resource_id
  kind                          = "AIServices"
  sku_name                      = var.ai_sku_name
  custom_subdomain_name         = var.ai_name
  allow_project_management      = true
  default_project               = var.ai_project_name
  public_network_access_enabled = false
  enable_telemetry              = false
  tags                          = var.tags

  managed_identities = {
    system_assigned = true
  }

  network_acls = {
    default_action = "Deny"
    bypass         = "AzureServices"
  }

  private_endpoints = {
    account = {
      name                            = "pe-${var.ai_name}"
      private_service_connection_name = "psc-${var.ai_name}"
      subnet_resource_id              = module.virtual_network.subnets["private_endpoint"].resource_id
      private_dns_zone_resource_ids = toset([
        module.private_dns_zones["cognitive_services"].resource_id,
        module.private_dns_zones["openai"].resource_id,
        module.private_dns_zones["ai_services"].resource_id,
      ])
    }
  }
}

# 公開済みTerraform AVMがないため、AzureRM Providerの正式resourceをrootで直接定義します。
resource "azurerm_cognitive_account_project" "this" {
  name                 = var.ai_project_name
  cognitive_account_id = module.ai_services.resource_id
  location             = var.ai_location
  display_name         = var.ai_project_name
  description          = "OCR-Demo Azure AI Foundry project"
  tags                 = var.tags

  identity {
    type = "SystemAssigned"
  }
}

# 11. Public IPなし、固定Private IP、公開鍵認証とMicrosoft Entra ID認証の管理VM。
module "admin_vm" {
  count = var.create_admin_vm ? 1 : 0

  source  = "Azure/avm-res-compute-virtualmachine/azurerm"
  version = "0.21.0"

  name                = var.admin_vm_name
  location            = var.location
  resource_group_name = module.resource_group.name
  zone                = null
  os_type             = "Linux"
  sku_size            = var.admin_vm_size
  enable_telemetry    = false
  tags                = var.tags

  account_credentials = {
    admin_credentials = {
      username                           = var.admin_username
      ssh_keys                           = [var.admin_ssh_public_key]
      generate_admin_password_or_ssh_key = false
    }
    password_authentication_disabled = true
  }

  managed_identities = {
    system_assigned = true
  }

  extensions = var.enable_admin_vm_entra_id_login ? {
    entra_id_ssh_login = {
      name                       = "AADSSHLoginForLinux"
      publisher                  = "Microsoft.Azure.ActiveDirectory"
      type                       = "AADSSHLoginForLinux"
      type_handler_version       = "1.0"
      auto_upgrade_minor_version = true
      automatic_upgrade_enabled  = true
    }
  } : {}

  network_interfaces = {
    primary = {
      name = "nic-${var.admin_vm_name}"
      ip_configurations = {
        primary = {
          name                          = "ipconfig1"
          private_ip_subnet_resource_id = module.virtual_network.subnets["admin"].resource_id
          private_ip_address            = var.admin_private_ip_address
          private_ip_address_allocation = "Static"
          create_public_ip_address      = false
        }
      }
      network_security_groups = {
        admin = {
          network_security_group_resource_id = module.admin_nsg[0].resource_id
        }
      }
    }
  }

  source_image_reference = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}
