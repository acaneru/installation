# Duration Keeper

Duration Keeper 会限制使用 Queue 的 Pod 的运行时长，当 Pod 的存在时间超出 Queue 的最大运行时长时，Duration Keeper 会删除 Pod。

Duration Keeper 遵守下列规则：

1. DaemonSet 的 Pod 不会被删除
1. 优先级大于等于 priority-class-threshold（通过命令行参数设置） 的 Pod 不会被删除

## 运行状态

查看 Duration Keeper 的运行状态：

```bash
$ kubectl -n t9k-system get pod -l tensorstack.dev/component=duration-keeper
NAME                               READY   STATUS    RESTARTS   AGE
duration-keeper-56b77df59f-f7854   1/1     Running   0          3d6h
```

查看 Duration Keeper 的日志：

```bash
$ kubectl -n t9k-system logs -l tensorstack.dev/component=duration-keeper
W1215 02:52:01.637881       1 client_config.go:617] Neither --kubeconfig nor --master was specified.  Using the inClusterConfig.  This might not work.
level=info time=2023-12-15T02:52:01.639233235Z Start="Run Duration Keeper"
```

## 设置

### 设置 Duration Keeper

Duration Keeper 有下列命令行参数：

```
  -kube-path string
    	The path of kube config
  -log-level string
    	log level can be "debug", "info", "warn" or "error" (default "info")
  -metrics-addr string
    	listening address for metric (default ":8080")
  -priority-class-threshold string
    	name of an existing PriorityClass, duration-keeper will not evict pods whose priority is larger than or equal to the threshold, defaults to 'system-cluster-critical' whose priority is 2000000000 if not specified
  -t9kSystemNamespace string
    	Namespace of t9k system, default is t9k-system (default "t9k-system")
  -threadiness int
    	number of threadiness to deal with expired pods, default is 1 (default 1)
```

你可以通过 kubectl edit 命令修改 duration keeper 的命令行参数：

```bash
$ kubectl -n t9k-system edit deploy duration-keeper
```

### 设置最大运行时长

管理员可通过 Queue 的 `spec.maxDuration` 字段来设置 Queue 的最大运行时长。`spec.maxDuration` 为空时，Queue 中运行的工作负载不会被 Duration Keeper 删除/暂停。

## 删除 Pod

Duration Keeper 针对不同类型的 Pods 采用不同的删除方式：

1. Pod 由 Owner Controller 创建维护，并且可以通过修改 Owner API Object 来删除 Pod：DurationKeeper 会修改 Pod Owner 的 Spec 以实现删除 Pod。可改的 Owner 记录在“[修改父资源]()”章节。
1. Pod 无 Owner Controller 维护，或者 Pod Owner 未提供删除 Pod 的 Spec API：DurationKeeper 直接删除 Pod。

如果 Pod 的 Owner 是下列资源对象，则 Duration Keeper 会修改 Owner spec 字段来删除 Pod：

1. T9k CRD：
    1. T9k Job：将 T9k Job 的 `spec.runMode.pause.enabled` 字段设为 true。
        1. MPIJob
        1. ColossalAIJob
        1. DeepSpeedJob
        1. GenericJob
        1. PyTorchTrainingJob
        1. TensorFlowTrainingJob
        1. XGBoostTrainingJob
    1. Tensorboard：将 `spec.runMode` 设为 paused
    1. Notebook：将 `spec.runMode` 设为 paused。
    1. MLService：将 `spec.runMode` 设为 paused。
    1. SimpleMLService：将 `spec.replicas` 设为 0。
1. K8s Native Resource：
    1. Deployment：将 `spec.replicas` 设为 0
    1. StatefulSet：将 `spec.replicas` 设为 0。
    1. ReplicaSet：将 `spec.replicas` 设为 0。
    1. Job：将 `spec.suspend` 设为 true。

当 Pod 有多级祖先资源时，按照下面规则来处理祖先资源，DurationKeeper 找到最高级别的可修改的祖先资源，然后对其进行修改。例如：Pod 的祖先关系如下，MLService -> Knative Service -> Configuration -> Revision -> Deployment -> ReplicaSet -> Pod，DurationKeeper 只修改 MLService。

## 示例

### 创建 Queue

在集群管理前端页面创建 Queue，最大运行时长设置为 10s，YAML 如下：

```yaml
apiVersion: scheduler.tensorstack.dev/v1beta1
kind: Queue
metadata:
  name: demo
  namespace: t9k-system
spec:
  closed: false
  maxDuration: 10s
  preemptible: true
  priority: 1
  quota:
    requests:
      cpu: "10"
      memory: "1Gi"
```

### 创建工作负载

运行下列命令，使用 kubectl 创建 Deployment test，使用 Queue demo：

```bash
$ kubectl create -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: test
spec:
  replicas: 2
  selector:
    matchLabels:
      name: deploy-test
  template:
    metadata:
      labels:
        name: deploy-test
        scheduler.tensorstack.dev/queue: demo
    spec:
      schedulerName: t9k-scheduler
      containers:
      - image: tsz.io/czx/nginx:latest
        name: nginx
        resources:
          requests:
            cpu: 1
            memory: 100Mi
EOF
```

然后查看 Pod 和 Deployment 的运行状态：

```bash
$ kubectl get pod -l name: deploy-test
NAME                    READY   STATUS    RESTARTS   AGE
test-5fd6c6c5bb-cn5p4   1/1     Running   0          8s
test-5fd6c6c5bb-kxznl   1/1     Running   0          8s

$ kubectl get pod -l name: deploy-test
NAME                    READY   STATUS    RESTARTS   AGE

$ kubectl get deploy
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
test   0/0     0            0           11s
```

可以发现 Pod 存在时间超过 10s 之后，Deployment 的 `spec.replicas` 会被设置为 0，从而导致 Pod 被删除。

查看 events：

```bash
$ kubectl get event | grep deployment/test
2m52s       Normal    ScalingReplicaSet     deployment/test              Scaled up replica set test-5fd6c6c5bb to 2
2m40s       Warning   MaxDurationExceeded   deployment/test              Set spec.replicas to 0 because its pod's lifetime exceeded maxDuraion defined in Queue
2m40s       Normal    ScalingReplicaSet     deployment/test              Scaled down replica set test-5fd6c6c5bb to 0
```
