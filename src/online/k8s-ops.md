# 集群维护

## 集群节点

### Worker 节点

> 参考：<https://github.com/kubernetes-sigs/kubespray/blob/master/docs/operations/nodes.md#addingreplacing-a-worker-node>

#### 增加 worker 节点

1. 修改 inventory.ini，下面是一个增加节点（nc15，worker node）的示例：
    
    <details><summary><code class="hljs">diff -u inventory-old.ini inventory-new.ini</code></summary>

    ```diff
    --- inventory-old.ini
    +++ inventory-new.ini
    @@ -1,6 +1,7 @@
    [all]
    nuc ansible_host=nuc
    nc11 ansible_host=nc11
    nc12 ansible_host=nc12
    nc13 ansible_host=nc13
    nc14 ansible_host=nc14
    +nc15 ansible_host=nc15

    @@ -18,6 +19,7 @@
    [kube_node]
    nuc
    nc11
    nc12
    nc13
    nc14
    +nc15
    ```

    </details>

2. 更新 facts

    ```bash
    ansible-playbook ../kubespray/playbooks/facts.yml \
        -i inventory/inventory.ini \
        --become -K
    ```

    <aside class="note">
    <div class="title">注意</div>

    kubespray 1.24.10 及之前的版本，需要运行 kubespray/facts.yml。1.25.9 之后 kubespray 移除了 kubespray/facts.yml 文件，作为代替的是 playbooks 文件夹中的 facts.yml。

    </aside>

3. 运行 kubespray 脚本来添加节点：

    ```bash
    # add node nc15
    ansible-playbook ../kubespray/scale.yml \
        -i inventory/inventory.ini \
        --become -K \
        --limit nc15
    ```

    <aside class="note">
    <div class="title">注意</div>

    使用命令行参数 `--limit nc15` 限制 playbook 的执行范围在 nc15 节点上，保障其他节点不受影响。如果有多个节点需要添加，使用例如 `--limit nc15,nc16` 的格式指定。

    </aside>

#### 移除 worker 节点

1. 更新 facts：

    ```bash
    ansible-playbook ../kubespray/playbooks/facts.yml \
        -i inventory/inventory.ini \
        --become -K
    ```

2. 运行 kubespray 脚本来删除节点：

    ```bash
    # remove node nc12
    ansible-playbook ../kubespray/remove-node.yml \
        -i inventory/inventory.ini \
        --become -K \
        -e node=nc12 --limit nc12 
    ```

    <aside class="note">
    <div class="title">注意</div>

    使用命令行参数 `-e` 设置 node 变量，指定要移除的节点。如果有多个节点需要移除，使用例如 `-e node=nc12,nc13 --limit nc12,nc13` 的格式指定。

    </aside>

3. 修改 inventory 文件，删去已经移除的节点。

### Control plane 节点

对 control plane 节点的修改需要运行 cluster.yml，具体请参考文档：

1. <https://github.com/kubernetes-sigs/kubespray/blob/master/docs/operations/nodes.md#addingreplacing-a-control-plane-node>
1. <https://github.com/kubernetes-sigs/kubespray/blob/master/docs/operations/nodes.md#replacing-a-first-control-plane-node>

## 集群拆除

<aside class="note warning">
<div class="title">警告</div>

1. 集群的拆除是不可逆的，在运行之前请确认您已经备份了集群中的重要数据；
1. 这里描述的方法仅限于使用 kubespray 部署的集群，并且要和集群部署时使用的 kubespray 版本和 inventory 一致。

</aside>

拆除集群：

```bash
ansible-playbook ../kubespray/reset.yml \
    -i inventory/inventory.ini \
    --become -K
```

## 升级 K8s 版本

<aside class="note">
<div class="title">注意</div>

1. 在升级集群之前，查看 <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/releases/#release-history">Release History</a> 的 Changelog 以了解 K8s 做了什么修改，并判断这些修改是否会影响您集群中的工作负载。
1. 检查 kubespray 的 kubeadm_checksums 变量的值来确定目标 K8s 版本是否被支持。这个变量位于 role download 的 defaults 文件夹中，可能是 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/v2.22.1/roles/download/defaults/main.yml#L488">main.yml</a> 或者 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/roles/download/defaults/main/checksums.yml#L292">main/checksums.yml</a>。
1. 升级时，请使用 T9k 提供的 kubespray 的相邻版本进行升级，不要跨多个版本升级。

</aside>

步骤：

1. 将 kubespray 切换到合适的分支
1. 修改 inventory，指定合适的 `kube_version`，`docker_version` 等计划升级的版本
1. 运行升级脚本：

```bash
ansible-playbook ../kubespray/upgrade-cluster.yml \ 
    -i inventory/inventory.ini \
    --become \
    -e "@~/nc15-1.25.9/vault.yml" \
    --vault-password-file=~/ansible/.vault-password.txt
```

<details><summary><code class="hljs">运行成功的 PLAY RECAP 示例</code></summary>

```
PLAY RECAP *********************************************
localhost                  : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
nc12                       : ok=483  changed=32   unreachable=0    failed=0    skipped=814  rescued=0    ignored=1   
nc14                       : ok=483  changed=32   unreachable=0    failed=0    skipped=814  rescued=0    ignored=1   
nc15                       : ok=742  changed=61   unreachable=0    failed=0    skipped=1561 rescued=0    ignored=1
```

</details>

## 参考

<https://github.com/kubernetes-sigs/kubespray/blob/master/docs/operations/nodes.md>

<https://github.com/kubernetes-sigs/kubespray/blob/master/docs/operations/upgrades.md>
