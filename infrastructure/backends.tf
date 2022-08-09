locals {
  tf_backends = {
    backstage_test : {
      name = "backstage-testing"
    }
  }
}

resource "azurerm_storage_container" "tf_backends_sc" {
  for_each              = local.tf_backends
  name                  = each.value.name
  container_access_type = "private"
  storage_account_name  = azurerm_storage_account.terraform_state_storage.name
}