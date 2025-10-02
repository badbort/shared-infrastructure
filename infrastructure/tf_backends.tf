locals {
  // Use github_repos_with_apps instead
  tf_backends = {
    backstage_test : {
      name = "backstage-test"
      repo = "https://github.com/bortington/backstage-test"
    }
    tf-github-repo-management : {
      name = "tf-github-repo-management"
      repo = "https://github.com/badbort/tf-github-repo-management"
    }
    apim-managed-test : {
      name = "apim-managed-test"
      repo = "https://github.com/badbort/apim-managed-test"
    }
  }
}

resource "azurerm_storage_container" "tf_backends_sc" {
  for_each              = local.tf_backends
  name                  = each.value.name
  container_access_type = "private"
  storage_account_id    = azurerm_storage_account.terraform_state_storage.name
  metadata = {
    repo = each.value.repo
  }

  lifecycle {
  }
}
