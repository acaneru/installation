# 日志系统

日志系统负责收集保存 T9k 产品日志、集群事件，并提供查询服务。

主要由以下四个组件构成：

* Elasticsearch：一种 JSON 文档数据引擎，负责存储数据，并提供查询服务
* Fluentd：数据收集器，负责收集日志并发送给 ElasticSearch
* Event Router：收集集群事件，并将事件以日志形式打印出来，方便 Fluentd 收集
* Event Controller：负责监控各 Project 中的资源，生成相应事件

## Elasticsearch

### 部署

部署 ES 的文档：[K8s 组件](../installation/online/install-k8s-components/index.md)

### 修改配置

以 data 节点为例，以下为 data 节点的配置文件 data.yaml：

```yaml
clusterName: "elasticsearch"
nodeGroup: "data"
roles:
  master: "false"
  ingest: "true"
  data: "true"
replicas: 3
volumeClaimTemplate:
  accessModes: ["ReadWriteOnce"]
  resources:
    requests:
      storage: 60Gi
resources:
  requests:
    cpu: "1000m"
    memory: "3Gi"
  limits:
    cpu: "1000m"
    memory: "3Gi"
esConfig:
  elasticsearch.yml: |
    xpack.security.enabled: false
```

说明：

* replicas：节点数量
* resources：cpu、内存等资源配置

此外的其他字段，一经创建则不可修改。

使用以下命令更新 Elasticsearch 配置：

```bash
$ helm upgrade elasticsearch-data \
    oci://tsz.io/t9kcharts/elasticsearch \
    -n t9k-monitoring \
    --version 7.13.4 \
    --values data.yaml
```

使用该命令不能修改 PVC 的大小，请手动修改 pvc：

```bash
$ kubectl edit pvc -n t9k-monitoring elasticsearch-data-elasticsearch-data-0
```

### 配置日志生命周期

新部署好的 Elasticsearch 需要设置 index 的生命周期，以避免日志数量过多导致查询速度降低、存储空间不足等问题。

```bash
# 将部署好的 ElasticSearch 暴露出来：
kubectl -n t9k-monitoring port-forward service/elasticsearch-client 9200:9200

# R1 - 创建 ILM Policy，用于自动清理创建时间超过 30 天的 index：
curl -X PUT "http://localhost:9200/_ilm/policy/t9k-policy?pretty" \
   -H 'Content-Type: application/json' \
   -d '{
    "policy": {                       
      "phases": {
        "hot": {                      
          "actions": {}
        },
        "delete": {
          "min_age": "30d",           
          "actions": { "delete": {} }
        }
      }
    }
  }'

# R2 - 创建 Template，使 ElasticSearch 自动将 ILM Policy 绑定到合适的 
# Index（t9k-deploy-log-、t9k-deploy-log-、t9k-deploy-log-、t9k-event-）上：
curl -X PUT "http://localhost:9200/_template/logging_policy_template?pretty" \
 -H 'Content-Type: application/json' \
 -d '{
  "index_patterns": ["t9k-build-log-*", "t9k-deploy-log-*", "t9k-system-log-*", "t9k-event-*"],
  "settings": { "index.lifecycle.name": "t9k-policy" }
}'
```

### 添加、删除节点

