output "state_resource_group_name" {
  description = "Terraform state用Resource Group名。"
  value       = module.resource_group.name
}

output "state_storage_account_id" {
  description = "Terraform state用Storage AccountのResource ID。"
  value       = module.state_storage.resource_id
}

output "state_storage_account_name" {
  description = "Terraform state用Storage Account名。"
  value       = module.state_storage.name
}

output "state_container_name" {
  description = "Terraform state用Blob Container名。"
  value       = module.state_storage.containers["tfstate"].name
}

output "solution_backend_key" {
  description = "solution root moduleで使用するstate key。"
  value       = "ocr-demo/solution/terraform.tfstate"
}

output "bootstrap_backend_key" {
  description = "bootstrap root module自身で使用するstate key。"
  value       = "ocr-demo/bootstrap/terraform.tfstate"
}
