###############################################################################
# terraform-aisia-cluster — déploiement de la stack AISIA sur K8s existant.
# Cloud-agnostique : fonctionne sur EKS/AKS/GKE/Kapsule/OVH Managed K8s/etc.
###############################################################################

resource "kubernetes_namespace" "aisia" {
  count = var.create_namespace ? 1 : 0
  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/part-of" = "aisia"
      "aisia.fr/tier"             = var.tier
    }
  }
}

locals {
  ns = var.create_namespace ? kubernetes_namespace.aisia[0].metadata[0].name : var.namespace
  common_labels = {
    "app.kubernetes.io/part-of"    = "aisia"
    "app.kubernetes.io/managed-by" = "terraform"
  }
}

###############################################################################
# API AISIA — Deployment + Service (le bot/agent/backends suivent le même motif,
# voir modules/ ; ce module cœur expose l'API qui orchestre le reste).
###############################################################################
resource "kubernetes_deployment" "api" {
  metadata {
    name      = "aisia-api"
    namespace = local.ns
    labels    = merge(local.common_labels, { "app.kubernetes.io/name" = "aisia-api" })
  }
  spec {
    # replicas initial = borne basse ; le HPA prend le relais si activé.
    replicas = local.api_min
    selector {
      match_labels = { "app.kubernetes.io/name" = "aisia-api" }
    }
    template {
      metadata {
        labels = merge(local.common_labels, { "app.kubernetes.io/name" = "aisia-api" })
      }
      spec {
        container {
          name  = "api"
          image = "${var.image_registry}/aisia:${var.image_tag}"
          port {
            container_port = 8000
          }
          dynamic "env" {
            for_each = var.extra_env
            content {
              name  = env.key
              value = env.value
            }
          }
          env {
            name  = "AISIA_TIER"
            value = var.tier
          }
          readiness_probe {
            http_get {
              path = "/healthz"
              port = 8000
            }
            initial_delay_seconds = 10
            period_seconds        = 10
          }
          liveness_probe {
            http_get {
              path = "/healthz"
              port = 8000
            }
            initial_delay_seconds = 30
            period_seconds        = 20
          }
          resources {
            requests = { cpu = "250m", memory = "512Mi" }
            limits   = { cpu = "1000m", memory = "1Gi" }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "api" {
  metadata {
    name      = "aisia-api"
    namespace = local.ns
    labels    = local.common_labels
  }
  spec {
    selector = { "app.kubernetes.io/name" = "aisia-api" }
    port {
      port        = 80
      target_port = 8000
    }
    type = "ClusterIP"
  }
}

###############################################################################
# Scalabilité — HPA (Horizontal Pod Autoscaler v2) sur l'API.
###############################################################################
resource "kubernetes_horizontal_pod_autoscaler_v2" "api" {
  count = var.enable_autoscaling ? 1 : 0
  metadata {
    name      = "aisia-api"
    namespace = local.ns
  }
  spec {
    scale_target_ref {
      api_version = "apps/v1"
      kind        = "Deployment"
      name        = kubernetes_deployment.api.metadata[0].name
    }
    min_replicas = local.api_min
    max_replicas = local.api_max
    metric {
      type = "Resource"
      resource {
        name = "cpu"
        target {
          type                = "Utilization"
          average_utilization = var.api_cpu_target
        }
      }
    }
  }
}

###############################################################################
# Ingress + TLS (cert-manager) — exposition publique optionnelle.
###############################################################################
resource "kubernetes_ingress_v1" "api" {
  count = var.domain != "" ? 1 : 0
  metadata {
    name      = "aisia"
    namespace = local.ns
    annotations = merge(
      var.enable_tls ? { "cert-manager.io/cluster-issuer" = var.cluster_issuer } : {},
      { "kubernetes.io/ingress.class" = "nginx" }
    )
  }
  spec {
    rule {
      host = var.domain
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service.api.metadata[0].name
              port { number = 80 }
            }
          }
        }
      }
    }
    dynamic "tls" {
      for_each = var.enable_tls ? [1] : []
      content {
        hosts       = [var.domain]
        secret_name = "aisia-tls"
      }
    }
  }
}

###############################################################################
# Maintien opérationnel — backups planifiés (CronJob) vers stockage objet.
###############################################################################
resource "kubernetes_cron_job_v1" "backup" {
  count = var.backup_schedule != "" ? 1 : 0
  metadata {
    name      = "aisia-backup"
    namespace = local.ns
  }
  spec {
    schedule                      = var.backup_schedule
    concurrency_policy            = "Forbid"
    successful_jobs_history_limit = 3
    failed_jobs_history_limit     = 3
    job_template {
      metadata {
        labels = local.common_labels
      }
      spec {
        template {
          metadata {
            labels = local.common_labels
          }
          spec {
            container {
              name    = "backup"
              image   = "${var.image_registry}/aisia:${var.image_tag}"
              command = ["python3", "scripts/cratedb_logical_backup.py"]
            }
            restart_policy = "OnFailure"
          }
        }
      }
    }
  }
}