添加节点，可以参考[修改配置](#修改配置)通过修改配置文件，执行 helm upgrade 命令完成。

删除节点，需要将待删除节点的数据移动到其他节点，然后再删除该节点。以下为删除节点的步骤。

首先将 elasticsearch 服务暴露出来：

```bash
kubectl port-forward service/elasticsearch-client -n t9k-monitoring 9200:9200
```

通过浏览器查看集群中的分片情况（url：`http://localhost:9200/_cat/shards`）：

<figure class="screenshot">
  <img alt="api-key" src="../assets/monitoring-and-log-system/log-system/shards-1.png" />
</figure>

如果我们想将 data 节点数量从 8 缩小到 3，则需要删除 elasticsearch-data-3 到 elasticsearch-data-7 这 5 个节点。

执行以下命令，将 elasticsearch-data-7 节点排出 elastic 集群（ip 可以从上图中获得）：

```bash
curl -XPUT http://localhost:9200/_cluster/settings -H "Content-Type: application/json" -d '{
  "transient" :{
      "cluster.routing.allocation.exclude._ip" : "10.233.89.175"
   }
}'
```

再次通过浏览器查看集群中的分片情况（url：`http://localhost:9200/_cat/shards`）：

<figure class="screenshot">
  <img alt="api-key" src="../assets/monitoring-and-log-system/log-system/shards-2.png" />
</figure>

可以看到这一节点上的数据正在被复制到其他节点上。

刷新上述浏览器页面，直到发现 elasticsearch-data-7 节点上没有任何分片后，可以关闭该节点：

```bash
kubectl scale --replicas=7 sts elasticsearch-data -n t9k-monitoring
```

将 statefulset 的 replicas 数量缩小 1。

重复上面步骤，删除剩下的 elasticsearch-data-3 到 elasticsearch-data-6 四个节点。全部删除后，执行如下操作：

```bash
curl -XPUT http://localhost:9200/_cluster/settings -H "Content-Type: application/json" -d '{
  "transient" :{
      "cluster.routing.allocation.exclude._ip" : ""
   }
}'
```

恢复集群设置。

<aside class="note">
<div class="title">注意</div>

1. elasticsearch 的数据节点同时只能删除一个
1. 节点删除应从序号大的节点开始删除，这是 k8s statefulset 的性质决定的，我们无法跳过大序号的节点去删除小序号节点
1. 删除节点后，注意手动删除 pvc，腾出空间

</aside>

## Fluentd

### 查看配置

运行下列命令可以查看 Fluentd 的配置：

```bash
$ kubectl -n t9k-monitoring get configmap fluentd-ds
```

### 修改 Fluentd 配置

运行下列命令可以修改 Fluentd 配置：

```bash
$ kubectl -n t9k-monitoring edit configmap fluentd-ds
```

```yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: fluentd-ds
data:
  fluentd.conf: |-
    ...
    <source>
      @id event
      @type tail
      path /var/log/containers/eventrouter-*_eventrouter-*.log
      pos_file /var/fluentd-cache/eventrouter-log.pos
      tag event.*
      <parse>
        @type json
        time_format %Y-%m-%dT%H:%M:%S.%NZ
      </parse>
    </source>
    <filter event.**>
      @type parser
      key_name log
      <parse>
        @type json
        json_parser yajl
        time_type string
        time_format %Y-%m-%dT%H:%M:%S.%NZ
      </parse>
    </filter>
    <match event.**>
      @id elasticsearch-event
      @type elasticsearch
      @log_level info
      suppress_type_name true
      log_es_400_reason true
      request_timeout 30s
      host elasticsearch-client
      port 9200
      logstash_format true
      logstash_prefix t9k-event
      <buffer>
        @type file
        timekey 1h
        path /var/fluentd-cache/elasticsearch-event.buffer
        flush_mode interval
        retry_type exponential_backoff
        flush_thread_count 2
        flush_interval 5s
        retry_forever
        retry_max_interval 30
        chunk_limit_size 2M
        queue_limit_length 8
        overflow_action block
      </buffer>
    </match>
...
```

在上述配置中：

* `<source>` 标签标记数据来源
    * path：日志文件名
    * `<parse>` 标签用于解析每一行日志（不同的 container runtime 打印的日志具有不同的格式，参考[日志格式解析](#日志格式解析)）
* `<filter>` 标签为每一条数据添加 Kubernetes 相关信息
* `<match>` 标签将数据发送到 elasticsearch 中，该标签的详细说明请参考 <a target="_blank" rel="noopener noreferrer" href="https://github.com/uken/fluent-plugin-elasticsearch">Github</a>

在修改过 Fluentd 配置后，需要重启集群中的 fluentd 来使配置生效：

```bash
kubectl -n t9k-monitoring delete pods -l app=fluentd-ds
```

#### 日志格式解析

Kubernetes 底层可以使用不同的容器运行时。不同的运行时，存储的日志格式是不同的，比如：

* Docker 日志格式：`{"log":" Average Recall     (AR) @[ IoU=0.50:0.95 | area= large | maxDets=100 ] = 0.804\n","stream":"stdout","time":"2022-09-19T06:13:01.856641709Z"}`
* Containerd 日志格式：`2022-10-25T05:54:00.897711526Z stderr F 	/root/repos/aimd-server/gen/component/repos/aimd-server/pkg/lakefs/client.go:102 +0x251`

所以日志的解析方式也需要变化，Fluentd 使用 parser 对日志进行解析，上述两种日志格式分别可以使用 json parser 和 regexp parser 进行解析。

Docker 的日志解析方式：

```
<parse>
  @type json
  time_format %Y-%m-%dT%H:%M:%S.%NZ
</parse>
```

将日志当成 json 来解析，提取其中的 time 字段作为当前日志的时间戳，time 字段的格式为 `%Y-%m-%dT%H:%M:%S.%NZ`。

Containerd 的日志解析方式：

```
<parse>
  @type regexp
  time_key logtime
  expression /^(?<logtime>[^ ]*) (stdout|stderr) F (?<log>.*)$/
  time_format %Y-%m-%dT%H:%M:%S.%NZ
</parse>
```

用正则表达式 `/^(?<logtime>[^ ]*) (stdout|stderr) F (?<log>.*)$/` 分析日志，将其中 `<logtime>` 所匹配到的字符串作为日志的时间戳，其格式为 `%Y-%m-%dT%H:%M:%S.%NZ`。

使用其他容器运行时，可以 ssh 进入集群节点：

```bash
ssh t9k@100.64.4.199
```

进入任意一个容器文件夹：

```bash
cd /var/log/pods/[pod_ref]/[container-name]
```

打印当前容器的日志：

```bash
cat 0.log
```

根据日志的格式修改 parser 的内容，一般来说 json 格式的日志使用 json parser，其他字符串格式的日志使用 regexp parser 解析，需要根据实际情况修改 regexp parser 的 expression。

### 修改部署配置

我们在 Kubernetes 上创建一个 DaemonSet 来将 Fluentd 部署到每一个节点上（如果不想在每一个节点上都部署 Fluentd，可以设置 `nodeSelector` 字段，限制只在具有对应标签的节点上部署 Fluentd）：

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
spec:
  template:
    spec:
      nodeSelector:
        beta.kubernetes.io/fluentd-ds-ready: "true"
      containers:
      - image: tsz.io/t9k/fluentd-elasticsearch:v1.14.5-1.1
...
```

为了使 Fluentd 读取到节点上的日志文件，需要将文件通过 hostPath 的方式绑定到 Fluentd 上：

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd
spec:
  template:
    spec:
      nodeSelector:
        beta.kubernetes.io/fluentd-ds-ready: "true"
      containers:
      - volumeMounts:
        - mountPath: /var/log/containers
          name: varlogcontainers
          readOnly: true
        - mountPath: /var/log/pods
          name: varlogpods
          readOnly: true
        - mountPath: /var/lib/docker/containers
          name: varlibdockercontainers
          readOnly: true
        ...
      volumes:
      - hostPath:
        path: /var/log/containers
        name: varlogcontainers
      - hostPath:
        path: /var/log/pods
        name: varlogpods
      - hostPath:
        path: /var/lib/docker/containers
        name: varlibdockercontainers
...
```

Kubernetes 中日志文件是通过软链接出现在 `/var/log/containers` 的，我们需要将软链接的完整链接路径都绑定到 Pod 上，才能使 Fluentd 读取到日志文件。软链接完整链接路径的获取方式参考[Kubernetes 中的日志存储](#kubernetes-中的日志存储)。

#### Kubernetes 中的日志存储

在 Kubernetes 中，日志文件由容器运行时（Container Runtime）捕获容器 STDOUT 后产生，其地址决定于容器运行时的配置。

容器运行时以 Docker 为例：默认情况下，Docker 会将日志文件保存到节点的 `/var/lib/docker/containers` 路径下。该路径取决于容器运行时的种类和容器运行时本身的配置。

由于 Kubernetes 直接运行的不是容器，Kubernetes 还在节点上创建了 `/var/log/pods/` 和 `/var/log/containers/` 目录，以帮助更好地组织日志文件：

* 在 `/var/log/pods/` 中，容器的日志文件被存储在 `/var/log/pods/<namespace>_<pod_name>_<pod_id>/<container_name>/0.log`。0.log 文件与日志轮换策略相关，可能存在 1.log 等。
* 在 `/var/log/containers/` 中，容器的日志文件被存储在 `/var/log/containers/<pod_name>_<namespace>_<container_id>.log`。

上述三种日志路径中，`/var/log/containers/` 格式的路径格式更加确定且结构扁平（所有日志文件都直接存放在 `/var/log/containers/` 中），所以 Fluentd 直接从此处读取日志文件更为方便。

需要注意的是，上述三种路径实际上指向相同的文件，后两者记录的是符号链接：
`/var/lib/docker/containers/… <- /var/log/pods/… <- /var/log/containers/…`。读取 `/var/log/containers/` 中的文件，实际上是通过两步跳转，直接读取 `/var/lib/docker/containers/` 中的文件。

## Event Router

Event Router 将集群中所有事件以日志形式，打印到标准输出中。

查看 Event Router 运行状态：

```bash
$ kubectl -n t9k-monitoring get deploy eventrouter
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
eventrouter   1/1     1            1           239d
$ kubectl get pods -n t9k-monitoring -l app=eventrouter
NAME                          READY   STATUS    RESTARTS   AGE
eventrouter-7949d78bf-vd2tm   1/1     Running   0          75m
```

## Event Controller

Event controller 负责监听系统中一些资源的生命周期变化，然后生成相应的 Events，以方便在前端展示、Event Router 收集等。

### 查看配置

在 project-operator-event-ctl-config 中配置 Event Controller 要监控的集群资源，通过以下命令查看 Event Controller 配置：

```bash
kubectl -n t9k-system get configmap project-operator-event-ctl-config
```

### 修改配置

```bash
kubectl edit configmap -n t9k-system project-operator-event-ctl-config
```

```yaml
apiVersion: v1
data:
  config.json: |-
    {
      "resources": [
        {
          "group": "tensorstack.dev",
          "version": "v1beta1",
          "resource": "notebooks"
        },
        ...
      ]
    }
kind: ConfigMap
```

配置修改后，需要重启 project operator 使配置生效：

```bash
kubectl delete -n t9k-system -l control-plane=project-ctl
```
