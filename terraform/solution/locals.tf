locals {
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
