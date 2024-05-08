# 安装 K8s

```
TODO：
    1. 描述如何设置 CRI, CNI, Ingress, LoadBalancer 等的选项。
```

## 目的

完成一个最基本的 K8s 集群安装。

## 前提条件

准备好了 inventory 并且服务器节点满足要求，可按照前述 [准备 Inventory](./prepare-inventory.md) 和 [准备节点](./prepare-nodes.md) 步骤执行。

## 配置

## 安装 K8s

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
    -e "@~/ansible/$T9K_CLUSTER/vault.yml" \
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

> 使用 ansible 安装 K8s 过程的更多详情，请参考：[安装 K8s 注释 > 过程解释](../appendix/k8s-install-notes.md#过程解释)

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

## 参考

- [使用 ansible 安装 K8s 过程的注释](../appendix/k8s-install-notes.md)