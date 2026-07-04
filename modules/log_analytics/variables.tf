variable "resource_group_name" { type = string }
variable "location" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}
variable "workspace_name" { type = string }
variable "workspace_retention_in_days" { type = number }
