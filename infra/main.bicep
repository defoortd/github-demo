@allowed([
  'dev'
  'tst'
  'prd'
])
param environmentName string
param location string = resourceGroup().location

var projectName = 'defoortd'
var tags = {
  environment: environmentName
  project: projectName
  owner: 'defoortd'
}

module naming_convention 'modules/naming-convention.bicep' = {
  name: 'Naming_Convention'
  params: {
    environmentName: environmentName
    projectName: projectName
    regionShortName: 'weu'
  }
}

module key_vault 'modules/keyvault.bicep' = {
  name: '${projectName}-KeyVault'
  params: {
    accessPolicies: []
    location: location
    name: '${naming_convention.outputs.key_vault}-001'
    enableMonitoring: false
    sku: 'standard'
    tags: tags
  }
}

module storage_account 'modules/storage-account.bicep' = {
  name: '${projectName}-StorageAccount'
  params: {
    connectionstringSecretName: '${naming_convention.outputs.storage_account}001-connectionstring'
    keyVaultName: key_vault.outputs.keyvaultName
    location: location
    tags: tags
    networkAcls: {
    }
    storageAccountName: '${naming_convention.outputs.storage_account}001'
  }
}
