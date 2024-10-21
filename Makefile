all:

.PHONY:deploy-all deploy kubeconfig reboot shutdown help

deploy-all:deploy kubeconfig help ## Deploy prod-k3s.cluster and copy kube-config

deploy: ## Deploy prod-k3s.cluster.
	@echo "Deploy prod-k3s.cluster ..."
	@ansible-playbook site.yml

kubeconfig: ## Copy 'kubeconfig'.
	@echo "\nCopy kubeconfig to ~/.kube/ ...\n"
	@scp vagrant@192.168.40.200:~/.kube/config ~/.kube/config
	@kubectl get nodes --show-kind

reboot: ## Reboot prod-k3s.cluster.
	@echo "\nReboot prod-k3s.cluster ..."
	@ansible-playbook reboot.yml

shutdown: ## Shutdown prod-k3s.cluster.
	@echo "\nShutdown prod-k3s.cluster ..."
	@ansible-playbook reset.yml

help: ## Display this help.
	@echo "\nDisplay this help ..."
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
