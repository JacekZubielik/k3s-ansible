ARG PHUSION_BASEIMAGE_VERSION

FROM phusion/baseimage:focal-${PHUSION_BASEIMAGE_VERSION}

ARG KUBERNETES_VERSION

RUN apt-get -y update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -qqy --no-install-recommends \
      apt-transport-https \
      bash-completion \
      docker.io \
      dnsutils \
      git \
      groff \
      jq \
      python3-pip \
      shellcheck \
      zsh \
      unzip \
      gcc && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    curl -fsSLo /usr/local/bin/kubectl https://dl.k8s.io/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl && \
    apt-get clean && \
    rm -rf \
      /var/lib/apt/lists/* \
      /tmp/* \
      /var/tmp/*

RUN pip3 install -U pip

RUN pip3 install setuptools

ARG ANSIBLE_VERSION

ARG ANSIBLE_GALAXY_COMMUNITY_GENERAL_VERSION

ARG ANSIBLE_LINT_VERSION

ARG OC_CLIENT_VERSION

ARG PYYAML_VERSION

ARG JINJA2_VERSION

RUN pip3 install \
      ansible==${ANSIBLE_VERSION} \
      jmespath \
      jinja2==${JINJA2_VERSION} \
      jsonpatch \
      kubernetes \
      kubernetes-validate \
      netaddr \
      lxml \
      passlib \
      bcrypt \
      packaging \
      pyyaml==${PYYAML_VERSION} \
      unidecode \
      openshift==${OC_CLIENT_VERSION} \
      yamllint \
      ansible-lint==${ANSIBLE_LINT_VERSION}

ARG TERRAFORM_VERSION

ARG HELM3_VERSION

RUN curl -sL https://get.helm.sh/helm-v${HELM3_VERSION}-linux-amd64.tar.gz \
    | zcat \
    | tar -x linux-amd64/helm && \
    mv linux-amd64/helm /usr/local/bin/helm3 && \
    chmod +x /usr/local/bin/helm3 && \
    rmdir linux-amd64

ARG YQ_VERSION

RUN curl \
      -L https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64 \
      -o /usr/local/bin/yq && \
    chmod +x /usr/local/bin/yq

ARG K9S_VERSION

RUN curl -sL https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_amd64.tar.gz \
    | zcat \
    | tar -x k9s && \
    mv k9s /usr/local/bin && \
    chmod +x /usr/local/bin/k9s

ARG ARGOCD_VERSION

RUN curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v${ARGOCD_VERSION}/argocd-linux-amd64 && \
    chmod +x /usr/local/bin/argocd

ARG GID

RUN groupadd --non-unique -g $GID runner

ARG UID

ARG RUNNER_USER

RUN useradd -u $UID -g $GID -m -d /home/$RUNNER_USER -s /bin/bash $RUNNER_USER

USER $RUNNER_USER

COPY .ansible-lint .yamllint /home/${RUNNER_USER}/

RUN ansible-galaxy collection install community.general:${ANSIBLE_GALAXY_COMMUNITY_GENERAL_VERSION}

RUN mkdir -m 0700 \
      /home/${RUNNER_USER}/.ssh \
      /home/${RUNNER_USER}/.kube && \
    touch /home/${RUNNER_USER}/.bash_history && \
    chmod 0600 /home/${RUNNER_USER}/.bash_history && \
    echo "export HISTSIZE=1000000"                            >> /home/${RUNNER_USER}/.bash_profile && \
    echo "source <(kubectl completion bash)"                  >> /home/${RUNNER_USER}/.bash_profile && \
    echo "source $HOME/.bashrc"                               >> /home/${RUNNER_USER}/.bash_profile && \
    echo "alias k=kubectl"                                    >> /home/${RUNNER_USER}/.bash_profile && \
    echo 'export PS1="\u@\[\e[33m\]${ENV_NAME}\[\e[m\]:\W$ "' >> /home/${RUNNER_USER}/.bash_profile && \
    echo "set nocompatible"                                   >> /home/${RUNNER_USER}/.vimrc &&
