ifndef ENV_NAME
ENV_NAME := dev
endif

KUBECONFIG_IP := $(shell grep 'apiserver_endpoint:' ansible/inventory/group_vars/$(ENV_NAME).env.yml | cut -d'"' -f2)

ifneq ($(DEBUG),y)
.SILENT:
endif

SHELL                  := bash
.SHELLFLAGS            := -eu -o pipefail -c
.DEFAULT_GOAL          := default
.DELETE_ON_ERROR:
.SUFFIXES:

# ifneq ($(DEBUG), y)
# .SILENT:
# else
# ANSIBLE_EXTRA_ARGS     := -vvv
# ifneq ($(findstring version, $(MAKECMDGOALS)), version)
# .SHELLFLAGS            := -eu -o pipefail -c -x
# else
# .SILENT:
# endif
# endif

OS_TYPE                := $(shell uname -s)

# ifeq ($(findstring not a tty, $(shell tty)), not a tty)
# REAL_COLUMNS           := 80
# else
# REAL_COLUMNS           := $(shell tput cols 2>/dev/null)
# endif

# ifeq ($(USER),jacek)
# PREFFERED_SHELL                := zsh
# PREFFERED_SHELL_OH_MY_ZSH      := y
# PREFFERED_SHELL_OH_MY_ZSH_DIR  := ~/.oh-my-zsh
# PREFFERED_SHELL_P10K           := y
# PREFFERED_SHELL_P10K_CFG       := ~/p10k.zsh
# endif

# ifndef PREFFERED_SHELL
# PREFFERED_SHELL        := bash -l
# endif



all:
.PHONY: all deploy-requirements kubeconfig reboot shutdown help

all: deploy-requirements deploy kubeconfig help ## Deploy dev.cluster and copy kube-config

.PHONY: deploy-requirements
deploy-requirements: ## Deploy requirements.
	echo "Deploy requirements ..."
	ansible-galaxy install -r ./ansible/collections/requirements.yml

# .PHONY: deploy
# deploy: ## Deploy dev.cluster.
# 	echo "Deploy dev.cluster ..."
# 	ansible-playbook ./ansible/site.yml

.PHONY: deploy
deploy: ## Deploy cluster for specified ENV_NAME.
	echo "Deploy $(ENV_NAME).cluster ..."
	ansible-playbook ./ansible/site.yml -i ./ansible/inventory/$(ENV_NAME).ini


# .PHONY: kubeconfig
# kubeconfig: ## Copy 'kubeconfig'.
# 	echo "Copy kubeconfig to ~/.kube/ ..."
# 	scp ansible@$(KUBECONFIG_IP):~/.kube/config ~/.kube/config
# 	kubectl get nodes --show-kind

.PHONY: kubeconfig
kubeconfig: ## Copy 'kubeconfig' for specified ENV_NAME.
	echo "Copy kubeconfig to target/$(ENV_NAME)/.kube/config ..."
	# mkdir -p target/$(ENV_NAME)/.kube
	scp ansible@$(KUBECONFIG_IP):~/.kube/config target/$(ENV_NAME)/.kube/config
	kubectl --kubeconfig=target/$(ENV_NAME)/.kube/config get nodes --show-kind

# .PHONY: reboot
# reboot: ## Reboot dev.cluster.
# 	echo "Reboot dev.cluster ..."
# 	ansible-playbook ./ansible/reboot.yml

.PHONY: reboot
reboot: ## Reboot cluster for specified ENV_NAME.
	echo "Reboot $(ENV_NAME).cluster ..."
	ansible-playbook ./ansible/reboot.yml -i ./ansible/inventory/$(ENV_NAME).ini

# .PHONY: shutdown
# shutdown: ## Shutdown dev.cluster.
# 	echo "Shutdown dev.cluster ..."
# 	ansible-playbook ./ansible/reset.yml

.PHONY: shutdown
shutdown: ## Shutdown cluster for specified ENV_NAME.
	echo "Shutdown $(ENV_NAME).cluster ..."
	ansible-playbook ./ansible/reset.yml -i ./ansible/inventory/$(ENV_NAME).ini

