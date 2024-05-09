# Queue

## 概念

> TODO:

## 管理

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
