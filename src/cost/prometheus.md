# Prometheus

## 查看运行状态

运行状态：

```bash
kubectl get pod -n t9k-system -l prometheus=cost-server
```

```
NAME                       READY   STATUS    RESTARTS   AGE
prometheus-cost-server-0   2/2     Running   0          3d22h
prometheus-cost-server-1   2/2     Running   0          3d22h
```

查看监控目标的健康状态：

```bash
kubectl port-forward svc/prometheus-cost-server -n t9k-system 9090:9090
```

访问网页 <a target="_blank" rel="noopener noreferrer" href="http://localhost:9090/targets">Prometheus targets</a>，所有的监控目标 targets 应当都是 “up” 状态。

## 查看配置

查看配置：

```bash
kubectl get prometheus -n t9k-system cost-server -o yaml
```

修改配置：

```bash
kubectl edit prometheus -n t9k-system cost-server
```

<details><summary><code class="hljs">配置示例：prometheus-cost-server.yaml</code></summary>

```yaml
apiVersion: monitoring.coreos.com/v1
kind: Prometheus
metadata:
  name: cost-server
  namespace: t9k-system
spec:
  image: docker.io/t9kpublic/prometheus:v2.41.0
  podMonitorNamespaceSelector: {}
  podMonitorSelector:
    matchLabels:
      tensorstack.dev/metrics-collected-by: cost-server
  probeNamespaceSelector: {}
  probeSelector: {}
  replicas: 2
  resources:
    requests:
      cpu: 200m
      memory: 400Mi
  retention: 5y
  retentionSize: 84GB
  ruleNamespaceSelector: {}
  ruleSelector:
    matchLabels:
      tensorstack.dev/metrics-collected-by: cost-server
  scrapeInterval: 30s
  serviceMonitorNamespaceSelector: {}
  serviceMonitorSelector:
    matchLabels:
      tensorstack.dev/metrics-collected-by: cost-server
  storage:
    volumeClaimTemplate:
      spec:
        resources:
          requests:
            storage: 100Gi
  version: 2.41.0
...
```

</details>

Prometheus 服务的配置在 Prometheus 实例的 `spec` 字段中设置，其中：

* `retention` 字段表示 Prometheus 数据的保留时间。如果 `retention` 和 `retentionSize` 均未设置，默认为 24h。
* `retentionSize` 字段表示 Prometheus 数据的最大存储空间。
* `storage` 字段表示 Prometheus 所使用的 Kubernetes Volume 信息。