.PHONY: help
help: ## Display this help.
	echo "Display this help ..."
	awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)





# include versions

# ifndef ENV_NAME
# ENV_NAME      := $(shell echo $(ENV_NAME) | tr A-Z_ a-z-)
# endif

# STATIC_PROFILES        += dev
# STATIC_PROFILES        += prod

# ifneq ($(MAKECMDGOALS), )
# ifneq ($(findstring help,    $(MAKECMDGOALS)), help)
# ifneq ($(findstring logo,    $(MAKECMDGOALS)), logo)
# ifneq ($(findstring usage,   $(MAKECMDGOALS)), usage)
# ifneq ($(findstring header,  $(MAKECMDGOALS)), header)
# ifneq ($(findstring version, $(MAKECMDGOALS)), version)

# ifndef ENV_PROFILE
# ifeq ($(findstring $(ENV_NAME), $(STATIC_PROFILES)), $(ENV_NAME))
# ENV_PROFILE            := $(ENV_NAME)
# endif

# ifeq ($(findstring $(ENV_NAME), current), current)
# ENV_PROFILE            := pr
# endif
# endif

# ifeq ($(findstring vault-view-common, $(MAKECMDGOALS)), vault-view-common)
# ENV_PROFILE            := dev
# endif

# ifeq ($(findstring vault-edit-common, $(MAKECMDGOALS)), vault-edit-common)
# ENV_PROFILE            := dev
# endif

# ifndef ENV_PROFILE
# $(error NO_ENV_PROFILE_ERROR)
# endif

# ifeq ($(wildcard ansible/inventory/hostvars/$(ENV_PROFILE).vault.yml),)
# $(error NO_ENV_PROFILE_ERROR)
# endif

# define profile_vars
# docker run \
#   --rm \
#   -v ${PWD}:/workdir \
#   -u $(UID):$(GID) \
#   --privileged \
#   mikefarah/yq:$(YQ_VERSION) \
#   sh $(.SHELLFLAGS) '\
#   export YQ_CMD="yq read ansible/inventory/hostvars/$(ENV_PROFILE).env.yml"; \
#   echo ENV_DOMAIN                                          := $$($${YQ_CMD} env.domain); \
#   # echo ENV_TYPE                                            := $$($${YQ_CMD} env.type); \
#   '
# endef

# include $(shell mkdir -p target && $(call profile_vars) > target/vars && echo target/vars)

# ifndef ENV_TYPE
# $(error NO_ENV_TYPE_ERROR)
# endif

# ifndef ENV_DOMAIN
# $(error NO_ENV_DOMAIN_ERROR)
# endif


# %:      DOCKER_EXTRA_ARGS := -it
# image:  DOCKER_EXTRA_ARGS :=

# ifeq ($(DOCKER_CACHE),n)
# image:  DOCKER_EXTRA_ARGS += --no-cache
# endif
# else
# %:      DOCKER_EXTRA_ARGS := -i
# runner: DOCKER_EXTRA_ARGS := -it
# image:  DOCKER_EXTRA_ARGS :=

# ifeq ($(DOCKER_CACHE),n)
# image:  DOCKER_EXTRA_ARGS += --no-cache
# endif


# ifndef LE_API_ENV
# LE_API_ENV             := prod
# endif

# PROTECTED_ENVS         := dev
# PROTECTED_ENVS         += stage
# PROTECTED_ENVS         += prod

# RUNNER_USER            := runner
# IMAGE                  := runner:$(PROJECT)-$(shell echo $(ENV_NAME) | tr A-Z a-z)
# UID                    := $(shell id -u)
# GID                    := $(shell id -g)
# HELM3_DIR              := $(PWD)/target/$(ENV_NAME)/.config/helm
# DOCKER_DIR             := $(PWD)/target/$(ENV_NAME)/.docker
# SSH_PRIVATE_KEY        := $(HOME)/.ssh/id_rsa
# SSH_PUBLIC_KEY         := $(SSH_PRIVATE_KEY).pub

