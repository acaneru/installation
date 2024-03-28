# T9k 验证规则列表

## T9k Scheduler 相关的验证规则

下列验证规则只能作用于使用 T9k Scheduler 的工作负载或 PodGroup，无法作用于使用其他调度器的工作负载。

### R001 - Disallow unauthorized use of queue

#### 描述

阻止用户在无权使用 Queue 的 namespace 中创建/更新工作负载和 PodGroup

相关参考：[队列的使用权限](../t9k-scheduler.md#使用权限)

#### Template

在集群内运行下列命令可以查看 ConstraintTemplate 详情：

```bash
kubectl get constrainttemplate disallowunauthorizeduseofqueue -o yaml
```

#### 默认 Constraint

T9k 默认会在集群内部署下列 Constraint：

1. 该验证规则作用于所有的用户项目（用户项目对应的 Namespace 含有标签 `project.tensorstack.dev: "true"`）
1. 该验证规则作用于工作负载和 PodGroup
1. 综上：当用户尝试在项目内创建/修改工作负载时，如果当前项目无权使用队列，则拒绝创建/修改行为。

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: DisallowUnauthorizedUseOfQueue
metadata:
 name: unauthorized
spec:
 enforcementAction: deny
 match:
   kinds:
   - apiGroups: ["*"]
     kinds: ["Pod"]
   - apiGroups: ["scheduler.tensorstack.dev"]
     kinds: ["PodGroup"]
   - apiGroups: ["batch.tensorstack.dev"]
     kinds: ["BeamJob","ColossalAIJob","DeepSpeedJob","GenericJob","MPIJob","PyTorchTrainingJob","TensorFlowTrainingJob","XGBoostTrainingJob"]
   - apiGroups: ["tensorstack.dev"]
     kinds: ["AutoTuneExperiment","MLService","Notebook","SimpleMLService"]
   namespaceSelector:
     matchLabels:
       project.tensorstack.dev: "true"
```

### R002 - Prohibit queue overQuota

#### 描述

下列任一条件满足时，认为该工作负载会导致队列资源超额:

1. 工作负载的所有容器申请的资源总量 + 队列已被分配资源量 > 队列资源配额
1. 队列资源配额中定义了 cpu 或 memory，工作负载中有容器未声明 `requests.cpu` 或 `requests.memory`

用户创建工作负载时，如果该工作负载会导致队列资源超额，则 R002 会阻止这个工作负载的创建。

相关参考：[队列的资源配额](../t9k-scheduler.md#资源配额)。

#### Template

在集群内运行下列命令可以查看 ConstraintTemplate 详情：

```bash
kubectl get prohibitqueueoverquota  prohibitqueueoverquota -o yaml
```

#### 默认 Constraint

T9k 默认会在集群内部署下列 Constraint：

1. 该验证规则作用于所有的用户项目
1. 该验证规则作用于工作负载
1. 综上：当用户尝试在项目内创建工作负载时，如果该工作负载会导致队列资源超额，则拒绝创建行为。

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: ProhibitQueueOverQuota
metadata:
 name: overquota
spec:
 enforcementAction: deny
 match:
   kinds:
   - apiGroups: ["*"]
     kinds: ["Pod"]
   - apiGroups: ["batch.tensorstack.dev"]
     kinds: ["BeamJob","ColossalAIJob","DeepSpeedJob","GenericJob","MPIJob","PyTorchTrainingJob","TensorFlowTrainingJob","XGBoostTrainingJob"]
   - apiGroups: ["tensorstack.dev"]
     kinds: ["AutoTuneExperiment","MLService","Notebook","SimpleMLService"]
   namespaceSelector:
     matchLabels:
       project.tensorstack.dev: "true"
```

### R003 - Verify Queue ResourceShape

#### 描述

用户创建/更新使用 T9k Scheduler 的工作负载时，R003 会对工作负载进行 resource shape 检验。如果工作负载声明的资源量超过队列定义的 ResourceShape，拒绝工作负载的创建/更新。

当下列任一条件满足时，会认为工作负载资源量超过 ResourceShape：

1. 工作负载所有容器声明的资源量总和超过 ResourceShape
1. ResourceShape 中定义了 `requests.cpu` 或 `requests.memory`，工作负载中有容器未声明 `requests.cpu` 或 `requests.memory`
1. ResourceShape 中定义了 `limits.cpu` 或 `limits.memory`，工作负载中有容器未声明 `limits.cpu` 或 `limits.memory`

相关参考：[队列的资源尺寸模版（ResourceShape）](../t9k-scheduler.md#资源尺寸模版)

#### Template

在集群内运行下列命令可以查看 ConstraintTemplate 详情：

```bash
kubectl get constrainttemplate  verifyresourceshape -o yaml
```

#### 默认 Constraint

T9k 默认会在集群内部署下列 Constraint：

1. 该验证规则作用于所有的用户项目
1. 该验证规则作用于工作负载
1. 综上：当用户尝试在项目内创建工作负载时，如果该工作负载声明的资源量超过队列定义的 ResourceShape，则拒绝创建行为。

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: VerifyResourceShape
metadata:
 name: violateresourceshape
spec:
 enforcementAction: deny
 match:
   kinds:
   - apiGroups: ["*"]
     kinds: ["Pod"]
   - apiGroups: ["batch.tensorstack.dev"]
     kinds: ["BeamJob","ColossalAIJob","DeepSpeedJob","GenericJob","MPIJob","PyTorchTrainingJob","TensorFlowTrainingJob","XGBoostTrainingJob"]
   - apiGroups: ["tensorstack.dev"]
     kinds: ["AutoTuneExperiment","MLService","Notebook","SimpleMLService"]
   namespaceSelector:
     matchLabels:
       project.tensorstack.dev: "true"
```

## 常规验证规则

### R026 - Verify ResourceShape of Container

#### 描述

用户创建/更新工作负载时，R026 会对工作负载的容器进行 Resource Shape 检验。如果工作负载中任一容器声明的资源量超过 Resource Shape 资源量，拒绝工作负载的创建/更新。Resource Shape 资源量在 Constraint 的 `spec.parameters` 中设置。

#### Template

在集群内运行下列命令可以查看 ConstraintTemplate 详情：

```bash
kubectl get constrainttemplate  verifyresourceshapeofcontainer -o yaml
```

#### 默认 Constraint

T9k 默认会在集群内部署下列 Constraint：

1. 该验证规则作用于所有的用户项目
1. 该验证规则作用于工作负载
1. Resource Shape 资源量是 nvidia.com/gpu.shared: 1
1. 综上：工作负载中每个容器声明的 nvidia.com/gpu.shared 数量不能超过 1（<a target="_blank" rel="noopener noreferrer" href="https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-sharing.html#understanding-time-slicing-gpus">原因</a>），否则拒绝工作负载的创建/更新。

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: VerifyResourceShapeOfContainer
metadata:
 name: verify-sharedgpu
spec:
 enforcementAction: deny
 match:
   kinds:
   - apiGroups: ["*"]
     kinds: ["Pod"]
   - apiGroups: ["tensorstack.dev"]
     kinds: ["AutoTuneExperiment","Notebook","SimpleMLService","MLService"]
   - apiGroups: ["batch.tensorstack.dev"]
     kinds: ["BeamJob","ColossalAIJob","DeepSpeedJob","GenericJob","MPIJob","PyTorchTrainingJob","TensorFlowTrainingJob","XGBoostTrainingJob"]
   namespaceSelector:
     matchLabels:
       project.tensorstack.dev: "true"
 parameters:
   limits:
     nvidia.com/gpu.shared: 1
```

### R027 - Verify workload scheduler

#### 描述

用户创建/更新工作负载时，只能使用指定的调度器，否则拒绝工作负载的创建/更新。

#### Template

在集群内运行下列命令可以查看 ConstraintTemplate 详情：

```bash
kubectl get constrainttemplate  verifyworkloadscheduler -o yaml
```

#### 默认 Constraint

T9k 不会为该 ConstraintTemplate 部署默认的 Constraints。

#### 示例

下面是一个 Constraint 示例：

1. 验证规则作用于 namespace demo
1. 验证规则作用于资源对象 Nodebook
1. 被允许的调度器名称是 default-scheduler
1. 综上：用户在 namespace demo 创建/更新 Notebook 时，使用的调度器必须是 default-scheduler，否则拒绝 Notebook 的创建/更新。

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: VerifyWorkloadScheduler
metadata:
 name: notebook-default-scheduler
spec:
 enforcementAction: deny
 match:
   kinds:
   - apiGroups: ["tensorstack.dev"]
     kinds: ["Notebook"]
   namespaceSelector:
     matchLabels:
       kubernetes.io/metadata.name: demo
 parameters:
   scheduler: ["default-scheduler"]
```
