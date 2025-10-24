@description('Location for the resource')
param location string

@description('NAT Gateway name')
param natGatewayName string

@description('Public IP name for NAT Gateway')
param natPublicIPName string

resource natPublicIP 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: natPublicIPName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource natGateway 'Microsoft.Network/natGateways@2023-11-01' = {
  name: natGatewayName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIpAddresses: [
      {
        id: natPublicIP.id
      }
    ]
    idleTimeoutInMinutes: 10
  }
}

output natGatewayId string = natGateway.id
output natPublicIP string = natPublicIP.properties.ipAddress
