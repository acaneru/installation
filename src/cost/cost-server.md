# Cost Server

## 查看运行状态

运行状态：

```bash
kubectl get pod -n t9k-system -l app=cost-server
```

```
NAME                          READY   STATUS    RESTARTS        AGE
cost-server-cc67588bd-mmplv   2/2     Running   2 (3d22h ago)   3d22h
```

日志：

```bash
kubectl logs -n t9k-system -l app=cost-server -c cost-server --tail=100 -f
```

<details><summary><code class="hljs">output</code></summary>

```
2024-03-20T16:02:51.02869912+08:00 ??? Log level set to info
2024-03-20T16:02:51.028771957+08:00 INF Starting cost-model version v1.105.2 (beb0ef1c)
2024-03-20T16:02:51.028811971+08:00 INF Prometheus/Thanos Client Max Concurrency set to 5
2024-03-20T16:02:51.038624154+08:00 INF Success: retrieved the 'up' query against prometheus at: http://prometheus-cost-server:9090
2024-03-20T16:02:51.051082378+08:00 INF Retrieved a prometheus config file from: http://prometheus-cost-server:9090
2024-03-20T16:02:51.068494084+08:00 INF Using scrape interval of 60.000000
2024-03-20T16:02:51.068912996+08:00 INF NAMESPACE: t9k-system
2024-03-20T16:02:52.170085421+08:00 INF Done waiting
2024-03-20T16:02:52.170149555+08:00 INF Starting *v1.Namespace controller
2024-03-20T16:02:52.170182505+08:00 INF Starting *v1.PersistentVolume controller
2024-03-20T16:02:52.17020926+08:00 INF Starting *v1.Service controller
2024-03-20T16:02:52.170131568+08:00 INF Starting *v1.Node controller
2024-03-20T16:02:52.17020657+08:00 INF Starting *v1.Job controller
2024-03-20T16:02:52.170214638+08:00 INF Starting *v1.Pod controller
2024-03-20T16:02:52.170167128+08:00 INF Starting *v1.ConfigMap controller
2024-03-20T16:02:52.170252046+08:00 INF Starting *v1.StorageClass controller
2024-03-20T16:02:52.170283858+08:00 INF Starting *v1.StatefulSet controller
2024-03-20T16:02:52.170265024+08:00 INF Starting *v1.ReplicaSet controller
2024-03-20T16:02:52.170279531+08:00 INF Starting *v1beta1.PodDisruptionBudget controller
2024-03-20T16:02:52.170259412+08:00 INF Starting *v1.PersistentVolumeClaim controller
2024-03-20T16:02:52.170363486+08:00 INF Starting *v1.DaemonSet controller
2024-03-20T16:02:52.170388661+08:00 INF Starting *v1.ReplicationController controller
2024-03-20T16:02:52.17076028+08:00 INF Starting *v1.Deployment controller
2024-03-20T16:02:52.171951964+08:00 INF Using JSON Provider with JSON at default.json of ConfigMap cost-server-pricing-config
2024-03-20T16:02:52.233144025+08:00 INF No pricing-configs configmap found at install time, using existing configs: configmaps "pricing-configs" not found
2024-03-20T16:02:52.234799159+08:00 INF Found configmap cost-server-pricing-config, watching...
2024-03-20T16:02:52.241731121+08:00 INF No metrics-config configmap found at install time, using existing configs: configmaps "metrics-config" not found
2024-03-20T16:02:53.837051287+08:00 INF Init: AggregateCostModel cache warming disabled
2024-03-20T16:02:53.83729973+08:00 ERR couldn't start CSV export worker:  is not set, skipping CSV exporter
2024-03-20T16:02:53.83923736+08:00 WRN Failed to locate default region
...
```

</details>

## 查看配置

查看配置：

```bash
kubectl get deploy -n t9k-system cost-server -o yaml
```

修改配置：

```bash
kubectl edit deploy -n t9k-system cost-server
```

<details><summary><code class="hljs">配置示例：deploy-cost-server.yaml</code></summary>

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cost-server
  namespace: t9k-system
spec:
  template:
    spec:
      containers:
      - env:
        - name: TZ
          value: Asia/Shanghai
        - name: T9K_SECURITY_SERVER_URL
          value: https://security-console-server.t9k-system:8081
        - name: T9K_SECURITY_SERVER_JWK_URI
          value: https://kc.kube.tensorstack.net/auth/realms/t9k-realm/protocol/openid-connect/certs
        - name: T9K_SECURITY_SERVER_USER_KEY
          value: preferred_username
        - name: T9K_POSTGRES_HOST
          value: cost-server-postgresql
        - name: T9K_POSTGRES_PORT
          value: "5432"
        - name: T9K_POSTGRES_DATABASE
          value: cost_server
        - name: T9K_POSTGRES_USER
          value: postgres
        - name: T9K_POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              key: postgres-password
              name: cost-server-postgresql
        - name: T9K_REFRESH_INTERVAL_SECONDS
          value: "600"
        - name: USE_JSON_PROVIDER
          value: "True"
        - name: JSON_PRICING_CONFIGMAP_NAME
          value: cost-server-pricing-config
        - name: KUBECOST_NAMESPACE
          value: t9k-system
        - name: CACHE_WARMING_ENABLED
          value: "false"
        - name: PROMETHEUS_SERVER_ENDPOINT
          value: http://prometheus-cost-server:9090
        - name: CLOUD_PROVIDER_API_KEY
          value: AIzaSyD29bGxmHAVEOBYtgd8sYM2gM2ekfxQX4U
        - name: CLUSTER_ID
          value: cluster-one
        image: tsz.io/t9k/cost-server:1.79.1
        imagePullPolicy: IfNotPresent
        name: cost-server
...
```

</details>

Cost Server 的配置直接以环境变量的形式声明，其中：

* `TZ` 字段表示时区，国内环境通常设置为 `Asia/Shanghai`。
* `T9K_SECURITY_SERVER_URL` 字段表示 [Security Console](../user-and-security-management/view-running-status.md#security-console) 服务的访问地址。
* `T9K_SECURITY_SERVER_JWK_URI` 字段表示 [Keycloak](../user-and-security-management/view-running-status.md#keycloak) 服务的访问地址。
* `T9K_SECURITY_SERVER_USER_KEY` 字段表示 Security Console 服务的 user key。
* `T9K_POSTGRES_HOST` 字段表示 PostgreSQL 服务的地址。
* `T9K_POSTGRES_PORT` 字段表示 PostgreSQL 服务的端口。
* `T9K_POSTGRES_DATABASE` 字段表示 PostgreSQL 服务的的数据库名称。
* `T9K_POSTGRES_USER` 字段表示 PostgreSQL 服务的用户名称。
* `T9K_POSTGRES_PASSWORD` 字段表示 PostgreSQL 服务的用户密码，引用 Secret `cost-server-postgresql` 的键 `postgres-password` 的值。
* `T9K_REFRESH_INTERVAL_SECONDS` 字段表示系统刷新项目的所有者的缓存的时间间隔。
* `JSON_PRICING_CONFIGMAP_NAME` 字段表示价格配置 ConfigMap 的名称。
* `PROMETHEUS_SERVER_ENDPOINT` 字段表示 Prometheus 服务的访问地址。

一般在安装完成后不需要修改这些配置。

修改配置后，Cost Server 服务自动重启，配置生效。
