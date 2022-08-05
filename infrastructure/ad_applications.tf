locals {
  github_repos_with_apps = {
    backstage_testing : {
      repo        = "tftesting-testing"
      environment = "tfplan"
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

# resource "azuread_application_federated_identity_credential" "example" {
#   for_each              = azuread_application.github_actions_aadapplication
#   application_object_id = each.value.object_id
#   display_name          = "my-repo-deploy"
#   description           = "Deployments for my-repo"
#   audiences             = ["api://AzureADTokenExchange"]
#   issuer                = "https://token.actions.githubusercontent.com"
#   subject               = "repo:${each.value.<something?>.repo}/my-repo:environment:prod"
# }