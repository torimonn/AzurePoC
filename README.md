# OCR Demo Terraform

Terraform code for the Azure OCR-Demo PoC. The repository separates the private foundation layer from the later application layer.

## Structure

- `01-foundation-network-ai`: Resource Group, VNet, subnets, Azure AI Services/Foundry project, Blob Storage, Key Vault, Private Endpoints, Private DNS Zones, Log Analytics, and a private admin VM.
- `02-app`: Future application layer for ACR, managed identities, Container Apps, role assignments, API, and UI.

## Phase 1 Network

The phase 1 network in `01-foundation-network-ai/terraform.tfvars` is intentionally small.

```hcl
vnet_address_space = ["10.30.0.0/23"]

snet_aca_infra_prefixes        = ["10.30.0.0/24"]
snet_private_endpoint_prefixes = ["10.30.1.0/25"]
snet_admin_prefixes            = ["10.30.1.128/28"]

admin_private_ip_address = "10.30.1.132"
```

The remaining `10.30.1.144` to `10.30.1.255` range is reserved for future use.

## Required Values

Check these values before applying in each environment.

| File | Variable | Notes |
|---|---|---|
| `01-foundation-network-ai/terraform.tfvars` | `subscription_id` | Leave as `null` to use the current Azure CLI subscription, or set explicitly. |
| `01-foundation-network-ai/terraform.tfvars` | `storage_account_name` | Must be globally unique, 3-24 lowercase letters and numbers. |
| `01-foundation-network-ai/terraform.tfvars` | `key_vault_name` | Must be globally unique. |
| `01-foundation-network-ai/terraform.tfvars` | `admin_ssh_public_key` | Required when `create_admin_vm = true`. Use only a public key, never a private key. |
| `01-foundation-network-ai/terraform.tfvars` | `hub_azure_bastion_subnet_prefix` | Optional in phase 1. If `null`, no SSH allow rule is created. |
| `01-foundation-network-ai/terraform.tfvars` | `hub_firewall_private_ip` | Set the Hub Azure Firewall private IP before enabling UDR. |
| `02-app/terraform.tfvars` | `acr_name` | Must be globally unique when the app phase is implemented. |

## Phase 1 Settings

Phase 1 creates the admin VM, but it does not attach a Public IP. The NIC uses a static private IP in `snet-admin`.

```hcl
create_admin_vm          = true
admin_private_ip_address = "10.30.1.132"
admin_ssh_public_key     = "<SSH public key>"
```

Private-only access is enabled for Azure AI Services, Storage, and Key Vault.

```hcl
enable_ai_private_only_access        = true
enable_storage_private_only_access   = true
enable_key_vault_private_only_access = true
```

For this PoC, Storage Account shared key access is temporarily enabled so Terraform can continue from Azure Cloud Shell. This does not reopen Storage public network access.

```hcl
storage_shared_access_key_enabled = true
```

Blob containers are not created in phase 1 because private-only Storage can block Terraform data-plane access from Cloud Shell.

```hcl
create_blob_container = false
```

## UDR And Firewall Notes

UDR is prepared but disabled in phase 1 because the Hub connection may not exist yet.

```hcl
enable_udr_to_hub_firewall = false
hub_firewall_private_ip    = "<Hub Firewall Private IP>"
```

When UDR is enabled later, the route table is associated only with `snet-aca-infra` and `snet-admin`. It is not associated with `snet-private-endpoint`.

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

## Run

Run the foundation first.

```powershell
cd 01-foundation-network-ai
terraform init
terraform fmt
terraform validate
terraform plan -out main.tfplan
terraform apply main.tfplan
```

After the app phase is implemented, build images and apply `02-app`.

```powershell
az acr build --registry <acr_name> --image ocr-demo-api:v1 ./src/backend
az acr build --registry <acr_name> --image ocr-demo-ui:v1 ./src/ui

cd ../02-app
terraform init
terraform fmt
terraform validate
terraform plan -out main.tfplan
terraform apply main.tfplan
```

## Caution

Changing VNet or subnet CIDR ranges can force recreation of existing Azure resources. For a disposable PoC environment, deleting the existing Resource Group and applying fresh is often cleaner than changing an already partially-created environment.
