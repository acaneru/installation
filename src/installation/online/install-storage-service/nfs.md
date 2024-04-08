# NFS

本文档是在选定的单个节点上安装一个 NFS 服务，并基于该服务在 K8s 集群中安装 NFS CSI driver 和相应的 StorageClass nfs-csi。参考文档为[准备节点与安装 K8s](../prepare-nodes-and-install-k8s.md) 以及 [Installing NFS](https://docs.google.com/document/d/1B9s4nx1chGsFaTby8YnVXHnCc8jblxaeBA2QUQZI-zA/edit#heading=h.er81k4h8wpj1)。

## 前置条件

准备 Inventory，并完成 K8s 集群的部署。

## 设置变量

在 `~/ansible/ks-clusters/inventory/inventory.ini` 中，将合适的节点设置为 nfs_server：

```ini
[nfs_server] # group nfs_server 仅可设置一个节点，多余的节点会被忽略
node-name
```

## 安装

[离线安装场景]修改镜像仓库的设置：

```bash
$ cd ~/ansible/ks-clusters/t9k-playbooks/roles/nfs
$ vim defaults/main.yml
# change docker_image_repo
$ diff -u main.yml new-main.yml 
--- main.yml	2023-12-05 15:52:37.000000000 +0800
+++ new-main.yml	2023-12-12 18:09:27.000000000 +0800
@@ -1,7 +1,7 @@
 # default settings in the inventory
 kube_config_dir: "/etc/kubernetes"
 bin_dir: "/usr/local/bin"
-docker_image_repo: "docker.io/t9kpublic"
+docker_image_repo: "192.169.101.159:5000/t9kpublic"
 
 # directory on control_plane[0] to save nfs manifests
 nfs_manifests_dir: "{{ kube_config_dir }}/addons/nfs"
```

安装 nfs：

```bash
$ cd ~/ansible/<cluster>

# 方法 1: 交互式输入 become password
$ ansible-playbook ../ks-clusters/t9k-playbooks/10-install-nfs.yml \
    -i inventory/inventory.ini \
    --become -K \
    -e nfs_server_ip="x.x.x.x" \
    -e nfs_share_network="x.x.x.x/24"

# 方法 2: 使用 ansible vault 中保存的 become password
$ ansible-playbook ../ks-clusters/t9k-playbooks/10-install-nfs.yml \
    -i inventory/inventory.ini \
    --become \
    -e "@~/ansible/<new-cluster-name>-<version>/vault.yml" \
    --vault-password-file=~/.vault-password.txt \
    -e nfs_server_ip="x.x.x.x" \
    -e nfs_share_network="x.x.x.x/24"
```

该脚本中包含了：
1. 在所有节点上安装 nfs 的基础包 nfs-common
1. 在 nfs_server 节点创建 nfs 共享目录，运行 nfs 服务
1. 在 K8s 集群中创建 NFS CSI Driver，创建 StorageClass nfs-csi
1. 运行测试用例
    1. 使用 storageClass nfs-csi 创建 PVC
    1. 创建 Pod 挂载该 PVC
        1. 向 PVC 路径写入一段特定字符串
        1. Pod 中运行 cat 命令，获取刚写入的文件内容作为 Pod log
    1. 等待 Pod 状态变为 Succeeded
    1. 验证 Pod log 是否和特定字符串一致
    1. 删除测试用例

## 验证

Playbook 的最后包含了测试案例。见上一章节。

### 检查 Package

检查节点中的 nfs package：

* 所有集群中的节点（具体节点可参见 <a target="_blank" rel="noopener noreferrer" href="https://github.com/t9k/ks-clusters/blob/master/t9k-playbooks/10-install-nfs.yml#L1">playbook</a>）都需要安装了 nfs-common；
* nfs-server 的节点额外需要 nfs-kernel-server。

```bash
$ dpkg --get-selections | grep nfs
libnfs13:amd64					install
libnfsidmap2:amd64				install
nfs-common					install
nfs-kernel-server				install
```

### 测试 NFS server

测试 nfs-server，首先在 nfs-server 中创建文件：

```bash
# 进入 nfs_dir 路径，默认值是 /data/nfs_share
$ cd /data/nfs_share
$ echo "Hello World!" > test.txt
```

然后在另一个 nfs_share_network 地址范围内的节点运行：

```bash
$ sudo mkdir -p /mnt/nfs_client_on_nfs_server

# nfs_server_ip 见上文设置，nfs_dir 默认值为 /data/nfs_share
$ sudo mount -t nfs <nfs_server_ip>:<nfs_dir> \
    /mnt/nfs_client_on_nfs_server

# 期望的测试结果
$ cat /mnt/nfs_client_on_nfs_server/test.txt
Hello World!

# clean up
$ sudo umount /mnt/nfs_client_on_nfs_server
$ sudo rmdir /mnt/nfs_client_on_nfs_server
```

### 检查 NFS CSI Driver

查看 Pod 运行状态：

```bash
$ kubectl -n kube-system get pod -l app=csi-nfs-controller
NAME                                  READY   STATUS    RESTARTS         AGE
csi-nfs-controller-6b9894ff59-p6fgj   4/4     Running   15 (2d18h ago)   27d

$ kubectl -n kube-system get pod -l app=csi-nfs-node
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
$ kubectl get sc
NAME                PROVISIONER      RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
nfs-csi (default)   nfs.csi.k8s.io   Delete          Immediate           false                  14d
```
