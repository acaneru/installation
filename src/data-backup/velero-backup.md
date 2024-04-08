# velero 备份

## 前提条件

使用 velero 备份 k8s 集群有以下条件：

1. k8s 集群已安装 volume snapshot 相关 crd 及 controller
1. 每个需要备份的 storage class 具有对应的 volume snapshot class，且 volume snapshot class 拥有 label velero.io/csi-volumesnapshot-class: "true"
1. PVC 的 storage provider（例如 ceph）已使用的存储空间小于 50%
1. k8s 集群已安装 velero server，本地已安装 velero cli，详见[附录：安装 velero server/cli](./reference/install-velero-server-cli.md)

验证条件 1：

```bash
$ kubectl get crd | grep volumesnapshot
volumesnapshotclasses.snapshot.storage.k8s.io              2023-12-07T17:30:08Z
volumesnapshotcontents.snapshot.storage.k8s.io             2023-12-07T17:30:10Z
volumesnapshots.snapshot.storage.k8s.io                    2023-12-07T17:30:12Z

$ kubectl get pod -n kube-system -l app=snapshot-controller
NAME                                   READY   STATUS    RESTARTS   AGE
snapshot-controller-5546c56556-zxg2n   1/1     Running   0          14h
```

验证条件 2：

```bash
$ kubectl get storageclass
NAME         PROVISIONER               RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
cephfs-hdd   cephfs-hdd.csi.ceph.com   Delete          Immediate           true                   7h11m
cephfs-ssd   cephfs-ssd.csi.ceph.com   Delete          Immediate           true                   7h11m

$ kubectl get volumesnapshotclass -l velero.io/csi-volumesnapshot-class=true
NAME                       DRIVER                    DELETIONPOLICY   AGE
cephfs-hdd-snapshotclass   cephfs-hdd.csi.ceph.com   Delete           7h10m
cephfs-ssd-snapshotclass   cephfs-ssd.csi.ceph.com   Delete           7h11m
```

验证条件 3（以 ceph 为例）：

```bash
$ ceph df
--- RAW STORAGE ---
CLASS    SIZE    AVAIL     USED  RAW USED  %RAW USED
hdd    44 TiB   29 TiB   14 TiB    14 TiB      33.06
ssd    13 TiB  9.7 TiB  3.0 TiB   3.0 TiB      23.46
TOTAL  56 TiB   39 TiB   17 TiB    17 TiB      30.90
```

验证条件 4：

```bash
$ velero version
Client:
	Version: v1.12.1
	Git commit: 5c4fdfe147357ec7b908339f4516cd96d6b97c61
Server:
	Version: v1.12.1
```

## 备份

在创建备份之前，可选择性完成以下操作：

1. 为不需要备份的资源添加 label velero.io/exclude-from-backup=true
1. 运行[脚本]()将所有的 t9k job 设为暂停状态，以避免 [status 被删除]()引发的问题

通过以下命令备份整个集群：

```bash
$ velero backup create <backup-name>
```

或者，通过以下命令备份一个或多个 namespace：

```bash
$ velero backup create <backup-name> \
    --include-namespaces <namespace1>,<namespace2>
```

通过以下命令查看备份情况：

```bash
$ velero backup get
$ velero backup describe <backup-name>
$ velero backup describe <backup-name> --details
$ velero backup logs <backup-name>
```

## 恢复

通过以下命令恢复整个集群：

```bash
$ velero restore create --from-backup <backup-name>
```

或者，通过以下命令恢复一个或几个 namespace：

```bash
$ velero restore create --from-backup <backup-name> \
    --include-namespaces <namespace1>,<namespace2>
```

通过以下命令查看恢复情况：

```bash
$ velero restore get
$ velero restore describe <restore-name>
$ velero restore describe <restore-name> --details
$ velero restore logs <restore-name>
```

## 已知问题

### 备份相关问题

#### csi-s3 pvc 备份失败

如果备份集群时，velero 报告如下错误：

