locals {
  # Explicitly-declared Pulumi KMS keys (used as `secrets-provider` in Pulumi
  # stacks via azurekeyvault://.../keys/<name>). Additional entries are
  # merged in from ad_backends.tf where an entry lists `pulumi_keys = [...]`.
  pulumi_keys_explicit = {
    infra-azure-foundations-stack-adi-tenant = {
      readers = [
        "github-actions-infra-azure-foundations-infra",
        "github-actions-infra-azure-foundations-preview",
      ]
      # Optional overrides (shown here as examples; can be omitted):
      # key_type = "RSA"           # RSA, RSA-HSM, EC, EC-HSM, oct-HSM
      # key_size = 2048            # for RSA
      # curve   = null             # for EC: P-256, P-256K, P-384, P-521
      # key_ops = ["wrapKey","unwrapKey"]  # default below
      # exportable       = false
      # expiration_date  = null     # RFC3339 timestamp string, e.g., "2026-12-31T23:59:59Z"
      # not_before_date  = null
      # tags             = { purpose = "pulumi-kms" }
    }
  }

  # Pulumi KMS key entries derived from ad_backends. Each string in a
  # backend's `pulumi_keys` list becomes a separate key, and readers = the
  # backend's `identities` — so the same SPs that hold Storage Blob Data
  # Contributor on the state container also gain Key Vault Crypto User on
  # the matching key.
  pulumi_keys_from_ad_backends = {
    for pair in flatten([
      for k, v in local.ad_backends : [
        for kname in try(v.pulumi_keys, []) : {
          name    = kname
          readers = try(v.identities, [])
        }
      ]
    ]) : pair.name => { readers = pair.readers }
  }

  pulumi_keys = merge(local.pulumi_keys_explicit, local.pulumi_keys_from_ad_backends)

  # Provide sensible defaults, then merge per-key overrides from `pulumi_keys`
  pulumi_keys_merged = {
    for k, v in local.pulumi_keys :
    k => merge(
      {
        key_type = "RSA"
        key_size = 2048
        curve    = null
        key_ops  = ["encrypt", "decrypt"] # good default for KMS use
        tags     = {}
        readers  = try(v.readers, [])
      },
      v
    )
  }

  # (key_name, reader_name) pairs for RBAC
  key_reader_pairs = flatten([
    for kname, cfg in local.pulumi_keys_merged : [
      for r in cfg.readers : {
        key_name    = kname
        reader_name = r
      }
    ]
  ])

  # Distinct list of reader display names to resolve
  key_reader_names = distinct([for p in local.key_reader_pairs : p.reader_name])

  key_principal_by_name = {
    for sp in data.azuread_service_principals.key_readers.service_principals :
    sp.display_name => sp.object_id
  }
}

resource "azurerm_key_vault" "pulumi_kv" {
  name                          = "kv-badbort-pulumi-pw"
  tenant_id                     = data.azuread_client_config.current.tenant_id
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  rbac_authorization_enabled    = true
  soft_delete_retention_days    = 90
  purge_protection_enabled      = true
  sku_name                      = "standard"
  public_network_access_enabled = true
}

data "azuread_service_principals" "key_readers" {
  display_names = local.key_reader_names
  depends_on    = [azuread_service_principal.github_actions_sp]
}

resource "azurerm_key_vault_key" "pulumi_keys" {
  for_each     = local.pulumi_keys_merged
  name         = each.key
  key_vault_id = azurerm_key_vault.pulumi_kv.id
  key_type     = each.value.key_type
  key_size     = try(each.value.key_size, null)
  curve        = try(each.value.curve, null)
  key_opts     = try(each.value.key_ops, null)
  tags         = try(each.value.tags, null)
}

resource "azurerm_role_assignment" "key_readers" {
  for_each = {
    for p in local.key_reader_pairs :
    "${p.key_name}|${p.reader_name}" => p
  }
  scope                = azurerm_key_vault_key.pulumi_keys[each.value.key_name].resource_versionless_id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = local.key_principal_by_name[each.value.reader_name]
}
