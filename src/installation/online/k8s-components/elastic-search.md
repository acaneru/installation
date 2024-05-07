# Elastic Search

如果使用 Elastic Search 保存集群日志，则需要安装此组件。

## 目的

在 namespace `t9k-monitoring` 中安装 Elastic Search 以存储集群日志。

## 安装

如果 namespace `t9k-monitoring` 不存在，则需创建：

```bash
kubectl create ns t9k-monitoring
```
<aside class="note">
<div class="title">离线安装</div>

修改镜像仓库的设置：

```bash
cat >> ../ks-clusters/additionals/elasticsearch/master.yaml << EOF
image: "192.168.101.159:5000/t9kpublic/elasticsearch"
EOF

cat >> ../ks-clusters/additionals/elasticsearch/client.yaml << EOF
image: "192.168.101.159:5000/t9kpublic/elasticsearch"
EOF

cat >> ../ks-clusters/additionals/elasticsearch/data.yaml << EOF
image: "192.168.101.159:5000/t9kpublic/elasticsearch"
EOF

cat >> ../ks-clusters/additionals/elasticsearch/single.yaml << EOF
image: "192.168.101.159:5000/t9kpublic/elasticsearch"
EOF
```
</aside>

### 多节点集群

多节点 K8s 集群中的安装，选择下列一种方式。

在线安装：

```bash
# online installation
helm install elasticsearch-master \
  oci://tsz.io/t9kcharts/elasticsearch \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/elasticsearch/master.yaml

helm install elasticsearch-client \
  oci://tsz.io/t9kcharts/elasticsearch \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/elasticsearch/client.yaml

helm install elasticsearch-data \
  oci://tsz.io/t9kcharts/elasticsearch \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/elasticsearch/data.yaml

```

离线安装：

```bash
# offline install
helm install elasticsearch-master \
  ../ks-clusters/tools/offline-additionals/charts/elasticsearch-7.13.4.tgz \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/elasticsearch/master.yaml

helm install elasticsearch-client \
  ../ks-clusters/tools/offline-additionals/charts/elasticsearch-7.13.4.tgz \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/elasticsearch/client.yaml

helm install elasticsearch-data \
  ../ks-clusters/tools/offline-additionals/charts/elasticsearch-7.13.4.tgz \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/elasticsearch/data.yaml
```

其中 Helm Chart 的来源参考：[Elastic Search 的 Helm Chart 修改](../../appendix/modify-helm-chart.md#elastic-search)

### 单节点安装

选择下列一种方式。

在线安装：

```bash
# online installation
helm install elasticsearch-single \
  oci://tsz.io/t9kcharts/elasticsearch \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/elasticsearch/single.yaml
```

离线安装：

```
# offline install
helm install elasticsearch-single \
  ../ks-clusters/tools/offline-additionals/charts/elasticsearch-7.13.4.tgz \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/elasticsearch/single.yaml
```

<aside class="note">
<div class="title">注意</div>

单节点安装方式仅在只有一个 K8s 节点的测试场景中适用。

</aside>

## 验证

以多节点安装为例，查看 helm status：

```bash
helm status -n t9k-monitoring elasticsearch-master

helm status -n t9k-monitoring elasticsearch-client

helm status -n t9k-monitoring elasticsearch-data
```

以多节点安装为例，确认 elasticsearch Pod 正常运行：

```bash
kubectl get pods --namespace=t9k-monitoring -l app=elasticsearch-master
```

输出：

```
NAME                     READY   STATUS    RESTARTS   AGE
elasticsearch-master-0   1/1     Running   0          64d
elasticsearch-master-1   1/1     Running   0          105d
elasticsearch-master-2   1/1     Running   0          11d
```

```bash
kubectl get pods --namespace=t9k-monitoring -l app=elasticsearch-client
```

输出：

```
NAME                     READY   STATUS    RESTARTS   AGE
elasticsearch-client-0   1/1     Running   0          11d
elasticsearch-client-1   1/1     Running   0          64d
```

```bash
kubectl get pods --namespace=t9k-monitoring -l app=elasticsearch-data
```

输出：

```
NAME                   READY   STATUS    RESTARTS   AGE
elasticsearch-data-0   1/1     Running   0          132d
elasticsearch-data-1   1/1     Running   0          11d
elasticsearch-data-2   1/1     Running   0          64d
```


<aside class="note">
<div class="title">注意</div>

在 Post Install 流程中，我们还需要为 Elasticsearch 配置 Index。

</aside>

## 参考

<https://github.com/elastic/elasticsearch>
