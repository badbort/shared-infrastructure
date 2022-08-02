variable "sc_name" {
    description = "Storage Container name"
    type = string
}

variable "repo_url" {
  description = "Git repo location used within tags"
}

locals {
  tags = {
    git_url = var.repo_url
  }
}

module "common_values" {
  source = "../common_values"
}

data "azurerm_storage_account" "terraform_state_storage" {
  name                     = module.common_values.tf_sta_name
}

resource "azurerm_storage_container" "terraform_state" {
  name                  = var.sc_name
  container_access_type = "private"
  storage_account_name  = azurerm_storage_account.terraform_state_storage.name
  tags = var.tags
}