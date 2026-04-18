locals {
  # Source of truth is var.ad_backends (see variables.tf for the object
  # schema, backends.auto.tfvars for the values).

  // Unique set of all SP display names that need blob access across all backends
  ad_backend_identity_names = toset(flatten([
    for k, v in var.ad_backends : v.identities
  ]))

  // Flat map of backend+identity pairs for role assignment
  ad_backend_identity_assignments = {
    for pair in flatten([
      for backend_key, backend in var.ad_backends : [
        for identity in backend.identities : {
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
  for_each              = var.ad_backends
  name                  = each.value.name
  container_access_type = "private"
  storage_account_id    = azurerm_storage_account.terraform_state_storage.id
  metadata = {
    repo = each.value.repo
  }
}
