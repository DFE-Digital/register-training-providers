module "application_configuration" {
  source = "./vendor/modules/aks//aks/application_configuration"

  namespace              = var.namespace
  environment            = var.environment
  azure_resource_prefix  = var.azure_resource_prefix
  service_short          = var.service_short
  config_short           = var.config_short
  secret_key_vault_short = "app"
  config_variables_path  = "${path.module}/config/${var.config}.yml"

  # Delete for non rails apps
  is_rails_application = true

  config_variables = {
    ENVIRONMENT_NAME = var.environment
    PGSSLMODE        = local.postgres_ssl_mode
  }
  secret_variables = {
    DATABASE_URL        = module.postgres.url
    BLAZER_DATABASE_URL = module.postgres.url
  }
}

module "migration" {
  source = "./vendor/modules/aks//aks/job_configuration"

  namespace    = var.namespace
  environment  = var.environment
  service_name = var.service_name
  docker_image = var.docker_image
  commands     = var.commands
  arguments    = var.arguments
  job_name     = var.job_name
  enable_logit = true

  config_map_ref = module.application_configuration.kubernetes_config_map_name
  secret_ref     = module.application_configuration.kubernetes_secret_name
  cpu            = module.cluster_data.configuration_map.cpu_min
}

module "web_application" {
  source = "./vendor/modules/aks//aks/application"
  depends_on = [module.migration]

  is_web = true

  namespace    = var.namespace
  environment  = var.environment
  service_name = var.service_name
  probe_path = "/ping"
  replicas     = var.replicas

  run_as_non_root = true

  cluster_configuration_map  = module.cluster_data.configuration_map
  kubernetes_config_map_name = module.application_configuration.kubernetes_config_map_name
  kubernetes_secret_name     = module.application_configuration.kubernetes_secret_name

  docker_image = var.docker_image
  enable_logit = true

  send_traffic_to_maintenance_page = var.send_traffic_to_maintenance_page
}

module "worker_application" {
  source     = "./vendor/modules/aks//aks/application"
  depends_on = [module.migration]

  is_web = false

  run_as_non_root = true

  name         = "worker"
  namespace    = var.namespace
  environment  = var.environment
  service_name = var.service_name

  cluster_configuration_map  = module.cluster_data.configuration_map
  kubernetes_config_map_name = module.application_configuration.kubernetes_config_map_name
  kubernetes_secret_name     = module.application_configuration.kubernetes_secret_name

  docker_image = var.docker_image

  command       = ["bundle", "exec", "rake", "solid_queue:start"]
  probe_command = ["pgrep", "-f", "solid-queue-worker"]

  replicas   = var.worker_replicas
  max_memory = var.worker_memory_max

  enable_logit   = true
}
