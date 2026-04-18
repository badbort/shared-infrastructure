# Platform-level CanNotDelete locks on foundational resources. These apply at
# the Azure control-plane layer, so they block deletion from Terraform, the
# portal, the CLI, and any other client. Removing a lock is itself a
# deliberate Terraform change — catch it in code review.

resource "azurerm_management_lock" "rg_common" {
  name       = "cannot-delete"
  scope      = azurerm_resource_group.rg.id
  lock_level = "CanNotDelete"
  notes      = "Shared infrastructure RG. Contains state storage and Pulumi KV."
}

resource "azurerm_management_lock" "terraform_state_storage" {
  name       = "cannot-delete"
  scope      = azurerm_storage_account.terraform_state_storage.id
  lock_level = "CanNotDelete"
  notes      = "Holds Terraform state for all consumer repos."
}

resource "azurerm_management_lock" "pulumi_kv" {
  name       = "cannot-delete"
  scope      = azurerm_key_vault.pulumi_kv.id
  lock_level = "CanNotDelete"
  notes      = "Holds Pulumi KMS keys used to encrypt stack state."
}
