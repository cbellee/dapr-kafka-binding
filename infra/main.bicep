param tags object = {
  evnironment: 'dev'
  costcode: '1234567890'
}
param adminGroupId string = 'f6a900e2-df11-43e7-ba3e-22be99d3cede'
param sshPublicKey string
param objectId string = '57963f10-818b-406d-a2f6-6e758d86e259'

var acrPullRoleId = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var readerRoleId = resourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
var managedIdentityOperatorRoleId = resourceId('Microsoft.Authorization/roleDefinitions', 'f1a07417-d97a-45cb-824c-7a7467783830')
var virtualMachineContributorRoleId = resourceId('Microsoft.Authorization/roleDefinitions', '9980e02c-c2be-4d73-94e8-173b1dc7cf3c')
var suffix = '${uniqueString(resourceGroup().id)}'
var keyVaultName = 'kv-${suffix}'
var acrName = 'acr${suffix}'
var vnetName = 'vnet-${suffix}'
var wksName = 'wks-${suffix}'
var aksName = 'aks-${suffix}'
var aiName = 'ai-${suffix}'
var accessPolicies = [
  {
    permissions: {
      certificates: [
        'all'
      ]
      keys: [
        'all'
      ]
      secrets: [
        'all'
      ]
      storage: [
        'all'
      ]
    }
    objectId: objectId
    tenantId: subscription().tenantId
  }
  {
    permissions: {
      certificates: []
      keys: []
      secrets: [
        'get'
        'list'
      ]
      storage: []
    }
    objectId: aksMod.outputs.aksKubeletPrincipalId
    tenantId: subscription().tenantId
  }
]

module wksMod 'modules/wks.bicep' = {
  name: 'wksDeployment'
  params: {
    name: wksName
    retentionInDays: 30
    tags: tags
  }
}

module aiMod './modules/ai.bicep' = {
  name: 'aiDeployment'
  params: {
    name: aiName
    tags: tags
    workspaceId: wksMod.outputs.workspaceId
  }
}

module acrMod 'modules/acr.bicep' = {
  name: 'acrDeployment'
  params: {
    acrName: acrName
    tags: tags
  }
}

module kvMod 'modules/keyvault.bicep' = {
  name: 'keyVaultDeployment'
  params: {
    name: keyVaultName
    accessPolicies: accessPolicies
    tags: tags
    sku: {
      family: 'A'
      name: 'standard'
    }
  }
}

module vnetMod 'modules/vnet.bicep' = {
  name: 'vnetDeployment'
  params: {
    name: vnetName
    tags: tags
    addressPrefix: '10.0.0.0/16'
    subnets: [
      {
        name: 'aks-sys-subnet'
        addressPrefix: '10.0.0.0/24'
      }
      {
        name: 'aks-usr-subnet'
        addressPrefix: '10.0.1.0/24'
      }
    ]
  }
}

module aksMod 'modules/aks.bicep' = {
  name: aksName
  params: {
    name: aksName
    addOns: {}
    aksVersion: '1.20.7'
    networkPlugin: 'azure'
    enableAutoScaling: true
    aksAgentOsDiskSizeGB: 30
    adminGroupObjectID: adminGroupId
    aksSystemSubnetId: vnetMod.outputs.subnets[0].id
    aksUserSubnetId: vnetMod.outputs.subnets[1].id
    linuxAdminUserName: 'localadmin'
    logAnalyticsWorkspaceId: wksMod.outputs.workspaceId
    sshPublicKey: sshPublicKey
    tags: tags
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' existing = {
  name: acrName
}

resource AssignAcrPullToAks 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid(resourceGroup().id, acrName, 'AssignAcrPullToAks')
  scope: acr
  properties: {
    description: 'Assign AcrPull role to AKS'
    principalId: aksMod.outputs.aksKubeletPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: acrPullRoleId
  }
}

resource AssignReaderRoleToAksManagedIdentity 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid(resourceGroup().id, aksName, 'AssignReaderRoleToAksManagedIdentity')
  properties: {
    description: 'Assign RespourceGroup Reader role to AKS managed identity'
    principalId: aksMod.outputs.aksKubeletPrincipalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: readerRoleId
  }
}

module AssignManagedIdentityOperatorRoleToAksManagedIdentityMod 'modules/identity.bicep' = {
  name: 'managedIdentityOperatorRoleDeployment'
  scope: resourceGroup('MC_${resourceGroup().name}_${aksName}_${resourceGroup().location}')
  params: {
    name: aksName
    description: 'Assign ManagedIdentityOperator role to Aks Managed Identity'
    roleAssignmentName: guid(resourceGroup().id, aksName, 'AssignManagedIdentityOperatorRoleToAksManagedIdentity')
    roleId: managedIdentityOperatorRoleId
    principalId: aksMod.outputs.aksKubeletPrincipalId
  }
}

module AssignReaderVirtualMachineContributorToAksManagedIdentityMod 'modules/identity.bicep' = {
  name: 'readerVirtualMachineContributorDeployment'
  scope: resourceGroup('MC_${resourceGroup().name}_${aksName}_${resourceGroup().location}')
  params: {
    name: aksName
    description: 'Assign VirtualMachineContributor role to Aks Managed Identity'
    roleAssignmentName: guid(resourceGroup().id, aksName, 'AssignReaderVirtualMachineContributorToAksManagedIdentity')
    roleId: virtualMachineContributorRoleId
    principalId: aksMod.outputs.aksKubeletPrincipalId
  }
}

output acrId string = acr.id
output kvId string = kvMod.outputs.id
output kvUri string = kvMod.outputs.keyVaultUri
output aksClusterName string = aksMod.outputs.aksClusterName
output appInsightsId string = aiMod.outputs.id
output appInsightsName string = aiMod.outputs.name