# KUBE_DIR               := $(PWD)/target/$(ENV_NAME)/.kube

# PROXY_PORT             := 8001

# ifndef VAULT_PASSWORD_FILE
# VAULT_PASSWORD_FILE    := ~/.ansible-vault.k8s.dev
# endif

# ifndef WATCH
# WATCH                  := n
# endif

# ENV_PROFILE_UNDERSCORE := $(shell echo $(ENV_PROFILE) | tr '-' '_')

# define exec_cmd
# docker --config $(DOCKER_DIR) run $(DOCKER_EXTRA_ARGS) --rm \
#   -u $(UID):$(GID) \
#   --privileged \
#   -e ANSIBLE_FORCE_COLOR=True \
#   -e ANSIBLE_ROLES_PATH=/home/$(RUNNER_USER)/app/ansible/roles \
#   -e ANSIBLE_VAULT_K8S_$(ENV_PROFILE_UNDERSCORE)=$(ANSIBLE_VAULT_K8S_$(ENV_PROFILE_UNDERSCORE)) \
#   -e ANSIBLE_VERSION=$(ANSIBLE_VERSION) \
#   -e ANSIBLE_GALAXY_COMMUNITY_GENERAL_VERSION=$(ANSIBLE_GALAXY_COMMUNITY_GENERAL_VERSION) \
#   -e ANSIBLE_LINT_VERSION=$(ANSIBLE_LINT_VERSION) \
#   -e ARGOCD_VERSION=$(ARGOCD_VERSION) \
#   -e ARGOCD_HELM_CHART_VERSION=$(ARGOCD_HELM_CHART_VERSION) \
#   -e CURL_VERSION=$(CURL_VERSION) \
#   -e ENV_NAME=$(ENV_NAME) \
#   -e ENV_DOMAIN=$(ENV_DOMAIN) \
#   -e ENV_PROFILE=$(ENV_PROFILE) \
#   -e HELM3_VERSION=$(HELM3_VERSION) \
#   -e JINJA2_VERSION=$(JINJA2_VERSION) \
#   -e K9S_VERSION=$(K9S_VERSION) \
#   -e KUBERNETES_VERSION=$(KUBERNETES_VERSION) \
#   -e PYYAML_VERSION=$(PYYAML_VERSION) \
#   -e PROJECT=$(PROJECT) \
#   -e VERSION=$(VERSION) \
#   -e DEBUG=$(DEBUG) \
#   -e USERS=$(USERS) \
#   -e APPS=$(APPS) \
#   $(if $(filter $(OS_TYPE),Linux),-e SSH_AUTH_SOCK=$(SSH_AUTH_SOCK),) \
#   -v $(ARGOCD_DIR):/home/$(RUNNER_USER)/.config/argocd \
#   -v $(SSH_PRIVATE_KEY):/home/$(RUNNER_USER)/.ssh/id_rsa:ro \
#   -v $(SSH_PUBLIC_KEY):/home/$(RUNNER_USER)/.ssh/id_rsa.pub:ro \
#   -v $(KUBE_DIR):/home/$(RUNNER_USER)/.kube \
#   -v $(HELM3_DIR):/home/$(RUNNER_USER)/.config/helm \
#   -v $(DOCKER_DIR):/home/$(RUNNER_USER)/.docker \
#   -v $(PWD):/home/$(RUNNER_USER)/app \
#   -v $(PWD)/target/.bash_history:/home/$(RUNNER_USER)/.bash_history \
#   -v $(VAULT_PASSWORD_FILE):/home/$(RUNNER_USER)/.ansible-vault \
#   $(if $(filter $(PREFFERED_SHELL),zsh), -v ~/.zsh_history:/home/$(RUNNER_USER)/.zsh_history,) \
#   $(if $(filter $(PREFFERED_SHELL),zsh), -v ~/.zshrc:/home/$(RUNNER_USER)/.zshrc,) \
#   $(if $(filter $(PREFFERED_SHELL_OH_MY_ZSH),y), -v $(PREFFERED_SHELL_OH_MY_ZSH_DIR):/home/$(RUNNER_USER)/.oh-my-zsh,) \
#   $(if $(filter $(PREFFERED_SHELL_P10K),y), -v $(PREFFERED_SHELL_P10K_CFG):/home/$(RUNNER_USER)/.p10k.zsh:rw,) \
#   -w /home/$(RUNNER_USER)/app \
#   --network=host \
#   --hostname=runner \
#   --dns="8.8.8.8" \
#   $(IMAGE) \
#   $(1)
# endef

