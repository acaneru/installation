# Project Resource Quota

Project Resource Quota 可以限制 Project 中的工作负载可以使用的资源上限。CRD Project 中定义了 project 的 quota 及其他信息，project controller 负责 reconcile 这些配置。

## 运行状态

```bash
# pod
$ kubectl -n t9k-system get pods -l tensorstack.dev/component=project
NAME                                                   READY   STATUS    RESTARTS   AGE
project-operator-controller-manager-74c9568997-dbmqt   1/1     Running   0          5d

# logs
$ kubectl -n t9k-system logs --tail=-1 -l tensorstack.dev/component=project
I1 10/16 08:53:17 project_controller.go:91 project-operator/project-controller [reconcile project] name=sec-project
I1 10/16 08:53:17 controller.go:270 project-operator/controller [Successfully Reconciled] controller=project name=sec-project namespace=sec-project reconcilerGroup=tensorstack.dev reconcilerKind=Project
...
```

## 配置控制器

执行以下命令，查看项目控制器（project controller）的 deployment：

```yaml
$ kubectl -n t9k-system get deploy project-operator-controller-manager   \
  -o jsonpath-as-json='{.spec.template.spec.containers[].args}'
[
    [
        "--health-probe-bind-address=:8081",
        "--metrics-bind-address=0.0.0.0:8080",
        "--leader-elect",
        "--show-error-trace",
        "--v=3",
        "--event-ctl-image=tsz.io/t9k/event-controller:1.77.1",
        "--event-ctl-config=/event-ctl/config.json",
        "--quota-warning-percentage=80",
        "--disable-cert-rotation=false"
    ]
]
```

参数说明：

* health-probe-bind-address：设置服务健康检查 API 的地址，请勿修改
* metrics-bind-address：设置服务指标 API 的地址，请勿修改
* leader-elect：控制器使用“选举机制”，用于避免运行多个实例控制器时导致对同一个资源事件的重复处理
* show-error-trace 和 v ：日志设置，分别是打印 error 的产生途径、日志等级
* event-ctl-image 和 event-ctl-config：项目控制器会在每一个项目中会创建一个事件控制器，来收集当前项目下的资源变化。这两个字段为事件控制器配置，分别指定事件控制器的镜像和配置文件。
* quota-warning-percentage：资源配额警告水位线，该实例中当资源使用量达到配额的 80% 以上时，会在项目状态中提示“资源使用量过高”的信息，该参数的取值范围是 [0, 100]
* disable-quota-profile：禁用 QuotaProfile
* disable-cert-rotation：
    * 默认为 false，此时 cert-rotation 负责自动管理生成 webhook 的 ssl 证书，并正确设置 validatingwebhookconfiguration。
    * 设置为 true，表明禁用 cert-rotation，管理员需要改用其他方式来管理 webhook 的 ssl 证书，并需要正确配置 validatingwebhookconfiguration。

### 事件控制器配置

用户创建一个 project 之后，Project 控制器会在相应的 namespace 中运行一个事件控制器以观测 project 中有关对象的变化，并产生相应的 K8s events。

查看项目 demo 的 event-controller 的 logs：

```bash
$ kubectl -n demo logs -l app=event-controller --tail=100
I1 10/20 04:37:06 controller.go:103 event-controller/tensorflowtrainingjobs [start to watch] from=454541178
I1 10/20 04:47:19 controller.go:103 event-controller/tensorboards [start to watch] from=471778799
…
```

监听会因为网络错误、链接超时等原因而中断，上述日志中 from=454541178 表示事件控制器从 454541178 这个 resource version 开始继续监听一种资源，resource version 字段在资源定义中的位置如下：

```yaml
apiVersion: tensorstack.dev/v1beta1
kind: Notebook
metadata:
  creationTimestamp: "2023-10-18T06:09:49Z"
  generation: 3
  name: kaniko
  resourceVersion: "479109581"
  uid: 4c9ba5f8-08af-42ef-ac46-4d92a10a8cc2
```

查看事件控制器（event controller）的配置（所有 project 的 event controller 配置一样）：

```bash
$ kubectl -n t9k-system get cm project-operator-event-ctl-config
NAME                                DATA   AGE
project-operator-event-ctl-config   1      7d
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
metadata:
  name: project-operator-event-ctl-config
  namespace: t9k-system
```

config.json 中 resources 的每一个元素都是事件控制器监控的一种资源，事件控制器会检测这些资源的变化，产生对应的事件（创建、删除等）。

运行下列命令可以修改事件控制器的配置文件：

```bash
$ kubectl -n t9k-system edit cm project-operator-event-ctl-config
```

