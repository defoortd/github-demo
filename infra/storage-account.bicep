param tags object = {}
param storageAccountName string
param location string = resourceGroup().location

@allowed([
    'Standard_LRS'
    'Standard_GRS'
    'Standard_RAGRS'
    'Standard_ZRS'
    'Premium_LRS'
    'Premium_ZRS'
    'Standard_GZRS'
    'Standard_RAGZRS'
])
@description('Pricing Tier')
param skuName string = 'Standard_LRS'

param keyvaultName string
param connectionstringSecretName string

param enableMonitoring bool = false
param loganalyticsWorkspaceId string = ''

param enableprivateendpoint bool = true
param subnetId string = ''
param privateDnsZoneId string = ''

param networkAcls object
@allowed([
    'Enabled'
    'Disabled'
])
param publicNetworkAccess string = 'Disabled'
param allowBlobPublicAccess bool = false
param allowSharedKeyAccess bool = false

param userAssignedIdentityResourceId string = ''

var systemAssigned = {
    type: 'SystemAssigned'
}
var userAssigned = {
    type: 'UserAssigned'
    userAssignedIdentities: {
        '${userAssignedIdentityResourceId}': {}
    }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-06-01' = {
    name: storageAccountName
    location: location
    sku: {
        name: skuName
    }
    identity: userAssignedIdentityResourceId == '' ? systemAssigned : userAssigned
    kind: 'StorageV2'
    tags: tags
    properties: {
        encryption: {
            services: {
                blob: {
                    enabled: true
                }
                file: {
                    enabled: true
                }
            }
            keySource: 'Microsoft.Storage'
        }
        supportsHttpsTrafficOnly: true
        minimumTlsVersion: 'TLS1_2'
        publicNetworkAccess: publicNetworkAccess
        allowBlobPublicAccess: allowBlobPublicAccess
        allowSharedKeyAccess: allowSharedKeyAccess
        accessTier: 'Hot'
        networkAcls: networkAcls
    }
}

resource blobServices 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
    name: 'default'
    parent: storageAccount
    properties: {
        deleteRetentionPolicy: {
            enabled: true
            days: 180
        }
        isVersioningEnabled: true
        changeFeed: {
            enabled: true
        }
        restorePolicy: {
            enabled: true
            days: 179
        }
        containerDeleteRetentionPolicy: {
            enabled: true
            days: 180
        }
        automaticSnapshotPolicyEnabled: true
    }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = if (enableprivateendpoint) {
    name: '${storageAccountName}-pe'
    location: location
    tags: tags
    properties: {
        subnet: {
            id: subnetId
        }
        privateLinkServiceConnections: [
            {
                name: '${storageAccountName}-pe'
                properties: {
                    privateLinkServiceId: storageAccount.id
                    groupIds: [
                        'blob'
                    ]
                }
            }
        ]
    }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = if (enableprivateendpoint) {
    name: 'default'
    parent: privateEndpoint
    properties: {
        privateDnsZoneConfigs: [
            {
                name: 'privatelink.blob.${environment().suffixes.storage}'
                properties: {
                    privateDnsZoneId: privateDnsZoneId
                }
            }
        ]
    }
}

resource saDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableMonitoring) {
    name: 'DLW-AzureMonitoring'
    scope: storageAccount
    properties: {
        workspaceId: loganalyticsWorkspaceId
        metrics: [
            {
                category: 'Transaction'
                enabled: true
            }
        ]
    }
}

resource blobDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableMonitoring) {
    name: 'DLW-AzureMonitoring'
    scope: blobServices
    properties: {
        workspaceId: loganalyticsWorkspaceId
        logs: [
            {
                category: 'StorageRead'
                enabled: true
            }
            {
                category: 'StorageWrite'
                enabled: true
            }
            {
                category: 'StorageDelete'
                enabled: true
            }
        ]
        metrics: [
            {
                category: 'Transaction'
                enabled: true
            }
        ]
    }
}

resource tableServices 'Microsoft.Storage/storageAccounts/tableServices@2021-06-01' = if (enableMonitoring) {
    name: 'default'
    parent: storageAccount
}

resource tableDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableMonitoring) {
    name: 'DLW-AzureMonitoring'
    scope: tableServices
    properties: {
        workspaceId: loganalyticsWorkspaceId
        logs: [
            {
                category: 'StorageRead'
                enabled: true
            }
            {
                category: 'StorageWrite'
                enabled: true
            }
            {
                category: 'StorageDelete'
                enabled: true
            }
        ]
        metrics: [
            {
                category: 'Transaction'
                enabled: true
            }
        ]
    }
}

resource fileServices 'Microsoft.Storage/storageAccounts/fileServices@2021-06-01' = if (enableMonitoring) {
    name: 'default'
    parent: storageAccount
}

resource fileDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableMonitoring) {
    name: 'DLW-AzureMonitoring'
    scope: fileServices
    properties: {
        workspaceId: loganalyticsWorkspaceId
        logs: [
            {
                category: 'StorageRead'
                enabled: true
            }
            {
                category: 'StorageWrite'
                enabled: true
            }
            {
                category: 'StorageDelete'
                enabled: true
            }
        ]
        metrics: [
            {
                category: 'Transaction'
                enabled: true
            }
        ]
    }
}

resource queueServices 'Microsoft.Storage/storageAccounts/queueServices@2021-06-01' = if (enableMonitoring) {
    name: 'default'
    parent: storageAccount
}

resource queueDiag 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableMonitoring) {
    name: 'DLW-AzureMonitoring'
    scope: queueServices
    properties: {
        workspaceId: loganalyticsWorkspaceId
        logs: [
            {
                category: 'StorageRead'
                enabled: true
            }
            {
                category: 'StorageWrite'
                enabled: true
            }
            {
                category: 'StorageDelete'
                enabled: true
            }
        ]
        metrics: [
            {
                category: 'Transaction'
                enabled: true
            }
        ]
    }
}

resource connectionstring 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
    name: '${keyvaultName}/${connectionstringSecretName}'
    properties: {
        value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${storageAccount.listKeys(storageAccount.apiVersion).Keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
    }
}

output name string = storageAccount.name
output id string = storageAccount.id
