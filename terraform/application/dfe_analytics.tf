provider "google" {
  project = "rugged-abacus-218110"
}

module "dfe_analytics" {
  count  = var.enable_dfe_analytics_federated_auth ? 1 : 0
  source = "./vendor/modules/aks//aks/dfe_analytics"

  azure_resource_prefix = var.azure_resource_prefix
  cluster               = var.cluster
  namespace             = var.namespace
  service_short         = var.service_short
  environment           = var.environment
  gcp_keyring           = "bat-key-ring"
  gcp_key               = "bat-key"
  gcp_taxonomy_id       = "69524444121704657"
  gcp_policy_tag_id     = "6523652585511281766"
}