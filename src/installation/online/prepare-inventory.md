# 准备 Inventory

我们使用 <a target="_blank" rel="noopener noreferrer" href="https://docs.ansible.com/">ansible</a> 安装 K8s 及各种辅助组件，因此，我们需要准备一台电脑作为 <a target="_blank" rel="noopener noreferrer" href="https://docs.ansible.com/ansible/latest/network/getting_started/basic_concepts.html">ansible 控制节点</a>，以运行 ansible 命令，并在这个控制节点上，准备 ansible 的 <a target="_blank" rel="noopener noreferrer" href="https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html">inventory</a>。

## 目的

1. 准备好使用 ansible 的环境；
2. 确认目标集群服务器可通过 ansible 访问。

## 前提条件

可通过网络访问集群的服务器，并具备适当的（root 或者 sudo）访问凭证。

## 基本步骤

首先，在 ansible 控制节点上设置环境，可按照如下步骤执行：

1. 安装 ansible
2. 克隆相关的 git repos
3. 准备本次安装的 inventory 目录

### 安装 ansible

使用 conda 管理 python 环境：

```bash
conda create -n kubespray python=3.10
conda activate kubespray
```

安装 ansible：

```bash
# Use -i https://pypi.tuna.tsinghua.edu.cn/simple or other pypi index may help with slow connections.
python -m pip install -r kubespray/requirements.txt
```

如果无 Internet 链接，可使用本地 python package：

```bash
# use offline package directory
python -m pip install --no-index \
    --find-links=<python-packages-folder> -r kubespray/requirements.txt
```

确认 ansible 安装成功：

```bash
ansible --version
```


### Clone repos

```bash
# create directory and clone repos
mkdir -p ~/ansible
cd ~/ansible

git clone  git@github.com:t9k/ks-clusters.git
git clone git@github.com:t9k/kubespray.git
```

将 kubespray 切换到合适分支：

```bash
# 将 kubespray 切换到合适分支，例如 kubernetes-1.25.9
cd kubespray
git checkout -b kubernetes-<version> origin/kubernetes-<version>
```

### 复制 inventory 模版

集群的所有配置等存放在环境变量 `T9K_CLUSTER` 指向的子目录中：

```bash
# 注意：当使用合适的集群名字
T9K_CLUSTER=demo

# 创建目录
mkdir -p ~/ansible/$T9K_CLUSTER && cd ~/ansible/$T9K_CLUSTER
```

另外，推荐使用 git 对此 inventory 进行版本管理：

```bash
# recommended: version this folder
git init .
```

复制模版文件：

```bash
cd ~/ansible/$T9K_CLUSTER

# for some default configs
cp ../ks-clusters/inventory/ansible.cfg .

# copy a sample inventory to current directory
cp -r ../ks-clusters/inventory/sample-<variant> inventory
```

