# T9k Scheduler

T9k Scheduler 是 K8s 调度器，负责将 Pod 分配到合适的节点上。相比于 K8s 的默认调度器 kube-scheduler，T9k Scheduler 增强了对 AI 计算场景的支持，并增加了额外的机制方便对集群进行更加精细化管理等。

通过修改 T9k Scheduler 的配置文件可以调整 T9k Scheduler 的行为。

## 运行状态

t9k-scheduler 以 deploy 的形式部署：

```bash
$ kubectl -n t9k-system get deploy -l app=t9k-scheduler
NAME            READY   UP-TO-DATE   AVAILABLE   AGE
t9k-scheduler   1/1     1            1           6d21h
```

查看 t9k-scheduler 的 logs：

```bash
$ kubectl -n t9k-system logs -l app=t9k-scheduler --tail=200 -f
W1020 09:17:15.765322       1 client_config.go:552] Neither --kubeconfig nor --master was specified.  Using the inClusterConfig.  This might not work.
I1 10/20 09:17:15 init.go:156 t9k-scheduler/base [Flag is set] name=leader-elect value=true
I1 10/20 09:17:15 init.go:156 t9k-scheduler/base [Flag is set] name=v value=1
I0 10/20 09:17:15 init.go:194 t9k-scheduler/base [Initialized] name=t9k-scheduler
I1020 09:17:15.768159       1 leaderelection.go:242] attempting to acquire leader lease  t9k-system/t9k-scheduler...
I1020 09:17:36.148966       1 leaderelection.go:252] successfully acquired lease t9k-system/t9k-scheduler
I0 10/20 09:17:36 scheduler.go:98 t9k-scheduler [Init Config according to ConfigMap] configmap=t9k-system/scheduler-config
I0 10/20 09:17:50 watch_configmap.go:56 t9k-scheduler [Received ConfigMap watch event] configmap=t9k-system/scheduler-config eventType="MODIFIED" resourceVersion=472487800
I0 10/20 09:17:50 scheduler.go:98 t9k-scheduler [Update Config according to ConfigMap] configmap=t9k-system/scheduler-config
```

获得 scheduler 的 metrics：

```bash
$ kubectl -n t9k-system get svc -l app=t9k-scheduler
NAME            TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
t9k-scheduler   ClusterIP   10.233.9.97   <none>        8080/TCP   6d21h

# set up port-forward
$ kubectl -n t9k-system port-forward svc/t9k-scheduler 8080:8080

# scrape metrics
$ curl http://localhost:8080/metrics
# HELP T9kScheduler_node_resource_requests The number of requested request by non-terminal Pods in a Node.
# TYPE T9kScheduler_node_resource_requests gauge
T9kScheduler_node_resource_requests{node="nc01",resource="cpu",unit="core"} 3.77
T9kScheduler_node_resource_requests{node="nc01",resource="hugepages-1Gi",unit="integer"} 0
T9kScheduler_node_resource_requests{node="nc01",resource="hugepages-2Mi",unit="integer"} 0
T9kScheduler_node_resource_requests{node="nc01",resource="memory",unit="byte"} 1.98289408e+09
...
```

## 查看配置

查看 t9k-scheduler 配置文件：

```bash
$ kubectl -n t9k-system get cm scheduler-config -o yaml
```

配置示例：

```yaml
apiVersion: v1
data:
  scheduler.conf: |
    actions: "allocate,preempt"
    tiers:
    - plugins:
      - name: basic
      - name: resource
      - name: affinity
        arguments:
          weight: 10
      - name: predicates
      - name: binpack
        arguments:
          strategy: MostAllocated
          weight: 1
          resources: nvidia.com/gpu,nvidia.com/gpu.shared
          resources.cpu: 2
          resources.memory: 1
          resources.nvidia.com/gpu: 5
          resources.nvidia.com/gpu.shared: 5
kind: ConfigMap
metadata:
  name: scheduler-config
  namespace: t9k-system
```

t9k-scheduler 的配置由 actions 和 plugins 组成。

### actions 

actions 定义了 t9k-scheduler 执行哪些行为，T9k Scheduler 有以下 actions：

1. allocate：必选，否则调度器无法正常工作。allocate 是调度器为 Pod 进行资源分配的行为。
1. preempt：可选。开启 preempt 后，调度器会尝试为 Pending Pod 抢占资源。优先级高的 Queue 可以抢占优先级低的 Queue 使用的资源。

#### 开启/关闭资源抢占

在 actions 中添加/删除 preempt 可以开启/关闭资源抢占模式。

### plugins

plugins 定义了 t9k-scheduler 启用哪些插件，一般不需要修改。plugin 会影响调度器的行为。T9k Scheduler 有以下 plugins：

#### basic

必选。提供基础功能，例如确定 PodGroup 是否满足 minMember 要求、确定 PodGroup 的优先级。

#### affinity

必选。根据 Pod 的 podAffinity 和 nodeAffinity 来对节点进行筛选/排序。

affinity Plugin 有以下参数（arguments）：

1. weight：类型 int，默认值是 1，范围 [0,10]。表明 BinPack 评分所占的权重。

#### predicates

必选。过滤不符合 Pod 要求的节点。

#### resource

开启 actions.preempt 时，必选。作用有：

1. 根据队列的资源使用情况来判断队列的被分配资源的优先级
1. 确保在抢占行为中，低优先级的 Pod 优先被抢占资源。

#### binPack

可选。为 Pod 分配节点时，BinPack 会根据节点上资源使用量来对节点进行评分，BinPack 有两种评分策略：

1. LeastAllocated：allocated/capacity 较低的节点，评分更高。
    1. 影响：为 Pod 分配资源时，优先把 Pod 放置到最空闲的节点上。倾向于让所有节点的资源使用率比较接近。
    1. 适用场景：希望充分利用集群资源，减少资源闲置，以提高集群计算的整体效率。
1. MostAllocated：allocated/capacity 较大的节点，评分更高。
    1. 影响：为 Pod 分配资源时，优先把 Pod 放置到最繁忙的节点上，尽量保持有节点有较多的空闲资源。
    1. 适用场景：尽可能减少节点上的空闲资源碎片，在空闲节点上预留足够多的空闲资源来运行大型任务。

BinPack Plugin 有以下参数（arguments）：
1. strategy：可选值是 LeastAllocated or MostAllocated，默认是 MostAllocated。表明使用的评分策略。
1. weight：类型 int，默认值是 1，范围 [0,10]。表明 BinPack 评分在[节点优先级判定](#节点优先级判定)中所占的权重。
1. resources：类型 []string，默认包含 cpu 和 memory（无论这个参数被设为什么值，BinPack 计算节点分数时都会考虑 cpu 和 memory）。表明 BinPack 会根据哪些资源来计算节点的分数。
1. resource weight：类型 map[string]int，默认的权重是 1，范围 [0,10]。为每种资源定义分数权重。BinPack 会计算每种资源的分数，然后根据资源分数权重来计算出节点的加权总和。

管理员通过 ConfigMap scheduler-config 来设置 BinPack Plugin 的参数，下面是一个 Config 示例：

```yaml
$ kubectl -n t9k-system get cm scheduler-config  -o yaml
apiVersion: v1
data:
  scheduler.conf: |
    actions: "allocate,preempt"
    tiers:
    - plugins:
      - name: basic
      - name: resource
      - name: affinity
        arguments:
          weight: 10
      - name: predicates
      - name: binpack
        arguments:
          strategy: MostAllocated
          weight: 1
          resources: nvidia.com/gpu,nvidia.com/gpu.shared
          resources.cpu: 2
          resources.memory: 1
          resources.nvidia.com/gpu: 5
          resources.nvidia.com/gpu.shared: 5
kind: ConfigMap
metadata:
  name: scheduler-config
  namespace: t9k-system
```

上面示例中，管理员设置 BinPack Plugin 的参数为：

1. strategy：LeastAllocated
1. weight：1
1. resources：BinPack 会根据资源 cpu、memory、nvidia.com/gpu、example.com/foo 的使用情况来判断 Node 的优先级。
1. resource weight：
    1. cpu: 2
    1. memory：1
    1. nvidia.com/gpu：5
    1. nvidia.com/gpu.shared：5

### 调度器行为

Plugin 会影响调度器的下列行为：

#### 判定 Queue 被分配资源的优先级

plugin basic 和 plugin resource 都定义了如何判定 Queue 被分配资源的优先级：

* plugin basic：根据 Queue 的 `spec.priority` 判定 Queue 被分配资源的优先级，`spec.priority` 较大的 Queue 会被优先分配资源。
* plugin resource：根据 Queue 的 Dominant Resource Share 来判断 Queue 的优先级。Dominant Resource Share 较小的 Queue 会被优先分配资源。

当有多个 Plugin 实现 “判定 Queue 被分配资源的优先级” 时：

1. 根据 Plugin 的优先级顺序（[Plugin 的优先级](#plugin-的优先级)）来判定 Queue 被分配资源的优先级，优先采用高优先级的 Plugin 的判定方法。
1. 当优先级高的 Plugin 认为 Queue 被分配资源的优先级相同时，再采用优先级低的 Plugin 来判断 Queue 被分配资源的优先级。

什么是 Dominant Resource Share？

定义：在 Queue 的多种类型资源中，”usage/quota” 最大的资源被称为 Dominant resource，Dominant Resource 的使用量占比是 Dominant Resource Share。

示例：

* Queue Quota 是 {cpu: 10, memory: 20Gi}，Queue 已使用的资源 {cpu: 5,memory: 3Gi}
* CPU share = 5/10 = 0.5，memory share = 3Gi/20Gi = 0.15。所以 CPU 是 Dominant resource，Dominant Resource Share 是 0.5。

#### 节点优先级判定

plugin affinity 和 plugin binPack 都定义了判定节点优先级的方法，当多个节点满足 Pod 需求时，调度器倾向于将 Pod 分配到优先级最高的节点上。

实现了“节点优先级判定”的 Plugin 会同时影响节点优先级判定，每个 Plugin 设有参数 weight，weight 越大的 plugin 对节点优先级判定的影响越大。

### plugin 的优先级

在配置文件的 tires.plugins 中，plugin 的设置顺序会影响下列调度器行为，设置在前面的 plugins 的优先级更高：

* Queue 优先级判定

例如：plugin basic 和 resource 都定义了判定 Queue 被分配资源的优先级的方法，当 plugin basic 优先级更高时（管理员应该配置 plugin basic 有最高的优先级，否则会影响调度器性能）：
1. 调度器会优先采用 basic 中定义的 Queue 优先级判定方法
1. 当 plugin basic 中判定两个 Queue 的优先级相同时，调度器再采用 plugin resource 中定义的 Queue 优先级判定方法。

## 修改配置

运行下列命令可以修改 t9k-scheduler 配置文件：

```bash
$ kubectl -n t9k-system edit cm scheduler-config
```

更新 ConfigMap scheduler-config 之后，t9k-scheduler 会自动监测到配置变化。你可以通过 T9k Scheduler 的日志来查看它是否更新为当前配置：

```bash
$ kubectl -n t9k-system logs -l app=t9k-scheduler --tail=100
...
I0 10/16 01:45:47 scheduler.go:95 t9k-scheduler [Config is Updated] resourceVersion=462771736
```

## HA 部署

为了保证高可用性，可部署多个 scheduler 副本。需要确保以下两点：

1. 副本数量应该 <= 集群中 Master Node 的数量；
1. 运行 T9k Scheduler 的命令中包含命令行参数 `--leader-elect=true`。

示例：

```yaml
$ kubectl -n t9k-system get deploy t9k-scheduler -o yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: t9k-scheduler
  namespace: t9k-system
spec:
  replicas: 3
  template:
    spec:
      containers:
      - args:
        - --v=1
        - --leader-elect=true
        command:
        - /app/t9k-scheduler
...
```

## 禁用/启用 t9k-scheduler

可以通过停止 t9k-scheduler Pod 的方式禁用 t9k-scheduler。

禁用 t9k-scheduler：

```bash
$ kubectl -n t9k-system scale --replicas=0 deploy/t9k-scheduler
deployment.apps/t9k-scheduler scaled
```

启用 T9k Scheduler:

```bash
$ control_plane_count=$(kubectl get nodes -l node-role.kubernetes.io/control-plane="" -o json | jq -r '.items | length')
$ kubectl -n t9k-system scale --replicas=$control_plane_count deploy/t9k-scheduler
```

## Queue 管理

管理员可以通过 Queue 来划分资源池并设置访问权限，对集群资源进行管理。

### 列举 Queue

通过下列命令可以列举集群内所有的 Queue：

```bash
$ kubectl -n t9k-system get q
```

### 查看 Queue

通过下列命令可以查看 Queue demo 的详情：

```bash
$ kubectl -n t9k-system get q demo -o yaml
```

Queue Spec 详情见[附录：Queue](./reference/queue.md)。

### 创建 Queue

你可以通过 Cluster Admin 前端来创建 Queue。

如果你想使用命令行创建 Queue，你需要向 security-console-server 发送请求来创建 Queue，下面是参考示例：

1. 首先将集群内的 security-console-server 服务转发到本地的 8080 端口：

```bash
$ pod_name=$(k -n t9k-system get pod -l tensorstack.dev/component=security-console-server | grep security | awk '{print $1}')
$ kubectl -n t9k-system port-forward $pod_name 8080
```

2. 然后创建 Queue demo：

```bash
$ curl -X POST localhost:8080/apis/v1/admin/queues -d '{
  "name": "demo",
  "labels": {
    "key": "Value"
  },
  "spec": {
    "closed": false,
    "preemptible": false,
    "priority": 80,
    "quota": {
      "requests": {
        "cpu": "10",
        "memory": "100Gi",
        "nvidia.com/gpu": "2"
      }
    }
  }
}'
```

### 修改 Queue 

通过下列命令可以修改 Queue demo 的配置：

```bash
$ kubectl -n t9k-system edit q demo
```

你可以通过修改 Queue Spec 来修改：

* 资源配额
* 优先级
* ……

详情见[附录：Queue](./reference/queue.md)。

### 设置 Queue 的属性

管理员可以设置 Queue 的下列属性，以实现对 Queue 的管理。

#### 使用权限

管理员可以通过下列行为来控制哪些 namespace 有权使用 Queue：

1. 设置 Queue 的使用者
1. 设置 Queue 的 `spec.namespaceSelector` 字段（namespaceSelector 类型是 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes/apimachinery/blob/v0.29.0/pkg/apis/meta/v1/types.go#L1213">labelSelector</a>）

当 namespace N 满足下列任一条件时，用户有权在 namespace N 中创建使用 Queue Q 的工作负载：

1. Queue Q 设置了 spec.namespaceSelector，且 namespace N 的标签符合 Queue Q 的 spec.namespaceSelector 的要求（当 namespaceSelector 字段未设置或设置为 {} 时，任何 namespace 都不满足 namespaceSelector 的要求）；
1. namespace N 是一个 Project namespace，Project 的 owner 是用户 a，并且用户 a 有权限使用 Queue Q。

设置 Queue 的使用者，请参考下面步骤：

1. 进入 Cluster Admin 模块，选择左侧导航菜单的 Scheduler > Queues。
2. 点击想要修改的 Queue 名称，进入 Queue 的详情。
3. 在 Constraints > User/Group 中，点击编辑按钮，选择 Queue 的使用者。

设置 Queue `spec.namespaceSelector`，请参考下面步骤：

1. 进入 Cluster Admin 模块，选择左侧导航菜单的 Scheduler > Queues。
2. 点击想要修改的 Queue 名称，进入 Queue 的详情。
3. 在 Constraints > Namespace 中，点击编辑按钮，从而可以修改 Queue `spec.namespaceSelector`。

#### 资源配额

资源配额用于限制 Queue 可以使用的资源上限。

管理员可以通过 Queue 的 `spec.quota` 字段设置资源配额，示例如下

```yaml
spec:
 quota:
   requests:
     cpu: 60
     memory: 20Gi
     nvidia.com/gpu: 12
     nvidia.com/gpu.shared: 50
```

资源配额的工作机制如下：

1. 管理员为 Queue 设置资源配额。
1. 用户创建使用 Queue 的工作负载时，如果该工作负载会导致 Queue 使用的资源量超出资源配额限制，用户的创建行为会被拒绝。

说明：

1. 资源配额只用于限制工作负载声明的 `resources.requests`，不限制 `resources.limits`(<a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/#requests-and-limits">requests and limits</a>)。
1. 如果 Queue 的资源配额中设置了 cpu、memory，用户创建的工作负载中每一个 Container 中都需要定义 `requests.cpu`、`requests.memory`，否则用户的创建行为会被拒绝。
1. 资源配额不代表集群的实际可使用资源量，无法保证用户使用队列时，集群可供使用的资源量一定超过资源配额。所以管理员需要合理设置资源配额。

#### 优先级

Queue 的优先级可以影响下列行为：

1. 优先级较高的 Queue 会被调度器优先分配资源
1. 优先级较高的 Queue 有权抢占低优先级 Queue 的资源

管理员可以通过 `spec.priority` 字段设置 Queue 的优先级，值范围是 [0,100]，示例如下

```yaml
spec:
  priority: 2
```

#### 是否可被抢占资源

管理员可以通过 Queue 的 `spec.preemptible` 字段来设置 Queue 是否可以被其他 Queue 抢占资源：

1. 字段被设置为 false 时，Queue 无法被其他 Queue 抢占资源。
1. 字段未设置或设置为 true 时，Queue 可以被其他 Queue 抢占资源。

示例：

```yaml
spec:
  preemptible: true
```

#### 开启/关闭

管理员可以通过 Queue 的 `spec.closed` 字段来设置 Queue 是否处于关闭状态，当 Queue 处于关闭状态时，用户无法创建使用 Queue 的工作负载：

1. 字段未设置或被设置为 false 时，Queue 处于开启状态
1. 字段被设置为 true 时，Queue 处于关闭状态

示例：

```yaml
spec:
  closed: true
```

#### 最大运行时长

最大运行时长用于限制 Queue 中 Pod 的运行时长，如果 Pod 的存在时长（Pod 存在时长=当前时间 - Pod 创建时间）超过最大运行时长，Pod 会被删除（详情见 [Duration Keeper](./duration-keeper.md)）。

管理员可以通过 `spec.maxDuration` 字段设置 Queue 的最大运行时长：

1. 值类型是 string，并且需要满足正则表达式 `^(0|(([0-9]+)y)?(([0-9]+)w)?(([0-9]+)d)?(([0-9]+)h)?(([0-9]+)m)?(([0-9]+)s)?(([0-9]+)ms)?)$`
1. 支持的时间单位：y, w（周）, d, h, m, s, ms
1. 示例："3w",  "2h45m"。

设置最大运行时长的示例如下：

```yaml
spec:
  maxDuration: 2h
```

#### 资源尺寸模版

资源尺寸用于限制工作负载可以申请的资源数量，当用户创建/修改的工作负载超过资源尺寸限制时，拒绝创建/修改行为。

在命名空间 t9k-system 中，ConfigMap resource-shapes 定义了所有的资源尺寸模版。运行下列命令可以查看资源尺寸模版：

```yaml
$ kubectl -n t9k-system get cm resource-shapes -o yaml
apiVersion: v1
data:
  config.yaml: |
    profiles:
    - name: default
      rules:
      - apiGroups:
        - '*'
        resources:
        - 'pods'
        resourceShape:
          requests:
            cpu: 10
            memory: 10Gi
          limits:
            cpu: 10
            memory: 20Gi
            nvidia.com/gpu: 4
            nvidia.com/gpu.shared: 1
    - name: superUser
      rules:
      - apiGroups:
        - '*'
        resources:
        - 'pods'
        resourceShape:
          requests:
            cpu: 20
            memory: 20Gi
          limits:
            cpu: 20
            memory: 40Gi
            nvidia.com/gpu: 10
            nvidia.com/gpu.shared: 1
kind: ConfigMap
metadata:
  name: resource-shapes
  namespace: t9k-system
```

ConfigMap 的 `data.[config.yaml].profiles[*]` 字段定义了资源尺寸模版，每个模版包含下列字段：

1. name：模版名称。
1. rules：一组 resourceShape rule，每个 resourceShape rule 包含下列字段：
    1. apiGroups：类型 string[]，这个 rule 作用于哪些 apiGroups。设置为 * 时表明匹配所有的 apiGroups。
    1. resources：类型 string[]，这个 rule 作用于哪些 resources。设置为 * 时表明匹配所有的 resources。
    1. resourceShape：类型 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes/kubernetes/tree/v1.28.4/staging/src/k8s.io/api/core/v1#L2394">ResourceRequirements</a>，apiGroup 匹配 apiGroups，resource 匹配 resources 的资源对象声明的资源量不能超过 resourceShape。

管理员可以通过设置 `spec.resourceShapeProfile` 字段来选择资源尺寸模版，表示 Queue 采用模版中定义的资源量限制：

1. `spec.resourceShapeProfile` 对应的 profile 名称不存在：Queue 无 resourceShape 限制。
1. `spec.resourceShapeProfile` 对应的 profile 名称存在：用户创建/修改使用 Queue 的工作负载时，如果工作负载的资源量超过 resourceShape，禁止创建/修改行为。当下列任一条件满足时，会认为工作负载资源量超过 ResourceShape：
    1. 工作负载所有容器声明的资源量总和超过 ResourceShape
    1. ResourceShape 中定义了 `requests.cpu` 或 `requests.memory`，工作负载中有容器未声明 `requests.cpu` 或 `requests.memory`
    1. ResourceShape 中定义了 `limits.cpu` 或 `limits.memory`，工作负载中有容器未声明 `limits.cpu` 或 `limits.memory`

#### 节点权限

节点权限用于限制 Queue 可以使用哪些节点。

管理员可以通过 spec.nodeSelector 字段设置节点权限，nodeSelector 的类型是 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes/apimachinery/blob/v0.29.0/pkg/apis/meta/v1/types.go#L1213">labelSelector</a>：

1. 未设置时，Queue 可以使用集群内所有的节点。
1. 设置之后，Queue 只能使用节点标签满足 `spec.nodeSelector` 的节点，无法使用其他节点。

示例：

```yaml
spec:
 nodeSelector:
   matchExpressions:
   - key: topology.kubernetes.io/zone
     operator: In
     values:
     - peking
     - tianjin
```

上面为 Queue 设置的节点权限，说明 Queue 可以使用节点标签包含 `topology.kubernetes.io/zone: peking` 或 `topology.kubernetes.io/zone: tianjin` 的节点。

### “Queue 权限机制” 升级

Queue 在 1.76.0 版本之前不具有用户管理功能，如果更新到 1.76.0 之后的版本，需要执行 Queue 转换脚本。

* 项目仓库：https://gitlab.dev.tensorstack.net/t9k/security-console-server
* 脚本运行环境：需能连接到集群、能访问 keycloak 服务
* 执行命令：

```bash
go run ./security-console-server/cmd/queue-transformer/main.go \
  --host auth.xxx.tensorstack.net --username t9kadmin --password xxx
```

(上述参数：--host 为 keycloak 地址，--username 和 --password 分别是 keycloak 管理员的用户名和密码。当前脚本还接受其他参数，具体请参考 --help)
