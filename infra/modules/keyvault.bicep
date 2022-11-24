@description('Name of the KeyVault')
param name string

@description('Name of the Log Analytics Workspace')
param logAnalyticsWorkspaceId string = ''

@description('Access Policies in the keyVault')
param accessPolicies array

@allowed([
  'standard'
  'premium'
])
param sku string = 'standard'
param retentionInDays int = 90
param tags object = {}
param location string = resourceGroup().location
param enableMonitoring bool = false

resource keyvault 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: sku
    }
    tenantId: subscription().tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enabledForDiskEncryption: false
    enableSoftDelete: true
    enablePurgeProtection: true
    softDeleteRetentionInDays: retentionInDays
    accessPolicies: accessPolicies
  }
}

resource diagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = if (enableMonitoring) {
  name: 'Monitoring'
  scope: keyvault
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'AuditEvent'
        enabled: true
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
      }
    ]
  }
}

output keyvaultName string = keyvault.name
output keyvaultId string = keyvault.id
output keyvaultUri string = keyvault.properties.vaultUri
