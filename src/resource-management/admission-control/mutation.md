# Mutation

用户发送创建/修改资源对象的请求后，Mutation 会对相关的资源对象进行修改，然后 K8s API Server 会接收到修改后的资源对象。某些特殊情况下，Mutation 会直接拒绝资源对象的创建/修改行为。

Mutation 中定义了多个 features，目前的 features 均作用于 Pod，详情见 [features 列表](#features-列表)。

## 运行状态

安装 T9k Admission 之后，运行下列命令检查 mutation 的组件是否正常运行：

```bash
$ kubectl -n t9k-system get pod -l tensorstack.dev/component=admission
NAME                                 READY   STATUS    RESTARTS   AGE
admission-control-5688b8cb69-pld6z   1/1     Running   0          20s

$ kubectl -n t9k-system get svc -l tensorstack.dev/component=admission
NAME                TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
admission-webhook   ClusterIP   10.233.9.182   <none>        443/TCP   6d17h
```

查看 logs：

```bash
$ kubectl -n t9k-system logs -l app=admission-control --tail=100 -f
W1020 08:35:30.838783       1 client_config.go:617] Neither --kubeconfig nor --master was specified.  Using the inClusterConfig.  This might not work.
level=info time=2023-10-20T08:35:30.844678432Z configuration=Features InitConfiguration="features is set according to ConfigMap admission-features"
level=info time=2023-10-20T08:35:30.847042008Z configuration=Arguments InitConfiguration="set arguments for Security.ContainerNVIDIAGPUENV.PodMutation according to configmap"
level=info time=2023-10-20T08:35:30.847071556Z configuration=Arguments InitConfiguration="set arguments for Scheduler.SetDefaultScheduler.PodMutation according to configmap"
level=info time=2023-10-20T08:35:30.847085665Z configuration=Arguments InitConfiguration="set arguments for Security.SecurityContext.PodMutation according to configmap"
I1020 08:35:31.948372       1 request.go:690] Waited for 1.098064408s due to client-side throttling, not priority and fairness, request: GET:https://10.233.0.1:443/apis/discovery.k8s.io/v1?timeout=32s
level=info time=2023-10-20T08:35:34.450589267Z msg="starting admission control"
level=info time=2023-10-20T08:35:34.45066687Z msg="setting up cert rotation"
level=info time=2023-10-20T09:22:44.389571375Z configuration=Arguments msg="Received ConfigMap watch event" configmap=t9k-system/admission-arguments eventType=MODIFIED resourceVersion=472495540
level=info time=2023-10-20T09:22:44.38960508Z configuration=Arguments UpdateConfiguration="set arguments for Security.ContainerNVIDIAGPUENV.PodMutation according to configmap"
level=info time=2023-10-20T09:22:44.389639832Z configuration=Arguments UpdateConfiguration="set arguments for Scheduler.SetDefaultScheduler.PodMutation according to configmap"
level=info time=2023-10-20T09:22:44.389651132Z configuration=Arguments UpdateConfiguration="set arguments for Security.SecurityContext.PodMutation according to configmap"
```

## 查看/修改配置

Mutation 有 4 种类型的配置：

1. 命令行参数：基本配置，例如 log level。
1. features 配置：控制 features 的开启/关闭。
1. arguments 配置：提供参数，控制 mutation 的具体行为。
1. mutatingwebhookconfiguration：用于向 K8s 注册 mutation 服务。

### 命令行参数

Mutation 有下列命令行参数：

* enable-leader-election：Enable leader election for controller manager. Enabling this will ensure there is only one active controller manager.
* log-level：log level can be "debug", "info", "warn" or "error" (default "info")
* metrics-addr：The address the metric endpoint binds to. (default ":8080")
* mutator-path：Webhook register path for mutator. (default "/mutate")
* port：Secure port that the webhook listens on (default 443)
* webhook-cert-dir：The directory where certs are stored in webhook server, default is /tmp/k8s-webhook-server/serving-certs (default "/tmp/k8s-webhook-server/serving-certs")

查看当前命令行参数：

```bash
$ kubectl -n t9k-system get deploy admission-control \
  -o jsonpath-as-json='{.spec.template.spec.containers[].args}' jsonpath-as-json='{.spec.template.spec.containers[].args}'
[
    [
        "--webhook-cert-dir=/etc/ssl/admission-control"
    ]
]
```

可通过下面命令修改命令行参数：

```bash
$ kubectl -n t9k-system edit deploy admission-control
```

### features 配置

Mutation 根据 features 配置文件来确定开启/关闭哪些 features，features 配置存放在 ConfigMap admission-features 中。

#### 配置示例

```yaml
apiVersion: v1
data:
  _example: |-
    ################################
    #                              #
    #    EXAMPLE CONFIGURATION     #
    #                              #
    ################################
    # This block is not actually functional configuration,
    # but serves to illustrate the available configuration
    # options and document them in a way that is accessible
    # to users that `kubectl edit` this config map.
    #
    # These sample configuration options may be copied out of
    # this example block and unindented to be in the data block
    # to actually change the configuration.
    # indicates whether restrict SecurityContext of Containers in Pod, value is "enabled" | "disabled", default is "enabled"
    security.securitycontext.pod-mutation: enabled
    # indicates whether set env NVIDIA_VISIBLE_DEVICES=void in a container which doesn't declare extended resources about the NVIDIA GPU.
    # value is "enabled" | "disabled", default is "enabled"
    security.container-nvidia-gpu-env.pod-mutation: enabled
    # indicates whether set spec.schedulerName when pod's spec.scheduerName is default-scheduler.
    # value is "enabled" | "disabled", default is "enabled".
    scheduler.set-default-scheduler.pod-mutation: enabled
  scheduler.set-default-scheduler.pod-mutation: disabled
  security.container-nvidia-gpu-env.pod-mutation: enabled
  security.securitycontext.pod-mutation: disabled
kind: ConfigMap
metadata:
  name: admission-features
  namespace: t9k-system
```

#### features 列表

##### *scheduler.set-default-scheduler.pod-mutation*

描述：将 Pod 的调度器修改为指定的调度器名称（指定的调度器名称在 arguments 中配置）。

目标资源对象：Pod

##### *security.container-nvidia-gpu-env.pod-mutation*

描述：mutatoin 会修改 Container 的环境变量 NVIDIA_VISIBLE_DEVICES。具体行为是：

1. 如果用户在 Pod Spec 中为 Container 设置了环境变量 NVIDIA_VISIBLE_DEVICES，且环境变量值不是 void，本策略根据 arguments prevent-pod-creation 的值进行以下操作：
    1. true：禁止 Pod 的创建。
    1. false：删除用户设置的环境变量 NVIDIA_VISIBLE_DEVICES，然后创建 Pod。
1. 如果 Container 未声明与 NVIDIA GPU 相关的扩展资源，Mutation 会为 Container 添加环境变量 NVIDIA_VISIBLE_DEVICES=void。

目标资源对象：Pod

##### *security.securitycontext.pod-mutation*

描述：本策略会对 Pod 的 SecurityContext 子字段 allowPrivilegeEscalation 和 privileged 进行检查，并根据 arguments 配置对违规 Pod 进行操作。

目标资源对象：Pod

**allowPrivilegeEscalation**

当 allowPrivilegeEscalation 被用户主动设置为 true 时，本策略会认为 Pod 是违规的，并根据 arguments 配置进行下列操作：

* ignore：什么都不做，允许 Pod 的创建。
* deny：拒绝 Pod 的创建。
* mutate：将 allowPrivilegeEscalation 修改为 false。

当 allowPrivilegeEscalation 未被主动设置时（K8s 认为 allowPrivilegeEscalation 默认值是 true），本策略会根据配置参数进行下列操作：

* ignore：什么都不做
* deny/mutate：将 allowPrivilegeEscalation 设置为 false。

<aside class="note">
<div class="title">注意</div>

因为用户创建 Pod 时很有可能不会设置 allowPrivilegeEscalation 字段。所以在用户未主动设置 allowPrivilegeEscalation 字段时，本策略不会拒绝 Pod 的创建，只是默认将 allowPrivilegeEscalation 改为 false。

</aside>

**privileged**

当 privileged 被设置为 true 时，本策略会认为 Pod 是违规的，并根据 arguments 配置进行下列操作：

* ignore：什么都不做，允许 Pod 的创建。
* deny：拒绝 Pod 的创建。
* mutate：将 allowPrivilegeEscalation 修改为 false。

#### 查看配置

运行下列命令可以查看 features 配置文件：

```bash
$ kubectl -n t9k-system get cm admission-features -o yaml
```

#### 修改配置

修改配置文件的命令：

```bash
$ kubectl -n t9k-system edit cm admission-features 
```

### arguments 配置

arguments 配置向 Mutation feature 提供参数。

#### 配置示例

```yaml
apiVersion: v1
data:
  _annotatin: |-
    ################################
    #                              #
    #   EXAMPLE CONFIGURATION      #
    #                              #
    ################################
    # This block is not actually functional configuration,
    # but serves to illustrate the available configuration
    # options and document them in a way that is accessible
    # to users that `kubectl edit` this config map.
    #
    # Arguments for security.securitycontext.pod-mutation
    # 1. "allowPrivilegeEscalation": define mutation's actions about allowPrivilegeEscalation, value can be:
    #   1.1 ignore: do nothing
    #   1.2 deny(default): reject pod creation when user set allowPrivilegeEscalation=true. mutate allowPrivilegeEscalation=false when allowPrivilegeEscalation is not set.
    #   1.3 mutate: mutate allowPrivilegeEscalation to false when user set allowPrivilegeEscalation=true or allowPrivilegeEscalation is not set.
    # 2. "privileged": define mutation's actions about privileged, value can be:
    #   2.1 ignore: do nothing
    #   2.2 deny(default): reject pod creation when user set privileged=true.
    #   2.3 mutate: mutate privileged to false when user set privileged=true.
    security.securitycontext.pod-mutation.json: |-
      {
        "allowPrivilegeEscalation": "deny",
        "privileged": "deny"
      }
    #
    # Arguments for security.container-nvidia-gpu-env.pod-mutation
    # 1. "resource-regex": An array of resource name's regex about nvidia gpu, default is ["^nvidia.com/gpu.*$","^nvidia.com/mig.*$"]
    # 2. "prevent-pod-creation" value is true or false, default is true:
    #       2.1 true: prevent pod creation when Pod's Container is set env NVIDIA_VISIBLE_DEVICES.
    #       2.2 false: delete env NVIDIA_VISIBLE_DEVICES in container when it's set.
    security.container-nvidia-gpu-env.pod-mutation.json: |-
      {
          "resource-regex": ["^nvidia.com/gpu.*$","^nvidia.com/mig.*$"],
          "prevent-pod-creation": true
      }
    #
    # Arguments for scheduler.set-default-scheduler.pod-mutation
    # "scheduler-name": default scheduler's name that admission-control will set for pod whose spec.scheduerName is default-scheduler. default is "t9k-scheduler"
    scheduler.set-default-scheduler.pod-mutation.json: |-
      {
          "scheduler-name": "t9k-scheduler"
      }
  scheduler.set-default-scheduler.pod-mutation.json: |-
    {
        "scheduler-name": "t9k-scheduler"
    }
  security.container-nvidia-gpu-env.pod-mutation.json: |-
    {
        "resource-regex": ["^nvidia.com/gpu.*$","^nvidia.com/mig.*$"],
        "prevent-pod-creation": true
    }
  security.securitycontext.pod-mutation.json: |-
    {
      "allowPrivilegeEscalation": "mutate",
      "privileged": "mutate"
    }
kind: ConfigMap
metadata:
  name: admission-arguments
  namespace: t9k-system
```

#### arguments 列表

##### *security.container-nvidia-gpu-env.pod-mutation.json*

参数示例：

```json
{
    "resource-regex": ["^nvidia.com/gpu.*$","^nvidia.com/mig.*$"],
    "prevent-pod-creation": true
}
```

* resource-regex：记录 NVIDIA GPU 扩展资源的正则表达式
* prevent-pod-creation：当用户在 Pod Spec 中为 Container 设置了环境变量 NVIDIA_VISIBLE_DEVICES 时，影响 Mutation 的行为。

##### *scheduler.set-default-scheduler.pod-mutation.json*

参数示例：

```json
    {
        "scheduler-name": "t9k-scheduler"
    }
```

* scheduler-name：scheduler.set-default-scheduler.pod-mutation feature 会根据 scheduler-name 来修改 Pod 的调度器名称。

##### *security.securitycontext.pod-mutation.json*

参数示例

```json
{
  "allowPrivilegeEscalation": "deny",
  "privileged": "deny"
}
```

* allowPrivilegeEscalation：可选值”ignore”/“deny”/”mutate”，默认值是 deny。不同值对策略行为的影响请见 [feature 说明](#securitysecuritycontextpod-mutation)。
* privileged：可选值”ignore”/“deny”/”mutate”，默认值是 deny。不同值对策略行为的影响请见 [feature 说明](#securitysecuritycontextpod-mutation)。

#### 查看配置

查看配置文件的命令：

```bash
$ kubectl -n t9k-system get cm admission-arguments -o yaml
```

#### 修改配置

修改配置文件的命令：

```bash
$ kubectl -n t9k-system edit cm admission-arguments 
```

### mutatingwebhookconfiguration

mutation 通过 mutatingwebhookconfiguration admission.tensorstack.dev 向 K8s APIServer 注册 webhook 服务，mutatingwebhookconfiguration API 详情见 <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.28/#mutatingwebhookconfiguration-v1-admissionregistration-k8s-io">K8s Reference</a>。

#### 查看配置

```bash
$ kubectl get mutatingwebhookconfiguration admission.tensorstack.dev -o yaml
```

需要注意，默认的 mutatingwebhookconfiguration 设置了下列 namespaceSelector，使得 Mutation 只作用于 Project 对应的 namespace：

```yaml
webhooks:
-   namespaceSelector:
    matchExpressions:
    - key: project.tensorstack.dev
      operator: In
      values:
      - "true"
```

## 常见操作

TODO

## TLS 证书

Mutation 会自动管理相关的 tls 证书，包括：

1. 自动更新 secret admission-webhook-cert 中存储的 tls 证书
1. 自动配置 mutatingwebhookconfiguration admission.tensorstack.dev 的 `webhooks[*].clientConfig.caBundle` 字段

通过下列命令可以查看生成的证书：

```bash
$ kubectl -n t9k-system get secret admission-webhook-cert  -o yaml
```

查看 cert 的过期时间：

```bash
$ kubectl -n t9k-system get secret admission-webhook-cert  -o jsonpath='{.data.tls\.crt}' \
  | base64 --decode | openssl x509  -noout -enddate
```

通过下列命令可以查看 mutatingwebhookconfiguration 配置，其中 `webhooks[*].clientConfig.caBundle` 字段与上述 secert 的 ca.crt 一致。

```bash
$ kubectl get mutatingwebhookconfiguration admission.tensorstack.dev -o yaml
```
