output "namespace" {
  description = "Namespace Kubernetes où AISIA est déployé."
  value       = local.ns
}

output "api_service" {
  description = "Nom du Service ClusterIP de l'API AISIA."
  value       = kubernetes_service.api.metadata[0].name
}

output "api_endpoint_internal" {
  description = "Endpoint interne cluster de l'API."
  value       = "http://${kubernetes_service.api.metadata[0].name}.${local.ns}.svc.cluster.local"
}

output "public_url" {
  description = "URL publique (si domain fourni)."
  value       = var.domain != "" ? "https://${var.domain}" : null
}

output "autoscaling" {
  description = "Bornes de scaling effectives (min/max) appliquées."
  value       = { enabled = var.enable_autoscaling, min = local.api_min, max = local.api_max, cpu_target = var.api_cpu_target }
}

output "tier" {
  description = "Tier d'exploitation appliqué."
  value       = var.tier
}
