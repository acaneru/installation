# 基本设置

## 目的

1. 准备好使用 ansible 的环境；
2. 确认目标集群服务器可通过 ansible 访问。

## 前提条件

可通过网络访问集群的服务器，并具备适当的（root 或者 sudo）访问凭证。

## 准备环境

首先，在 ansible 控制节点上设置环境，按照如下步骤执行：

1. 克隆相关的 git repos
2. 安装 ansible
3. 复制 inventory 模版

### 克隆 repos

```bash
# create directory and clone repos
mkdir -p ~/ansible
cd ~/ansible

git clone git@github.com:t9k/ks-clusters.git
git clone git@github.com:t9k/kubespray.git
```

将 kubespray 切换到合适分支：

```bash
# 将 kubespray 切换到合适分支，例如 kubernetes-1.25.9
cd kubespray
git checkout -b kubernetes-<version> origin/kubernetes-<version>
```

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

>  此步骤复制的 `inventory` 子目录里的内容详情见：[inventory 结构](./inventory-advanced.md#inventory-结构)。

## 设置 inventory

<aside class="note">
<div class="title">注意</div>

此部分需要根据集群的实际情况进行填写，例如服务器节点等。

</aside>

在 `inventory.ini` 中填入服务器信息（参考：[节点组](./inventory-advanced.md#节点组)）：

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

有关 inventory 更多的设置，请参考 [inventory 高级设置](./inventory-advanced.md)。


## 下一步

准备好 ansible inventory 之后，即可进行下一步的 [准备节点](../prepare-nodes.md) 工作。

## 参考

<https://docs.ansible.com/>
