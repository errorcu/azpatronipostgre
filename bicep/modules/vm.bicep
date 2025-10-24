@description('Location for the resource')
param location string

@description('VM names array')
param vmNames array

@description('VM IPs array')
param vmIps array

@description('Availability zones')
param zones array

@description('VM size')
param vmSize string

@description('Data disk size in GB')
param dataDiskSizeGB int

@description('WAL disk size in GB')
param walDiskSizeGB int

@description('Admin username')
param adminUsername string

@description('Admin password')
@secure()
param adminPassword string

@description('Disk SKU')
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'StandardSSD_LRS'
  'StandardSSD_ZRS'
  'UltraSSD_LRS'
])
param diskSku string = 'Premium_LRS'

@description('VNet name')
param vnetName string

@description('Subnet name')
param subnetName string

@description('NSG name')
param nsgName string

@description('Load balancer name')
param ilbName string

@description('Backend pool name')
param bePoolName string

@description('PostgreSQL password')
@secure()
param postgresPassword string

@description('Replicator password')
@secure()
param replicatorPassword string

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' existing = {
  name: subnetName
  parent: vnet
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-11-01' existing = {
  name: nsgName
}

resource lb 'Microsoft.Network/loadBalancers@2023-11-01' existing = {
  name: ilbName
}

resource backendPool 'Microsoft.Network/loadBalancers/backendAddressPools@2023-11-01' existing = {
  name: bePoolName
  parent: lb
}

resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = [for (vmName, i) in vmNames: {
  name: '${vmName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: vmIps[i]
          loadBalancerBackendAddressPools: [
            {
              id: backendPool.id
            }
          ]
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}]

resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = [for (vmName, i) in vmNames: {
  name: vmName
  location: location
  zones: [zones[i]]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
      customData: base64(loadTextContent('cloudinit/cloud-init.yaml'))
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-jammy'
        sku: '22_04-lts'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      dataDisks: dataDiskSizeGB > 0 ? [
        {
          lun: 0
          createOption: 'Empty'
          diskSizeGB: dataDiskSizeGB
          managedDisk: {
            storageAccountType: diskSku
          }
        }
        {
          lun: 1
          createOption: 'Empty'
          diskSizeGB: walDiskSizeGB
          managedDisk: {
            storageAccountType: diskSku
          }
        }
      ] : []
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic[i].id
        }
      ]
    }
  }
  dependsOn: [
    nic
  ]
}]

output vmIds array = [for (vmName, i) in vmNames: vm[i].id]