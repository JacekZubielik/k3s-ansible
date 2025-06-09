SHELL					:= bash
.SHELLFLAGS				:= -eu -o pipefail -c
.DEFAULT_GOAL			:= default
UID                		:= $(shell id -u)
GID						:= $(shell id -g)
OS_TYPE					:= $(shell uname -s)
# PLAYBOOKS				:= $(wildcard ansible/*.yml)

ifndef ENV_NAME
ENV_NAME := dev
endif

KUBECONFIG_IP := $(shell grep 'apiserver_endpoint:' ansible/inventory/$(ENV_NAME).env.yml | cut -d'"' -f2)

ifndef INVENTORY
INVENTORY := ansible/inventory/$(ENV_NAME).env.yml
endif

ifneq ($(DEBUG),y)
.SILENT:
endif

ifndef TYPE
TYPE := all
endif

all:
.PHONY: all deps kubeconfig reboot shutdown help

all: deps deploy help

.PHONY: deps
deps: ## Deploy requirements.
	echo "Deploy requirements ..."
	ansible-galaxy install -r ./ansible/collections/requirements.yml

.PHONY: deploy
deploy: ## Deploy cluster for specified ENV_NAME.
	echo "Deploy $(ENV_NAME).cluster ..."
	ansible-playbook ./ansible/site.yml -i $(INVENTORY) -e "env_name=$(ENV_NAME)"

.PHONY: kubeconfig
kubeconfig: ## Copy 'kubeconfig' for specified ENV_NAME.
	echo "Copy kubeconfig to ansible/target/$(ENV_NAME)/.kube/config ..."
	scp ansible@$(KUBECONFIG_IP):~/.kube/config ansible/target/$(ENV_NAME)/.kube/config
	kubectl --kubeconfig=ansible/target/$(ENV_NAME)/.kube/config get nodes --show-kind

.PHONY: reboot
reboot: ## Reboot cluster for specified ENV_NAME.
	echo "Reboot $(ENV_NAME).cluster ..."
	ansible-playbook ./ansible/reboot.yml -i $(INVENTORY) -e "env_name=$(ENV_NAME)"

.PHONY: shutdown
shutdown: ## Shutdown cluster for specified ENV_NAME.
	echo "Shutdown $(ENV_NAME).cluster ..."
	ansible-playbook ./ansible/reset.yml -i $(INVENTORY) -e "env_name=$(ENV_NAME)"

.PHONY: help
help: ## Display this help.
	echo "Display this help ..."
	awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
