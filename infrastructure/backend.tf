terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-common"
    storage_account_name = "badbortcommontfstatesta"
    container_name       = "common-infrastructure-tfstate"
    key                  = "common-infrastructure.tfstate"
    subscription_id      = "bd8e250a-66a6-4038-acd8-0d6aced3e3c8"
  }
}