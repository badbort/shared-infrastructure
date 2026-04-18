# AGENTS.md

Guidance for AI agents adding new Terraform or Pulumi state backends to this
repo.

All infrastructure lives in `infrastructure/`. Shared resources:

- Resource group: `rg-common` (Australia East)
- State storage account: `badbortcommontfstatesta` (Azure Blob)
- Pulumi Key Vault: `kv-badbort-pulumi-pw` (RBAC-enabled)
- Subscription: `bd8e250a-66a6-4038-acd8-0d6aced3e3c8`

**Do not edit `ad_applications.tf`.** Its `github_repos_with_apps` map is
deprecated — it provisions AAD apps and service principals on behalf of
consumer repos, which is no longer the preferred pattern. Consumer repos
should manage their own identity (workload identity, user-assigned managed
identity, or their own SP). This repo only grants that identity access to a
state container (and, for Pulumi, a Key Vault KMS key for state encryption).

Canonical examples to copy: **`uplift-2026`** (Terraform) and
**`infra-azure-frontdoor`** (Pulumi) in `ad_backends.tf`.

---

## Adding a backend

Everything goes in **`ad_backends.tf`** under `local.ad_backends`. One entry
per backend.

```hcl
my-new-repo : {
  name        = "my-new-repo"                         # blob container name
  repo        = "https://github.com/badbort/my-new-repo"
  identities  = ["github-actions-my-new-repo"]        # optional, existing SPs
  pulumi_keys = ["my-new-repo-prod"]                  # optional, KMS key names
}
```

Fields:

- `name` — the private blob container created in `badbortcommontfstatesta`.
- `repo` — recorded as container metadata; informational.
- `identities` — optional list of **existing** AAD SP display names. Each is
  granted `Storage Blob Data Contributor` on the new container. Omit (like
  `hackathon-2026`) if access is granted out-of-band. SPs must already exist
  in the tenant — they are resolved via `data "azuread_service_principal"`
  and a missing SP fails the plan.
- `pulumi_keys` — optional `list(string)` of Pulumi KMS key names. For each
  name, an RSA key with that exact name is created in `kv-badbort-pulumi-pw`
  and the backend's `identities` gain **Key Vault Crypto User** on it.
  Merged into `pulumi_keys` in `pulumi-kv.tf` automatically. Supply multiple
  names to share one state container across several Pulumi stacks.

Consumer repo's Terraform `backend.tf`:

```hcl
backend "azurerm" {
  resource_group_name  = "rg-common"
  storage_account_name = "badbortcommontfstatesta"
  container_name       = "my-new-repo"
  key                  = "terraform.tfstate"
  subscription_id      = "bd8e250a-66a6-4038-acd8-0d6aced3e3c8"
  use_azuread_auth     = true
}
```

Consumer repo using Pulumi (for each key name in `pulumi_keys`):

- Backend URL:
  `azblob://my-new-repo?storage_account=badbortcommontfstatesta`
- Secrets provider:
  `azurekeyvault://kv-badbort-pulumi-pw.vault.azure.net/keys/<key-name>`

No passphrase env var needed — Pulumi uses the KMS key directly via the
Crypto User role.

---

## Workflow for an agent

1. Confirm the consumer repo's identity (SP display name) already exists in
   the tenant. If not, ask the user — do **not** add it to
   `ad_applications.tf`.
2. Add an entry to `local.ad_backends` in `ad_backends.tf` modeled on
   `uplift-2026` (with `identities`) or `hackathon-2026` (without). For
   Pulumi, also set `pulumi_keys = ["<key-name>", ...]`.
3. Run `terraform plan` from `infrastructure/` and confirm only the intended
   additions. Apply.
4. Report back: container name, KV key names (if Pulumi), and the SPs
   that were granted access.
