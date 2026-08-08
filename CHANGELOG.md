# Changelog — terraform-aisia-cluster

Format : [Keep a Changelog](https://keepachangelog.com/) · Versioning : SemVer.

## [Unreleased] — correction pré-publication (2026-08-05)

### Fixed
- `VERSION` rétabli à `6.12.80` (dernière version AISIA **certifiée LIVE**, DEPLOY-REPORT
  all-green — `project_facts.json:prod_live_version`) ; gate `run_terraform_modules_gate`
  de nouveau vert. `image_tag` n'a pas de `default` sur ce module (variable requise
  explicite, pas de valeur implicite risquée) — la description avait déjà été corrigée
  vers « ex. v6.12.80 » par le commit `8d818d7826e` (après une dérive vers « ex. v6.12.81 »
  introduite par `5a5ab47fa`). Voir les CHANGELOG des modules per-cloud pour le défaut
  fonctionnel plus grave (`image_tag` default = v6.12.81) corrigé dans cette même session.
  ⚠️ **registry.terraform.io a déjà ingéré une version `6.12.81` immuable** — cette
  correction locale ne la retire pas ; à republier dans une future version.

## [6.12.80] — 2026-08-05

### Changed
- Entrée rétroactive : VERSION module -> `6.12.80` (release AISIA v6.12.80 LIVE,
  DEPLOY-REPORT all-green). Aucun changement fonctionnel.

## [6.12.79] — 2026-08-04

### Changed
- Entrée rétroactive : VERSION module -> `6.12.79`. Aucun changement fonctionnel.

## [6.12.78] — 2026-08-04

### Changed
- Sync `image_tag` default -> `v6.12.78` (release AISIA v6.12.78 LIVE). Rattrape aussi le
  saut `v6.12.77` (VERSION + image_tag bumpés en v6.12.77 par le commit `ad31e4ac8` sans
  entrée CHANGELOG, jamais publié au registry). Aucun changement fonctionnel des
  resources/variables/outputs (patch de synchronisation de version).

## [6.12.76] — 2026-08-02

### Changed
- Sync `image_tag` default -> `v6.12.76` (release AISIA v6.12.76 LIVE). Aucun changement
  fonctionnel des resources/variables/outputs (patch de synchronisation de version).

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
