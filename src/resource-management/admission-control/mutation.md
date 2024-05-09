# 变更控制器

T9k 变更控制器（Mutating Admission Controller）采用 K8s 的 <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/">Dynamic Admission Control</a> 机制实施管理策略。

当用户发送资源（目前，2024/04，变更规则只作用于 Pod）的创建/修改的请求后，T9k 变更控制器会根据策略对此请求进行修改，然后再传送给 K8s API Server。某些情况下，变更控制器也可以直接拒绝资源对象的创建/修改行为。

## 运行状态

安装 T9k Admission 之后，运行下列命令检查 mutating 的组件是否正常运行：

```bash
kubectl -n t9k-system get pod,svc -l tensorstack.dev/component=admission
```

<details><summary><code class="hljs">output</code></summary>

```
NAME                                   READY   STATUS    RESTARTS      AGE
pod/admission-control-cc57874b-zsqjv   1/1     Running   0   23m

NAME                             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/admission-webhook        ClusterIP   10.233.9.182    <none>        443/TCP   23m
```

</details>

查看 logs：

```bash
kubectl -n t9k-system logs -l app=admission-control --tail=100 -f
```

<details><summary><code class="hljs">output</code></summary>

```
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

</details>



## 规则介绍

变更控制器根据变更规则（mutating policy）来对资源对象进行修改/检查，管理员可以修改变更规则的配置，从而控制变更控制器的行为。目前，变更规则可分为两类：

1. 安全：与安全相关的变更规则。
1. 调度器：与调度器相关的变更规则。

### 安全

此类型的规则目前有两个：

1. `securityContext`
     1. 作用于资源对象： Pod
     2. 描述：确保 Pod Container 中定义的 SecurityContext 字段设置符合管理员设置的安全规范，阻止不适当的特权升级等。

2. `containerNvidiaGPUEnv`
     1. 作用于资源对象： Pod
     2. 描述：确保 NVIDIA 的 GPU 设备没有被非授权用户使用。

#### securityContext

变更规则 `securityContext` 会对 Pod Container 中定义的 `SecurityContext` 字段进行检查，具体会检查子字段 `allowPrivilegeEscalation` 和 `privileged。`

本变更规则有下列配置参数:

1. `allowPrivilegeEscalation`：可选值”ignore”/“deny”/”mutate”，默认值是 deny。
1. `privileged`：可选值”ignore”/“deny”/”mutate”，默认值是 deny。


<aside class="note">
<div class="title">说明</div>

**allowPrivilegeEscalation**

当 `allowPrivilegeEscalation` 被用户主动设置为 `true` 时，本变更规则会认为 Pod 是违规的，并根据配置参数进行下列操作：

* `ignore`：do nothing，允许 Pod 的创建。
* `deny`：拒绝 Pod 的创建。
* `mutate`：将 allowPrivilegeEscalation 修改为 false。

当 `allowPrivilegeEscalation` 未被主动设置时，本变更规则会根据配置参数进行下列操作：

* `ignore`：do nothing
* `deny/mutate`：将 `allowPrivilegeEscalation` 设置为 false。

**privileged**

当 `privileged` 被设置为 `true` 时，本变更规则会认为 Pod 是违规的，并根据配置参数进行下列操作：

* `ignore`：do nothing，允许 Pod 的创建。
* `deny`：拒绝 Pod 的创建。
* `mutate`：将 `privileged` 修改为 false。

</aside>

#### containerNvidiaGPUEnv

本变更规则会在用户创建 Pod 时实施如下行为，以保护集群中的 NVIDIA GPU 资源：

1. 如果用户在 Pod 的 Spec 中为 Container 设置了环境变量 NVIDIA_VISIBLE_DEVICES，且环境变量值不是 void，本变更规则根据参数 preventPodCreation 的值进行以下操作：
    1. `true`：禁止 Pod 的创建。
    1. `false`：删除用户设置的环境变量 NVIDIA_VISIBLE_DEVICES。
1. 如果 Container 未声明与 NVIDIA GPU 相关的扩展资源，控制器会为 Container 添加环境变量 NVIDIA_VISIBLE_DEVICES=void。

本规则有下列配置参数：

1. `resourceRegex`：数据类型是 string，默认值是 `^nvidia\.com\/(gpu|mig).*$`。参数值是正则表达式，满足该正则表达式的扩展资源会被认为是 NVIDIA GPU 扩展资源。
1. `preventPodCreation`：数据类型是 bool，默认值是 false。当用户创建 Pod 时为 Container 设置了环境变量 NVIDIA_VISIBLE_DEVICES，参数 preventPodCreation 的值会影响本变更规则的行为：
    1. `true`：本变更规则禁止 Pod 的创建。
    1. `false`：本变更规则删除用户设置的环境变量 NVIDIA_VISIBLE_DEVICES。

### 调度器

#### setDefaultScheduler

本规则会修改 Pod 的调度器名称，将调度器名称修改为本规则的配置参数中定义的 `defaultSchedulerName`：

1. 作用于资源对象： Pod。
1. 描述：利用本变更规则，管理员可以强制让所有 Pod 都使用指定的调度器。Pod 被创建之后，如果 Pod 的 `spec.schedulerName` 不是 `defaultSchedulerName`，本变更规则会将其修改为 `defaultSchedulerName`。

本规则有下列配置参数：

* `defaultSchedulerName`：数据类型是  string。调度器的名称，默认值是 `t9k-scheduler`。

## 规则配置

变更规则配置分存储位置：

1. 与安全相关配置，存储在 ConfigMap `admission-security` 中。
1. 与调度相关配置，存储在 ConfigMap `admission-sched` 中。

### 安全

#### 配置内容

配置存在 ConfigMap admission-security 中，ConfigMap 中可以定义多个模版（profiles）。例如：

```bash
kubectl -n t9k-system  get cm admission-security -o yaml
```

<details><summary><code class="hljs">admission-security.yaml</code></summary>

```yaml
apiVersion: v1
data:
 config.yaml: |
   profiles:
   - name: default
     securityContext:
       enabled: true
       allowPrivilegeEscalation: "deny"
       privileged: "deny"
     containerNvidiaGPUEnv:
       enabled: true
       resourceRegex: ^nvidia\.com\/(gpu|mig).*$
       preventPodCreation: true
   - name: superUser
     securityContext:
       enabled: false
     containerNvidiaGPUEnv:
       enabled: false
