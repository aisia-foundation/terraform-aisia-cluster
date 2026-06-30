# Changelog — terraform-aisia-cluster

Format : [Keep a Changelog](https://keepachangelog.com/) · Versioning : SemVer.

## [1.0.1] — 2026-06-29

### Changed
- Mise à jour de l'exemple `image_tag` vers `v6.9.60` (AISIA v6.9.60).
- Correction de la description de la variable `image_tag` (exemple `v6.9.30` → `v6.9.60`).
- Ajout de `versions.tf` aux modules cloud bootstrap (azure/ovh/scaleway) — conformité registry.
- Correction des noms de variables dans les README cloud (aisia_image_tag → image_tag,
  worker_count → node_count, manager/worker_vm_size → instance_flavor).

## [1.0.0] — 2026-06-24

### Added
- Module initial publiable (Terraform Registry) : déploiement de la stack AISIA
  sur un cluster Kubernetes existant, cloud-agnostique.
- **Déploiement** : Deployment + Service API AISIA (image `${registry}/aisia:${tag}`),
  probes readiness/liveness `/healthz`, ressources requests/limits.
- **Scalabilité** : HPA v2 (CPU target) avec bornes min/max dérivées du `tier`
  (free/saas/baas/paas), surchargeables.
- **Maintien opérationnel** : Ingress + TLS automatique via cert-manager,
  CronJob de backup planifié.
- Variables tier-aware, `extra_env`, `storage_class`, exemple `examples/basic`.
- README (Inputs/Outputs/Usage), LICENSE MPL-2.0, versions.tf (TF >=1.5, k8s/helm).
