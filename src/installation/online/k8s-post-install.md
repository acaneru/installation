# 安装后配置

### 设置集群存储

#### 使用 nfs

参考文档：[Installing NFS](https://docs.google.com/document/d/1B9s4nx1chGsFaTby8YnVXHnCc8jblxaeBA2QUQZI-zA/edit#heading=h.er81k4h8wpj1)

ks-clusters/t9k-playbooks/roles/nfs/defaults/main.yml 中定义了变量 nfs_server_ip, nfs_share_network，可在运行 playbook 时在命令行设置。

```bash
# nfs_server ip address, e.g. 1.2.3.4
nfs_server_ip: "x.x.x.x"
# only clients with IP addresses in the network can access the share, e.g. 1.2.3.4/24
nfs_share_network: "x.x.x.x/24"
```

运行脚本，并设置 NFS 相关变量：

```bash
$ ansible-playbook ../ks-clusters/t9k-playbooks/10-install-nfs.yml \
  -i inventory/inventory.ini \
  -e nfs_server_ip="x.x.x.x" \
  -e nfs_share_network="x.x.x.x/24" \
  --become -K
```

该脚本中包含了：

* 节点上安装 nfs 相关的包
* 创建 nfs 共享目录
* 在 K8s 集群中创建 NFS CSI Driver
* 运行测试案例

#### 使用 Ceph

参考：<a target="_blank" rel="noopener noreferrer" href="https://t9k.github.io/ceph-admin-docs/overview.html">Ceph 存储集群管理员手册</a>

运行脚本安装 Ceph packages：

```bash
$ ansible-playbook ../ks-clusters/t9k-playbooks/11-install-ceph-package.yml \
    -i inventory/inventory.ini \
    --become -K
```

Ceph 集群的创建需要具体考虑各个节点的情况。TODO：将 Ceph 集群的创建自动化。

设置 Ceph CSI Driver 的变量（在 ks-clusters/t9k-playbooks/roles/ceph-csi/defaults/main.yml 中）：

```yaml
ceph:
  manifests_dir: "{{ kube_config_dir }}/addons/ceph"
  set_default_storage_class: true
  namespace: cephfs-hdd
  storage_class_name: cephfs-hdd
  driver_name: cephfs-hdd.csi.ceph.com
  cluster_id: <your-cluster-id>
  fs_name: k8s_hdd
  admin_id: k8s_hdd
  admin_key: <your-admin-key>
  metrics_port: 8681
  monitors:
  - "100.0.0.1:6789"
  - "100.0.0.2:6789"
...
```

运行脚本安装 Ceph CSI Driver：

```bash
$ ansible-playbook ../ks-clusters/t9k-playbooks/12-install-ceph-csi.yml \
    -i inventory/inventory.ini
```

### 加固集群安全

<https://github.com/kubernetes-sigs/kubespray/blob/master/docs/hardening.md>
