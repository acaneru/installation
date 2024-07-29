# Loki

如果使用 Loki 保存集群日志，则需要安装此组件。

## 目的

在 namespace `t9k-monitoring` 中安装 Loki 以存储集群日志。

## 安装

如果 namespace `t9k-monitoring` 不存在，则需创建：

```bash
kubectl create ns t9k-monitoring
```

<aside class="note">
<div class="title">离线安装</div>

修改镜像仓库的设置：

```bash
sed -i -e 's/docker.io/192.168.101.159:5000/' ../ks-clusters/additionals/loki/loki.yaml
sed -i -e 's/docker.io/192.168.101.159:5000/' ../ks-clusters/additionals/loki/loki-single.yaml
sed -i -e 's/docker.io/192.168.101.159:5000/' ../ks-clusters/additionals/loki/promtail.yaml
```
</aside>

### 多节点集群

多节点 K8s 集群中的安装，选择下列一种方式。

在线安装：

```bash
helm install loki \
  grafana/loki --version 6.6.4 \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/loki/loki.yaml 

helm upgrade promtail \
  grafana/promtail --version 6.16.2 \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/loki/promtail.yaml
```

离线安装：

```bash
helm install loki \
  ../ks-clusters/tools/offline-additionals/charts/loki-6.6.4.tgz \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/loki/loki.yaml 

helm upgrade promtail \
  ../ks-clusters/tools/offline-additionals/charts/promtail-6.16.2.tgz \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/loki/promtail.yaml
```

### 单节点安装

选择下列一种方式。

在线安装：

```bash
helm install loki \
  grafana/loki --version 6.6.4 \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/loki/loki-single.yaml 

helm upgrade promtail \
  grafana/promtail --version 6.16.2 \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/loki/promtail.yaml
```

离线安装：

```bash
helm install loki \
  ../ks-clusters/tools/offline-additionals/charts/loki-6.6.4.tgz \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/loki/loki-single.yaml 

helm upgrade promtail \
  ../ks-clusters/tools/offline-additionals/charts/promtail-6.16.2.tgz \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/loki/promtail.yaml
```

<aside class="note">
<div class="title">注意</div>

单节点安装方式仅在只有一个 K8s 节点的测试场景中适用。

</aside>

## 验证

以多节点安装为例，查看 helm status：

```bash
helm status -n t9k-monitoring loki

helm status -n t9k-monitoring promtail
```

以多节点安装为例，确认 Pod 正常运行：

```bash
% kubectl get pods -n t9k-monitoring
```

输出：

```
NAME                            READY   STATUS    RESTARTS   AGE
loki-0                          1/1     Running   0          156m
loki-canary-jjz5d               1/1     Running   0          156m
loki-chunks-cache-0             2/2     Running   0          156m
loki-gateway-59b665996c-xf4c9   1/1     Running   0          156m
loki-minio-0                    1/1     Running   0          156m
loki-results-cache-0            2/2     Running   0          156m
promtail-76cpg                  1/1     Running   0          3h56m
```

## 参考

<https://grafana.com/docs/loki/latest/get-started/overview/>
