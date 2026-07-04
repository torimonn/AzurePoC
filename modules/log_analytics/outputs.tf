output "log_analytics_workspace_id" {
  description = "Log Analytics WorkspaceのResource ID。"
  value       = azurerm_log_analytics_workspace.this.id
}

output "log_analytics_workspace_customer_id" {
  description = "Log Analytics WorkspaceのCustomer ID。"
  value       = azurerm_log_analytics_workspace.this.workspace_id
}

output "log_analytics_workspace_primary_shared_key" {
  description = "Log Analytics WorkspaceのPrimary Shared Key。"
  value       = azurerm_log_analytics_workspace.this.primary_shared_key
  sensitive   = true
}
