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

### Values 配置

#### 存储

参考 [Loki Values](https://github.com/grafana/loki/blob/v3.0.0/production/helm/loki/values.yaml#L272)，Loki 支持 s3、gcs 等多种日志存储方式，我们一般使用 S3 存储。

在使用 S3 数据库存储时，需要提前创建好 Loki 所需 Bucket：loki-chunks、loki-ruler 和 loki-admin。如果需要修改 Bucket 名称，请修改 `../ks-clusters/additionals/loki/loki.yaml` 中的 `loki.storage.bucketName` 字段。同时，据实填写 `loki.storage.s3` 中的字段。

Loki 支持在未提前创建数据库的情况下部署，Loki 会自动部署 Minio 并在其中创建好对应的 Bucket（参考 `../ks-clusters/additionals/loki/loki-single.yaml` 中的 `minio` 字段）。

#### T9k 审计日志

如果想启用 [T9k 审计日志](../products/pre-install/t9k-monitoring.md#启用-t9k-审计日志)，请确保 `../ks-clusters/additionals/loki/promtail.yaml` 文件的 `config.snippets.scrapeConfigs` 字段中包含下列内容：

```yaml
      # ----------------------------------------------------
      # Collect auditing logs.
      # ----------------------------------------------------
      - job_name: t9k-auditing-logs
        static_configs:
          - targets:
              - localhost
            labels:
              __path__: /var/log/kubernetes/audit/*log       
        pipeline_stages:
          - json:
              expressions:
                object_resources: objectRef.resource
                requestURI: requestURI
          - drop:
              source: requestURI
              expression: ".*dryRun=.*"
          - labels:
              object_resources:
          - match:
              selector: '{object_resources="proxyoperations"}'
              stages:
                - json:
                    expressions:
                      requestObject: requestObject
                      spec: requestObject.spec
                      verb: requestObject.spec.verb
                      involvedObject: requestObject.spec.involvedObject
                      timestamp: requestReceivedTimestamp
                - labels:
                    involvedObject:
                    verb:
                - static_labels:
                    type: t9k_operations
                    level: info
                - timestamp:
                    source: timestamp
                    format: RFC3339 
                - output:
                    source: spec
          - match:
              selector: '{object_resources!="proxyoperations"}'
              stages:
                - json:
                    expressions:
                      verb: verb
                      object_apiGroup: objectRef.apiGroup
                      object_resources: objectRef.resource
                      object_namespace: objectRef.namespace
                      response_code: responseStatus.code
                      timestamp: requestReceivedTimestamp
                - labels:
                    object_namespace:
                    object_apiGroup:
                    object_resources:
                    response_code:
                    verb:
                - static_labels:
                    type: k8s_objects
                - timestamp:
                    source: timestamp
                    format: RFC3339
                - match:
                    selector: '{response_code=~"1.+|2.+|3.+"}'
                    stages:
                      - static_labels:
                          level: info
                - match:
                    selector: '{response_code!~"1.+|2.+|3.+"}'
                    stages:
                      - static_labels:
                          level: warning
                - labeldrop:
                    - response_code
          - tenant:
              value: t9k-auditing-logs
```

### 多节点集群

多节点 K8s 集群中的安装，选择下列一种方式。

在线安装：

```bash
helm install loki \
  oci://tsz.io/t9kcharts/loki --version 6.6.4 \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/loki/loki.yaml 

helm install promtail \
  oci://tsz.io/t9kcharts/promtail --version 6.16.2 \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/loki/promtail.yaml
```

离线安装：

```bash
helm install loki \
  ../ks-clusters/tools/offline-additionals/charts/loki-6.6.4.tgz \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/loki/loki.yaml 

helm install promtail \
  ../ks-clusters/tools/offline-additionals/charts/promtail-6.16.2.tgz \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/loki/promtail.yaml
```

### 单节点安装

选择下列一种方式。

在线安装：

```bash
helm install loki \
  oci://tsz.io/t9kcharts/loki --version 6.6.4 \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/loki/loki-single.yaml 

helm install promtail \
  oci://tsz.io/t9kcharts/promtail --version 6.16.2 \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/loki/promtail.yaml
```

离线安装：

```bash
helm install loki \
  ../ks-clusters/tools/offline-additionals/charts/loki-6.6.4.tgz \
  -n t9k-monitoring \
  -f ../ks-clusters/additionals/loki/loki-single.yaml 

helm install promtail \
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
