# 运行状态

## Prometheus Operator

Prometheus Operator 部署、配置 Prometheus 和 Alertmanager。Prometheus Operator 提供了多种 CRD 来简化安装、配置。

查看 Prometheus Operator 运行状态：

```bash
kubectl -n t9k-monitoring get deploy prometheus-operator
```

```
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
prometheus-operator   1/1     1            1           233d
```

```bash
kubectl -n t9k-monitoring get pod -l "app.kubernetes.io/name"="prometheus-operator"
```

```
NAME                                   READY   STATUS    RESTARTS   AGE
prometheus-operator-5b8987464c-m9kzb   2/2     Running   0          231d
```

日志：

```bash
kubectl -n t9k-monitoring logs -l "app.kubernetes.io/name"="prometheus-operator" -f
```

<details><summary><code class="hljs">output</code></summary>

```log
...
level=info ts=2024-01-10T06:13:28.052160615Z caller=operator.go:1162 component=prometheusoperator key=t9k-system/cost-server msg="sync prometheus"
level=info ts=2024-01-10T06:13:28.052294533Z caller=operator.go:1330 component=prometheusoperator key=t9k-monitoring/k8s msg="update prometheus status"
level=info ts=2024-01-10T06:13:31.67006835Z caller=operator.go:1330 component=prometheusoperator key=t9k-system/cost-server msg="update prometheus status"
...
```

</details>



## 组件详情

### Prometheus

查看 Prometheus 运行状态：

```bash
kubectl -n t9k-monitoring get prometheus k8s
```

```
NAME   VERSION   DESIRED   READY   RECONCILED   AVAILABLE   AGE
k8s    2.41.0    2         2       True         True        222d
```

对应的 Pod：

```bash
kubectl -n t9k-monitoring get pod -l prometheus=k8s
```

```
NAME               READY   STATUS    RESTARTS   AGE
prometheus-k8s-0   3/3     Running   0          96d
prometheus-k8s-1   3/3     Running   0          126d
```

### Grafana

查看 Grafana 运行状态：

```bash
kubectl -n t9k-monitoring get deploy grafana
```

```
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
grafana   1/1     1            1           232d
```

Pod:

```bash
kubectl -n t9k-monitoring get pod -l app.kubernetes.io/component=grafana
```

```
NAME                       READY   STATUS    RESTARTS      AGE
grafana-646cf546cd-62hd6   2/2     Running      0          2d
```

### Alertmanager

查看 Alertmanager 运行状态：

```bash
kubectl -n t9k-monitoring get alertmanager main
```

```
NAME   VERSION   REPLICAS   AGE
main   0.25.0    3          2d
```

Pod:

```bash
kubectl -n t9k-monitoring get pod -l alertmanager=main
```

```
NAME                  READY   STATUS    RESTARTS      AGE
alertmanager-main-0   3/3     Running   0             2d
alertmanager-main-1   3/3     Running   0             2d
alertmanager-main-2   3/3     Running   0             2d
```

### kube-state-metrics

查看 kube-state-metrics 运行状态：

```bash
kubectl -n t9k-monitoring get deploy kube-state-metrics
```

```
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
kube-state-metrics   1/1     1            1           232d
```

```bash
kubectl -n t9k-monitoring get pod -l "app.kubernetes.io/name"="kube-state-metrics"
```

```
NAME                                 READY   STATUS    RESTARTS   AGE
kube-state-metrics-95658b8d7-x7f6t   3/3     Running   0          187d
```

```bash
kubectl -n t9k-monitoring logs -l "app.kubernetes.io/name"="kube-state-metrics" -f
```

<details><summary><code class="hljs">output</code></summary>

