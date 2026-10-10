// Beacon : infrastructure complète (état cible à la fin de la phase 2)
targetScope = 'resourceGroup'

@allowed(['dev', 'prod'])
param env string = 'dev'
param location string = resourceGroup().location
param workload string = 'beacon'
param entraAdminLogin string
param entraAdminObjectId string
@allowed(['User', 'Group'])
param entraAdminType string = 'User'
@secure()
param alertWebhookKey string
@description('Vide = on déploie l\'infrastructure sans l\'application (premier passage). Sinon : image complète dans ACR.')
param containerImage string = ''
@allowed(['Enabled', 'Disabled'])
param sqlPublicNetworkAccess string = 'Enabled'

var namePrefix = '${workload}-${env}'
var tags = {
  project: workload
  env: env
  managedBy: 'bicep'
}
var deployApp = !empty(containerImage)

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    location: location
    namePrefix: namePrefix
    tags: tags
  }
}

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${namePrefix}'
  location: location
  tags: tags
}

module sql 'modules/sql.bicep' = {
  name: 'sql'
  params: {
    location: location
    namePrefix: namePrefix
    tags: tags
    entraAdminLogin: entraAdminLogin
    entraAdminObjectId: entraAdminObjectId
    entraAdminType: entraAdminType
    publicNetworkAccess: sqlPublicNetworkAccess
  }
}

module network 'modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    namePrefix: namePrefix
    tags: tags
    sqlServerId: sql.outputs.serverId
  }
}

module acr 'modules/acr.bicep' = {
  name: 'acr'
  params: {
    location: location
    namePrefix: namePrefix
    tags: tags
    pullerPrincipalId: identity.properties.principalId
    pullerIdentityId: identity.id
  }
}

module keyvault 'modules/keyvault.bicep' = {
  name: 'keyvault'
  params: {
    location: location
    namePrefix: namePrefix
    tags: tags
    readerPrincipalId: identity.properties.principalId
    readerIdentityId: identity.id
    alertWebhookKey: alertWebhookKey
  }
}

module app 'modules/containerapp.bicep' = if (deployApp) {
  name: 'containerapp'
  params: {
    location: location
    namePrefix: namePrefix
    tags: tags
    infrastructureSubnetId: network.outputs.acaSubnetId
    logAnalyticsWorkspaceName: monitoring.outputs.workspaceName
    acrLoginServer: acr.outputs.loginServer
    identityId: identity.id
    identityClientId: identity.properties.clientId
    image: containerImage
    sqlConnectionString: 'Server=tcp:${sql.outputs.fqdn},1433;Database=${sql.outputs.databaseName};Authentication=Active Directory Managed Identity;User Id=${identity.properties.clientId};Encrypt=True;'
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    alertKeySecretUri: keyvault.outputs.alertKeySecretUri
  }
}

module alerts 'modules/alerts.bicep' = if (deployApp) {
  name: 'alerts'
  params: {
    location: location
    namePrefix: namePrefix
    tags: tags
    appInsightsId: monitoring.outputs.appInsightsId
    sqlDatabaseId: sql.outputs.databaseId
    webhookUrl: 'https://${app!.outputs.fqdn}/api/alerts?key=${alertWebhookKey}'
  }
}

output acrLoginServer string = acr.outputs.loginServer
output sqlServerFqdn string = sql.outputs.fqdn
output identityName string = identity.name
output identityClientId string = identity.properties.clientId
output appFqdn string = deployApp ? app!.outputs.fqdn : ''
