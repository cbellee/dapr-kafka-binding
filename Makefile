DOCKER_PASSWORD=''

build:
	docker build -t belstarr/dapr-pub:latest -f ./src/pub/Dockerfile .
	docker build -t belstarr/dapr-sub:latest -f ./src/sub/Dockerfile .

push:
	docker login -u belstarr -p ${DOCKER_PASSWORD}
	docker push belstarr/dapr-pub:latest
	docker push belstarr/dapr-sub:latest

k8s:
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

infra:
	./infra/deploy.sh

all:
	make build && make push && make deploy_k8s