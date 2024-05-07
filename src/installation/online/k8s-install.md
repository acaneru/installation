# 安装 K8s

## 目的

完成一个最基本的 K8s 集群安装。

## 前提条件

准备好了 inventory 并且服务器节点满足要求，可按照前述 [准备 Inventory](./prepare-inventory.md) 和 [准备节点](./prepare-nodes.md) 步骤执行。

## 配置

 TODO：描述如何设置 CRI, CNI, Ingress, LoadBalancer 等的选项。

## 安装集群

进入为此次安装准备的 inventory 目录：

```bash
cd ~/ansible/$T9K_CLUSTER 
```

运行 ansible 脚本，以安装 K8s 集群。

方法 1 - 交互式输入 become password：

```bash
ansible-playbook ../kubespray/cluster.yml \
  -i inventory/inventory.ini \
  --become -K
```

方法 2 - 使用 ansible vault 中保存的 become password：

```bash
ansible-playbook ../kubespray/cluster.yml \
    -i inventory/inventory.ini \
    --become \
    -e "@~/ansible/<cluster-name>/vault.yml" \
    --vault-password-file=~/ansible/.vault-password.txt
```

<aside class="note">
<div class="title">参数解释</div>

```
--become: 使用其它用户运行操作，默认使用 root 用户。
-K: 询问 become 所需的权限升级密码 (become password)。
-e: 设置额外的变量，@说明通过文件传入。
--vault-password-file: 保存了 vault 密码的文件。
```
</aside>

## 过程解释

### 脚本内容

集群安装脚本 `cluster.yml` 需要执行 ~1300 个 ansible Tasks，可以通过下面的命令输出完整的 Task 列表：

```bash
ansible-playbook ../kubespray/playbooks/cluster.yml \
    -i inventory/inventory.ini \
    --list-tasks
```

### 安装时常

安装 K8s 集群所需要的时间受网络下载速度（主要因素）、节点性能、节点当前状态影响。

初次运行该脚本的用时通常在 30 分钟到 1 小时范围内。其中，命令行工具、镜像等内容的下载约 25 分钟，下载之外的运行时间约 20 分钟。

### 安装进度

Ansible 在执行过程中会输出当前运行的 Task 名称（方括号中的内容），及对每个节点的运行结果。格式如下：

```
TASK [reset : reset | Restart network]********************************
changed: [nc12]
changed: [nc13]
changed: [nc11]
changed: [nuc]
changed: [nc14]
```

### 查看结果

Ansible playbook 在运行结束后会输出一个运行回顾，示例如下：

```
PLAY RECAP *****************************************************************************************************
localhost                  : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
nc11                       : ok=609  changed=35   unreachable=0    failed=0    skipped=1108 rescued=0    ignored=1   
nc12                       : ok=452  changed=22   unreachable=0    failed=0    skipped=758  rescued=0    ignored=1   
nc13                       : ok=610  changed=34   unreachable=0    failed=0    skipped=1107 rescued=0    ignored=1  
nc14                       : ok=452  changed=22   unreachable=0    failed=0    skipped=758  rescued=0    ignored=1   
nuc                        : ok=728  changed=45   unreachable=0    failed=0    skipped=1237 rescued=0    ignored=7
```

如果出现异常，需进一步检查：

1. unreachable: 如果有节点显示为不可达，那么您应该检查该节点状态和网络连接。
2. failed: 如果有任务失败，那么您应该检查失败原因，并尝试解决问题。
3. ignored: 如果有错误被忽略，那么您应该检查忽略原因，并确定是否需要采取进一步的措施。这一步可以参考[常见 ignored fatal](https://docs.google.com/document/d/13X6vAjNVKEtzG6H5ydSNPcMx3Sbzzh1LFaFA-UKqBIo/edit#heading=h.rkmh2bn7pw2c)。

如果安装完成后，部分节点的 unreachable 或 failed 不为 0，则需要处理错误。

### 常见失败原因

安装过程中，有以下常见失败原因：

1. 镜像、命令行工具下载失败
    1. 设置的镜像名称错误
    1. Registry 不可访问，或者网络不通、不稳定
1. 验证未通过
    1. 重启 cri-dockerd 等系统服务时，等待时间超过预设值
    1. 用户配置不符合要求，如 etcd 节点数量为偶数
1. 节点遗留设置与现有设置冲突，导致命令运行出错
    1. 节点中设置了额外的 apt 源，导致冲突
    1. 节点中已经安装了新版本 docker，导致试图安装指定版本时失败

## 获取 kubeconfig

集群安装成功之后，可获取其 kubeconfig，以开始使用。

### 从 inventory 获取

如果设置了安装过程中复制 kubeconfig（`kubeconfig_localhost: true`，文件 `group_vars/k8s_cluster/k8s-cluster.yml`），可以在 `inventory/artifacts` 目录中找到 `admin.conf`（cluster-admin 权限）：

```bash
cp inventory/artifacts/admin.conf \
    ~/.kube/example-cluster.conf
```

<aside class="note">
<div class="title">注意</div>

ks-clusters 的 git repo 里已经配置了 `.gitignore` 文件以避免 `admin.conf` 文件被保存到 git repo 中，但仍需要谨慎操作，避免错误地把 `admin.conf` 放入 git 中，造成安全隐患。

</aside>

### 从 control-plane 节点获取

无论是否设置了 `kubeconfig_localhost`，都可以直接从 control-plane 节点获取 kubeconfig。

假设 `master01` 是一个 control-plane 节点，其 IP 为 `100.64.100.11`。

1. 复制 kubeconfig 文件

    ```bash
    ssh -t master01 'sudo cat /root/.kube/config' |tee ~/.kube/example-cluster.conf
    sed -i "1d" $HOME/.kube/example-cluster.conf
    ```

2. 替换 kubeconfig 中的 server 地址
   
   如果未配置 HA 模式，则直接使用 control-plane 节点的 IP 地址 + 端口（`100.64.100.11:6443`）：

    ```bash
    sed -i 's|^    server: https://.*|    server: https://100.64.100.11:6443|' \
        ~/.kube/example-cluster.conf
    ```

    如果使用 kube vip 配置了高可用集群，则应当将 server 地址设置为 kube vip 的 virtual IP 和 port，或其它 HA 场景的适当设置。


##  集群检查

验证 kubeconfig 可用，并查看集群中的节点信息：

```bash
KUBECONFIG=~/.kube/example-cluster.conf kubectl get node
```

## 下一步

- [设置集群存储](./k8s-storage.md)
