export KUBECONFIG_IP 	:= 192.168.40.200

all:

ifneq ($(DEBUG),y)
.SILENT:
endif

.PHONY: all deploy-requirements kubeconfig reboot shutdown help

all:deploy kubeconfig help ## Deploy dev.cluster and copy kube-config

.PHONY: deploy-requirements
deploy-requirements: ## Deploy requirements.
	echo "Deploy requirements ..."
	ansible-galaxy install -r collections/requirements.yml

.PHONY: deploy
deploy: ## Deploy dev.cluster.
	echo "Deploy dev.cluster ..."
	ansible-playbook site.yml

.PHONY: kubeconfig
kubeconfig: ## Copy 'kubeconfig'.
	echo "Copy kubeconfig to ~/.kube/ ..."
	scp ansible@$(KUBECONFIG_IP):~/.kube/config ~/.kube/config
	kubectl get nodes --show-kind

.PHONY: reboot
reboot: ## Reboot dev.cluster.
	echo "Reboot dev.cluster ..."
	ansible-playbook reboot.yml

.PHONY: shutdown
shutdown: ## Shutdown dev.cluster.
	echo "Shutdown dev.cluster ..."
	ansible-playbook reset.yml

.PHONY: help
help: ## Display this help.
	echo "Display this help ..."
	awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
