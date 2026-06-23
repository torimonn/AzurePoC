# Terraform Documentation Evidence

Collected: 2026-06-24

This note records the official documentation checks used for the OCR-Demo Terraform code.

## Checked Terraform Provider Resources

The Terraform Registry UI requires JavaScript, so the evidence below also references the matching HashiCorp `terraform-provider-azurerm` Markdown files from the official provider repository.

| Area | Terraform resource | Official documentation |
|---|---|---|
| Provider | `hashicorp/azurerm` | https://registry.terraform.io/providers/hashicorp/azurerm/latest |
| VNet | `azurerm_virtual_network` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network |
| Subnet | `azurerm_subnet` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet |
| Private DNS Zone | `azurerm_private_dns_zone` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone |
| Private DNS VNet Link | `azurerm_private_dns_zone_virtual_network_link` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_dns_zone_virtual_network_link |
| Private Endpoint | `azurerm_private_endpoint` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/private_endpoint |
| Azure AI Services | `azurerm_cognitive_account` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cognitive_account |
| Azure AI Foundry Project | `azurerm_cognitive_account_project` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cognitive_account_project |
| Storage Account | `azurerm_storage_account` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account |
| Blob Container | `azurerm_storage_container` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container |
| Key Vault | `azurerm_key_vault` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault |
| Route Table | `azurerm_route_table` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route_table |
| Route | `azurerm_route` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/route |
| Route Table Association | `azurerm_subnet_route_table_association` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet_route_table_association |
| NSG | `azurerm_network_security_group` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group |
| NSG Rule | `azurerm_network_security_rule` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_rule |
| NIC | `azurerm_network_interface` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface |
| Linux VM | `azurerm_linux_virtual_machine` | https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine |

## Current Phase 1 Network Design

The phase 1 foundation uses a compact `/23` VNet:

```text
VNet:                     10.30.0.0/23
ACA infrastructure subnet: 10.30.0.0/24
Private Endpoint subnet:   10.30.1.0/25
Admin VM subnet:           10.30.1.128/28
Admin VM private IP:       10.30.1.132
Reserved:                  10.30.1.144 - 10.30.1.255
```

The ACA subnet is intended for a future Azure Container Apps workload profiles environment. Microsoft Learn states that workload profiles environments support UDR and require a minimum subnet size of `/27`, while legacy consumption-only environments require `/23` and do not support UDR.

## Implementation Notes

- `azurerm_subnet.private_endpoint` explicitly sets `private_endpoint_network_policies = "Disabled"`, matching the provider documentation for Private Endpoint subnets.
- Azure AI private DNS zones are kept as three separate zones:
  - `privatelink.cognitiveservices.azure.com`
  - `privatelink.openai.azure.com`
  - `privatelink.services.ai.azure.com`
- Blob and Key Vault private DNS zones are also included:
  - `privatelink.blob.core.windows.net`
  - `privatelink.vaultcore.azure.net`
- `azurerm_key_vault.this` uses `rbac_authorization_enabled = true`, which is the current provider argument for enabling Azure RBAC authorization.
- Storage Account keeps `shared_access_key_enabled = true` for the PoC Cloud Shell Terraform workflow, while public network access remains controlled separately by `public_network_access_enabled` and network rules.
- Blob containers are optional and disabled by default with `create_blob_container = false` because data-plane access may fail from Cloud Shell after private-only access is enabled.
- No Key Vault secret resources are created in phase 1.
- Admin VM is private-only:
  - No public IP resource is used.
  - The NIC has only private IP configuration.
  - The private IP is static.
  - SSH rule creation depends on `hub_azure_bastion_subnet_prefix != null`.
- UDR resources are created only when `enable_udr_to_hub_firewall = true`.
- Route table association is limited to ACA and Admin subnets. The Private Endpoint subnet is intentionally not associated.
- Azure DNS Private Resolver resources are intentionally not created in this Spoke Terraform because DNS Resolver belongs to the Hub shared foundation.

## Firewall And Outbound Access Note

When UDR to the hub firewall is enabled, Azure Container Apps may require limited outbound access for platform dependencies, Managed Identity token acquisition, container image pulls, and monitoring.

Candidate outbound destinations to review with the network team include:

- `mcr.microsoft.com`
- `*.data.mcr.microsoft.com`
- `packages.aks.azure.com`
- `acs-mirror.azureedge.net`
- `login.microsoftonline.com`
- `*.login.microsoftonline.com`
- `*.identity.azure.net`
- `<ACR name>.azurecr.io`
- Azure Monitor / Log Analytics endpoints or AMPLS design

Business application traffic should use Private Endpoints or on-premises routes wherever possible. Firewall rules themselves are managed outside this Spoke Terraform.
