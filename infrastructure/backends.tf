locals {
  tf_backends = {
    backstage_test : {
      name = "backstage-test"
      repo = "https://github.com/bortington/backstage-test"
    }
  }
}

resource "azurerm_storage_container" "tf_backends_sc" {
  for_each              = local.tf_backends
  name                  = each.value.name
  container_access_type = "private"
  storage_account_name  = azurerm_storage_account.terraform_state_storage.name
  metadata = {
    Repo_URL = each.value.repo
  }
}