kind: ConfigMap
metadata:
  name: admission-security
  namespace: t9k-system
```

</details>

上述配置定义了两个模版：`default` 和 `superUser`。注意 ConfigMap 中必须定义 `default` 模版。

一个模版包含下列字段：

1. `name`：模版名称
1. `securityContext`：用于设置 [securitycontext](#securitycontext) 变更规则的配置参数。当这个字段未设置时，下面所有字段都会被设为默认值。
    1. `enabled`：类型 bool，默认值 `true`。用于表明是否启用这个变更规则。
    1. `allowPrivilegeEscalation`：可选值 `”ignore”/“deny”/”mutate”`，默认值是 `deny`。
    1. `privileged`：可选值 `”ignore”/“deny”/”mutate”`，默认值是 `deny`。
1. `containerNvidiaGPUEnv`：用于设置 [containerNvidiaGPUEnv](#containernvidiagpuenv) 变更规则的配置参数。当这个字段未设置时，下面所有字段都被认为是默认值。
    1. `enabled`：类型 bool，默认值 `true`。用于表明是否启用这个变更规则。
    1. `resourceRegex`：数据类型是 string，默认值是 `^nvidia\.com\/(gpu|mig).*$`。
    1. `preventPodCreation`：数据类型是 bool，默认值是 `true`。

#### 默认配置

> TODO: 如何获得这个默认配置？

当 ConfigMap admission-security 未通过[验证](#配置验证)时，系统会采用下列默认配置：

<details><summary><code class="hljs">cm-default.yaml</code></summary>

```yaml
config.yaml: |
  profiles:
  - name: default
    securityContext:
      enabled: true
      allowPrivilegeEscalation: "deny"
      privileged: "deny"
    containerNvidiaGPUEnv:
      enabled: true
      resourceRegex: ^nvidia\.com\/(gpu|mig).*$
      preventPodCreation: true
