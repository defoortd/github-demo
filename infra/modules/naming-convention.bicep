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