>  此步骤复制的 `inventory` 子目录里的内容详情见：[Inventory 结构](#inventory-结构)。

### 设置 inventory

<aside class="note">
<div class="title">注意</div>

此部分需要根据集群的实际情况进行填写，例如服务器节点等。

</aside>

在 `inventory.ini` 中填入服务器信息（参考：[节点组](#节点组)）：

```bash
cd ~/ansible/$T9K_CLUSTER

vim inventory/inventory.ini
```

确认 inventory 设置正常：

```bash
# 确认 server 列表
ansible-inventory -i inventory/inventory.ini --list

# 测试可访问
ansible all -m ping -i inventory/inventory.ini
```

更高级的设置，请参考下文。

## 其他


### 使用 jump host

如果需要通过跳板机来连接到 K8s 集群的节点，则使用以下参数来运行 ansible 命令：

``` bash
ansible all -m ping -i inventory/inventory.ini \
  -e 'ansible_ssh_common_args="-o ProxyCommand=\"ssh -q -W %h:%p <user>@<bastion-host>\""'
```

通过 ansible-playbook 命令运行 Kubespray 的脚本时，你可以通过 [配置 bastion host](#配置-bastion-host) 来省略这里的参数。

### 配置 bastion host

Kubespray 的脚本支持使用 Bastion Host，可在 inventory 中设置 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/docs/ansible.md#bastion-host">Bastion host</a>。

修改 `inventory/inventory.ini` 文件，设置以下内容：

```ini
## configure a bastion host if your nodes are not directly reachable
[bastion]
bastion ansible_host=<x.x.x.x> ansible_user=<some_user>
```

然后照常执行安装流程即可。

### 使用 ansible vault

如果需要保存敏感信息，例如 ansible become password，可以使用本章的方式进行配置。

首先创建一个文件保存 ansible vault 的密码：

``` bash
# 从 stdin 读入 vault 密码，并保存在此文件中
cat > ~/ansible/.vault-password.txt

chmod 600 ~/ansible/.vault-password.txt
```

<aside class="note">
<div class="title">注意</div>

`vault-password.txt` 文件应当设置私有的可读权限，以避免泄漏 vault 的密码。该文件也可以使用更加安全的方式，例如 MacOS 的 <a target="_blank" rel="noopener noreferrer" href="https://support.apple.com/guide/keychain-access/what-is-keychain-access-kyca1083/mac">Keychain Access</a> 来保存。

</aside>

创建 `vault.yml` 以保存变量的值：

``` bash
# 创建一个文件夹来保存 vault.yml
mkdir ~/ansible/<cluster-name>

# 使用上面创建的 vault password 加密
# 警告：虽然 vault.yml 被加密，但不要放在公开的代码仓库中，以防止暴力破解等风险
ansible-vault create ~/ansible/<cluster-name>/vault.yml \
  --vault-password-file ~/ansible/.vault-password.txt
```

ansible-vault 命令会打开编辑器，在其中输入：

```
ansible_become_password: <your-become-password>
```

保存之后，ansible-vault 会加密 `vault.yml`，可通过以下命令编辑文件：

``` bash
ansible-vault edit ~/ansible/<cluster-name>/vault.yml \
  --vault-password-file ~/ansible/.vault-password.txt
```

<aside class="note">
<div class="title">注意</div>

如需要给特定 node 设置单独的 `ansible_become_pass`，可在 inventory 中单独设置其 var ：

```ini
[all]
node1 ansible_become_pass="{{ nuc.vault_ansible_become_pass }}"
node2 ansible_become_pass="{{ nc11.vault_ansible_become_pass }}"
```

在 ansible-vault 打开的编辑器中设定 var 的值：

```yaml
node1:
  vault_ansible_become_pass: <become-password-for-node1>
node2:
  vault_ansible_become_pass: <become-password-for-node2>
```
</aside>


运行脚本时，使用 ansible vault 中保存的 ansible become password 时的安装命令为：

``` bash
ansible-playbook ../kubespray/cluster.yml \
  -i inventory/inventory.ini \
  --become \
  -e "@~/ansible/<cluster-name>/vault.yml" \
  --vault-password-file=~/ansible/.vault-password.txt
```


### 复制 SSH 公钥

我们可以一次性地通过 ansible 命令将控制节点的 SSH key 复制到所有受控节点上，以方便之后直接使用 SSH key 进行身份验证。

> TODO: Is sshpass required?

安装 sshpass，以支持 ansible 使用 Password Authentication：

``` bash
# for macOS
brew install esolitos/ipa/sshpass

# for ubuntu
sudo apt install sshpass -y
```

<aside class="note">
<div class="title">注意</div>

使用默认配置的 SSH Server 支持 Password Authentication 功能。如果修改过 SSH Server 的配置，请确认 SSH Server 设置中不包含 "PasswordAuthentication no"。

</aside>

使用 Password Authentication 的 ad-hoc 命令，将本机的 SSH 公钥复制到所有节点 (group all) 上：

```bash
ansible all \
  -i inventory/inventory.ini \
  -m authorized_key \
  -a "user=<user> key={{ lookup('file', '~/.ssh/id_rsa.pub') }}" \
  --ask-pass 
```

验证：

```bash
ansible -i inventory/inventory.ini -m ping all
```

### Inventory 结构

#### 节点组

`inventory.ini` 文件中定义了多个节点组，解释如下。

**Kubespray 节点组**

Kubespray playbooks 使用 `inventory.ini` 中的如下分组：

* `all` - 集群所有节点，可在此设置 `ansible_host`, `ansible_user` 等额外信息；
* `kube_control_plane` - 集群控制平面的节点；
* `etcd` - etcd 服务的节点；
* `kube_node` - K8s 集群的工作节点；
* `ingress-node` - 运行 Ingress controller 的节点，
* `bastion` - 指定 bastion 节点，以支持访问无法直接访问的节点。

<aside class="note info">
<div class="title">节点分组</div>

* 如果一个节点仅在 `kube_node` 中，它会作为工作节点加入 K8s 集群；
* 如果一个节点仅在 `kube_control_plane` 中，它会作为 control plane 节点加入 K8s 集群，并添加 `node-role.kubernetes.io/control-plane:NoSchedule` 的 Taint；
* 如果一个节点同时在 `kube_node` 和 `kube_control_plane` 中，它会作为 control plane 节点加入 K8s 集群，但不添加 `node-role.kubernetes.io/control-plane:NoSchedule` 的 Taint。

</aside>


**其它分组**

下列分组被非 Kubespray playbooks 使用：

* `chronyserver` -  使用 `t9k-playbooks/2-sync-time.yml` 安装 chrony 时，此 group 指定 chrony server 节点；
* `chronyclients` - 同上，安装 chrony 时，此 group 指定 chrony client 节点；
* `nfs_server` -  使用 `t9k-playbooks/10-install-nfs.yml` 安装 nfs 作为集群存储时，需要用这个 group 指定 nfs server 节点（nfs server 只使用一个节点，即此 group 中的第一个节点）。


#### 目录结构

查看文件树：

```bash
# edit this inventory to suit your needs
tree inventory/
```

输出：

```
inventory/
├── group_vars
│   ├── all
│   │   ├── all.yml
│   │   ├── docker.yml
│   │   ├── download.yml
│   │   └── etcd.yml
│   └── k8s_cluster
│       ├── addons.yml
│       └── k8s-cluster.yml
├── inventory.ini
└── patches
    ├── kube-controller-manager+merge.yaml
    └── kube-scheduler+merge.yaml
```

#### 设置的 variables

进一步的查看设置的 variables：

```bash
# review variables
grep -Ev "^$|^\s*#" inventory/group_vars/all/all.yml
grep -Ev "^$|^\s*#" inventory/group_vars/all/docker.yml
grep -Ev "^$|^\s*#" inventory/group_vars/all/download.yml
grep -Ev "^$|^\s*#" inventory/group_vars/all/etcd.yml

grep -Ev "^$|^\s*#" inventory/group_vars/k8s_cluster/addons.yml
grep -Ev "^$|^\s*#" inventory/group_vars/k8s_cluster/k8s-cluster.yml
```


## 下一步

准备好 ansible inventory 之后，即可进行下一步的 [准备节点](./prepare-nodes.md) 工作。

## 参考

<https://docs.ansible.com/>
