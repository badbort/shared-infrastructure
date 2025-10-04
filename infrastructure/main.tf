provider "azurerm" {
  subscription_id = "bd8e250a-66a6-4038-acd8-0d6aced3e3c8"

  features {}
}

provider "azuread" {}

module "common" {
  source = "./modules/common_values"
}

resource "azurerm_resource_group" "rg" {
  name     = module.common.rg_name
  location = module.common.rg_location
  tags     = var.resource_tags
}

resource "azurerm_storage_account" "terraform_state_storage" {
  name                     = module.common.tf_sta_name
  account_replication_type = "LRS"
  account_tier             = "Standard"
  min_tls_version          = "TLS1_2"
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
}

resource "azurerm_storage_container" "terraform_state" {
  name                  = "common-infrastructure-tfstate"
  container_access_type = "private"
  storage_account_name  = azurerm_storage_account.terraform_state_storage.name
}

data "azuread_client_config" "current" {}