```

</details>

#### 应用配置

管理员为 Project Namespace 添加 labels `policy.tensorstack.dev/security-profile:<profile-name>` 来表明这个 namespace 采用哪个模版。

未设置这个标签、或指定的模版不存在，变更控制器会认为这个 namespace 使用 default 模版。

### 调度器

#### 配置内容

配置存在 ConfigMap admission-sched 中，ConfigMap 中可以定义多个模版（profiles），例如：

<details><summary><code class="hljs">admission-sched.yaml</code></summary>

```yaml
apiVersion: v1
data:
 config.yaml: |
   profiles:
   - name: default
     setDefaultScheduler:
       enabled: false
       defaultSchedulerName: t9k-scheduler
   - name: demo
     setDefaultScheduler:
       enabled: true
       defaultSchedulerName: t9k-scheduler
kind: ConfigMap
metadata:
 name: admission-sched
 namespace: t9k-system
```

</details>

上述配置定义了两个模版：default 和 demo。注意：ConfigMap 中必须定义 default 模版。

一个模版包含下列字段：

* name：模版名称。
* setDefaultScheduler：用于设置 [setDefaultScheduler](#setdefaultscheduler) 变更规则的配置参数。当这个字段未设置时，下面所有字段都会被设为默认值。
    * enable：类型 bool，默认值 false。用于表明是否启用这个变更规则。
    * defaultSchedulerName：数据类型是 string，默认值是 t9k-scheduler。

#### 默认配置

当 ConfigMap admission-sched 未通过[验证](#配置验证)时。系统会采用下列默认配置：

<details><summary><code class="hljs">cm-default-admission-sched.yaml</code></summary>

```yaml
config.yaml: |
  profiles:
  - name: default
    setDefaultScheduler:
      enabled: false
      defaultSchedulerName: t9k-scheduler
```
</details>

#### 应用配置

管理员为 Project Namespace 添加 labels `policy.tensorstack.dev/sched-profile:<profile-name>` 来表明这个 namespace 采用哪个模版。未设置这个标签、或指定的模版不存在，变更控制器会认为这个 namespace 使用 default 模版。

### 配置验证

系统会对安全和调度相关的变更规则的配置进行验证，当配置满足下列任一条件时，认为配置未通过验证：

1. 配置对应的 ConfigMap 不存在
1. ConfigMap 未设置 `data."config.yaml"` 字段
1. 未设置名为 default 的模版
1. 有多个模版设置了相同的名称
1. 有模版的名称为空

当配置未通过验证时，系统会采用默认配置（安全，调度）。

## 其他设置

除了变更规则配置，你还可以设置下列内容：

1. Admission Controller 的命令行参数：例如修改 log level。
1. mutatingwebhookconfiguration：设定向 K8s 注册 Admission Controller 时的参数。

### 命令行参数

T9k Admission Controller 支持下列命令行参数：

* `disable-cert-rotation`: 设置为 true 时，会禁用 cert rotation。cert rotation 负责自动生成 [TLS 证书](#tls-证书)。 
* `enable-leader-election`：设置 true 时会启用 leader election。启用 leader election 后，可以部署多副本的变更控制器，leader election 会从中选择一个作为执行变更规则的控制器。
* `log-level`：日志等级，可以被设为 "debug", "info", "warn" 或 "error" (默认 "info")
* `metrics-addr`：metrics 服务对应的地址和端口 (默认 ":8080")
* `mutator-path`：mutation webhook 服务对应的 path (默认 "/mutate")
* `port`：mutation webhook 对应的服务端口(默认 443)
* `webhook-cert-dir`：存储 tls 证书的文件路径 (默认 "/tmp/k8s-webhook-server/serving-certs")

查看当前命令行参数：

```bash
kubectl -n t9k-system get deploy admission-control \
  -o jsonpath-as-json='{.spec.template.spec.containers[].args}'
