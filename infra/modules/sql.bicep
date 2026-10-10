// Azure SQL : serveur (auth Entra seulement) + base serverless (offre gratuite si disponible)
param location string
param namePrefix string
param tags object = {}
param entraAdminLogin string
param entraAdminObjectId string
@allowed(['User', 'Group'])
param entraAdminType string = 'User'
param databaseName string = 'beacon'
param useFreeOffer bool = true
@description('Passer à Disabled une fois le private endpoint validé (semaine 5).')
@allowed(['Enabled', 'Disabled'])
param publicNetworkAccess string = 'Enabled'

resource server 'Microsoft.Sql/servers@2023-08-01' = {
  name: 'sql-${namePrefix}-${uniqueString(resourceGroup().id)}'
  location: location
  tags: tags
  properties: {
    minimalTlsVersion: '1.2'
    publicNetworkAccess: publicNetworkAccess
    administrators: {
      administratorType: 'ActiveDirectory'
      principalType: entraAdminType
      login: entraAdminLogin
      sid: entraAdminObjectId
      tenantId: tenant().tenantId
      azureADOnlyAuthentication: true
    }
  }
}

resource db 'Microsoft.Sql/servers/databases@2023-08-01' = {
  parent: server
  name: databaseName
  location: location
  tags: tags
  sku: {
    name: 'GP_S_Gen5'
    tier: 'GeneralPurpose'
    family: 'Gen5'
    capacity: 1
  }
  properties: {
    autoPauseDelay: 60
    minCapacity: json('0.5')
    useFreeLimit: useFreeOffer
    freeLimitExhaustionBehavior: 'AutoPause'
    maxSizeBytes: 34359738368
    requestedBackupStorageRedundancy: 'Local'
  }
}

output serverId string = server.id
output serverName string = server.name
output fqdn string = server.properties.fullyQualifiedDomainName
output databaseName string = db.name
output databaseId string = db.id
