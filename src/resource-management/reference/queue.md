# Queue

## Spec

下面是一个 Queue 的示例

```yaml
apiVersion: scheduler.tensorstack.dev/v1beta1
kind: Queue
metadata:
  name: test
spec:
  priority: 1
  preemptible: false
  closed: false
  quota:
    requests:
      cpu: 40
      memory: 200Gi
  nodeSelector:
    matchExpressions:
    - key: kubernetes.io/hostname
      operator: In
      values:
      - z02
      - z820
  namespaceSelector: 
    matchExpressions:
    - key: kubernetes.io/metadata.name
      operator: In
      values:
      - demo
```

Queue Spec 中的所有字段如下：

* `priority`：类型 int，值范围 [0,100]，默认值 0。定义 Queue 的优先级。优先级高的 Queue 会被优先分配资源，开启抢占时，优先级高的 Queue 可以抢占优先级低的 Queue 的资源。
* `preemptible`：类型 bool，未设置时默认可被抢占资源。说明 Queue 是否可以被其他 Queue 抢占资源。
* `closed`：类型 bool，默认值 false。表明 Queue 是否被关闭，无法创建使用关闭的 Queue 的资源对象。
* `quota.requests`：类型 map，定义 Queue 可以使用的资源上限。
* `nodeSelector`：类型 labelSelector，通过标签来筛选节点，Queue 可以使用这些节点的资源。未设置时，表明 Queue 可以使用所有节点的资源。
* `namespaceSelector`：类型 labelSelector，通过标签来筛选 namespace，这些 namespace 有权使用这个 Queue。未设置时，表明所有 namespace 都不可以使用这个 Queue。

## Status

下面是一个 Queue status 示例：

```yaml
status:
  allocated:
    cpu: 21590m
    memory: "102622035968"
    nvidia.com/gpu: "1"
  conditions:
  - lastTransitionTime: "2023-10-09T10:54:18Z"
    message: Queue is open
    reason: QueueOpen
    status: "False"
    type: QueueClosed
  - lastTransitionTime: "2023-10-09T10:54:18Z"
    message: Queue has sufficient resource quota
    reason: QueueHasNoResourcePressure
    status: "False"
    type: ResourcePressure
  podGroups:
    total: 27
  pods:
    failed: 1
    pending: 0
    running: 17
    succeeded: 2
    unknown: 0
```

Queue Status 中的所有字段如下：

* `allocated`：Queue 已被分配的资源量
* `conditions`：
    * Type QueueClosed：记录 Queue 的开关状态以及开关时刻。
    * Type ResourcePressure：当 Queue 使用的资源超过 Quota 90%  时，提示资源压力。
* `podGroups`：运行在 Queue 中的 podGroup 数量，包含虚拟的 PodGroup 数量（当一个 Pod 使用 Queue 且 Pod 未指定 PodGroup 时，调度器会创建一个虚拟的 PodGroup）。
* `pods`：Queue 中处于不同 phase 的 Pod 数量
