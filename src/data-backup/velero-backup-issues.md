# 已知问题

## 备份

### csi-s3 pvc 备份失败

如果备份集群时，velero 报告如下错误：

```
name: /managed-notebook-86349-0 error: /error executing custom action (groupResource=persistentvolumeclaims, namespace=demo, name=csi-s3-pvc): rpc error: code = Unknown desc = failed to get volumesnapshotclass for storageclass csi-s3: error getting volumesnapshotclass: failed to get volumesnapshotclass for provisioner ru.yandex.s3.csi, ensure that the desired volumesnapshot class has the velero.io/csi-volumesnapshot-class label
```

原因是 csi-s3 类型的 pvc 不支持 volume snapshot。

此类错误可以忽略，恢复集群时 csi-s3 类型的 pvc 将由 storageshim 控制器重新创建，无需备份。

### cephfs static pvc 备份失败

如果备份集群时，velero 报告如下错误：

```
name: /cephfs-static-pvc error: /error executing custom action (groupResource=persistentvolumeclaims, namespace=demo, name=cephfs-static-pvc): rpc error: code = Unknown desc = error getting storage class: resource name may not be empty
```

原因是 cephfs static pvc 的 `spec.storageClassName` 为空字符串，velero 无法找到对应的 storage class。

此类错误可以忽略，恢复集群时 cephfs static pvc 将由 storageshim 控制器重新创建，无需备份。

## 恢复

### pod 绑定 pvc 失败

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
# StorageClass 1  installed in cephfs-hdd
kubectl delete pod -n cephfs-hdd --all

# StorageClass 2  installed in cephfs-hdd
kubectl delete pod -n cephfs-ssd --all
```

### owner reference 被删除

如果恢复集群后出现如下情况：

* crd 的子资源存在两份（例如每个 notebook 存在两个对应的 pod）
* crd 控制器报错同名的子资源已存在（例如 StorageShim 报错 Resource csi-s3-pvc-tensorstack-dgvuc of Kind Secret already exists and is not managed by StorageShim: conflicting Secret Name）

原因是 velero 在恢复资源时会删除资源的 owner reference 字段。

管理员需要运行 [脚本] (tbd.sh)删除所有不带 owner reference 的子资源，使得 crd 控制器自动创建带 owner reference 的子资源。

### status 被删除

如果恢复集群后，本已运行完毕的 t9k job 被重新运行，原因是 velero 在恢复资源时会删除资源的 status 字段。

管理员需要在备份集群之前运行[脚本](tbd.sh)将所有的 t9k job 设置为暂停状态；恢复集群后，用户可自行选择是否重新运行。

### 创建 crd 被 webhook 拒绝

如果恢复集群后，velero 报告如下错误：

```log
error restoring podautoscalers.autoscaling.internal.knative.dev/demo/torch-mnist-mlservice-predict-test-00001: Internal error occurred: failed calling webhook "webhook.serving.knative.dev": failed to call webhook: Post "https://webhook.knative-serving.svc:443/defaulting?timeout=10s": dial tcp 10.233.39.172:443: connect: connection refused
```

原因是创建 crd 时对应的 webhook pod 尚未就绪。

管理员需要根据 velero 的报错信息决定是否需要手动创建这些资源。

### 已运行完毕的 pod 和 k8s job 没有恢复

如果恢复集群后，原集群中已运行完毕（无论成功还是失败）的 pod 和 K8s job 没有被恢复，这是正常现象。velero 会备份但是不会恢复已运行完毕的 pod 和 k8s job。