```log
I0425 23:23:45.820298       1 server.go:316] "Run with Kubernetes cluster version" major="1" minor="24" gitVersion="v1.24.10" gitTreeState="clean" gitCommit="5c1d2d4295f9b4eb12bfbf6429fdf989f2ca8a02" platform="linux/amd64"
I0425 23:23:45.820358       1 server.go:317] "Communication with server successful"
I0425 23:23:45.820717       1 server.go:263] "Started metrics server" metricsServerAddress="127.0.0.1:8081"
I0425 23:23:45.820789       1 metrics_handler.go:97] "Autosharding disabled"
I0425 23:23:45.820894       1 server.go:252] "Started kube-state-metrics self metrics server" telemetryAddress="127.0.0.1:8082"
I0425 23:23:45.820984       1 server.go:69] levelinfomsgListening onaddress127.0.0.1:8081
I0425 23:23:45.821019       1 server.go:69] levelinfomsgTLS is disabled.http2falseaddress127.0.0.1:8081
I0425 23:23:45.821102       1 server.go:69] levelinfomsgListening onaddress127.0.0.1:8082
I0425 23:23:45.821121       1 server.go:69] levelinfomsgTLS is disabled.http2falseaddress127.0.0.1:8082
I0425 23:23:46.043264       1 builder.go:257] "Active resources" activeStoreNames="certificatesigningrequests,configmaps,cronjobs,daemonsets,deployments,endpoints,horizontalpodautoscalers,ingresses,jobs,leases,limitranges,mutatingwebhookconfigurations,namespaces,networkpolicies,nodes,persistentvolumeclaims,persistentvolumes,poddisruptionbudgets,pods,replicasets,replicationcontrollers,resourcequotas,secrets,services,statefulsets,storageclasses,validatingwebhookconfigurations,volumeattachments"
```

</details>

###  node-exporter

查看 node-exporter 运行状态：

```bash
kubectl -n t9k-monitoring get ds node-exporter
```

```
NAME           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
node-exporter  10        10        10      10           10          kubernetes.io/os=linux   233d
```

```bash
kubectl -n t9k-monitoring get pod -l "app.kubernetes.io/name"="node-exporter" -o wide
```

```
NAME                   READY  STATUS    RESTARTS      AGE    IP             NODE 
node-exporter-8x59x   2/2     Running   0             231d   100.64.24.57    node07    
node-exporter-dw4c7   2/2     Running   0             231d   100.64.24.51    node01    
node-exporter-gxjzg   2/2     Running   0             231d   100.64.24.26    node15     
...
```

### t9k-state-metrics

查看 t9k-state-metrics 运行状态：

```bash
kubectl -n t9k-monitoring get deploy t9k-state-metrics
```

```
NAME                READY   UP-TO-DATE   AVAILABLE   AGE
t9k-state-metrics   1/1     1            1           214d
```

```bash
kubectl -n t9k-monitoring get pod -l app=t9k-state-metrics
```

```
NAME                                 READY   STATUS    RESTARTS   AGE
t9k-state-metrics-57d7cd8b58-29g65   1/1     Running   0          2d2h
```

```bash
kubectl -n t9k-monitoring logs -l app=t9k-state-metrics -f
```

<details><summary><code class="hljs">output</code></summary>

```log
level=info time=2024-05-07T09:45:13.915522444Z register="Resource simplemlservices's metrics will be generated"
level=info time=2024-05-07T09:45:13.915837909Z register="Resource notebooks's metrics will be generated"
level=info time=2024-05-07T09:45:13.915884243Z register="Resource tensorboards's metrics will be generated"
level=info time=2024-05-07T09:45:13.915913937Z register="Resource t9kjobs's metrics will be generated"
level=info time=2024-05-07T09:45:13.916049387Z register="Resource mlservices's metrics will be generated"
level=info time=2024-05-07T09:45:13.916096374Z Msg="t9k-state-metrics started"
```

</details>

## 参考

<https://prometheus-operator.dev/>

<https://prometheus.io/>

<https://grafana.com/>

<https://prometheus.io/docs/alerting/latest/alertmanager/>

<https://github.com/prometheus/node_exporter>

<https://github.com/kubernetes/kube-state-metrics>
