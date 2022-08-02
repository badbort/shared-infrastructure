locals {
  rg_name     = "rg-common"
  rg_location = "Australia East"
  tf_sta_name = "badbortcommontfstatesta"
}

output "tf_sta_name" {
  description = "Name of the shared Azure storage account for storing tfstate containers and files"
  value = local.tf_sta_name
}

output "rg_name" {
  description = "The name of the common resource group"
  value       = local.rg_name
}

output "rg_location" {
  description = "The common resource group location"
  value       = local.rg_location
}