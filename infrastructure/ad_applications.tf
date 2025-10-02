locals {
  github_repos_with_apps = {
    backstage_test : {
      github_org  = "bortington"
      repo        = "backstage-test"
      environment = "tf"
    }
    azure-functions-playground : {
      github_org  = "badbort"
      repo        = "azure-functions-playground"
      environment = "prod"
    }
    tf-sandbox : {
      github_org  = "badbort"
      repo        = "tf-sandbox"
      environment = "main"
    }
    tf-github-repo-management : {
      github_org  = "badbort"
      repo        = "tf-github-repo-management"
      environment = "main"
    }
    apim-managed-test-dev : {
      github_org     = "badbort"
      repo           = "apim-managed-test"
      environment    = "dev"
      resource_group = "rg-apim-managed-test"
    }
    telemetry-test : {
      github_org     = "bortington"
      repo           = "telemetry-test"
      environment    = "primary"
      resource_group = "rg-telemetry-test"
      backend        = "telemetry-test"
      role_assignments = [
        "Storage Account Contributor",
        "Storage Blob Data Owner",
        "Storage Table Data Contributor",
        "Storage File Data Privileged Contributor",
        "Storage File Data SMB Share Contributor",
        "Storage File Data SMB Share Elevated Contributor",
        "Owner",
        "User Access Administrator",
        "Azure Service Bus Data Owner",
        "Key Vault Administrator"
      ]
    }
    infra-azure-foundations-infra : {
      github_org  = "badbort"
      repo        = "infra-azure-foundations"
      environment = "infra"
      backend     = "infra-azure-foundations"
    }
    infra-azure-foundations-preview : {
      github_org  = "badbort"
      repo        = "infra-azure-foundations"
      environment = "preview"
    }
  }

  resource_groups = { for key, value in local.github_repos_with_apps : key => value if try(value.resource_group, null) != null }

  custom_role_assignments = flatten([
    for repo_key, repo in local.github_repos_with_apps : [
      for role in try(repo.role_assignments, []) : {
        repo_key             = repo_key
        role_definition_name = role
      }
    ]
  ])

  ad_tf_backends = { for key, value in local.github_repos_with_apps : key => value if try(value.backend, null) != null }
}

resource "azuread_application" "github_actions_aadapplication" {
  for_each     = local.github_repos_with_apps
  display_name = join("-", ["github-actions", each.value.repo, each.value.environment])
  owners       = [data.azuread_client_config.current.object_id]

  lifecycle {
    ignore_changes = [
      required_resource_access
    ]
  }
}

resource "azuread_service_principal" "github_actions_sp" {
  for_each                     = azuread_application.github_actions_aadapplication
  client_id                    = each.value.client_id
  app_role_assignment_required = false
}

resource "azuread_application_federated_identity_credential" "cred" {
  for_each       = local.github_repos_with_apps
  application_id = azuread_application.github_actions_aadapplication[each.key].id
  display_name   = each.value.repo
  description    = "Terraform deployments for ${each.value.github_org}/${each.value.repo}"
  audiences      = ["api://AzureADTokenExchange"]
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${each.value.github_org}/${each.value.repo}:environment:${each.value.environment}"
}

resource "azurerm_resource_group" "instance" {
  for_each = local.resource_groups
  name     = each.value.resource_group
  location = "Australia East"
}

resource "azurerm_role_assignment" "instance" {
  for_each             = local.resource_groups
  principal_id         = azuread_service_principal.github_actions_sp[each.key].object_id
  role_definition_name = "Contributor"
  scope                = azurerm_resource_group.instance[each.key].id
}

resource "azurerm_role_assignment" "custom_rg_assignments" {
  for_each = {
    for ra in local.custom_role_assignments :
    "${ra.repo_key}-${replace(lower(ra.role_definition_name), " ", "-")}" => ra
  }

  principal_id         = azuread_service_principal.github_actions_sp[each.value.repo_key].object_id
  role_definition_name = each.value.role_definition_name
  scope                = azurerm_resource_group.instance[each.value.repo_key].id
}

resource "azurerm_storage_container" "ad_tf_backends" {
  for_each              = local.ad_tf_backends
  name                  = each.value.backend
  container_access_type = "private"
  storage_account_id    = azurerm_storage_account.terraform_state_storage.id
  metadata = {
    repo       = each.value.repo
    github_org = each.value.github_org
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_role_assignment" "backend_ad_blob_contributor" {
  for_each             = local.ad_tf_backends
  principal_id         = azuread_service_principal.github_actions_sp[each.key].object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_container.ad_tf_backends[each.key].resource_manager_id
}
