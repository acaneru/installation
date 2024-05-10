# etcd 备份

## 备份

登录 k8s 集群的 etcd 节点，执行以下命令将 etcd 数据库备份到 ./snapshotdb 文件中：

```bash
cat /etc/etcd.env
```

<details><summary><code class="hljs">output</code></summary>

```console
...
# CLI settings
ETCDCTL_ENDPOINTS=https://127.0.0.1:2379
ETCDCTL_CACERT=/etc/ssl/etcd/ssl/ca.pem
ETCDCTL_KEY=/etc/ssl/etcd/ssl/admin-nuc-key.pem
ETCDCTL_CERT=/etc/ssl/etcd/ssl/admin-nuc.pem
...
```
</details>

```
source /etc/etcd.env

ETCDCTL_API=3 etcdctl \
    --endpoints=$ETCDCTL_ENDPOINTS \
    --cacert=$ETCDCTL_CACERT \
    --cert=$ETCDCTL_CERT \
    --key=$ETCDCTL_KEY \
    snapshot save snapshotdb
```

<details><summary><code class="hljs">output</code></summary>

```
{"level":"info","ts":"2023-12-05T07:37:15.889Z","caller":"snapshot/v3_snapshot.go:65","msg":"created temporary db file","path":"snapshotdb.part"}
{"level":"info","ts":"2023-12-05T07:37:15.895Z","logger":"client","caller":"v3@v3.5.6/maintenance.go:212","msg":"opened snapshot stream; downloading"}
{"level":"info","ts":"2023-12-05T07:37:15.895Z","caller":"snapshot/v3_snapshot.go:73","msg":"fetching snapshot","endpoint":"https://127.0.0.1:2379"}
{"level":"info","ts":"2023-12-05T07:37:16.187Z","logger":"client","caller":"v3@v3.5.6/maintenance.go:220","msg":"completed snapshot read; closing"}
{"level":"info","ts":"2023-12-05T07:37:18.972Z","caller":"snapshot/v3_snapshot.go:88","msg":"fetched snapshot","endpoint":"https://127.0.0.1:2379","size":"58 MB","took":"3 seconds ago"}
{"level":"info","ts":"2023-12-05T07:37:19.022Z","caller":"snapshot/v3_snapshot.go:97","msg":"saved","path":"snapshotdb"}
Snapshot saved at snapshotdb
```
</details>

查看备份文件：

```bash
# etcdctl, deprecated
# ETCDCTL_API=3 etcdctl --write-out=table snapshot status ./snapshotdb

ETCDCTL_API=3 etcdutl --write-out=table snapshot status ./snapshotdb
```

<details><summary><code class="hljs">output</code></summary>

```
+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| 47d5c868 |  4607924 |       8674 |      58 MB |
+----------+----------+------------+------------+
```

</details>

## 恢复

根据 <a target="_blank" rel="noopener noreferrer" href="https://v1-25.docs.kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#restoring-an-etcd-cluster">k8s 文档</a>，按照以下步骤恢复 etcd：

1. 暂停所有 api server pod
1. 恢复每个 etcd 数据库
1. 启动所有 api server pod
1. 重启 kubelet 及 kube-scheduler、kube-controller-manager 等系统组件

首先，将 etcd 备份文件拷贝到所有 etcd 节点上。

然后，在每个控制平面节点上，运行以下命令暂停 api server pod：

```bash
mv /etc/kubernetes/manifests/kube-apiserver.yaml ./
```

在每个 etcd 节点上，运行以下命令恢复 etcd 数据库：

```bash
source /etc/etcd.env
ETCDCTL_API=3 etcdctl \
     --endpoints=$ETCDCTL_ENDPOINTS \
     --cacert=$ETCDCTL_CACERT \
     --cert=$ETCDCTL_CERT \
     --key=$ETCDCTL_KEY \
     snapshot restore ./snapshotdb
```

<details><summary><code class="hljs">output</code></summary>

```
Deprecated: Use `etcdutl snapshot restore` instead.

2023-12-08T10:03:54Z	info	snapshot/v3_snapshot.go:248	restoring snapshot	{"path": "snapshotdb", "wal-dir": "default.etcd/member/wal", "data-dir": "default.etcd", "snap-dir": "default.etcd/member/snap", "stack": "go.etcd.io/etcd/etcdutl/v3/snapshot.(*v3Manager).Restore\n\tgo.etcd.io/etcd/etcdutl/v3@v3.5.6/snapshot/v3_snapshot.go:254\ngo.etcd.io/etcd/etcdutl/v3/etcdutl.SnapshotRestoreCommandFunc\n\tgo.etcd.io/etcd/etcdutl/v3@v3.5.6/etcdutl/snapshot_command.go:147\ngo.etcd.io/etcd/etcdctl/v3/ctlv3/command.snapshotRestoreCommandFunc\n\tgo.etcd.io/etcd/etcdctl/v3/ctlv3/command/snapshot_command.go:129\ngithub.com/spf13/cobra.(*Command).execute\n\tgithub.com/spf13/cobra@v1.1.3/command.go:856\ngithub.com/spf13/cobra.(*Command).ExecuteC\n\tgithub.com/spf13/cobra@v1.1.3/command.go:960\ngithub.com/spf13/cobra.(*Command).Execute\n\tgithub.com/spf13/cobra@v1.1.3/command.go:897\ngo.etcd.io/etcd/etcdctl/v3/ctlv3.Start\n\tgo.etcd.io/etcd/etcdctl/v3/ctlv3/ctl.go:107\ngo.etcd.io/etcd/etcdctl/v3/ctlv3.MustStart\n\tgo.etcd.io/etcd/etcdctl/v3/ctlv3/ctl.go:111\nmain.main\n\tgo.etcd.io/etcd/etcdctl/v3/main.go:59\nruntime.main\n\truntime/proc.go:225"}
2023-12-08T10:03:54Z	info	membership/store.go:141	Trimming membership information from the backend...
2023-12-08T10:03:54Z	info	membership/cluster.go:421	added member	{"cluster-id": "cdf818194e3a8c32", "local-member-id": "0", "added-peer-id": "8e9e05c52164694d", "added-peer-peer-urls": ["http://localhost:2380"]}
2023-12-08T10:03:54Z	info	snapshot/v3_snapshot.go:269	restored snapshot	{"path": "snapshotdb", "wal-dir": "default.etcd/member/wal", "data-dir": "default.etcd", "snap-dir": "default.etcd/member/snap"}
```

</details>

在每个控制平面节点上，运行以下命令启动 api server pod：

```bash
mv ./kube-apiserver.yaml  /etc/kubernetes/manifests/kube-apiserver.yaml
```

在每个控制平面节点上，运行以下命令重启 kubelet：

```bash
systemctl restart kubelet
```

重启系统组件：

```bash
kubectl delete po -n kube-system --all
```

等待一段时间，确认集群工作正常：

```bash
kubectl get node
kubectl get pod -A
```
