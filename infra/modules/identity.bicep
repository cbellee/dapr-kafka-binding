param name string
param principalId string
param roleId string
param roleAssignmentName string
param description string

resource ManagedIdentity 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid(resourceGroup().id, name, roleAssignmentName)
  scope: resourceGroup()
  properties: {
    description: description
    principalId: principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: roleId
  }
}
