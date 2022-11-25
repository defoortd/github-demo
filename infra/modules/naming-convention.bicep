/*
Naming convention according to the Microsoft Cloud Adoption Framework recommendation:
https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-naming
*/

@allowed([
  'dev'
  'tst'
  'prd'
])
param environmentName string
param projectName string
@allowed([
  'weu'
  'neu'
])
param regionShortName string

var naming = toLower('${projectName}-${environmentName}-${regionShortName}')

output key_vault string = 'kv-${naming}'
output storage_account string = replace('sa-${naming}', '-', '')
