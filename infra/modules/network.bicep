// VNet + sous-réseaux + NSG + private endpoint SQL + zone DNS privée
param location string
param namePrefix string
param tags object = {}
param sqlServerId string
param vnetAddressPrefix string = '10.20.0.0/16'
param acaSubnetPrefix string = '10.20.0.0/23'
param peSubnetPrefix string = '10.20.2.0/27'
param testSubnetPrefix string = '10.20.3.0/28'

resource nsgPe 'Microsoft.Network/networkSecurityGroups@2023-11-01' = {
  name: 'nsg-${namePrefix}-pe'
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: 'vnet-${namePrefix}'
  location: location
  tags: tags
  properties: {
    addressSpace: { addressPrefixes: [vnetAddressPrefix] }
    subnets: [
      {
        name: 'snet-aca'
        properties: {
          addressPrefix: acaSubnetPrefix
          delegations: [
            {
              name: 'aca'
              properties: { serviceName: 'Microsoft.App/environments' }
            }
          ]
        }
      }
      {
        name: 'snet-pe'
        properties: {
          addressPrefix: peSubnetPrefix
          networkSecurityGroup: { id: nsgPe.id }
        }
      }
      {
        name: 'snet-test'
        properties: { addressPrefix: testSubnetPrefix }
      }
    ]
  }
}

resource dnsZoneSql 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink${environment().suffixes.sqlServerHostname}'
  location: 'global'
  tags: tags
}

resource dnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: dnsZoneSql
  name: 'link-${vnet.name}'
  location: 'global'
  tags: tags
  properties: {
    registrationEnabled: false
    virtualNetwork: { id: vnet.id }
  }
}

resource peSql 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: 'pe-${namePrefix}-sql'
  location: location
  tags: tags
  properties: {
    subnet: { id: '${vnet.id}/subnets/snet-pe' }
    privateLinkServiceConnections: [
      {
        name: 'sql'
        properties: {
          privateLinkServiceId: sqlServerId
          groupIds: ['sqlServer']
        }
      }
    ]
  }
}

resource peSqlDns 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: peSql
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'sql'
        properties: { privateDnsZoneId: dnsZoneSql.id }
      }
    ]
  }
}

output vnetId string = vnet.id
output acaSubnetId string = '${vnet.id}/subnets/snet-aca'
