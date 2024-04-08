# Gatekeeper

## Provider

Provider 是 Gatekeeper System 中定义的 CRD，用来向 Gatekeeper 提供 externaldata。

下面是一个 Provider 示例：

```yaml
apiVersion: externaldata.gatekeeper.sh/v1beta1
kind: Provider
metadata:
  name: queue-authz
spec:
  caBundle: <>
  timeout: 3
  url: https://t9k-admission-provider.t9k-system:443/authz/queue
```

Provider 所有的 spec 字段如下：

* `caBundle`：用于 TLS 验证的 CA bundle
* `timeout`：单位是秒，超过这个时间，provider 返回 timeout error。
* `url`：提供 externaldata 的服务地址，必须是 https 服务。

参考：<https://open-policy-agent.github.io/gatekeeper/website/docs/externaldata>

## ConstraintTemplate

### Spec

下面是一个 ConstraintTemplate spec 示例：

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

#### crd

定义了一个 CRD，这个 CRD 对应的资源对象就是这个 ConstraintTemplate 的 constraint 实例。

#### targets

用 rego 语言编写的验证逻辑。详情见 <a target="_blank" rel="noopener noreferrer" href="https://www.openpolicyagent.org/docs/latest/policy-language/">Open Policy Agent -> Policy Language</a>。

### status

下面是一个 status 示例：

```yaml
status:
  byPod:
  - id: gatekeeper-audit-69c9c485df-7kkcr
    observedGeneration: 1
    operations:
    - audit
    - mutation-status
    - status
    templateUID: 8dae29db-9a69-4cc2-87ef-b2fe8c53bcce
  - id: gatekeeper-controller-manager-c9d6c5dd8-6d9hm
    observedGeneration: 1
    operations:
    - mutation-webhook
    - webhook
    templateUID: 8dae29db-9a69-4cc2-87ef-b2fe8c53bcce
  - id: gatekeeper-controller-manager-c9d6c5dd8-bgzw2
    observedGeneration: 1
    operations:
    - mutation-webhook
    - webhook
    templateUID: 8dae29db-9a69-4cc2-87ef-b2fe8c53bcce
  - id: gatekeeper-controller-manager-c9d6c5dd8-cdtvx
    observedGeneration: 1
    operations:
    - mutation-webhook
    - webhook
    templateUID: 8dae29db-9a69-4cc2-87ef-b2fe8c53bcce
  created: true
```

status 常见字段解析：

1. `byPod`：列举了所有观察到当前 constrainttemplate 的 gatekeeper 组件
1. `created`：表明当前 constrainttemplate 相关的 CRD 是否被创建完成。

更多信息请参考 <a target="_blank" rel="noopener noreferrer" href="https://open-policy-agent.github.io/gatekeeper/website/docs/constrainttemplates">gatekeeper 文档</a>。

## Constraint 

### Spec

下面是 Constraint 示例，管理员可以通过 Constraint spec 字段来控制验证规则的部分行为。

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

#### enforcementAction

enforcementAction 定义了当资源对象违规时，准入控制器对资源对象采取什么行为。这个字段可选值是 deny/warn/dryrun。默认是 deny。

* deny：禁止资源对象的创建/修改。
* warn：不影响资源对象的创建/修改，在用户创建/修改时显示警告信息，并在 `constraint.status` 中记录违规原因。
* dryrun：不影响资源对象的创建/修改，在 `constraint.status` 中记录违规原因。

#### match

Constraint CRD 的 spec.match 字段定义 Constraint 可以影响哪些资源对象，spec.match 的常见子字段如下。

##### kinds

定义目标资源对象的 apiGroups 和 kinds。

示例：

```yaml
spec:
  match:
    kinds:
    - apiGroups:
      - '*'
      kinds:
      - Pod
    - apiGroups:
      - scheduler.tensorstack.dev
      kinds:
      - PodGroup
```

##### namespaceSelector

类型是 label selector，定义了作用于哪些 namespaces。

示例：

```yaml
spec:
    namespaceSelector:
      matchLabels:
        project.tensorstack.dev: "true"
```

参考：<https://open-policy-agent.github.io/gatekeeper/website/docs/howto#constraints>

#### Status

集群中已经存在并违反 constraints 的资源对象会被记录在 constraint status 字段中。

例如：

```yaml
status:
  auditTimestamp: "2019-05-11T01:46:13Z"
  enforced: true
  byPod:
  - constraintUID: 32bbe633-4cce-453a-9dba-c6ac9f4b7b16
    enforced: true
    id: gatekeeper-audit-69c9c485df-7kkcr
    observedGeneration: 1
    operations:
    - audit
    - mutation-status
    - status
  - constraintUID: 32bbe633-4cce-453a-9dba-c6ac9f4b7b16
    enforced: true
    id: gatekeeper-controller-manager-c9d6c5dd8-6d9hm
    observedGeneration: 1
    operations:
    - mutation-webhook
    - webhook
  violations:
  - enforcementAction: deny
    group: ""
    version: v1
    kind: Namespace
    message: 'you must provide labels: {"gatekeeper"}'
    name: default
  - enforcementAction: deny
    group: ""
    version: v1
    kind: Namespace
    message: 'you must provide labels: {"gatekeeper"}'
    name: gatekeeper-system
  totalViolations: 2
```

status 常见字段解析：

1. `enforced`：表明当前 constraint 是否被 Gatekeeper System 执行
1. `byPod`：列举了所有观察到当前 constraint 的 gatekeeper 组件
1. `violations`：列举了集群中已经存在的，并且违反了当前 constraint 的资源对象
1. `totalViolations`：violations 的总量

更多信息可以参考 <a target="_blank" rel="noopener noreferrer" href="https://open-policy-agent.github.io/gatekeeper/website/docs/audit#constraint-status">gatekeeper 文档</a>。
