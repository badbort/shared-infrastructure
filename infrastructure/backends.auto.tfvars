ad_backends = {
  backstage_test = {
    name = "backstage-test"
    repo = "https://github.com/bortington/backstage-test"
  }
  tf-github-repo-management = {
    name = "tf-github-repo-management"
    repo = "https://github.com/badbort/tf-github-repo-management"
  }
  apim-managed-test = {
    name = "apim-managed-test"
    repo = "https://github.com/badbort/apim-managed-test"
  }
  hackathon-2026 = {
    name = "hackathon-2026"
    repo = "https://github.com/racwasandbox/hackathon-spec-driven"
  }
  uplift-2026 = {
    name       = "uplift-2026"
    repo       = "https://github.com/badbort/uplift-2026"
    identities = ["github-actions-uplift-2026"]
  }
  infra-azure-frontdoor = {
    name = "infra-azure-frontdoor"
    repo = "https://github.com/badbort/infra-azure-frontdoor"
    identities = [
      "github-actions-infra-azure-frontdoor-infra",
      "github-actions-infra-azure-frontdoor-preview",
    ]
    pulumi_keys = ["infra-azure-frontdoor"]
  }
  shared-services = {
    name = "shared-services"
    repo = "https://github.com/badbort/shared-services"
    identities = [
      "github-actions-shared-services-infra",
      "github-actions-shared-services-plan",
    ]
  }
}
