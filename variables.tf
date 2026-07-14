###############################################################################
# terraform-aisia-cluster — variables d'entrée
# Déploie la stack AISIA sur un cluster Kubernetes existant (cloud-agnostique).
###############################################################################

variable "namespace" {
  description = "Namespace Kubernetes cible (créé si create_namespace=true)."
  type        = string
  default     = "aisia"
}

variable "create_namespace" {
  description = "Créer le namespace (false si géré ailleurs)."
  type        = bool
  default     = true
}

variable "image_registry" {
  description = "Registry des images AISIA (ex. registry.aisia.fr ou ghcr.io/aisia)."
  type        = string
  default     = "registry.aisia.fr"
}

variable "image_tag" {
  description = "Tag d'image AISIA à déployer (ex. v6.12.29)."
  type        = string
}

variable "domain" {
  description = "Domaine public de l'instance (ex. client.aisia.fr). Vide = pas d'Ingress."
  type        = string
  default     = ""
}

variable "tier" {
  description = "Tier d'exploitation : free | saas | baas | paas. Pilote les valeurs par défaut de scaling/ressources."
  type        = string
  default     = "saas"
  validation {
    condition     = contains(["free", "saas", "baas", "paas"], var.tier)
    error_message = "tier doit être l'un de : free, saas, baas, paas."
  }
}

variable "api_replicas_min" {
  description = "Replicas min de l'API (HPA). null = dérivé du tier."
  type        = number
  default     = null
}

variable "api_replicas_max" {
  description = "Replicas max de l'API (HPA). null = dérivé du tier."
  type        = number
  default     = null
}

variable "api_cpu_target" {
  description = "Cible d'utilisation CPU (%) pour l'autoscaling de l'API."
  type        = number
  default     = 70
}

variable "enable_autoscaling" {
  description = "Activer le HPA (Horizontal Pod Autoscaler) sur l'API + le bot."
  type        = bool
  default     = true
}

variable "enable_tls" {
  description = "Provisionner un certificat TLS via cert-manager (ClusterIssuer requis)."
  type        = bool
  default     = true
}

variable "cluster_issuer" {
  description = "Nom du ClusterIssuer cert-manager (ex. letsencrypt-prod)."
  type        = string
  default     = "letsencrypt-prod"
}

variable "backup_schedule" {
  description = "Cron des backups CrateDB/Qdrant/Redis vers le stockage objet. Vide = désactivé."
  type        = string
  default     = "0 3 * * *"
}

variable "storage_class" {
  description = "StorageClass pour les volumes persistants (CrateDB/Qdrant/Redis). Vide = défaut du cluster."
  type        = string
  default     = ""
}

variable "extra_env" {
  description = "Variables d'environnement supplémentaires injectées dans l'API."
  type        = map(string)
  default     = {}
}

# Dérive les bornes de scaling par tier si non fournies explicitement.
locals {
  tier_scaling = {
    free = { min = 1, max = 2 }
    saas = { min = 2, max = 6 }
    baas = { min = 2, max = 10 }
    paas = { min = 3, max = 20 }
  }
  api_min = coalesce(var.api_replicas_min, local.tier_scaling[var.tier].min)
  api_max = coalesce(var.api_replicas_max, local.tier_scaling[var.tier].max)
}
