# 验证控制器

## 运行状态

安装 T9k Admission 之后，运行下列命令检查验证控制器的组件是否正常运行：

Webhook configuration (<a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#configure-admission-webhooks-on-the-fly">参考</a>)：

```bash
$ kubectl get validatingwebhookconfigurations gatekeeper-validating-webhook-configuration
NAME                                          WEBHOOKS   AGE
gatekeeper-validating-webhook-configuration   2          216d
```

Gatekeeper Pods and services：

```bash
$ kubectl -n t9k-system get pod -l app=gatekeeper
NAME                                            READY   STATUS    RESTARTS          AGE
gatekeeper-audit-69c9c485df-7kkcr               1/1     Running   153 (10m ago)     20d
gatekeeper-controller-manager-c9d6c5dd8-6d9hm   1/1     Running   188 (3h23m ago)   207d
gatekeeper-controller-manager-c9d6c5dd8-bgzw2   1/1     Running   181 (6h16m ago)   173d
gatekeeper-controller-manager-c9d6c5dd8-cdtvx   1/1     Running   113 (9h ago)      216d

$ kubectl -n t9k-system get svc -l app=gatekeeper
NAME                         TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
gatekeeper-webhook-service   ClusterIP   10.233.39.78   <none>        443/TCP   216d
```

默认部署的 Provider 配置：

```bash
$ kubectl get provider
NAME                  AGE
container-resources   20d
queue-authz           20d
resource-shape        20d
workload-info         20d
```

检查 Provider Server 详情：

```bash
# url: https://t9k-admission-provider.t9k-system:443/authz/queue
$ kubectl get provider queue-authz -o yaml
# url: https://t9k-admission-provider.t9k-system:443/workload/info
$ kubectl  get provider workload-info -o yaml

$ kubectl -n t9k-system get svc,pod -l app=t9k-admission-provider
NAME                             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/t9k-admission-provider   ClusterIP   10.233.53.165   <none>        443/TCP   46d

NAME                                          READY   STATUS    RESTARTS   AGE
pod/t9k-admission-provider-779bd676b5-4klms   1/1     Running   0          19d
```

上述 4 个默认部署的 provider 均由 T9k Admission Provider 提供服务，T9k Admission Provider 详情见[参考：T9k Admission Provider](../reference/t9k-admission-provider.md)。

## 验证规则

管理员需要通过 ConstraintTemplate（规则模版） 和 Constraint（规则实例） 来定义验证规则：

1. ConstraintTemplate：规则模版定义了验证规则的逻辑以及 Constraint 的 Kind 和 Spec 字段。
1. Constraint：在规则模版被定义后，管理员可以创建该规则模版对应的规则实例。规则实例可以设置验证逻辑作用于哪些项目的哪些资源对象。

一个 Constraint 对应一个验证规则。

### 示例

下面是一个 ConstraintTemplate 示例，`spec` 内容如下：

* `crd`：定义了 Constraint 的 kind 是 K8sRequiredLabels；Constraint Spec 可以设置参数 labels，类型是 string array。
* `targets`：使用 <a target="_blank" rel="noopener noreferrer" href="https://www.openpolicyagent.org/docs/latest/policy-language/">rego</a> 语言编写的验证逻辑，当用户创建/修改目标资源对象时，如果资源对象的 label key 缺少参数里定义的值，拒绝目标资源对象的创建。

```yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
 name: k8srequiredlabels
spec:
 crd:
   spec:
     names:
       kind: K8sRequiredLabels
     validation:
       # Schema for the `parameters` field
       openAPIV3Schema:
         type: object
         properties:
           labels:
             type: array
             items:
               type: string
 targets:
   - target: admission.k8s.gatekeeper.sh
     rego: |
       package k8srequiredlabels

       violation[{"msg": msg, "details": {"missing_labels": missing}}] {
         provided := {label | input.review.object.metadata.labels[label]}
         required := {label | label := input.parameters.labels[_]}
         missing := required - provided
         count(missing) > 0
         msg := sprintf("you must provide labels: %v", [missing])
       }
```

下面是上述 ConstraintTemplate 对应的 Constraint 示例：

* `kind` 是 K8sRequiredLabels，表明他是上述 ConstraintTemplate 对应的 Constraint。
* `spec.match` 表明验证规则作用于 Namespace 资源对象。
* `spec.parameters.labels` 设置了参数 ["gatekeeper"]。

```yaml
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequiredLabels
metadata:
 name: ns-must-have-gk
spec:
 match:
   kinds:
     - apiGroups: [""]
       kinds: ["Namespace"]
 parameters:
   labels: ["gatekeeper"]
```

综上，Constraint 示例 ns-must-have-gk 定义的验证规则作用是：当用户创建/更新 Namespace 时，如果 Namespace 的标签缺少 key gatekeeper，则拒绝 Namespace 的创建/更新。

### T9k 验证规则列表

平台会在集群内部署一些默认的 ConstraintTemplate，并会为大多数 ConstraintTemplate 部署一个默认的 Constraint。管理员可以按需修改，不建议管理员删除这些 ConstraintTemplate，如果你想要关闭对应的验证规则，删除对应的 Constraint 即可。

平台提供的验证规则列表见[参考：T9k 验证规则列表](../reference/t9k-verification-rules.md)。

### 查看验证规则

运行下列命令可以查看已有 ConstraintTemplate：

```bash
$ kubectl get constrainttemplate
NAME                             AGE
disallowunauthorizeduseofqueue   20d
verifyworkloadscheduler          3d
```

运行下列命令可以查看 ConstraintTemplate disallowunauthorizeduseofqueue 对应的所有 Constraints：

```bash
$ kubectl get disallowunauthorizeduseofqueue
NAME           ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
unauthorized   warn                 4
```

运行下列命令可以查看所有 ConstraintTemplate 的所有 Constraints：

```bash
$ kubectl get constraints
NAME                                                                  ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
verifyworkloadscheduler.constraints.gatekeeper.sh/default-scheduler   deny                 1
NAME                                                                    ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
disallowunauthorizeduseofqueue.constraints.gatekeeper.sh/unauthorized   warn                 4
```

<aside class="note info">
<div class="title">提示</div>

Gatekeeper 生成 constraint CRD 时，会将 CRD 的 `spec.names.categories` 字段设置为 `[constraint,constraints]`，所以可以通过 `kubeclt get constraint` 来查看所有的 Constraints（参考 <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#categories">CRD categories</a>）。

</aside>

### 增加验证规则

管理员需要通过创建 ConstraintTemplate 和 Constraint 来创建验证规则。可参考 <a target="_blank" rel="noopener noreferrer" href="https://open-policy-agent.github.io/gatekeeper/website/docs/howto">Gatekeeper docs</a> 来创建 ConstraintTemplate 和 Constraint。

### 修改验证规则

管理员需要通过修改 ConstraintTemplate 和 Constraint 来修改验证规则。

常见的修改方法有：

1. 修改 Constraint 的 [`spec.enforcementAction`](../reference/gatekeeper.md#enforcementaction) 字段，来控制 Validation 如何处理违规资源对象。
1. 修改 Constraint 的 [`spec.match`](../reference/gatekeeper.md#match) 字段，控制验证规则作用于哪些资源对象、哪些 namespace。

### 禁用验证规则

有下列几种方法可以使得验证规则失效：

1. 修改 Constraint 的 `spec.enforcementAction` 为 warn 或 dryrun。详情见[参考：Constraint Spec](../reference/gatekeeper.md#constraint)。
2. 删除 Constraint 即可禁用其对应的验证规则。以默认验证规则为例，运行下列命令可以禁用验证规则 `disallowunauthorizeduseofqueue.constraints.gatekeeper.sh/all-workloads`：

```bash
$ kubectl delete disallowunauthorizeduseofqueue.constraints.gatekeeper.sh/all-workloads
```

3. 删除 ConstraintTemplate。

<aside class="note warning">
<div class="title">警告</div>

删除 ConstraintTemplate 会导致对应的所有 Constraint 都被删除。

</aside>

## 禁用 Gatekeeper

在紧急情况下，也可以禁用整个 GateKeeper。可通过删除 webhook configuration 实现：

```bash
# WARNING: this will delete the webhook configuration
# Assuming default name is used
$ kubectl delete validatingwebhookconfigurations gatekeeper-validating-webhook-configuration
```

如需要重新启用，需要重新创建这个 webhook configuration（<a target="_blank" rel="noopener noreferrer" href="https://open-policy-agent.github.io/gatekeeper/website/docs/emergency">参考</a>）。

更多的相关配置：

* webhook 的 failurePolicy（<a target="_blank" rel="noopener noreferrer" href="https://open-policy-agent.github.io/gatekeeper/website/docs/failing-closed">参考</a>）。
* webhook 的 namespaceSelector（<a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#matching-requests-namespaceselector">参考</a>）。
* 其他 webhook 的配置，例如 auditing、monitoring、best practices 等（<a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/">参考</a>）。

## TLS 证书

Gatekeeper 和 T9k Admission Provider 运行 https 服务，下面说明如何配置它们的 TLS 证书。

### gatekeeper

Gatekeeper Controller Manager 会自动管理 gatekeeper 相关的 ssl 证书，包括：

1. 自动更新 secret gatekeeper-webhook-server-cert 中存储的 ssl 证书
1. 自动配置 validatingwebhookconfigurations gatekeeper-validating-webhook-configuration 的 `webhooks[*].clientConfig.caBundle` 字段

通过下列命令可以查看生成的证书：

```bash
$ kubectl -n t9k-system get secret gatekeeper-webhook-server-cert -o yaml
```

查看 cert 的过期时间：

```bash
$ kubectl -n t9k-system get secret gatekeeper-webhook-server-cert \
   -o jsonpath='{.data.tls\.crt}' | base64 --decode | openssl x509  -noout -enddate
```

通过下列命令可以查看 validatingwebhookconfiguration 配置，其中 `webhooks[*].clientConfig.caBundle` 字段与上述 secert 的 ca.crt 一致。

```bash
$ kubectl get validatingwebhookconfigurations gatekeeper-validating-webhook-configuration -o yaml
```

### T9k Admission Provider

T9k Admission Provider 的 ssl 证书目前是手动生成的（临时方案，后续提升），有效期是是十年。

通过下列命令查看证书：

```bash
$ kubectl -n t9k-system get secret t9k-admission-provider-cert -o yaml
```

通过下列命令查看 Provider 的详情，provider queue-authz 和 workload-info 中的 `spec.caBundle` 字段应该与上述的 secert ca.crt 一致：

```bash
$ kubectl get provider queue-authz -o yaml
$ kubectl get provider workload-info  -o yaml
```

手动生成 ssl 证书的方法见[参考：手动生成 TSL 证书](../reference/generate-tsl-cert.md)。