# define ansible_playbook_cmd
# bash $(.SHELLFLAGS) '\
# cd ansible; \
# REPLACE="$(REPLACE)" \
#   ansible-playbook \
#     -i localhost, \
#     --vault-password-file=/home/$(RUNNER_USER)/.ansible-vault \
#     $(strip $(1)).yml \
#     $(ANSIBLE_EXTRA_ARGS) \
# '
# endef

# define ansible_playbook_syntax_check_cmd
# bash $(.SHELLFLAGS) '\
# cd ansible; \
# ansible-playbook \
#   -i localhost, \
#   --vault-password-file=/home/$(RUNNER_USER)/.ansible-vault \
#   --syntax-check \
#   *.yml \
#   $(ANSIBLE_EXTRA_ARGS) \
# '
# endef

# define ansible_vault_view_cmd
# bash $(.SHELLFLAGS) '\
# ansible-vault \
#   view \
#   --vault-password-file=/home/$(RUNNER_USER)/.ansible-vault \
#   $(strip $(1)) \
# '
# endef

# define ansible_vault_edit_cmd
# bash $(.SHELLFLAGS) '\
# ansible-vault \
#   edit \
#   --vault-password-file=/home/$(RUNNER_USER)/.ansible-vault \
#   $(strip $(1)) \
# '
# endef


# K8S_MAKEFILE_LOG_FILE := "$(S3_LOG_TIME)-env_$(ENV_NAME)-profile_$(ENV_PROFILE)-user_$(USER).txt"
# K8S_MAKEFILE_LOG_DIR  := "target/s3-log"

# define k8s_create_logfile
# mkdir -p target/s3-log
# touch $(K8S_MAKEFILE_LOG_DIR)/$(K8S_MAKEFILE_LOG_FILE)
# echo "Target goal: $(MAKECMDGOALS)" > $(K8S_MAKEFILE_LOG_DIR)/$(K8S_MAKEFILE_LOG_FILE)
# echo "Branch: $(GIT_BRANCH_LABEL)" >> $(K8S_MAKEFILE_LOG_DIR)/$(K8S_MAKEFILE_LOG_FILE)
# endef

# define s3_log_update
# aws s3 cp $(K8S_MAKEFILE_LOG_DIR)/$(K8S_MAKEFILE_LOG_FILE) s3://$(S3_LOG_BUCKET) 2>&1 | grep -v "upload: target/" || true
# endef

# ifeq ($(VERSION),)
# VERSION := $(shell $(call version))
# endif

# ifeq ($(VERSION),HEAD)
# VERSION := $(shell $(call version))
# endif

# define LOGO


#  ██╗  ██╗ █████╗ ███████╗
#  ██║ ██╔╝██╔══██╗██╔════╝
#  █████╔╝ ╚█████╔╝███████╗
#  ██╔═██╗ ██╔══██╗╚════██║
#  ██║  ██╗╚█████╔╝███████║
#  ╚═╝  ╚═╝ ╚════╝ ╚══════╝

# endef

# define HEADER
# \033[0m\033[38;5;15mVersion: \033[2m\033[38;5;86m$(shell printf "%-38s" "$(VERSION)")\033[0m     \033[38;5;15mEnvironment: \033[2m\033[38;5;86m$(ENV_NAME)\033[0m
# \033[0m\033[38;5;15mType:    \033[2m\033[38;5;86m$(shell printf "%-38s" "$(ENV_TYPE)")\033[0m     \033[38;5;15mBranch:      \033[2m\033[38;5;86m$(GIT_BRANCH_LABEL)\033[0m
# \033[0m\033[38;5;15mProfile: \033[2m\033[38;5;86m$(shell printf "%-38s" "$(ENV_PROFILE)")\033[0m     \033[38;5;15mDomain:      \033[2m\033[38;5;86m$(ENV_DOMAIN)\033[0m
# endef