```

```json
[
    [
        "--webhook-cert-dir=/etc/ssl/admission-control",
        "--log-level=debug"
    ]
]
```

可通过下面命令修改命令行参数：

```bash
kubectl -n t9k-system edit deploy admission-control
```

### MutatingWebhookConfiguration

变更控制器通过 MutatingWebhookConfiguration `admission.tensorstack.dev` 向 K8s APIServer 注册 Webhook，API 详情见 <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.28/#mutatingwebhookconfiguration-v1-admissionregistration-k8s-io">K8s Reference</a>。

查看配置：

```bash
kubectl get mutatingwebhookconfiguration admission.tensorstack.dev -o yaml
```

需要注意，默认的 mutatingwebhookconfiguration 设置了下列 `namespaceSelector`，使得变更控制器只作用于 Project 对应的 namespace（Project namespace 都含有标签 `project.tensorstack.dev: true`）：

```yaml
webhooks:
-   namespaceSelector:
    matchExpressions:
    - key: project.tensorstack.dev
      operator: In
      values:
      - "true"
```

<aside class="note">
<div class="title">注意</div>

当设置了 `namespaceSelector`（<a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.28/#mutatingwebhook-v1-admissionregistration-k8s-io">参考</a>）时：

1. 系统会根据资源对象的 namespace 是否与 `namespaceSelector` 匹配来决定 webhook 是否作用于这个资源对象。
1. 如果资源对象本身就是 Namespace，则根据 `object.metadata.labels` 执行匹配。
1. 如果资源对象是其他类型的 cluster scoped resource，它永远不会跳过 Webhook。

</aside>

### 禁用变更器

在紧急情况下，也可以禁用整个变更器，可通过删除 webhook configuration 实现：

```bash
# WARNING: this will delete the webhook configuration
kubectl delete mutatingwebhookconfiguration admission.tensorstack.dev
```

如需要重新启用，需要重新创建这个 webhook configuration

## 常见操作示例

### 应用安全配置模版

使用 kubectl 查看与安全相关的变更规则配置：

```bash
kubectl -n t9k-system get cm admission-security  -o yaml
```

<details><summary><code class="hljs">admission-security.yaml</code></summary>

```yaml
apiVersion: v1
data:
  config.yaml: |
    profiles:
      - name: default
        securityContext:
          enabled: true
          allowPrivilegeEscalation: deny
          privileged: deny
        containerNvidiaGPUEnv:
          enabled: true
          resourceRegex: ^nvidia\.com\/(gpu|mig).*$
          preventPodCreation: true
      - name: kubevirts
        securityContext:
          enabled: true
          allowPrivilegeEscalation: ignore
          privileged: deny
        containerNvidiaGPUEnv:
          enabled: true
          resourceRegex: ^nvidia\.com\/(gpu|mig).*$
          preventPodCreation: true
kind: ConfigMap
metadata:
  name: admission-security
  namespace: t9k-system
```

</details>

发现配置中定义了两个模版：`default` 和 `kubevirts`。

运行下列命令，将 `kubevirts` 模版应用于 Namespace `demo`：

```bash
kubectl label ns demo policy.tensorstack.dev/security-profile=kubevirts
```

### Web UI

通过 “集群管理（Cluser Admin）” 的网页：

1. 在菜单 “准入控制->变更规则” 下，可以查看/修改变更规则的配置模版。
1. 在菜单 ”项目管理->项目“ 下，进入 Project 详情，可以查看/修改 Namespace 应用的配置模版。

## TLS 证书

变更控制器可以自动管理相关的 TLS 证书，包括：

1. 自动更新 secret admission-webhook-cert 中存储的 TLS 证书
1. 自动配置 mutatingwebhookconfiguration `admission.tensorstack.dev` 的 `webhooks[*].clientConfig.caBundle` 字段

通过下列命令可以查看生成的证书：

```bash
kubectl -n t9k-system get secret admission-webhook-cert  -o yaml
```

查看 cert 的过期时间：

```bash
kubectl -n t9k-system get secret admission-webhook-cert  -o jsonpath='{.data.tls\.crt}' \
  | base64 --decode | openssl x509  -noout -enddate
```

通过下列命令可以查看 mutatingwebhookconfiguration 配置，其中 `webhooks[*].clientConfig.caBundle` 字段与上述 Secret 的 `ca.crt` 一致。

```bash
kubectl get mutatingwebhookconfiguration admission.tensorstack.dev -o yaml
```

## 参考

<https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/>
