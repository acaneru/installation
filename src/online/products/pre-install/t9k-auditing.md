# 审计日志

T9k 审计日志记录下列两种类型的操作：

1. 平台管理：记录 T9k 管理员的操作行为，例如创建用户、修改资源价格等。
2. 资源对象：记录系统 namespace （如 kube-system，t9k-system）及集群范围（cluster-wide） 资源对象发生的变化。例如，管理员修改了 kube-sytstem 中 ConfigMap coredns，或者创建了新的 CRD `workflowtemplates.argoproj.io`。

## 启用 T9k 审计日志

如需启用 T9k 审计日志，请确保进行了下列配置。

### 启用 Kubernetes 审计

安装 K8s 集群时，按照 [设置 Kubernetes 审计](../../k8s-install.md#设置-kubernetes-审计) 对集群进行配置。

### 配置 loki

安装 loki 时，按照 [Values 配置->T9k 审计日志](../../k8s-components/loki.md#t9k-审计日志) 对 promtail 进行配置。

### 产品模块设置

在安装 T9k 产品时通过 values.yaml 文件中设置合适的选项。

**t9k-cluster-admin**

确保 t9k-cluster-admin 使用的 values.yaml 设置了下列字段：

```yaml
options:
  proxyOperationCtl:
    enabled: true
```

**t9k-security-console-api**

确保产品模块 t9k-security-console-api 使用的 values.yaml 中字段 `global.t9k.securityService.resourceManagement.proxyoperation.enabled` 的值是 `true`。

**t9k-cost**

确保产品模块 t9k-cost 使用的 values.yaml 中字段 `global.t9k.cost.proxyoperation.enabled` 的值是 `true`。

## 禁用 T9k 审计日志

如需禁用 T9k 审计日志，请进行下列设置。

### 关闭 Kubernetes 审计

推荐在安装 K8s 集群时，将 [k8s-cluster.yml](../../k8s-install.md#k8s-clusteryml) 的 `kubernetes_audit` 字段设为 false，禁用 Kubernetes 审计。

### 配置 loki

在安装 loki 时，删除 [Values 配置->T9k 审计日志](../../k8s-components/loki.md#t9k-审计日志) 中收集 K8s 审计日志的配置内容。

### 产品模块设置

在安装 T9k 产品时通过 values.yaml 文件中设置合适的选项。

**t9k-cluster-admin**

确保产品模块 t9k-cluster-admin 使用的 values.yaml 设置了下列字段：

```yaml
options:
  proxyOperationCtl:
    enabled: false
```

**t9k-security-console-api**

确保产品模块 t9k-security-console-api 使用的 values.yaml 中字段 `global.t9k.securityService.resourceManagement.proxyoperation.enabled` 的值是 `false`。

**t9k-cost**

确保产品模块 t9k-cost 使用的 values.yaml 中字段 `global.t9k.cost.proxyoperation.enabled` 的值是 `false`。
