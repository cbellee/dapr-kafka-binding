param workspaceId string
param name string
param tags object
param retentionInDays int = 30

resource ai 'Microsoft.Insights/components@2020-02-02' = {
  location: resourceGroup().location
  kind: 'web'
  name: name
  tags: tags

  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: workspaceId
    RetentionInDays: retentionInDays
  }
}

output instrumentationKey string = ai.properties.InstrumentationKey
output id string = ai.id
output name string = ai.name
