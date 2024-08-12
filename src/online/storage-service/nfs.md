# NFS 和 StorageClass

本文档是在 K8s 集群选定的单个节点上安装一个 NFS 服务，并基于该服务在 K8s 集群中安装 NFS CSI driver 和相应的 StorageClass `nfs-csi`。

<aside class="note">
<div class="title">注意</div>

使用 NFS 作为 K8s 集群存储仅在小规模或者测试场景下适用。

</aside>

## 前置条件

完成 [K8s 基本集群](../k8s-install.md)的部署。

## 安装

如直接使用 Internet 的镜像仓库（例如 docker hub、阿里云等）安装，则跳过 “离线设置” 部分。

### 离线设置

<aside class="note">
<div class="title">注意</div>

如果[离线安装 K8s 集群](../../offline/install/k8s.md#安装-k8s-集群)时已经设置过这个变量，则检查变量设置符合预期即可。

</aside>

如果无 Internet 连接，需要使用本地设置的容器镜像仓库，设置如下：

```bash
# 进入为此次安装准备的 inventory 目录
cd ~/ansible/$T9K_CLUSTER

# 修改 inventory/group_vars/all/download.yml
vim inventory/group_vars/all/download.yml
```

下面的示例使用运行在 `192.169.101.159:5000` 的 image registry：

```diff
diff -u ./inventory/group_vars/all/download.yml ./inventory/group_vars/all/new-download.yml
--- ./inventory/group_vars/all/download.yml
+++ ./inventory/group_vars/all/new-download.yml
@@ -16,7 +16,7 @@
 ## Container Registry overrides
 gcr_image_repo: "docker.io/t9kpublic"
 kube_image_repo: "docker.io/t9kpublic"
-docker_image_repo: "docker.io/t9kpublic"
+docker_image_repo: "192.169.101.159:5000/t9kpublic"
 quay_image_repo: "docker.io/t9kpublic"
 # github_image_repo: "{{ registry_host }}"
```



### 设置变量

在 `~/ansible/$T9K_CLUSTER/inventory/inventory.ini` 中，将选定的节点放在节点组 `nfs_server` 中：

```ini
[nfs_server] # group nfs_server 仅可设置一个节点，多余的节点会被忽略
node-name
```


### 运行 ansible

安装 nfs。注意，需要手工指定 2 个变量的值 `nfs_server_ip, nfs_share_network`：

```bash
cd ~/ansible/$T9K_CLUSTER

# 方法 1: 交互式输入 become password
ansible-playbook ../ks-clusters/t9k-playbooks/10-install-nfs.yml \
  -i inventory/inventory.ini \
  --become -K \
  -e nfs_server_ip="x.x.x.x" \
  -e nfs_share_network="x.x.x.x/24"

# 方法 2: 使用 ansible vault 中保存的 become password
ansible-playbook ../ks-clusters/t9k-playbooks/10-install-nfs.yml \
  -i inventory/inventory.ini \
  --become \
  -e "@~/ansible/$T9K_CLUSTER/vault.yml" \
  --vault-password-file=~/ansible/.vault-password.txt \
  -e nfs_server_ip="x.x.x.x" \
  -e nfs_share_network="x.x.x.x/24"
```

该 ansible 脚本执行如下操作：

1. 在所有节点上安装 nfs 的基础包 `nfs-common`
1. 在 nfs_server 节点创建 nfs 共享目录；运行 nfs 服务
1. 在 K8s 集群中安装 NFS CSI Driver，创建 StorageClass `nfs-csi`
1. 运行测试用例
    1. 使用 storageClass `nfs-csi` 创建 PVC
    1. 创建 Pod 挂载该 PVC
        1. 向 PVC 路径写入一段特定字符串
        1. Pod 中运行 `cat` 命令，获取刚写入的文件内容作为 Pod log
    1. 等待 Pod 状态变为 `Succeeded`
    1. 验证 Pod log 是否和特定字符串一致
    1. 删除测试用例

## 验证

安装过程的最后步骤包含了使用此 NFS 的测试案例，详情见上一小节。

还可以运行如下步骤，手工验证安装的 pacakges 和服务。

### 检查 Package

检查节点中的 nfs package：

* 所有集群中的节点（具体节点可参见 <a target="_blank" rel="noopener noreferrer" href="https://github.com/t9k/ks-clusters/blob/master/t9k-playbooks/10-install-nfs.yml#L1">playbook</a>）都需要安装了 nfs-common；
* nfs-server 的节点额外需要 nfs-kernel-server。

```bash
# use apt to show installed pacakgess
apt list --installed | grep nfs

# or, use dpkg
dpkg --get-selections | grep nfs
```

输出：

```console
libnfs13:amd64					install
libnfsidmap2:amd64				install
nfs-common					install
nfs-kernel-server				install
```

### 测试 NFS server

测试 nfs-server，首先在 nfs-server 中创建文件：

```bash
# 进入 nfs_dir 路径，默认值是 /data/nfs_share
cd /data/nfs_share
echo "Hello World!" > test.txt
```

然后在另一个 nfs_share_network 地址范围内的节点运行：

```bash
sudo mkdir -p /mnt/nfs_client_on_nfs_server

# nfs_server_ip 见上文设置，nfs_dir 默认值为 /data/nfs_share
sudo mount -t nfs <nfs_server_ip>:<nfs_dir> \
  /mnt/nfs_client_on_nfs_server

cat /mnt/nfs_client_on_nfs_server/test.txt
```

期望的测试结果：

```console
Hello World!
```

卸载：

```bash
sudo umount /mnt/nfs_client_on_nfs_server
sudo rmdir /mnt/nfs_client_on_nfs_server
```

### 检查 NFS CSI Driver

查看 Controller Pod 运行状态：

```bash
kubectl -n kube-system get pod -l app=csi-nfs-controller
```

输出：

```console
NAME                                  READY   STATUS    RESTARTS         AGE
csi-nfs-controller-6b9894ff59-p6fgj   4/4     Running   15 (2d18h ago)   27d
```

查看 Node Pods：

```bash
kubectl -n kube-system get pod -l app=csi-nfs-node
```

输出：

```console
NAME                 READY   STATUS    RESTARTS          AGE
csi-nfs-node-sd8vl   3/3     Running   9 (37d ago)       77d
csi-nfs-node-tppsd   3/3     Running   6 (38d ago)       77d
csi-nfs-node-xm94s   3/3     Running   261 (2d18h ago)   77d
```

说明如下：

* csi-nfs-controller 用于处理创建、删除、管理 PV 和 PVC 的请求，期望的 Pod 数量为 1。
* csi-nfs-node 用于在每个节点上挂载和卸载存储卷，以支持 Pod 使用 PVC。期望的 Pod 数量与 K8s 集群节点数量相同。

检查 K8s 中的 Storage Class：

```bash
kubectl get sc
```

输出：

```console
NAME                PROVISIONER      RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
nfs-csi (default)   nfs.csi.k8s.io   Delete          Immediate           false                  14d
```

## 参考

<https://github.com/kubernetes-csi/csi-driver-nfs>
