# 准备 Inventory

我们使用 <a target="_blank" rel="noopener noreferrer" href="https://docs.ansible.com/">ansible</a> 安装 K8s 及各种辅助组件，因此，我们需要准备一台电脑作为 <a target="_blank" rel="noopener noreferrer" href="https://docs.ansible.com/ansible/latest/network/getting_started/basic_concepts.html">ansible 控制节点</a>，以运行 ansible 命令，并在这个控制节点上，准备 ansible 的 <a target="_blank" rel="noopener noreferrer" href="https://docs.ansible.com/ansible/latest/inventory_guide/intro_inventory.html">inventory</a>。

## 基本步骤

首先，在 ansible 控制节点上设置环境。可按照如下步骤执行：

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
cd ..
```

### 准备 inventory

集群的所有配置等存放在环境变量 T9K_CLUSTER 指向的子目录中：

```bash
cd ~/ansible

T9K_CLUSTER=demo
mkdir -p $T9K_CLUSTER && cd $T9K_CLUSTER
```

另外，推荐使用 git 对此 inventory 进行版本管理：

```bash
# recommended: version this folder
git init .
```

复制模版文件：

```bash
# for some default configs
cp ../ks-clusters/inventory/ansible.cfg .

# copy a sample inventory to current directory
cp -r ../ks-clusters/inventory/sample-<variant> inventory
```

查看文件树：

```bash
# edit this inventory to suit your needs
tree inventory/
```

目录结构：
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


## 其他

TODO: Finish this section.

### 使用 jump host

### 使用 ansible vault

### 复制 SSH 公钥

## 下一步

准备好 ansible inventory 之后，我们可进行[准备节点](./prepare-nodes.md) 的工作。

## 参考

<https://docs.ansible.com/>
