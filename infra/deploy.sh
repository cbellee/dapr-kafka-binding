RG_NAME='dapr-k8s-rg'
LOCATION='australiaeast'
DEPLOYMENT_NAME='dapr-k8s-deployment'
SSH_PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)

az group create --location $LOCATION --name $RG_NAME

az deployment group create \
    --resource-group $RG_NAME \
    --name $DEPLOYMENT_NAME \
    --template-file ./infra/main.bicep \
    --parameters sshPublicKey="$SSH_PUBLIC_KEY"

CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name $DEPLOYMENT_NAME --query 'properties.outputs.aksClusterName.value' -o tsv)

az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin