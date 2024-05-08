# 安装后配置

## 目的

进行初次安装后的配置工作，包括报警发送方式、日志系统等。

## 前提条件

完成 [产品安装](./install.md)。

## 管理员登录

以 T9k 产品管理员 (t9k-admin) 身份登陆系统，完成初步设置：

1. 在浏览器中访问 <https://home.sample.t9kcloud.cn/t9k/landing-page/>；
2. 点击**集群管理（Cluster Admin）**；
3. 通过 [安装产品](./install.md) 一节使用的配置文件中设置的 T9k 平台管理员账号密码登录。

点击**用户管理 > 用户**，进入用户列表页面。

<figure class="screenshot">
  <img alt="user-list" src="../../../assets/installation/online/user-list.png" />
</figure>

点击右上角的**创建用户**来创建一个新用户。

<figure class="screenshot">
  <img alt="create-user" src="../../../assets/installation/online/create-user.png" />
</figure>

点击**项目管理 > 项目**，进入项目列表页面。

<figure class="screenshot">
  <img alt="project-list" src="../../../assets/installation/online/project-list.png" />
</figure>

点击右上角的**创建项目**来创建一个新项目。

<figure class="screenshot">
  <img alt="create-project" src="../../../assets/installation/online/create-project.png" />
</figure>

## T9k 调度器配置

### 创建默认队列

如果集群部署了 T9k 调度器，您需要在集群管理页面：
1. 为 T9k 调度器创建名为 `default` 的队列；
2. 修改 default 队列的配置，允许所有用户使用该队列。

打开**集群管理（Cluster Admin）** 页面（参考[登录管理员账号](#登录管理员账号)），点击**资源管理 > T9k 调度器 > 队列**，进入队列列表页面。

<figure class="screenshot">
  <img alt="queue-list" src="../../../assets/installation/online/queue-list.png" />
</figure>

点击右上角的 **+** 来创建一个新队列，队列名称填写为 `default`，其他字段按需填写（参考 [设置 Queue 的属性](../../../resource-management/t9k-scheduler.md#设置-queue-的属性)）。

<figure class="screenshot">
  <img alt="queue-list" src="../../../assets/installation/online/create-queue.png" />
</figure>

回到队列列表页面，点击 `default` 队列的名称，进入队列详情页面。

<figure class="screenshot">
  <img alt="queue-list" src="../../../assets/installation/online/queue-detail.png" />
</figure>

点击**限制 > 用户/组**的编辑按钮，将用户权限设置为所有人。

<figure class="screenshot">
  <img alt="queue-list" src="../../../assets/installation/online/queue-all-users.png" />
</figure>

## 监控系统

### 安装 cAdvisor 服务

<aside class="note">
<div class="title">注意</div>

需要确认 t9k-monitoring 已经正确安装。

</aside>

在 K8s 1.24 及之后的版本，kubelet cadvisor 无法提供有效的 metrics 信息。管理员需要单独部署 cadvisor 服务来提供集群的 metrics 信息。已测试过存在该问题的 K8s 版本有 1.24.10，1.25.9，其他未测试版本根据 <a target="_blank" rel="noopener noreferrer" href="https://github.com/google/cadvisor/issues/2785#issuecomment-1205538108">issue</a> 中的讨论也存在相同的问题。

参考：[T9k Monitoring & Alert 问题记录](https://docs.google.com/document/d/141Vyd2joYRgdL0gttc6iLZnOFvWsHXFWFPXiafOkV0w/edit#heading=h.8zt69amb1stn)


1. 删除 servicemonitor kubelet 的 cadvisor 部分：

    ```bash
    kubectl -n t9k-monitoring edit servicemonitor kubelet

    # 需要删除的部分
    kubectl -n t9k-monitoring get servicemonitor kubelet \
        -o jsonpath="{.spec.endpoints[?(@.path=='/metrics/cadvisor')]}"
    ```

2. 部署 cadvisor 服务：
 
    <aside class="note">
    <div class="title">离线安装</div>

    如果采用本地容器镜像服务器，需要修改镜像仓库的设置：

    ```bash
    sed -i "s|docker.io/t9kpublic|192.168.101.159:5000/t9kpublic|g" \
      ../ks-clusters/additionals/monitoring/cadvisor.yaml
    ```

    </aside>


    ```bash
    kubectl apply -n kube-system -f ../ks-clusters/additionals/monitoring/cadvisor.yaml
    ```

### 配置 AlertManager

管理员可以通过创建 <a target="_blank" rel="noopener noreferrer" href="https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1alpha1.AlertmanagerConfig">AlertmanagerConfig</a> 来配置警报通知的处理，包括报警接收方 receivers，报警路由 route，报警抑制规则 inhibitRules。Alertmanager 支持多种订阅警报消息的方式，包括邮件、微信等等。

AlertmanagerConfig 是 namespace-scope resource，多个配置聚合在一起完成 Alertmanager 的配置功能。AlertmanagerConfig 需要与 Alertmanager 服务在同一个 namespace 中，并且包含以下 label，才能被系统识别：

```yaml
tensorstack.dev/component: alertmanager-config
tensorstack.dev/component-type: system
```

#### 邮件接收

想要通过邮件接受警报消息，管理员需要创建：

* Secret：存储 SMTP 用户密码
* AlertmanagerConfig

AlertmanagerConfig 需要设置 `spec.receivers.emailConfig` 字段，并提供如下信息：

* `<SMTP-server-host>`：SMTP 服务器地址。
* `<username-for-authentication>`：用于 SMTP 服务认证的用户名。
* `<sender-address>`：警报消息的发送方邮件地址。
* `<alert-recipient-address>`：警报消息的接收者的邮件地址。

示例如下：

```yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
metadata:
labels:
  tensorstack.dev/component: alertmanager-config
  tensorstack.dev/component-type: system
name: email
namespace: t9k-monitoring
spec:
 receivers:
 - emailConfigs:
   - authPassword:
       key: password
       name: email-password
     authUsername: <username-for-authentication>
     from: <sender-address>
     smarthost: <SMTP-server-host>
     to: <alert-recipient-address>
   name: t9k-sre
 route:
   groupBy:
   - alertname
   matchers:
   - name: severity
     value: critical
   - name: component
     value: t9k-user
     matchType: !=
   - name: namespace
     value: "|ceph.*|gatekeeper-system|gpu-operator|ingress-nginx|istio-system|keycloak-operator|knative-serving|kube-system|kubernetes-dashboard|t9k-monitoring|t9k-system"
     matchType: "=~"
   groupInterval: 5m
   groupWait: 30s
   receiver: t9k-sre
   repeatInterval: 6h
---
apiVersion: v1
kind: Secret
metadata:
 name: email-password
 namespace: t9k-monitoring
type: Opaque
data:
 password: <base64-encoded-password-for-authentication>
```


#### 微信接收

想要通过企业微信接受警报消息，管理员需要创建：

* Secret：存储企业微信 API Secret
* AlertmanagerConfig

AlertmanagerConfig 需要设置 `spec.receivers.wechatConfig` 字段，并提供如下信息：

* `<corpID>`：企业微信的 Company ID
* `<agentID>`：企业微信应用对应的 agentID
* `<toUser>`：optional，想要发送给哪些用户，值是 @all 时表明发送给所有用户。

如果想简化企业微信消息格式，可以将 `spec.receivers[0].wechatConfigs[0].message` 字段设置为 `{{ template "wechat.t9k.message" . }}`。

示例如下：

```yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
metadata:
 labels:
   tensorstack.dev/component: alertmanager-config
   tensorstack.dev/component-type: system
 name: wechat-test
 namespace: t9k-monitoring
spec:
 receivers:
 - wechatConfigs:
   - corpID: <corpID>
     agentID: <agentID>
     toUser: <toUser>
     message: '{{ template "wechat.t9k.message" . }}'
     apiSecret:
       name: wechat-apisecret
       key: apiSecret
   name: 'wechat'
 route:
   groupBy:
   - alertname
   matchers:
   - name: severity
     value: critical|warning
     matchType: =~
   - name: component
     value: t9k-user
     matchType: !=
   - name: namespace
     value: "|ceph.*|gatekeeper-system|gpu-operator|ingress-nginx|istio-system|keycloak-operator|knative-serving|kube-system|kubernetes-dashboard|t9k-monitoring|t9k-system"
   groupInterval: 5s
   groupWait: 10s
   receiver: wechat
   repeatInterval: 6h
---

apiVersion: v1
kind: Secret
metadata:
 name: wechat-apisecret
 namespace: t9k-monitoring
type: Opaque
data:
 apiSecret: <base64-encoded-apiSecret-for-authentication>
```

#### 查看配置

查看系统中的 AlertmanagerConfig

```bash
kubectl get AlertmanagerConfig -n t9k-monitoring \
  -l tensorstack.dev/component=alertmanager-config
```

查看 email 账号的安全凭证（密码）配置

```bash
kubectl -n t9k-monitoring get secret email-password
```

## Logging 系统

### 配置 ElasticSearch

新部署好的 ElasticSearch 需要添加以下设置：

1. index 的生命周期：30 天自动删除，防止数据过多
1. timestamp 类型设置为纳秒级别

```yaml
# 将部署好的 ElasticSearch 暴露出来：
kubectl -n t9k-monitoring port-forward service/elasticsearch-client 9200:9200

# 发送如下请求创建 ILM Policy，用于自动清理创建时间超过 30 天的 index：
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

# 创建 Template，使 ElasticSearch 自动将 ILM Policy 绑定到合适的 Index（t9k-deploy-log-、t9k-deploy-log-、t9k-deploy-log-、t9k-event-）上，并设置 timestamp 的类型（在搜索的时候，如果时间精度不够会导致顺序错误）：
curl -X PUT "http://localhost:9200/_template/logging_policy_template?pretty" \
 -H 'Content-Type: application/json' \
 -d '{
  "index_patterns": ["t9k-build-log-*", "t9k-deploy-log-*", "t9k-system-log-*", "t9k-event-*"],
  "mappings": {
    "properties": {
      "@timestamp": {
        "type": "date_nanos"
      }
    }
  },
  "settings": { "index.lifecycle.name": "t9k-policy" }
}'
```

#### 验证

```bash
curl -X GET "http://localhost:9200/_ilm/policy"  | jq .\"t9k-policy\"
```

```
{
  "version": 1,
  "modified_date": "2023-09-21T06:40:38.863Z",
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {}
      },
      "delete": {
        "min_age": "30d",
        "actions": {
          "delete": {
            "delete_searchable_snapshot": true
          }
        }
      }
    }
  }
}
```

```bash
curl -G "http://localhost:9200/_template" | jq .\"logging_policy_template\" 
```

```
{
  "order": 0,
  "index_patterns": [
    "t9k-build-log-*",
    "t9k-deploy-log-*",
    "t9k-system-log-*",
    "t9k-event-*"
  ],
  "settings": {
    "index": {
      "lifecycle": {
        "name": "t9k-policy"
      }
    }
  },
  "mappings": {
    "properties": {
      "@timestamp": {
        "type": "date_nanos"
      }
    }
  },
  "aliases": {}
}
```

### 节点 Label

检查节点的以下 label：

```yaml
# 查看所有节点
kubectl get node

# 查看具有 fluentd-ds-ready 标签的节点，期望的输出是所有的节点
kubectl get node -l beta.kubernetes.io/fluentd-ds-ready="true"

# 查看具有 control-plane 标签的节点，期望的输出是所有控制平面节点
kubectl get node -l node-role.kubernetes.io/control-plane

# 查看具有 control-plane 标签的节点，期望的输出是 1-2 个负责控制 ingress 的节点
kubectl get node -l node-role.kubernetes.io/ingress
```

### fluentd 的路径

kubernetes 的日志系统是通过软连接组织的。日志的实际路径在节点安装的时候由安装人员指定。如果不知道，在本节后面有如何查看软链接的方法。

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

>注意： 所有节点的所有软链接上的路径都需要写到这里，因为所有节点上的 fluentd 都是这个 daemonset 创建的。
>当然，也可以对每一个节点，单独创建 fluentd daemonset，但较麻烦。

### 日志格式

Kubernetes 底层可以使用不同的容器运行时，比如在 [Kubernetes 1.24.7 适配](https://docs.google.com/document/d/11vrEiYmV8uwHDSJcgz1TGpd87bVtnsT15EKy3k7HGU0/edit#)的时候，就使用不同的容器运行时。不同的运行时，存储的日志格式是不同的：

* 之前的版本日志格式：`{"log":" Average Recall     (AR) @[ IoU=0.50:0.95 | area= large | maxDets=100 ] = 0.804\n","stream":"stdout","time":"2022-09-19T06:13:01.856641709Z"}`
* 新版本日志格式：`2022-10-25T05:54:00.897711526Z stderr F 	/root/repos/aimd-server/gen/component/repos/aimd-server/pkg/lakefs/client.go:102 +0x251`

所以日志的解析方式也需要变化，Fluentd 之前使用 json parser 对日志进行解析，现在需要使用 regexp parser 对日志进行解析（需要修改 fluentd-ds ConfigMap）。

<aside class="note">
<div class="title">注意</div>

ConfigMap 中多处使用 parser 组件，只有 source 组件中的 parser 组件才是用来解析日志的，需要进行替换；其他的 parser 组件是用来解析其他字段的，不需要修改。

</aside>

之前版本（Docker）的日志解析方式：

```
<parse>
  @type json
  time_format %Y-%m-%dT%H:%M:%S.%NZ
</parse>
```

将日志当成 json 来解析，提取其中的 time 字段作为当前日志的时间戳，time 字段的格式为 %Y-%m-%dT%H:%M:%S.%NZ。

新版本（containerd）的日志解析方式：

```
<parse>
  @type regexp
  time_key logtime
  expression /^(?<logtime>[^ ]*) (stdout|stderr) F (?<log>.*)$/
  time_format %Y-%m-%dT%H:%M:%S.%NZ
</parse>
```

用正则表达式（`/^(?<logtime>[^ ]*) (stdout|stderr) F (?<log>.*)$/`）分析日志，将其中 `<logtime>` 所匹配到的字符串作为日志的时间戳，其格式为 `%Y-%m-%dT%H:%M:%S.%NZ`。

## 下一步

运行 <a target="_blank" rel="noopener noreferrer" href="https://t9k.github.io/user-manuals/latest/get-started/index.html"> 快速入门的例子 </a>，检验集群的功能。

注意：如果没有预先下载用户文档中使用的镜像，第一次创建资源时需要等待较长时间（根据网络情况，约 10 分钟）。


## 参考

<https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1alpha1.AlertmanagerConfig>
