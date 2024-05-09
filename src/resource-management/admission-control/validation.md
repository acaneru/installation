# 验证控制器

验证控制器通过 Gatekeeper 实现。

<a target="_blank" rel="noopener noreferrer" href="https://open-policy-agent.github.io/gatekeeper/website/docs">Gatekeeper</a>  是一个用于执行准入策略的 Webhook 认证器 (Validating Webhook)，实现对 Kubernetes 集群的准入控制。Gatekeeper 可以帮助集群管理员实施和执行各种治理策略，确保集群中的资源满足特定的合规标准和最佳实践。

> 快速了解 Gatekeeper 原理，请参考：[Gatekeeper 基本介绍](../appendix/gatekeeper.md)

## 运行状态

安装 T9k Admission 之后，运行下列命令检查验证控制器的组件是否正常运行：

### ValidatingWebhookConfiguration

验证控制器通过 Gatekeeper 实现，通过
ValidatingWebhookConfiguration (<a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#configure-admission-webhooks-on-the-fly">参考</a>) 进行动态配置：

```bash
kubectl get validatingwebhookconfigurations gatekeeper-validating-webhook-configuration
```

```
NAME                                          WEBHOOKS   AGE
gatekeeper-validating-webhook-configuration   2          216d
```

### Gatekeeper

Gatekeeper 的 Pods 及 Services：

```bash
kubectl -n t9k-system get pod,svc -l app=gatekeeper
```

```
NAME                                                 READY   STATUS    RESTARTS      AGE
pod/gatekeeper-audit-bf4dc46f5-vrxvx                 1/1     Running   0             20d
pod/gatekeeper-controller-manager-7555d46ff7-2ds5b   1/1     Running   1 (11d ago)   13d
pod/gatekeeper-controller-manager-7555d46ff7-88f5b   1/1     Running   5 (9d ago)    66d
pod/gatekeeper-controller-manager-7555d46ff7-sfw9r   1/1     Running   5 (47h ago)   66d

NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/gatekeeper-webhook-service   ClusterIP   10.233.34.128   <none>        443/TCP   79d
```

### Provider

Provider 是一种 Gatekeeper 系统中的自定义资源（CustomResource），它定义了如何从外部数据源获取数据，以及如何将这些数据馈送到 Gatekeeper 中进行策略评估。

T9k 默认部署的 Provider ：

```bash
kubectl get provider
```

```
NAME                  AGE
container-resources   20d
queue-authz           20d
resource-shape        20d
workload-info         20d
```

检查 Provider Server 详情：

```bash
kubectl get provider container-resources  -o jsonpath='{.spec.url}'
kubectl get provider queue-authz -o jsonpath='{.spec.url}'
kubectl get provider resource-shape   -o jsonpath='{.spec.url}'
kubectl get provider workload-info -o jsonpath='{.spec.url}'
```

```
https://t9k-admission-provider.t9k-system:443/authz/queue
https://t9k-admission-provider.t9k-system:443/workload/info
https://t9k-admission-provider.t9k-system:443/resource_shape/info
https://t9k-admission-provider.t9k-system:443/workload/container_resources
```

> 上述 4 个默认部署的 provider 均由 T9k Admission Provider 提供服务，T9k Admission Provider 详情见 [附录：T9k Admission Provider](../appendix/t9k-admission-provider.md)。

运行这些 provider 的 Pod 及 Service：

```
kubectl -n t9k-system get svc,pod -l app=t9k-admission-provider
```

```
NAME                             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/t9k-admission-provider   ClusterIP   10.233.53.165   <none>        443/TCP   46d

NAME                                          READY   STATUS    RESTARTS   AGE
pod/t9k-admission-provider-779bd676b5-4klms   1/1     Running   0          19d
```

Pod logs：

```bash
kubectl -n t9k-system logs -l app=t9k-admission-provider --tail=50 -f
```

## 验证规则

管理员需要通过 ConstraintTemplate（规则模版） 和 Constraint（规则实例） 来定义验证规则：

1. ConstraintTemplate：规则模版定义了验证规则的逻辑以及 Constraint 的 Kind 和 Spec 字段。
1. Constraint：在规则模版被定义后，管理员可以创建该规则模版对应的规则实例。规则实例可以设置验证逻辑作用于哪些项目的哪些资源对象。

一个 Constraint 对应一个验证规则。

### 查看

T9k 会在集群内部署一些默认的 ConstraintTemplate，并会为大多数 ConstraintTemplate 部署一个默认的 Constraint。管理员可以按需修改，不建议管理员删除这些 ConstraintTemplate，如果你想要关闭对应的验证规则，删除对应的 Constraint 即可。

T9k 提供的验证规则列表见 [附录：T9k 验证规则列表](../appendix/t9k-verification-rules.md)。


运行下列命令可以查看已有 ConstraintTemplate：

```bash
kubectl get constrainttemplate
```

```
NAME                             AGE
disallowunauthorizeduseofqueue   79d
prohibitqueueoverquota           57d
verifyresourceshape              57d
verifyresourceshapeofcontainer   57d
verifyworkloadscheduler          62d
```

运行下列命令可以查看 ConstraintTemplate disallowunauthorizeduseofqueue 对应的所有 Constraints：

```bash
kubectl get disallowunauthorizeduseofqueue
```

```
NAME           ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
unauthorized   warn                 4
```

运行下列命令可以查看所有 ConstraintTemplate 的所有 Constraints：

```bash
kubectl get constraints
```

<details><summary><code class="hljs">output</code></summary>

```
NAME                                                         ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
prohibitqueueoverquota.constraints.gatekeeper.sh/overquota   deny                 0

NAME                                                                       ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
verifyworkloadscheduler.constraints.gatekeeper.sh/pod-used-scheduler       warn                 0
verifyworkloadscheduler.constraints.gatekeeper.sh/visitor-used-scheduler   deny                 0

NAME                                                                    ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
disallowunauthorizeduseofqueue.constraints.gatekeeper.sh/unauthorized   warn                 4

NAME                                                                        ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
verifyresourceshapeofcontainer.constraints.gatekeeper.sh/verify-sharedgpu   deny                 0

NAME                                                                 ENFORCEMENT-ACTION   TOTAL-VIOLATIONS
verifyresourceshape.constraints.gatekeeper.sh/violateresourceshape   deny                 0
```

</details>


<aside class="note info">
<div class="title">提示</div>

Gatekeeper 生成 constraint CRD 时，会将 CRD 的 `spec.names.categories` 字段设置为 `[constraint,constraints]`，所以可以通过 `kubeclt get constraint` 来查看所有的 Constraints（参考 <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/tasks/extend-kubernetes/custom-resources/custom-resource-definitions/#categories">CRD categories</a>）。

</aside>

### 增加

管理员需要通过创建 ConstraintTemplate 和 Constraint 来创建验证规则。可参考 <a target="_blank" rel="noopener noreferrer" href="https://open-policy-agent.github.io/gatekeeper/website/docs/howto">Gatekeeper docs</a> 来创建 ConstraintTemplate 和 Constraint。

### 修改

管理员需要通过修改 ConstraintTemplate 和 Constraint 来修改验证规则。

常见的修改方法有：

1. 修改 Constraint 的 [`spec.enforcementAction`](../reference/gatekeeper.md#enforcementaction) 字段，来控制 Validation 如何处理违规资源对象。
1. 修改 Constraint 的 [`spec.match`](../reference/gatekeeper.md#match) 字段，控制验证规则作用于哪些资源对象、哪些 namespace。

### 禁用

有下列几种方法可以使得验证规则失效：

1. 修改 Constraint 的 `spec.enforcementAction` 为 warn 或 dryrun。详情见[附录：Constraint Spec](../reference/gatekeeper.md#constraint)。
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
kubectl delete validatingwebhookconfigurations gatekeeper-validating-webhook-configuration
```

如需要重新启用，需要重新创建这个 webhook configuration（<a target="_blank" rel="noopener noreferrer" href="https://open-policy-agent.github.io/gatekeeper/website/docs/emergency">参考</a>）。

更多的相关配置：

* webhook 的 failurePolicy（<a target="_blank" rel="noopener noreferrer" href="https://open-policy-agent.github.io/gatekeeper/website/docs/failing-closed">参考</a>）。
* webhook 的 namespaceSelector（<a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#matching-requests-namespaceselector">参考</a>）。
* 其他 webhook 的配置，例如 auditing、monitoring、best practices 等（<a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/">参考</a>）。

## TLS 证书

Gatekeeper 和 T9k Admission Provider 运行 https 服务，下面说明如何配置它们的 TLS 证书。

### Gatekeeper

Gatekeeper Controller Manager 会自动管理 gatekeeper 相关的 ssl 证书，包括：

1. 自动更新 secret gatekeeper-webhook-server-cert 中存储的 ssl 证书
1. 自动配置 validatingwebhookconfigurations gatekeeper-validating-webhook-configuration 的 `webhooks[*].clientConfig.caBundle` 字段

通过下列命令可以查看生成的证书：

```bash
kubectl -n t9k-system get secret gatekeeper-webhook-server-cert -o yaml
```

查看 cert 的过期时间：

```bash
kubectl -n t9k-system get secret gatekeeper-webhook-server-cert \
  -o jsonpath='{.data.tls\.crt}' | base64 --decode | openssl x509  -noout -enddate
```

通过下列命令可以查看 validatingwebhookconfiguration 配置，其中 `webhooks[*].clientConfig.caBundle` 字段与上述 secert 的 ca.crt 一致。

```bash
kubectl get validatingwebhookconfigurations gatekeeper-validating-webhook-configuration -o yaml
```

### T9k Admission Provider

T9k Admission Provider 的 ssl 证书目前是手动生成的（临时方案，后续提升），有效期是是十年。

通过下列命令查看证书：

```bash
kubectl -n t9k-system get secret t9k-admission-provider-cert -o yaml
```

通过下列命令查看 Provider 的详情，provider queue-authz 和 workload-info 中的 `spec.caBundle` 字段应该与上述的 secert ca.crt 一致：

```bash
kubectl get provider queue-authz -o yaml
kubectl get provider workload-info  -o yaml
```

手动生成 ssl 证书的方法见 [附录：手动生成 TSL 证书](../reference/generate-tsl-cert.md)。


## 参考

<https://open-policy-agent.github.io/gatekeeper/website/docs>

<https://kubernetes.io/docs/reference/access-authn-authz/extensible-admission-controllers/#configure-admission-webhooks-on-the-fly>
