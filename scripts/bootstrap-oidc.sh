#!/usr/bin/env bash
# Connecte GitHub Actions à Azure SANS secret (identité fédérée / OIDC).
# Usage : ./scripts/bootstrap-oidc.sh <owner/repo> <resource-group> [location]
set -euo pipefail
REPO="${1:?Usage: $0 <owner/repo> <resource-group> [location]}"
RG="${2:?resource group manquant}"
LOC="${3:-canadacentral}"

SUB_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

if [ "$(az group exists -n "$RG")" = "false" ]; then
  az group create -n "$RG" -l "$LOC" --tags project=beacon env=dev managedBy=bicep >/dev/null
fi
APP_ID=$(az ad app create --display-name "gh-${RG}" --query appId -o tsv)
az ad sp create --id "$APP_ID" >/dev/null
SP_OBJ_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv)

# Un identifiant fédéré par "contexte" GitHub. Si un job utilise "environment: dev",
# le sujet est environment:dev (et NON ref:refs/heads/main) : c'est l'erreur n°1.
for SUBJECT in "ref:refs/heads/main" "environment:dev" "environment:prod" "pull_request"; do
  NAME="gh-$(echo "$SUBJECT" | tr ':/' '--')"
  az ad app federated-credential create --id "$APP_ID" --parameters "{
    \"name\": \"$NAME\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:${REPO}:${SUBJECT}\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }" >/dev/null
done

SCOPE="/subscriptions/${SUB_ID}/resourceGroups/${RG}"
# Contributor pour déployer ; User Access Administrator parce que le Bicep crée des attributions de rôles.
# (À resserrer plus tard : voir l'ADR "moindre privilège".)
for ROLE in "Contributor" "User Access Administrator"; do
  az role assignment create --assignee-object-id "$SP_OBJ_ID" --assignee-principal-type ServicePrincipal \
    --role "$ROLE" --scope "$SCOPE" >/dev/null
done

echo
echo "Ajoute ces SECRETS dans GitHub (Settings > Secrets and variables > Actions) :"
echo "  AZURE_CLIENT_ID=$APP_ID"
echo "  AZURE_TENANT_ID=$TENANT_ID"
echo "  AZURE_SUBSCRIPTION_ID=$SUB_ID"
echo "Et la variable : RESOURCE_GROUP=$RG"
