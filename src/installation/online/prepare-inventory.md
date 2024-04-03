# 准备 Inventory

## 基本场景

在 ansible 控制节点上设置环境。

### clone repos

```bash
# create directory and clone repos
mkdir -p ~/ansible/charts
cd ~/ansible
git clone  git@github.com:t9k/ks-clusters.git
git clone git@github.com:t9k/kubespray.git
```

将 kubespray 切换到合适分支

```bash
# 将 kubespray 切换到合适分支，例如 kubernetes-1.25.9
$ cd kubespray
$ git checkout -b kubernetes-<version> origin/kubernetes-<version>
$ cd ..
```

### 安装 ansible

使用 conda 管理 python 环境。

```bash
$ conda create -n kubespray python=3.10
$ conda activate kubespray

# Use -i https://pypi.tuna.tsinghua.edu.cn/simple or other pypi index may help with slow connections.
$ python -m pip install -r kubespray/requirements.txt

# If in offline enviroment
$ python -m pip install --no-index \
    --find-links=<python-packages-folder> -r kubespray/requirements.txt
```

### 准备 inventory

集群的所有配置等存放在一个子目录 $T9K_CLUSTER 中。

```bash
$ T9K_CLUSTER=demo
# mkdir for cluster-specific files; 
$ mkdir -p $T9K_CLUSTER && cd $T9K_CLUSTER

# recommended: version this folder
$ git init .

# for some default configs
$ cp ../ks-clusters/inventory/ansible.cfg .

# 1. copy a sample inventory to current directory
cp -r ../ks-clusters/inventory/sample-<variant> inventory

# 2. edit this inventory to suit your needs
$ tree inventory/
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

# 3. review variables
grep -Ev "^$|^\s*#" inventory/group_vars/all/all.yml
grep -Ev "^$|^\s*#" inventory/group_vars/all/docker.yml
grep -Ev "^$|^\s*#" inventory/group_vars/all/download.yml
grep -Ev "^$|^\s*#" inventory/group_vars/all/etcd.yml

grep -Ev "^$|^\s*#" inventory/group_vars/k8s_cluster/addons.yml
grep -Ev "^$|^\s*#" inventory/group_vars/k8s_cluster/k8s-cluster.yml
```

## 其他

### 使用 jump host

### 使用 ansible vault

### 复制 SSH 公钥
