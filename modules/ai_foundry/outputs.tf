output "ai_account_id" {
  description = "Azure AI ServicesアカウントのResource ID。"
  value       = azurerm_cognitive_account.this.id
}

output "ai_account_endpoint" {
  description = "Azure AI ServicesアカウントのEndpoint。"
  value       = azurerm_cognitive_account.this.endpoint
}

output "ai_project_id" {
  description = "Azure AI Foundry ProjectのResource ID。"
  value       = azurerm_cognitive_account_project.default.id
}

output "ai_private_endpoint_id" {
  description = "AI Services用Private Endpoint ID。"
  value       = azurerm_private_endpoint.ai.id
}
