# Beacon — kit de démarrage

Ce kit accompagne le **Guide d'exécution T4 2026**. Il contient des solutions de **référence** : essaie d'abord d'écrire toi-même
(c'est comme ça qu'on apprend), puis compare. Tout a été validé : les gabarits Bicep compilent avec le CLI officiel (`az bicep build`)
et les workflows sont du YAML valide. Les workflows et le Bicep n'ont toutefois pas été exécutés contre ton abonnement : attends-toi à
ajuster des noms et des versions.

## Quand utiliser quoi
| Semaine | Fichier | Usage |
|---|---|---|
| S0-S2 | `scripts/bootstrap-oidc.sh` | Connecter GitHub Actions à Azure sans secret |
| S2 | `.github/workflows/deploy-appservice.yml` | Pipeline de la phase 1 (App Service) |
| S1+ | `.github/workflows/ci.yml` | Build + tests sur chaque PR |
| S6 | `infra/` | Référence pour ton Bicep (compare avec ton export décompilé) |
| S7 | `Dockerfile`, `.github/workflows/deploy.yml` | Container Apps : infra + image + application |
| S8 | `infra/modules/alerts.bicep` | Alertes qui appellent Beacon (`/api/alerts`) |
| Chaque séance de lab | `scripts/cleanup-lab.sh` | Supprimer les ressources de lab (coûts) |
| Dès S1 | `docs/adr`, `docs/postmortems`, `docs/runbooks` | Documentation : en anglais, c'est ton portfolio |
| Chaque semaine | `tracking/*.csv` | Journal d'étude et journal LeetCode |

## Structure attendue du dépôt `beacon`
```
src/Beacon.Api/            # ton API ASP.NET Core (tu l'écris)
tests/Beacon.Api.Tests/    # xUnit
infra/                     # Bicep (ce kit)
.github/workflows/         # pipelines (ce kit)
docs/                      # ADR, runbooks, postmortems, diagrammes
```

## Conventions
- Noms : `<type>-beacon-<env>` (ex. `vnet-beacon-dev`). Région : `canadacentral`.
- Tags obligatoires : `project=beacon`, `env=dev|prod`, `managedBy=bicep|manual`.
- Aucun secret dans Git. Jamais. (Les 3 valeurs OIDC ne sont pas des secrets sensibles, mais mets-les dans les "secrets" GitHub.)
- Dépôt **public** : c'est ton portfolio, et les règles d'approbation d'environnement GitHub y sont gratuites.
- Écris README, ADR et runbooks **en anglais** : c'est la langue du marché que tu vises.

## Avertissements
- La base SQL utilise l'offre gratuite d'Azure SQL si ton abonnement y est éligible ; sinon passe `useFreeOffer = false` et surveille le coût.
- Après suppression d'un groupe de ressources contenant un Key Vault, **purge** le coffre avant de redéployer (voir `cleanup-lab.sh`).
