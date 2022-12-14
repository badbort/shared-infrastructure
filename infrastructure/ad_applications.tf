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
  }
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
  application_id               = each.value.application_id
  app_role_assignment_required = false
}

resource "azuread_application_federated_identity_credential" "cred" {
  for_each              = local.github_repos_with_apps
  application_object_id = azuread_application.github_actions_aadapplication[each.key].object_id
  display_name          = each.value.repo
  description           = "Terraform deployments for ${each.value.github_org}/${each.value.repo}"
  audiences             = ["api://AzureADTokenExchange"]
  issuer                = "https://token.actions.githubusercontent.com"
  subject               = "repo:${each.value.github_org}/${each.value.repo}:environment:${each.value.environment}"
}

# data "github_repository" "repo" {
#   for_each     = local.github_repos_with_apps
#   full_name = "${each.value.github_org}/${each.value.repo}"
# }

# resource "github_repository_environment" "repo_env" {
#   for_each     = local.github_repos_with_apps
#   environment  = each.value.environment
#   repository   = data.github_repository.repo[each.key].full_name
# }
