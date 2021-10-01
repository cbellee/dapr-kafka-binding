param name string
param sku object
param tags object
param accessPolicies array

resource kv 'Microsoft.KeyVault/vaults@2021-06-01-preview' = {
  location: resourceGroup().location
  tags: tags
  name: name
  properties: {
    sku: sku
    tenantId: subscription().tenantId
    accessPolicies: accessPolicies
  }
}

output id string = kv.id
output keyVaultUri string = kv.properties.vaultUri
