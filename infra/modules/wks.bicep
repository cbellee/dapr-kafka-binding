param name string
param tags object
param retentionInDays int = 30

@allowed([
  'Standard'
  'PerGB2018'
])
param sku string = 'Standard'

resource azureMonitorWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  location: resourceGroup().location
  name: name
  tags: tags
  properties: {
    retentionInDays: retentionInDays
    sku: {
      name: sku
    }
  }
}

output workspaceId string = azureMonitorWorkspace.id 
