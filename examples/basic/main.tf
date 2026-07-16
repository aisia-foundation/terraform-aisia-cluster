###############################################################################
# Exemple basique — déployer AISIA sur un cluster K8s existant.
# Prérequis : un kubeconfig pointant vers VOTRE cluster + cert-manager installé.
###############################################################################

terraform {
  required_version = ">= 1.5.0"
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes {
    config_path = "~/.kube/config"
  }
}

module "aisia" {
  source = "../../"

  image_tag = "v6.12.48"
  domain    = "client.aisia.fr"
  tier      = "saas"

  enable_autoscaling = true
  enable_tls         = true
  cluster_issuer     = "letsencrypt-prod"
  backup_schedule    = "0 3 * * *"

  extra_env = {
    LOG_LEVEL = "INFO"
  }
}

output "aisia_url" {
  value = module.aisia.public_url
}

output "aisia_scaling" {
  value = module.aisia.autoscaling
}
