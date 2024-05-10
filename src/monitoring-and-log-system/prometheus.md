# Prometheus

Prometheus 负责收集及保存集群服务的各种指标数据，并提供 API 供其他服务使用。

## 部署设置

运行下列命令查看部署的 Prometheus 详情（<a target="_blank" rel="noopener noreferrer" href="https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.Prometheus">API Reference</a>）：

CRD 详情：

```bash
kubectl -n t9k-monitoring get prometheus k8s -o yaml
```

Pod：

```bash
kubectl -n t9k-monitoring get pod -l prometheus=k8s
```

通过设置 Prometheus spec 字段可以修改 Prometheus 部分配置。spec 字段中常用的子字段有：

* `retention`：值类型 <a target="_blank" rel="noopener noreferrer" href="https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.Duration">duration</a>，当 retention 和 retentionSize 据未设置时，retention 默认被设为 “24h”。监控数据的保存时长。
* `retentionSize`：值类型 <a target="_blank" rel="noopener noreferrer" href="https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.ByteSize">ByteSize</a>，保存监控数据的最大存储空间。例如 100GB。
* `storage`：值类型 <a target="_blank" rel="noopener noreferrer" href="https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.StorageSpec">StorageSpec</a>，定义了提供给 Prometheus 使用的 K8s Volume。例如，下列设置表明提供 1000Gi 大小的 PVC 给 Prometheus 使用，为 PVC 提供存储支持的 storageClass 是 cephfs-hdd：

```yaml
    storage:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: 1000Gi
          storageClassName: cephfs-hdd
```

## 查看 Web UI

Prometheus 成功运行之后，可以通过浏览器查看 Prometheus 的 Web UI。

可通过 **Cluster-Admin > 监控与报警 > 其它工具 > Prometheus** 进入 Prometheus Web UI。

**交互式查询** - 可以在搜索框输入 <a target="_blank" rel="noopener noreferrer" href="https://prometheus.io/docs/prometheus/latest/querying/basics/">PromQL</a>（Prometheus Query Lanaguage） 来查询监控数据：`https://<host>/t9k-monitoring/prometheus/graph`

**查看 Configuration** - 创建的[监控目标](#监控目标)会被添加到这个 Config 中，所以你可以通过这个页面来确定创建的监控目标是否生效：`https://<host>/t9k-monitoring/prometheus/config`

**监控目标的健康状态** -` https://<host>/t9k-monitoring/prometheus/targets`

**[告警规则](#告警规则记录规则)** - `https://<host>/t9k-monitoring/prometheus/rules`

## 参考

<https://prometheus.io/>
