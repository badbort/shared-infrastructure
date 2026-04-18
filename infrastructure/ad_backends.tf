locals {
  # Source of truth for state backends. Consumer repos manage their own
  # identity (existing AAD SP display names listed in `identities`); this repo
  # only creates the blob container and grants access.
  #
  # Fields:
  #   name       - blob container name in badbortcommontfstatesta
  #   repo       - recorded as container metadata (informational)
  #   identities - optional list of existing SP display names granted
  #                Storage Blob Data Contributor on the container
  #   passphrase - optional list(string) of Pulumi stack names. For each name,
  #                a passphrase secret and KMS key with that name are created
  #                in kv-badbort-pulumi-pw, and `identities` gain Key Vault
  #                Secrets User + Key Vault Crypto User on them. See
  #                pulumi-kv.tf.
  ad_backends = {
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
    hackathon-2026 : {
      name = "hackathon-2026"
      repo = "https://github.com/racwasandbox/hackathon-spec-driven"
    }
    uplift-2026 : {
      name       = "uplift-2026"
      repo       = "https://github.com/badbort/uplift-2026"
      identities = ["github-actions-uplift-2026"]
    }
    infra-azure-frontdoor : {
      name = "infra-azure-foundfrontdoorations"
      repo = "https://github.com/badbort/infra-azure-frontdoor"
      identities = [
        "github-actions-infra-azure-frontdoor-infra",
        "github-actions-infra-azure-frontdoor-preview",
      ]
      passphrase = ["infra-azure-frontdoor"]
    }
  }

  // Unique set of all SP display names that need blob access across all backends
  ad_backend_identity_names = toset(flatten([
    for k, v in local.ad_backends : try(v.identities, [])
  ]))

  // Flat map of backend+identity pairs for role assignment
  ad_backend_identity_assignments = {
    for pair in flatten([
      for backend_key, backend in local.ad_backends : [
        for identity in try(backend.identities, []) : {
          key         = "${backend_key}-${identity}"
          backend_key = backend_key
          identity    = identity
        }
      ]
    ]) : pair.key => pair
  }
}

data "azuread_service_principal" "tf_backend_identities" {
  for_each     = local.ad_backend_identity_names
  display_name = each.value
}

resource "azurerm_role_assignment" "tf_backend_blob_contributor" {
  for_each             = local.ad_backend_identity_assignments
  principal_id         = data.azuread_service_principal.tf_backend_identities[each.value.identity].object_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = azurerm_storage_container.tf_backends_sc[each.value.backend_key].resource_manager_id
}

resource "azurerm_storage_container" "tf_backends_sc" {
  for_each              = local.ad_backends
  name                  = each.value.name
  container_access_type = "private"
  storage_account_id    = azurerm_storage_account.terraform_state_storage.id
  metadata = {
    repo = each.value.repo
  }

  lifecycle {
  }
}
