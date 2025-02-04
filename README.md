# About the project

The [k3s-ansible](https://github.com/JacekZubielik/k3s-ansible) repository is a fork of the project [techno-tim/k3s-ansible](https://github.com/techno-tim/k3s-ansible) that allows you to automatically run highly available clusters using `Ansible` and `k3s` along with `MetalLB`, `Flannel`, `Calico`, `Cilium` or `Kube-VIP` of your choice on hybrid **x86\/ARM** nodes.

This release of the repository adds `Makefile` and new **Ansible** playbooks, which is a comprehensive solution for preparing the **Kubernetes** environment:

- Update and upgrade the **Debian** operating system, managing services and installing packages on each node.

- Integration with **Apt-Cacher**, which acts as a proxy cache for Debian packages.

- Preparation for **Longhorn** deployment, creating partitions, configuring the filesystem, checking requirements, and **labelling** and **annotating** the relevant nodes in the cluster.

- Redundant code removed (Proxmox LCX support, Proxy, etc.).

![](assets/images/k3s-ha-config.png)

# Related repositories

The project consists of multiple repositories, deployment is fully automated, the cluster can be redeployed in minutes as many times as required.

Please check the following repository for more information:

| Name                  | Description                                                              |
| --------------------- | ------------------------------------------------------------------------ |
| [k3s-ansible](https://github.com/JacekZubielik/k3s-ansible)          | Automated build of HA k3s cluster with kube-vip and MetalLB via ansible. |
| [dev-k3s-lab-autopilot](https://github.com/JacekZubielik/dev-k3s-lab-autopilot) | Deploying applications to the clusters with  ArgoCD Autopilot.           |
| [jz-helm-charts](https://github.com/JacekZubielik/jz-helm-charts)        | Personal Helm charts for applications deployed to the clusters           |

[![Play movie](assets/images/play.png)](https://odysee.com/$/embed/@dev-k3s-lab-autopilot:6/k3s-ansible:9?r=2exiFW5MjKi3cxzuB8VRhiE6E8khvcP8)

# Preparation for Installation

You can provision **virtual machines** or **bare metal**, as well as a mix of these solutions.

In the case of **bare metal**, you need to provide a physical data medium for each **node** designated to operate as `[storage_servers]`.

## **File Editing**: `hosts.ini`

```ini
[master]
dev-k3s-master-0.homelab.lan node_name=dev-k3s-master-0 host_key_checking=False
dev-k3s-master-1.homelab.lan node_name=dev-k3s-master-1 host_key_checking=False
dev-k3s-master-2.homelab.lan node_name=dev-k3s-master-2 host_key_checking=False

[node]
dev-k3s-node-0.homelab.lan node_name=dev-k3s-node-0 host_key_checking=False
dev-k3s-node-1.homelab.lan node_name=dev-k3s-node-1 host_key_checking=False
dev-k3s-node-2.homelab.lan node_name=dev-k3s-node-2 host_key_checking=False

[k3s_cluster:children]
master
node

[storage_servers]
dev-k3s-node-0.homelab.lan
dev-k3s-node-1.homelab.lan
dev-k3s-node-2.homelab.lan
```

## **File Editing**: `all.yml`

Applied a solution that provides a virtual **IP** address for the `Kubernetes` platform and a `load balancer` module for both the control plane and Kubernetes services. This way, we can have a single IP address (`192.168.40.200`) that can be used by all three masters. In the event of a failure of one, we can still communicate with the others without needing to change the IP address in the `kubeconfig` file.

`inventory/my-cluster/group_vars/all.yml`

```yaml
# apiserver_endpoint is virtual ip-address which will be configured on each master
apiserver_endpoint: "192.168.40.200"
```

Uncomment the appropriate entry to select the **CNI** for your deployment.

```
# uncomment cilium_iface to use cilium cni instead of flannel or calico
cilium_iface: "eth0"
```

```
# interface which will be used for flannel
# flannel_iface: eth0
```

```
# uncomment calico_iface to use tigera operator/calico cni instead of flannel https://docs.tigera.io/calico/latest/about
# calico_iface: eth0
```

## **File Editing**: `ansible.cfg`

This configuration file is tailored for a testing environment with optimizations like pipelining and fact caching while disabling some security features that are typically recommended in production settings.

The server and agent nodes must have SSH access configured without a password.

```ini
[defaults]
inventory                   = inventory/hosts.ini
roles_path                  = ./roles:/usr/share/ansible/roles
collections_path            = ./collections:/usr/share/ansible/collections
stdout_callback             = yaml
remote_tmp                  = $HOME/.ansible/tmp
local_tmp                   = $HOME/.ansible/tmp
timeout                     = 60
callbacks_enabled           = profile_tasks
callback_result_format      = yaml
log_path                    = ./ansible.log
host_key_checking           = false
validate_certs              = false
forks                       = 5
interpreter_python          = auto_silent
; vault_password_file         =./.vault/vault_pass.sh
ansible_python_interpreter  = /k3s-ansible/bin/python
hash_behaviour              = merge
pipelining                  = True
gathering                   = smart
fact_caching                = jsonfile
fact_caching_connection     = inventory/cache
fact_caching_timeout        = 86400
deprecation_warnings        = False

[ssh_connection]
scp_if_ssh = smart
retries = 3
ssh_args = -o ControlMaster=auto -o ControlPersist=30m -o Compression=yes -o ServerAliveInterval=15s
pipelining = true
control_path = %(directory)s/%%h-%%r
ansible_ssh_private_key_file = ~/.ssh/id_rsa
```

## The Role of `packages_debian`

The role of `packages_debian` is to update and modernize the Debian system by installing packages, configuring files, and managing services.


## The Role of `longhorn_util`

This playbook automates the process of creating partitions, configuring the file system, and mounting it in Linux, which is crucial for preparing the environment for Longhorn installation. As a result, the entire process is repeatable and easy to manage.

### Disable swap memory

```
- name: Disable swap memory
  include_tasks: disable_swap.yml
```

### Creating a Partition on the Disk

In this step, the parted module is used to create one large partition on the disk `/dev/vda`, which occupies all available space (from 0% to 100% of the disk).

```yaml
- name: "Create single large partition filling the disk"
  community.general.parted:
    device: /dev/vda
    number: 1
    state: present
    part_start: "0%"
    part_end: "100%"
    unit: GB
  when: disk_info.partitions | map(attribute='num') | list | select('==', '1') | list | length == 0
```

### Creating a File System

The aim of this task is to create an `ext4` file system on the device `/dev/vda1`, provided that certain conditions are met. This allows for the preparation of disk space for applications such as Longhorn, which require an appropriate file structure.

```yaml
- name: "Create filesystem on new partition before installing Longhorn"
  community.general.filesystem:
    fstype: ext4
    dev: /dev/vda1
    opts: -L data
    force: true
    state: present
  when: (filesystem.stdout | length == 0 or ('/dev/vda1' not in ansible_mounts | map(attribute='device') | list)) and (ansible_facts.filesystems['/dev/vda1'] is not defined)
```

The results of the command are displayed using the `debug` module, which allows you to see if the label has been correctly assigned.

```log
TASK [longhorn_util : debug] ************************************************************************************************************************************************************************************
Sunday 01 December 2024  00:03:06 +0100 (0:00:00.170)       0:00:20.568 *******
ok: [dev-k3s-node-0.homelab.lan] =>
  result.stdout_lines:
  - NAME    LABEL
  - 'sda     '
  - '├─sda1  '
  - '├─sda14 '
  - '└─sda15 '
  - 'vda     '
  - └─vda1  data
ok: [dev-k3s-node-1.homelab.lan] =>
  result.stdout_lines:
  - NAME    LABEL
  - 'sda     '
  - '├─sda1  '
  - '├─sda14 '
  - '└─sda15 '
  - 'vda     '
  - └─vda1  data
ok: [dev-k3s-node-2.homelab.lan] =>
  result.stdout_lines:
  - NAME    LABEL
  - 'sda     '
  - '├─sda1  '
  - '├─sda14 '
  - '└─sda15 '
  - 'vda     '
  - └─vda1  data
```

### Creating a Mount Point Directory
This step creates the directory `/mnt/data`, which will be used as a mount point for the new file system.

```yaml
- name: Create directory /mnt/data
  file:
    path: /mnt/data
    state: directory
    mode: '0777'
    owner: nobody
    group: nogroup
```

## Role of `longhorn_labels`

This code is used to verify the prerequisites for **Longhorn** and serves as a comprehensive solution for preparing the Kubernetes environment for Longhorn by **labeling** and **annotating** the appropriate nodes marked as [storage_servers] in the Kubernetes cluster.

### Labeling of Storage Nodes

This task applies the label `node.longhorn.io/create-default-disk=config` to all `storage nodes`, informing Longhorn that default disks are to be created.

```yaml
- name: "Apply label create-default-disk=config on storage nodes"
  ansible.builtin.command:
    kubectl label nodes {{ hostvars[item].node_name }}
    node.longhorn.io/create-default-disk=config --overwrite
  register: label_check
  changed_when: "'already has' not in label_check.stdout"
  loop: "{{ hostvars[inventory_hostname]['groups']['storage_servers'] }}"
```

The annotation indicates that the nodes are intended for fast data storage.

```yaml
- name: "Apply annotation default-node-tags=fast,storage on storage nodes"
  ansible.builtin.command:
    kubectl annotate nodes {{ hostvars[item].node_name }}
    node.longhorn.io/default-node-tags='["fast","storage"]' --overwrite
  register: annotation_check
  changed_when: "'already has' not in annotation_check.stdout"
  loop: "{{ hostvars[inventory_hostname]['groups']['storage_servers'] }}"
```

This task labels nodes as intended for use by **Longhorn**.

```yaml
- name: "Apply label storage=longhorn on storage nodes"
  ansible.builtin.command:
    kubectl label nodes {{ hostvars[item].node_name }}
    storage='longhorn' --overwrite
  register: label_check
  changed_when: "'already has' not in label_check.stdout"
  loop: "{{ hostvars[inventory_hostname]['groups']['storage_servers'] }}"
```

This task sets the `default disk` configuration for **Longhorn**, defining parameters such as the path, whether to allow scheduling, and specifying the size of reserved memory.

```yaml
- name: "Apply annotation default-disks-config for data and database on storage nodes"
  ansible.builtin.command:
    kubectl annotate nodes {{ hostvars[item].node_name }}
    node.longhorn.io/default-disks-config='[{"name":"data","path":"/mnt/data",
    "allowScheduling":true,"storageReserved":4294967296,"tags":["data","fast"]}]' --overwrite
  register: annotation_check
  changed_when: "'already has' not in annotation_check.stdout"
  loop: "{{ hostvars[inventory_hostname]['groups']['storage_servers'] }}"
```

The task removes the default flag `local-path`.

```yaml
- name: "Remove the default flag from the local-provisioner if it's set to true"
  ansible.builtin.command:
    kubectl patch storageclass local-path -p
    '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
  when: (storage_class_flag.stdout | default('false')) == 'true'
  register: patch_result
  changed_when: '"unchanged" not in patch_result.stderr'
```

## Compliance Check Script

This script checks the environment for compliance with Longhorn requirements.

```yaml
- name: "Download the preconfig script"
  ansible.builtin.get_url:
    url: "https://raw.githubusercontent.com/longhorn/longhorn/v1.7.2/scripts/environment_check.sh"
    dest: "/tmp/environment_check.sh"
    mode: '0755'
  register: script_download
```

```yaml
- name: "Run the preconfig script"
  ansible.builtin.command:
    cmd: "/tmp/environment_check.sh"
  register: script_check
  loop: "{{ hostvars[inventory_hostname]['groups']['storage_servers'] }}"
  loop_control:
    loop_var: server
  changed_when: script_check.stdout | length > 0
```

This task displays the results of a check script.

```yaml
- name: "Print script output"
  ansible.builtin.debug:
    msg: "{{ item.stdout if item.stdout is defined else 'No output or script failed' }}"
  loop: "{{ script_check.results }}"
```

### Labeling Worker Nodes

This task labels all nodes as worker nodes.

```yaml
- name: "Apply label node-role.kubernetes.io/worker=worker"
  ansible.builtin.command:
    kubectl label nodes {{ hostvars[item].node_name }}
    node-role.kubernetes.io/worker='worker' --overwrite
  register: label_check
  changed_when: "'already has' not in label_check.stdout"
  loop: "{{ hostvars[inventory_hostname]['groups']['node'] }}"
```

# Usage

Start provisioning the cluster using the following command:

`make deploy-all`

```shell
Usage:
  make <target>
  deploy-all       Deploy dev-k3s.cluster and copy kube-config
  deploy           Deploy dev-k3s.cluster.
  kubeconfig       Copy 'kubeconfig'.
  reboot           Reboot dev-k3s.cluster.
  shutdown         Shutdown dev-k3s.cluster.
  help             Display this help.
```

## To Do

- support for NVIDIA and Intel GPUs in Kubernetes clusters.