# define USAGE
# \Usage:
#   \033[2m\033[38;5;86mmake\033[0m\033[38;5;242m [COMMAND] [ENV_NAME=<name>] [ENV_PROFILE=<profile>] [FORCE=<y|n>] [DEBUG=<y|n>]\033[0m
# endef

# define RELEASE_ERROR
# Unable to release. Uncommited changes found
# endef

# export LOGO
# export HEADER
# export USAGE
# export DOCKER_BUILDKIT=1

# define GOAL
# echo -e " \033[0m\033[38;5;86m::: \033[1m\033[38;5;15mExecuting: ~> \033[0m\033[38;5;86m$@\033[0m"
# test -d $(K8S_MAKEFILE_LOG_DIR) && \
# (echo -e "`date '+%Y-%m-%d %H:%M:%S:'` Executing ~> $@" >> "$(K8S_MAKEFILE_LOG_DIR)/$(K8S_MAKEFILE_LOG_FILE)") || \
# true
# echo
# endef

# define HR
# printf "\033[38;5;238m%*s\033[0m\r\n" "$(REAL_COLUMNS)" '' | tr ' ' "-"
# endef



# .PHONY: all
# all: cluster

# .PHONY: default
# default: help

# .PHONY: version
# version:
# 	echo $(VERSION)

# .PHONY: logo
# logo:
# 	echo -e "\\033[38;5;86m$$LOGO\033[0m"
# 	$(call HR)

# .PHONY: header
# header:
# 	echo -e "$$HEADER"

# .PHONY: usage
# usage:
# 	echo -e "$$USAGE"

# .PHONY: help                           # This message #
# help: logo header usage
# 	echo -e " Commands:\n"
# 	echo -e "$$(grep '^.PHONY: .*#' Makefile  | sed 's/\.PHONY: \(.*\) # \(.*\) # *\(\[*.*=*.*\]*\)/   \\033[0m\\033[38;5;15m\1\\033[0m   \2\\033[0m\\033[38;5;242m \3\\033[0m/')\\n"

# .PHONY: init
# init: logo header
# 	if [ ! -d .git ]; then \
# 		git init; \
# 	fi
# 	if [ ! -d target/$(ENV_NAME) ]; then \
# 		mkdir -p -m 0700 target/$(ENV_NAME); \
# 	fi
# 	if [ ! -d target/.bash_history ]; then \
# 		touch target/.bash_history; \
# 		chmod 0600 target/.bash_history; \
# 	fi
# 	if [ ! -d $(ARGOCD_DIR) ]; then \
# 		mkdir -p -m 0700 $(ARGOCD_DIR); \
# 	fi
# 	if [ ! -d $(HELM3_DIR) ]; then \
# 		mkdir -p -m 0700 $(HELM3_DIR); \
# 	fi
# 	if [ ! -d $(KUBE_DIR) ]; then \
# 		mkdir -p -m 0700 $(KUBE_DIR); \
# 	fi
# 	if [ ! -d $(DOCKER_DIR) ]; then \
# 		mkdir -p -m 0700 $(DOCKER_DIR); \
# 	fi

