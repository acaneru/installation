# 安装 velero server/cli

从 <a target="_blank" rel="noopener noreferrer" href="https://github.com/vmware-tanzu/velero/releases/tag/v1.12.1">github release</a> 中下载 velero cli v1.12.1 并移动到 `/usr/local/bin`：

```bash
which velero
```

```
/usr/local/bin/velero
```

```bash
velero version
```

```
Client:
	Version: v1.12.1
	Git commit: 5c4fdfe147357ec7b908339f4516cd96d6b97c61
<error getting server version: no matches for kind "ServerStatusRequest" in version "velero.io/v1">
```

启用 csi 功能（<a target="_blank" rel="noopener noreferrer" href="https://velero.io/docs/v1.12/csi/#installing-velero-with-csi-support">参考</a>）：

```bash
velero client config set features=EnableCSI
```

通过以下命令安装 velero server，其中需要提供 s3 服务的 url、bucket、access key、secret key，用于存储所备份的 yaml 文件：

```bash
cat ./credentials-velero
```

```
[default]
aws_access_key_id = <access-key>
aws_secret_access_key = <secret-key>
```

```
velero install \
--features=EnableCSI \
--provider aws \
--plugins velero/velero-plugin-for-aws:v1.8.1,velero/velero-plugin-for-csi:v0.6.1 \
--bucket <s3-bucket> \
--secret-file ./credentials-velero \
--backup-location-config region=us-east-1,s3ForcePathStyle="true",s3Url=<s3-url> \
--snapshot-location-config region=us-east-1,s3ForcePathStyle="true",s3Url=<s3-url>
```

查看 velero server：

```bash
kubectl get pod -n velero
```

```
NAME                      READY   STATUS    RESTARTS   AGE
velero-758958764c-fw2x4   1/1     Running   0          76s
```

查看 BackupStorageLocation：

```bash
kubectl get BackupStorageLocation -n velero default -o yaml
```

```yaml
apiVersion: velero.io/v1
kind: BackupStorageLocation
metadata:
  creationTimestamp: "2023-11-22T03:32:08Z"
  generation: 5
  labels:
    component: velero
  name: default
  namespace: velero
  resourceVersion: "549476546"
  uid: 9d398b2c-805a-4979-bc15-583d314aa8b8
spec:
  config:
    region: us-east-1
    s3ForcePathStyle: "true"
    s3Url: <s3-url>
  default: true
  objectStorage:
    bucket: <s3-bucket>
  provider: aws
status:
  lastSyncedTime: "2023-11-22T03:34:31Z"
  lastValidationTime: "2023-11-22T03:34:31Z"
  phase: Available
```

查看 VolumeSnapshotLocation：

```bash
kubectl get VolumeSnapshotLocation -n velero default -o yaml
```

```yaml
apiVersion: velero.io/v1
kind: VolumeSnapshotLocation
metadata:
  creationTimestamp: "2023-11-22T03:32:08Z"
  generation: 1
  labels:
    component: velero
  name: default
  namespace: velero
  resourceVersion: "549472573"
  uid: 17f7b48e-5458-4186-a7e4-8b526246df7a
spec:
  config:
    region: us-east-1
    s3ForcePathStyle: "true"
    s3Url: <s3-url>
  provider: aws
```
