#!/usr/bin/env bash
# Supprime tous les groupes de ressources de labs (préfixe rg-lab-) et purge les Key Vault supprimés.
# À lancer à la FIN de chaque séance de lab : c'est ce qui évite les mauvaises surprises sur la facture.
set -euo pipefail
echo "Groupes existants :"; az group list --query "[].{nom:name, region:location}" -o table
for RG in $(az group list --query "[?starts_with(name,'rg-lab-')].name" -o tsv); do
  echo "Suppression de $RG ..."; az group delete -n "$RG" --yes --no-wait
done
echo "Si tu as supprimé un groupe contenant un Key Vault, purge-le avant de redéployer le même nom :"
echo "  az keyvault list-deleted --query \"[].name\" -o tsv"
echo "  az keyvault purge --name <nom>"
