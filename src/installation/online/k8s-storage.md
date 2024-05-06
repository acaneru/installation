# 设置集群存储

K8s 集群至少需要安装一个 StorageClass 来提供集群存储服务，即 “<a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/">动态持久卷制备/Dynamic Volume Provisioning</a>”。


我们可以使用多家存储系统产品，例如 NFS, Ceph, Lustre, GPFS 等。

## 使用 NFS

NFS 适合小规模或者测试场景，可通过 ansible 方便的安装，详情见 [安装 NFS 及 StorageClass](./storage-service/nfs.md)。

## 使用 Ceph

1. 获得 Ceph 集群

    Ceph 集群需要单独部署和管理，详情参考：<a target="_blank" rel="noopener noreferrer" href="https://t9k.github.io/ceph-admin-docs/overview.html">Ceph 存储集群管理员手册</a>


1. 配置 K8s 使用 Ceph 集群
   
    运行脚本在 K8s  集群的节点上安装 Ceph packages：

    ```bash
    $ ansible-playbook ../ks-clusters/t9k-playbooks/11-install-ceph-package.yml \
        -i inventory/inventory.ini \
        --become -K
    ```

1. 安装 CSI driver
    
    TODO: DO NOT change the playbook; configure vars in inventory.

    设置 Ceph CSI Driver 的变量（在` ks-clusters/t9k-playbooks/roles/ceph-csi/defaults/main.yml` 中）：

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

    使用 ansible 安装 Ceph CSI Driver：

    ```bash
    ansible-playbook ../ks-clusters/t9k-playbooks/12-install-ceph-csi.yml \
        -i inventory/inventory.ini
    ```

## 使用 Lustre

TODO: Add details.

## 参考

<https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/>

<https://t9k.github.io/ceph-admin-docs/overview.html>
