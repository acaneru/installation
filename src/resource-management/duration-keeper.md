# Duration Keeper

```
TODO: 说明如何在系统中关闭 Duration Keeper。
```

Duration Keeper 限制 Pod 的最大运行时长。例如，如果管理员为一个 Queue 设置了最大运行时长，则当使用其资源的 Pod 运行时间超出时，Duration Keeper 将尝试终止此 Pod。

Duration Keeper 遵守下列规则：

1. DaemonSet 的 Pod 不会被删除；
2. 优先级大于等于特定 `priority-class-threshold`（通过命令行参数设置） 的 Pod 不会被删除。

## 运行状态

查看 Duration Keeper 的运行状态：

```bash
kubectl -n t9k-system get pod -l tensorstack.dev/component=duration-keeper
```

```
NAME                               READY   STATUS    RESTARTS   AGE
duration-keeper-56b77df59f-f7854   1/1     Running   0          3d6h
```

查看 Duration Keeper 的日志：

```bash
kubectl -n t9k-system logs -l tensorstack.dev/component=duration-keeper -f
```

<details><summary><code class="hljs">output</code></summary>

```log
level=info time=2024-01-19T06:29:21.491096433Z msg=[Flag] name=log-level value=info
level=info time=2024-01-19T06:29:21.491370503Z msg=[Flag] name=metrics-addr value=:8080
level=info time=2024-01-19T06:29:21.49139546Z msg=[Flag] name=schedulers value=t9k-scheduler
level=info time=2024-01-19T06:29:21.491403677Z msg=[Flag] name=t9kSystemNamespace value=t9k-system
level=info time=2024-01-19T06:29:21.491411454Z msg=[Flag] name=threadiness value=1
W0419 06:29:21.491487       1 client_config.go:617] Neither --kubeconfig nor --master was specified.  Using the inClusterConfig.  This might not work.
level=info time=2024-04-19T06:29:21.492790927Z Start="Run Duration Keeper"
```

</details>

## 设置

### 命令行参数

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

管理员可通过 `kubectl edit` 修改 duration keeper 的命令行参数：

```bash
kubectl -n t9k-system edit deploy duration-keeper
```

### 运行时长

管理员可通过 Queue 的 `spec.maxDuration` 字段来设置 Queue 的最大运行时长。`spec.maxDuration` 为空时，Queue 中运行的工作负载不会被 Duration Keeper 删除/暂停。

> 注意：其它场景的最大运行时常支持待提供。

## Pod 删除行为

Duration Keeper 针对不同类型的 Pods 采用不同的删除方式：

1. Pod 由更加高层次的 Owner Controller，例如 Deployment 创建维护，并且可以通过修改 Owner API Object 来删除 Pod，则 Duration Keeper 会使用上层 API 实现删除 Pod；
2. Pod 无 Owner Controller 维护，或者 Pod Owner 未提供删除 Pod 的 Spec API，则 Duration Keeper 直接删除 Pod。

<aside class="note">
<div class="title">支持的 Owner API</div>

> TODO: Make sure the following list is accurate.

如果 Pod 的 Owner 是下列资源对象，则 Duration Keeper 会修改 Owner spec 字段来删除 Pod：

K8s 内置的 API：

1. Deployment：将 `spec.replicas` 设为 0
2. StatefulSet：将 `spec.replicas` 设为 0。
3. ReplicaSet：将 `spec.replicas` 设为 0。
4. Job：将 `spec.suspend` 设为 true。

T9k 提供的 API：

1. T9k Job：将 T9k Job 的 `spec.runMode.pause.enabled` 字段设为 `true`；
     1. MPIJob
     2. ColossalAIJob
     3. DeepSpeedJob
     4. GenericJob
     5. PyTorchTrainingJob
     6. TensorFlowTrainingJob
     7. XGBoostTrainingJob
2. Tensorboard：将 `spec.runMode` 设为 `paused`；
3. Notebook：将 `spec.runMode` 设为 `paused`；
4. MLService：将 `spec.runMode` 设为 `paused`；
5. SimpleMLService：将 `spec.replicas` 设为 0。


当 Pod 有多级祖先资源时，Duration Keeper 找到最高级别的可修改的祖先资源，然后对其进行修改。例如：Pod 的祖先关系如下，`MLService -> Knative Service -> Configuration -> Revision -> Deployment -> ReplicaSet -> Pod`，Duration Keeper 则只修改 `MLService`。

</aside>

## 示例

### 创建 Queue

创建 Queue，设置最大运行时长设置为 `10s`：

```yaml
apiVersion: scheduler.tensorstack.dev/v1beta1
kind: Queue
metadata:
  name: short-runs
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

创建 Deployment `nginx`，使用 Queue `short-runs`：

```bash
kubectl create -f - << EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nginx-test
  template:
    metadata:
      labels:
        app: nginx-test
        scheduler.tensorstack.dev/queue: short-runs
    spec:
      schedulerName: t9k-scheduler
      containers:
      - image: t9kpublic/nginx
        name: nginx
        resources:
          requests:
            cpu: 1
            memory: 100Mi
EOF
```

然后查看 Pod 和 Deployment 的运行状态：

```bash
kubectl get pod -l app=nginx-test
```

```
NAME                    READY   STATUS    RESTARTS   AGE
nginx-test-5fd6c6c5bb-cn5p4   1/1     Running   0          8s
nginx-test-5fd6c6c5bb-kxznl   1/1     Running   0          8s
```

可以发现 Pod 存在时间超过 10s 之后，Deployment 的 `spec.replicas` 会被设置为 0，从而导致 Pod 被删除：

```
kubectl get deploy
```

```
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
test   0/0     0            0           11s
```

查找 Pod：

```bash
kubectl get pod -l name: deploy-test
```

无相关 Pod：

```
NAME                    READY   STATUS    RESTARTS   AGE
```


查看 events：

```bash
kubectl get event | grep deployment/nginx-test
```

```log
2m52s       Normal    ScalingReplicaSet     deployment/nginx-test              Scaled up replica set test-5fd6c6c5bb to 2
2m40s       Warning   MaxDurationExceeded   deployment/nginx-test              Set spec.replicas to 0 because its pod's lifetime exceeded maxDuraion defined in Queue
2m40s       Normal    ScalingReplicaSet     deployment/nginx-test              Scaled down replica set test-5fd6c6c5bb to 0
```
