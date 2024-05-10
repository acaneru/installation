# Fluentd

### 查看配置

运行下列命令可以查看 Fluentd 的配置：

```bash
kubectl -n t9k-monitoring get configmap fluentd-ds
```

### 修改 Fluentd 配置

运行下列命令可以修改 Fluentd 配置：

```bash
kubectl -n t9k-monitoring edit configmap fluentd-ds
```

<details><summary><code class="hljs">configmap-fluentd-ds.yaml</code></summary>

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

</details>

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

#### 日志路径

Kubernetes 的日志系统是通过软连接组织的。日志的实际路径在节点安装的时候由安装人员指定。如果不知道，在本节后面有如何查看软链接的方法。

node01：

```bash
/var/log/pods/t9k-system_pinger-5bsln_49736add-de97-4160-8c84-e346a210494a/tpinger/0.log -> 
/var/lib/docker/containers/f2f62d917f8ced6ff4969d64515e9b3eb2d976bb9035e9b95d594fcbd12f6300/f2f62d917f8ced6ff4969d64515e9b3eb2d976bb9035e9b95d594fcbd12f6300-json.log
```

node02：

```bash
/var/log/pods/t9k-system_pinger-jplh7_5ae0be2f-29e9-4a27-a6a5-6d97c2e6db42/tpinger/0.log ->
/mnt/sdc/docker/containers/6a9948cc88659055176c24969db77e9cb1834e424e611328a5406200922e3072/6a9948cc88659055176c24969db77e9cb1834e424e611328a5406200922e3072-json.log
```

可以看到两个节点上的日志路径是不一样的，其中 node01 使用的是 docker 默认的地址，node02 是安装人员自行设置的磁盘路径。

软链接上的所有路径都必须绑定在 fluentd container 上，fluentd 程序才可以读取到日志。

**软链接的查找方式**

```bash
# 列举所有节点，不同节点的日志路径可能不一样（取决于节点的安装方式），所以可能每一个节点都需要检查（）
kubectl get nodes -o wide

# 进入 node01 节点
ssh node01
```

```bash
# 从日志的起点开始列举（任选一个 pod/container）
cd /var/log/pods/t9k-system_minio-2_1df1f922-f4ae-4142-8402-287fbc8653cc/minio
ls -al

# 结果为：
lrwxrwxrwx 1 root root  165 Nov 20 16:25 0.log -> /mnt/sdc/docker/containers/87d726631391a07798cfcf981e2e8bc8c1b8d9fb00ea05ae3cf279e315b9c972/87d726631391a07798cfcf981e2e8bc8c1b8d9fb00ea05ae3cf279e315b9c972-json.log

# 继续进入 /mnt/sdc/docker/containers/87d726631391a07798cfcf981e2e8bc8c1b8d9fb00ea05ae3cf279e315b9c972/ 查看日志的链接路径
# 将完整路径记录下来（有一些节点，软链接路径不止两级），全部绑定到 fluentd 上
```

**磁盘绑定方式**

```bash
# 编辑 fluentd 的 daemonset
kubectl edit daemonset -n t9k-monitoring fluentd-ds
```

修改挂载的 volumes：

<details><summary><code class="hljs">fluentd-ds.yaml</code></summary>

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-ds
  ...
spec:
  ...
  template:
    spec:
      containers:
      - name: xxxx
        volumeMounts:
        - mountPath: /var/log/pods
          name: varlogpods
          readOnly: true
        - mountPath: /mnt/sdc/docker/containers
          name: mntsdcdockercontainers
          readOnly: true
        - ...
      volumes:
      - hostPath:
          path: /var/log/pods
          type: ""
        name: varlogpods
      - hostPath:
          path: /mnt/sdc/docker/containers
          type: ""
        name: mntsdcdockercontainers
      - ...
```

</details>

>注意： 所有节点的所有软链接上的路径都需要写到这里，因为所有节点上的 fluentd 都是这个 daemonset 创建的。
>当然，也可以对每一个节点，单独创建 fluentd daemonset，但较麻烦。


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

## 参考

<https://github.com/fluent/fluentd>