```
name: /managed-notebook-86349-0 error: /error executing custom action (groupResource=persistentvolumeclaims, namespace=demo, name=csi-s3-pvc): rpc error: code = Unknown desc = failed to get volumesnapshotclass for storageclass csi-s3: error getting volumesnapshotclass: failed to get volumesnapshotclass for provisioner ru.yandex.s3.csi, ensure that the desired volumesnapshot class has the velero.io/csi-volumesnapshot-class label
```

原因是 csi-s3 类型的 pvc 不支持 volume snapshot。

此类错误可以忽略，恢复集群时 csi-s3 类型的 pvc 将由 storageshim 控制器重新创建，无需备份。

#### cephfs static pvc 备份失败

如果备份集群时，velero 报告如下错误：

```
name: /cephfs-static-pvc error: /error executing custom action (groupResource=persistentvolumeclaims, namespace=demo, name=cephfs-static-pvc): rpc error: code = Unknown desc = error getting storage class: resource name may not be empty
```

原因是 cephfs static pvc 的 `spec.storageClassName` 为空字符串，velero 无法找到对应的 storage class。

此类错误可以忽略，恢复集群时 cephfs static pvc 将由 storageshim 控制器重新创建，无需备份。

### 恢复相关问题

#### pod 绑定 pvc 失败

如果恢复集群后 pod 无法绑定 pvc，出现如下报错：

```bash
$ kubectl describe pod <pod-name>
...
Events:
  Type     Reason            Age                 From               Message
  ----     ------            ----                ----               -------
  Warning  FailedMount       11m (x23 over 42m)  kubelet            MountVolume.MountDevice failed for volume "pvc-dc813e79-a1c7-463e-bf72-351ff532965a" : kubernetes.io/csi: attacher.MountDevice failed to create newCsiDriverClient: driver name cephfs-hdd.csi.ceph.com not found in the list of registered CSI drivers
```

此时需要重启所有 ceph-csi pod，然后等待出错的 pod 自动重试即可：

```bash
$ kubectl delete pod -n cephfs-hdd --all

$ kubectl delete pod -n cephfs-ssd --all
```

#### owner reference 被删除

如果恢复集群后出现如下情况：

* crd 的子资源存在两份（例如每个 notebook 存在两个对应的 pod）
* crd 控制器报错同名的子资源已存在（例如 StorageShim 报错 Resource csi-s3-pvc-tensorstack-dgvuc of Kind Secret already exists and is not managed by StorageShim: conflicting Secret Name）

原因是 velero 在恢复资源时会删除资源的 owner reference 字段。

管理员需要运行[脚本]()删除所有不带 owner reference 的子资源，使得 crd 控制器自动创建带 owner reference 的子资源。

#### status 被删除

如果恢复集群后，本已运行完毕的 t9k job 被重新运行，原因是 velero 在恢复资源时会删除资源的 status 字段。

管理员需要在备份集群之前运行[脚本]()将所有的 t9k job 设置为暂停状态；恢复集群后，用户可自行选择是否重新运行。

#### 创建 crd 被 webhook 拒绝

如果恢复集群后，velero 报告如下错误：

```
error restoring podautoscalers.autoscaling.internal.knative.dev/demo/torch-mnist-mlservice-predict-test-00001: Internal error occurred: failed calling webhook "webhook.serving.knative.dev": failed to call webhook: Post "https://webhook.knative-serving.svc:443/defaulting?timeout=10s": dial tcp 10.233.39.172:443: connect: connection refused
```

原因是创建 crd 时对应的 webhook pod 尚未就绪。

管理员需要根据 velero 的报错信息决定是否需要手动创建这些资源。

#### 已运行完毕的 pod 和 k8s job 没有恢复

如果恢复集群后，原集群中已运行完毕（无论成功还是失败）的 pod 和 k8s job 没有被恢复，这是正常现象。velero 会备份但是不会恢复已运行完毕的 pod 和 k8s job。