# .PHONY: image                          # Build Docker image #
# image: init
# 	$(call GOAL)
# 	cd docker; \
# 	docker build . $(DOCKER_EXTRA_ARGS) \
# 		-t $(IMAGE) \
# 		--build-arg ANSIBLE_VERSION=$(ANSIBLE_VERSION) \
# 		--build-arg ANSIBLE_GALAXY_COMMUNITY_GENERAL_VERSION=$(ANSIBLE_GALAXY_COMMUNITY_GENERAL_VERSION) \
# 		--build-arg ANSIBLE_LINT_VERSION=$(ANSIBLE_LINT_VERSION) \
# 		--build-arg ARGOCD_VERSION=$(ARGOCD_VERSION) \
# 		--build-arg HELM3_VERSION=$(HELM3_VERSION) \
# 		--build-arg JINJA2_VERSION=$(JINJA2_VERSION) \
# 		--build-arg K9S_VERSION=$(K9S_VERSION) \
# 		--build-arg KUBECTL_WHO_CAN_VERSION=$(KUBECTL_WHO_CAN_VERSION) \
# 		--build-arg KUBERNETES_VERSION=$(KUBERNETES_VERSION) \
# 		--build-arg PHUSION_BASEIMAGE_VERSION=$(PHUSION_BASEIMAGE_VERSION) \
# 		--build-arg PYYAML_VERSION=$(PYYAML_VERSION) \
# 		--build-arg YQ_VERSION=$(YQ_VERSION) \
# 		--build-arg UID=$(UID) \
# 		--build-arg GID=$(GID) \
# 		--build-arg RUNNER_USER=$(RUNNER_USER) && \
# 	echo

# .PHONY: runner                         # Runner container shell #
# runner: image login
# 	$(call GOAL)
# 	$(call exec_cmd, $(PREFFERED_SHELL))
# 	echo


# # .PHONY: k8s-config                     # Configure Kubernetes cluster              # [LE_API_ENV=<dev|ci|prod>]
# # k8s-config: image login
# # 	$(call GOAL)
# # 	$(call exec_cmd, $(call ansible_playbook_cmd, k8s-config))
# # 	$(call exec_cmd, $(s3_log_update))

# .PHONY: proxy                          # Run kubectl proxy                         # [PROXY_PORT=8001]
# proxy: logo header
# 	$(call GOAL)
# 	echo
# 	$(call kubectl_proxy_stop_cmd)
# 	$(call kubectl_proxy_start_cmd)
# 	$(call exec_cmd, $(s3_log_update))


# .PHONY: stats                          # Show code statistics #
# stats: logo header
# 	$(call GOAL)
# 	echo
# 	printf "%-30s %20s\n" "$(shell echo -en "\033[38;5;15mType\033[0m")"         "$(shell echo -en "\033[38;5;15mLines\033[0m")"
# 	$(call HR)
# 	printf "%-30s %6s\n"  "$(shell echo -en "\033[38;5;36mAnsible\033[0m"):"     "$(shell cat ansible/*.yml ansible/**/*.yml ansible/**/**/**/*.yml | grep -Ev "#" | wc -l)"
# 	printf "%-30s %6s\n"  "$(shell echo -en "\033[38;5;36mJinja2\033[0m"):"      "$(shell cat ansible/**/**/**/*.j2 | grep -Ev "#" | wc -l)"
# 	printf "%-30s %6s\n"  "$(shell echo -en "\033[38;5;36mPython\033[0m"):"      "$(shell cat ansible/**/*.py | grep -Ev "#" | wc -l)"
# 	printf "%-30s %6s\n"  "$(shell echo -en "\033[38;5;36mMakefile\033[0m"):"    "$(shell cat Makefile versions | grep -Ev "#" | wc -l)"
# 	printf "%-30s %6s\n"  "$(shell echo -en "\033[38;5;36mDockerfile\033[0m"):"  "$(shell cat docker/* | grep -Ev "#" | wc -l)"
# 	printf "%-30s %6s\n"  "$(shell echo -en "\033[38;5;36mOther\033[0m"):"       "$(shell cat .gitignore | grep -Ev "#" | wc -l)"
# 	$(call HR)
# 	printf "%-30s %20s\n" "$(shell echo -en "\033[38;5;86mTotal\033[0m"):"       "$(shell echo -en "\033[38;5;15m$(shell $(call code_stats_total))\033[0m")"
# 	echo
# 	$(call exec_cmd, $(s3_log_update))





# endif
# endif
# endif
# endif
# endif
# endif
