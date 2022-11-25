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

param keyVaultName string
param keyVaultResourceGroup string = resourceGroup().name
param connectionstringSecretName string

param enableMonitoring bool = false
param loganalyticsWorkspaceId string = ''

param enableprivateendpoint bool = false
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

resource key_vault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
    name: keyVaultName
    scope: resourceGroup(keyVaultResourceGroup)
}

resource storage_account 'Microsoft.Storage/storageAccounts@2021-06-01' = {
    name: storageAccountName
    location: location
    sku: {
        name: skuName
    }
    identity: userAssignedIdentityResourceId == '' ? {
        type: 'SystemAssigned'
    } : {
        type: 'UserAssigned'
        userAssignedIdentities: {
            '${userAssignedIdentityResourceId}': {}
        }
    }
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

resource storage_account_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableMonitoring) {
    name: 'diagnostics'
    scope: storage_account
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

resource private_endpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = if (enableprivateendpoint) {
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
                    privateLinkServiceId: storage_account.id
                    groupIds: [
                        'blob'
                    ]
                }
            }
        ]
    }
}

resource private_dns_zone_group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = if (enableprivateendpoint) {
    name: 'default'
    parent: private_endpoint
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

resource blob_services 'Microsoft.Storage/storageAccounts/blobServices@2021-06-01' = {
    name: 'default'
    parent: storage_account
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

resource blob_services_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableMonitoring) {
    name: 'diagnostics'
    scope: blob_services
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

resource table_services 'Microsoft.Storage/storageAccounts/tableServices@2021-06-01' = if (enableMonitoring) {
    name: 'default'
    parent: storage_account
}

resource table_services_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableMonitoring) {
    name: 'diagnostics'
    scope: table_services
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

resource file_services 'Microsoft.Storage/storageAccounts/fileServices@2021-06-01' = if (enableMonitoring) {
    name: 'default'
    parent: storage_account
}

resource file_services_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableMonitoring) {
    name: 'diagnostics'
    scope: file_services
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

resource queue_services 'Microsoft.Storage/storageAccounts/queueServices@2021-06-01' = if (enableMonitoring) {
    name: 'default'
    parent: storage_account
}

resource queue_services_diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableMonitoring) {
    name: 'DLW-AzureMonitoring'
    scope: queue_services
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

resource connectionstring_secret 'Microsoft.KeyVault/vaults/secrets@2021-10-01' = {
    name: '${key_vault.name}/${connectionstringSecretName}'
    properties: {
        value: 'DefaultEndpointsProtocol=https;AccountName=${storage_account.name};AccountKey=${storage_account.listKeys(storage_account.apiVersion).Keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
    }
}

output name string = storage_account.name
output id string = storage_account.id
