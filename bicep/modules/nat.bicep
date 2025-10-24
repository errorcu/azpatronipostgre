@description('Location for the resource')
param location string

@description('NAT Gateway name')
param natGatewayName string

@description('VNet name')
param vnetName string

@description('Subnet name')
param subnetName string

// Create Public IP for NAT Gateway
resource natPublicIP 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: '${natGatewayName}-pip'
  location: location
  sku: {
    name: 'Standard'
  }
  zones: ['1', '2', '3']
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Create NAT Gateway
resource natGateway 'Microsoft.Network/natGateways@2023-11-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  zones: ['1', '2', '3']
  properties: {
    publicIPAddresses: [
      {
        id: natPublicIP.id
      }
    ]
    idleTimeoutInMinutes: 10
  }
}

// Get existing VNet
resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: vnetName
}

// Update subnet to use NAT Gateway
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: subnetName
  parent: vnet
  properties: {
    addressPrefix: vnet.properties.subnets[0].properties.addressPrefix
    natGateway: {
      id: natGateway.id
    }
  }
}

output natGatewayId string = natGateway.id
output natPublicIP string = natPublicIP.properties.ipAddress