如果需要添加新资源的监控，扩展 config.json 中的 resources 字段即可。如增加对 resource imagebuilders.tensorstack.dev/v1beta1 的监控：

```yaml
apiVersion: v1
data:
  config.json: |-
    {
      "resources": [
        {
          "group": "tensorstack.dev",
          "version": "v1beta1",
          "resource": "imagebuilders"
        },
        ...
      ]
    }
kind: ConfigMap
metadata:
  name: project-operator-event-ctl-config
  namespace: t9k-system
```

修改过配置后，需重新启动 Project 控制器使配置生效：

```bash
$ kubectl -n t9k-system rollout restart deploy/project-operator-controller-manager

# optionally, watch for restart process
$ kubectl -n t9k-system get pods -l control-plane=project-ctl -w
```

## 设置 Quota

Project 的资源配额可通过两种方式设置：

1. 直接设置 `.spec.resourceQuota` 字段
1. 通过设置 `.spec.quotaProfile` 字段，间接设置项目的 `.spec.resourceQuota` 字段

设置后的生效机制：

* `.spec.quotaProfile`：实时生效：
    * 当 Project 通过 `.spec.quotaProfile` 字段引用一个 Quota Profile，Project 控制器查看 QuotaProfile 中记录的资源配额，并将 Project `.spec.resourceQuota` 的资源配额设置为该值。
    * 若 Quota Profile 发生改变，则 Project 控制器会列举所有引用该 Quota Profile 的 Project，修改对应的 Project `.spec.resourceQuota`。
* `.spec.resourceQuota`：实时生效：
    * Project 控制器观测这个字段的变化，并实时创建/修改对应的 <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/concepts/policy/resource-quotas/">Resource Quotas</a> objects。
    * K8s 系统的 <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/tasks/administer-cluster/quota-api-object/">ResourceQuota admission plugins 具体负责保证</a>一个这个 Resource Quota objects 的设置被实施。

### Project Resource Quota

```bash
# project is a namespace scoped resource
$ kubectl -n demo get project demo -o yaml
```

```yaml
# project demo
apiVersion: tensorstack.dev/v1beta1
kind: Project
metadata:
  name: demo
spec:
  defaultScheduler:
    t9kScheduler:
      queue: default
  quotaProfile: demo
  resourceQuota:
    template:
      spec:
        hard:
          cpu: "200"
          memory: 1Ti
          nvidia.com/gpu: "16"
          persistentvolumeclaims: "20"
          pods: "100"
```

### QuotaProfile

CRD QuotaProfile 是资源配额模版，可用于批量修改项目的资源配额，其 spec 字段设置方式与 Resource Quota 相同，请参考 <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/concepts/policy/resource-quotas/">Resource Quota 文档</a>。

```bash
# QuotaProfile is a namespaced resource and created in namespace 't9k-system'
$ kubectl -n t9k-system get quotaprofile demo -o yaml
```

```yaml
apiVersion: tensorstack.dev/v1beta1
kind: QuotaProfile
metadata:
  name: demo-quota
  namespace: t9k-system
spec:
  hard:
    cpu: "200"
    memory: 1Ti
    nvidia.com/gpu: "16"
    persistentvolumeclaims: "20"
    pods: "1000"
```

```bash
# project is a namespace scoped resource
$ kubectl -n demo get project demo -o yaml
```

```yaml
# project demo
apiVersion: tensorstack.dev/v1beta1
kind: Project
metadata:
  name: demo-project
spec:
  defaultScheduler:
    t9kScheduler:
      queue: default
  quotaProfile: demo-quota
  resourceQuota:
    template:
      spec:
        hard:
          cpu: "200"
          memory: 1Ti
          nvidia.com/gpu: "16"
          persistentvolumeclaims: "20"
          pods: 1k
```

如上述内容，当 Quota Profile demo-quota 中记录的资源配额发生改变，Project demo-project 会立刻修改 `.spec.resourceQuota` 字段，调整资源配额。

这些修改最终体现在 namespace 里的 ResourceQuota objects:

```bash
# inspect the ResourceQuota objects created and status
$ kubectl -n demo get resourcequota demo -o yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: demo
  namespace: demo
...
spec:
  hard:
    cpu: "200"
    memory: 1Ti
    nvidia.com/gpu: "16"
    persistentvolumeclaims: "20"
    pods: 1k
status:
  hard:
    cpu: "200"
    memory: 1Ti
    nvidia.com/gpu: "16"
    persistentvolumeclaims: "20"
    pods: 1k
  used:
    cpu: 3110m
    memory: 7244Mi
    persistentvolumeclaims: "11"
    pods: "9"
```
