locals {
  ai_public_network_access_enabled = var.enable_ai_private_only_access ? false : var.ai_public_network_access_enabled
  ai_network_default_action        = var.enable_ai_private_only_access ? "Deny" : var.ai_network_default_action

  storage_public_network_access_enabled = var.enable_storage_private_only_access ? false : var.storage_public_network_access_enabled
  storage_network_default_action        = var.enable_storage_private_only_access ? "Deny" : var.storage_network_default_action

  key_vault_public_network_access_enabled = var.enable_key_vault_private_only_access ? false : var.key_vault_public_network_access_enabled
  key_vault_network_default_action        = var.enable_key_vault_private_only_access ? "Deny" : var.key_vault_network_default_action

  private_dns_zones = {
    cognitive_services = "privatelink.cognitiveservices.azure.com"
    openai             = "privatelink.openai.azure.com"
    ai_services        = "privatelink.services.ai.azure.com"
    blob               = "privatelink.blob.core.windows.net"
    key_vault          = "privatelink.vaultcore.azure.net"
  }

  route_table_association = var.enable_udr_to_hub_firewall ? {
    id = module.route_table[0].resource_id
  } : null

  base_subnets = {
    aca_infra = {
      name             = var.snet_aca_infra_name
      address_prefixes = var.snet_aca_infra_prefixes
      route_table      = local.route_table_association
      delegations = [{
        name = "Microsoft.App.environments"
        service_delegation = {
          name = "Microsoft.App/environments"
        }
      }]
    }
    private_endpoint = {
      name                              = var.snet_private_endpoint_name
      address_prefixes                  = var.snet_private_endpoint_prefixes
      private_endpoint_network_policies = "Disabled"
    }
  }

  admin_subnet = var.create_admin_vm ? {
    admin = {
      name             = var.snet_admin_name
      address_prefixes = var.snet_admin_prefixes
      network_security_group = {
        id = module.admin_nsg[0].resource_id
      }
      route_table = local.route_table_association
    }
  } : {}
}
