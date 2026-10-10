// Key Vault (RBAC) + secret du webhook d'alertes + droit de lecture pour l'identité de l'application
param location string
param namePrefix string
param tags object = {}
param readerPrincipalId string
param readerIdentityId string
@secure()
param alertWebhookKey string

var kvSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: take('kv-${namePrefix}-${uniqueString(resourceGroup().id)}', 24)
  location: location
  tags: tags
  properties: {
    tenantId: tenant().tenantId
    sku: { family: 'A', name: 'standard' }
    enableRbacAuthorization: true
    softDeleteRetentionInDays: 7
  }
}

resource alertKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: kv
  name: 'alert-webhook-key'
  properties: { value: alertWebhookKey }
}

resource read 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(kv.id, readerIdentityId, kvSecretsUserRoleId)
  scope: kv
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', kvSecretsUserRoleId)
    principalId: readerPrincipalId
    principalType: 'ServicePrincipal'
  }
}

output vaultName string = kv.name
output alertKeySecretUri string = alertKey.properties.secretUri
