RG_NAME='dapr-k8s-rg'
LOCATION='australiaeast'
SSH_PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)
DEPLOYMENT_NAME='dapr-k8s-deployment'

build:
	docker build -t belstarr/dapr-pub:latest -f ./src/pub/Dockerfile .
	docker build -t belstarr/dapr-sub:latest -f ./src/sub/Dockerfile .

push:
	docker login -u belstarr -p ${DOCKER_PASSWORD}
	docker push belstarr/dapr-pub:latest
	docker push belstarr/dapr-sub:latest

deploy_k8s:
	helm repo add dapr https://dapr.github.io/helm-charts/
	helm repo add bitnami https://charts.bitnami.com/bitnami
	helm repo update

	helm upgrade --install dapr dapr/dapr \
		--version=1.4 \
		--namespace dapr-system \
		--create-namespace \
		--wait \
	    --set dapr_operator.logLevel=debug \
		--set dapr_placement.logLevel=debug \
		--set dapr_sidecar_injector.logLevel=debug

	kubectl apply -f ./manifests/namespace.yml
	helm upgrade --install dapr-kafka bitnami/kafka --wait --namespace kafka
	kubectl apply -f ./manifests/kafka.binding.yml
	kubectl apply -f ./manifests/pub.yml
	kubectl apply -f ./manifests/sub.yml

deploy_infra:
	az group create --location ${LOCATION} --name ${RG_NAME}

	az deployment group create \
		--resource-group ${RG_NAME} \
		--name ${DEPLOYMENT_NAME} \
		--template-file ./infra/main.bicep \
		--parameters sshPublicKey="${SSH_PUBLIC_KEY}"

	CLUSTER_NAME=$(az deployment group show --resource-group ${RG_NAME} --name ${DEPLOYMENT_NAME} --query 'properties.outputs.aksClusterName.value' -o tsv)

	az aks get-credentials -g ${RG_NAME} -n ${CLUSTER_NAME} --admin

all:
	make build && make push && make deploy_k8s