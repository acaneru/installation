# 审计日志系统

T9k 审计日志分为下列两种类型：
1. 平台管理：记录 T9k 管理员的操作行为，例如创建用户、修改资源价格。
2. 资源对象：记录系统级别 namespace 中的资源对象发生的变化、cluster-wide 资源对象发生的变化，例如管理员在集群中创建了新的 CRD workflowtemplates.argoproj.io。

## 启用 T9k 审计日志

如果你想启用 T9k 审计日志，请确保进行了下列配置。

### 设置 Kubernetes 审计

安装 K8s 集群时，按照[设置 Kubernetes 审计](../../k8s-install.md#设置-kubernetes-审计)对集群进行配置。

### 配置 loki

安装 loki 时，按照[Values 配置->T9k 审计日志](../../k8s-components/loki.md#t9k-审计日志) 对 promtail 进行配置。

### values.yaml

确保 t9k-cluster-admin 使用的 values.yaml 设置了下列字段：

```yaml
options:
  proxyOperationCtl:
    enabled: true
```

## 禁用 T9k 审计日志

如果你想禁用 T9k 审计日志，请参考下列设置。

### [可选]设置 Kubernetes 审计

推荐你在安装 K8s 集群时，将 [k8s-cluster.yml](../../k8s-install.md#k8s-clusteryml) 的 `kubernetes_audit` 字段设为 false，禁用 Kubernetes 审计以节省计算资源。

### [可选]配置 loki

推荐你在安装 loki 时，删除[Values 配置->T9k 审计日志](../../k8s-components/loki.md#t9k-审计日志) 中收集 K8s 审计日志的配置内容。

### values.yaml

#### t9k-cluster-admin

确保产品模块 t9k-cluster-admin 使用的 values.yaml 设置了下列字段：

```yaml
options:
  proxyOperationCtl:
    enabled: false
```

#### t9k-security-console-api

确保产品模块 t9k-security-console-api 使用的 values.yaml 中字段 `global.t9k.securityService.resourceManagement.proxyoperation.enabled` 的值是 false。

#### t9k-cost

确保产品模块 t9k-cost 使用的 values.yaml 中字段 `global.t9k.cost.proxyoperation.enabled` 的值是 false。
