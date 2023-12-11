
default:
	just --list

# deploy (create AKS cluster, deploy dapr components, services etc)
deploy:
	./deploy.sh

# Deploy apps to k8s
deploy-to-k8s:
	./scripts/deploy-to-k8s.sh