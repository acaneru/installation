# velero 备份

## 前提条件

使用 velero 备份 k8s 集群有以下条件：

1. k8s 集群已安装 volume snapshot 相关 crd 及 controller
1. 每个需要备份的 storage class 具有对应的 volume snapshot class，且 volume snapshot class 拥有 label` velero.io/csi-volumesnapshot-class: "true"`
1. PVC 的 storage provider（例如 ceph）已使用的存储空间小于 50%
1. k8s 集群已安装 velero server，本地已安装 velero cli，详见 [附录：安装 velero server/cli](./appendix/install-velero-server-cli.md)

验证条件 1：

```bash
kubectl get crd | grep volumesnapshot
```

```
volumesnapshotclasses.snapshot.storage.k8s.io              2023-12-07T17:30:08Z
volumesnapshotcontents.snapshot.storage.k8s.io             2023-12-07T17:30:10Z
volumesnapshots.snapshot.storage.k8s.io                    2023-12-07T17:30:12Z
```

```
kubectl get pod -n kube-system -l app=snapshot-controller
```

```
NAME                                   READY   STATUS    RESTARTS   AGE
snapshot-controller-5546c56556-zxg2n   1/1     Running   0          14h
```

验证条件 2：

```bash
kubectl get storageclass
```

```
NAME         PROVISIONER               RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
cephfs-hdd   cephfs-hdd.csi.ceph.com   Delete          Immediate           true                   7h11m
cephfs-ssd   cephfs-ssd.csi.ceph.com   Delete          Immediate           true                   7h11m
```

```
kubectl get volumesnapshotclass -l velero.io/csi-volumesnapshot-class=true
```

```
NAME                       DRIVER                    DELETIONPOLICY   AGE
cephfs-hdd-snapshotclass   cephfs-hdd.csi.ceph.com   Delete           7h10m
cephfs-ssd-snapshotclass   cephfs-ssd.csi.ceph.com   Delete           7h11m
```

验证条件 3（以 ceph 为例）：

```bash
ceph df
```

```
--- RAW STORAGE ---
CLASS    SIZE    AVAIL     USED  RAW USED  %RAW USED
hdd    44 TiB   29 TiB   14 TiB    14 TiB      33.06
ssd    13 TiB  9.7 TiB  3.0 TiB   3.0 TiB      23.46
TOTAL  56 TiB   39 TiB   17 TiB    17 TiB      30.90
```

验证条件 4：

```bash
velero version
```

```
Client:
	Version: v1.12.1
	Git commit: 5c4fdfe147357ec7b908339f4516cd96d6b97c61
Server:
	Version: v1.12.1
```

## 备份

在创建备份之前，可选择性完成以下操作：

1. 为不需要备份的资源添加 label `velero.io/exclude-from-backup=true`
1. 运行 [脚本](tbd.sh) 将所有的 t9k job 设为暂停状态，以避免 [status 被删除](#status-被删除)引发的问题

备份整个集群：

```bash
velero backup create <backup-name>
```

或者，备份一个或多个 namespace：

```bash
velero backup create <backup-name> \
  --include-namespaces <namespace1>,<namespace2>
```

查看备份情况：

```bash
velero backup get
velero backup describe <backup-name>
velero backup describe <backup-name> --details
velero backup logs <backup-name>
```

## 恢复

恢复整个集群：

```bash
velero restore create --from-backup <backup-name>
```

或者，通过以下命令恢复一个或几个 namespace：

```bash
velero restore create --from-backup <backup-name> \
  --include-namespaces <namespace1>,<namespace2>
```

通过以下命令查看恢复情况：

```bash
velero restore get
velero restore describe <restore-name>
velero restore describe <restore-name> --details
velero restore logs <restore-name>
```

## 参考

<https://github.com/vmware-tanzu/velero>

[已知问题](./velero-backup-issues.md)
