variable "resource_tags" {
  description = "Tags to set for all resources"
  type        = map(string)
  default = {
    project     = "project-alpha",
    environment = "dev"
  }
}

variable "ad_backends" {
  description = <<-EOT
    State backends managed by this repo. Each entry provisions a private blob
    container in badbortcommontfstatesta and grants the listed existing AAD
    SPs `Storage Blob Data Contributor` on it. If `pulumi_keys` is non-empty,
    matching RSA keys are also created in kv-badbort-pulumi-pw and the same
    identities gain `Key Vault Crypto User` on each. Populated from
    infrastructure/backends.auto.tfvars.

    Fields:
      name        - blob container name (3-63 chars, lowercase, alphanumeric/hyphen)
      repo        - consumer repo URL, recorded as container metadata
      identities  - existing AAD SP display names to grant blob access
      pulumi_keys - Pulumi KMS key names to create; used as the Pulumi stack
                    secrets-provider (azurekeyvault://.../keys/<name>)
  EOT

  type = map(object({
    name        = string
    repo        = string
    identities  = optional(list(string), [])
    pulumi_keys = optional(list(string), [])
  }))
}