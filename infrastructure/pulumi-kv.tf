locals {
  pulumi_passphrases = {
    infra-azure-foundations : {
      readers : [
        "github-actions-infra-azure-foundations-infra",
        "github-actions-infra-azure-foundations-preview"
      ]
    }
  }

  secret_reader_pairs = flatten([
    for sname, cfg in local.pulumi_passphrases : [
      for r in cfg.readers : {
        secret_name = sname
        reader_name = r
      }
    ]
  ])

  # Distinct list of all reader display names
  secret_reader_names = distinct([for p in local.secret_reader_pairs : p.reader_name])

  principal_by_name = {
    for sp in data.azuread_service_principals.secret_readers.service_principals :
    sp.display_name => sp
  }
}

resource "azurerm_key_vault" "pulumi_kv" {
  name                          = "pulumi-passphrases"
  tenant_id                     = data.azuread_client_config.current.tenant_id
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  rbac_authorization_enabled    = true
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  sku_name                      = "standard"
  public_network_access_enabled = true
}

resource "random_password" "pass" {
  for_each = local.pulumi_passphrases
  length   = 12
  special  = false
  numeric  = true
}

resource "azurerm_key_vault_secret" "secrets" {
  for_each     = local.pulumi_passphrases
  name         = each.key
  value        = random_password.pass[each.key].result
  key_vault_id = azurerm_key_vault.pulumi_kv.id
  content_type = "text/plain"
}

data "azuread_service_principals" "secret_readers" {
  display_names = local.secret_reader_names
  depends_on    = [azuread_service_principal.github_actions_sp]
}

resource "azurerm_role_assignment" "secret_readers" {
  for_each = {
    for p in local.secret_reader_pairs :
    "${p.secret_name}|${p.reader_name}" => p
  }

  scope              = "${azurerm_key_vault.pulumi_kv.id}/secrets/${each.value.secret_name}"
  role_definition_id = "Key Vault Secrets User"
  principal_id       = local.principal_by_name[each.value.reader_name]
}