# 系统配置

## 监控目标

可以通过 CRD ServiceMonitor 和 PodMonitor 来设置 Prometheus 从哪些集群服务收集监控数据：

* ServiceMonitor（推荐）：表明从哪些 Service 资源对象收集监控数据。
* PodMonitor：表明从哪些 Pod 收集监控数据。

### 查看配置

列出本系统相关的监控目标：

```bash
kubectl get serviceMonitor -A -l tensorstack.dev/metrics-collected-by=t9k-monitoring
kubectl get podMonitor -A -l tensorstack.dev/metrics-collected-by=t9k-monitoring
```

查看 ServiceMonitor 的详情：

```bash
kubectl -n t9k-monitoring get servicemonitor coredns -o yaml
```

### 修改配置

修改 servicemonitor：

```bash
kubectl -n t9k-monitoring edit servicemonitor coredns
```

### 创建配置

运行下列命令可以创建一个基本的 ServiceMonitor：

```bash
kubectl apply -f - << EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: example-app
  namespace: demo
  labels:
    team: frontend
    tensorstack.dev/metrics-collected-by: t9k-monitoring
spec:
  selector:
    matchLabels:
      app: example-app
  endpoints:
  - port: web
EOF
```

> 创建 ServiceMonitor 或 PodMonitor 时，必须添加 label `tensorstack.dev/metrics-collected-by: t9k-monitoring` 以表明监控目标规则作用于 t9k-monitoring。

上面创建的 ServiceMonitor 定义的规则是：

1. 监听 namespace demo 下所有含有标签 `app:example-app` 的 service
1. 监听 service 的名称是 web 的端口

更多细节请参考 API Reference：<a target="_blank" rel="noopener noreferrer" href="https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.ServiceMonitor">ServiceMonitor</a> 和 <a target="_blank" rel="noopener noreferrer" href="https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.PodMonitor">PodMonitor</a>

## 告警/记录规则

管理员可以通过 CRD PrometheusRule 来设置 Prometheus 的告警规则（Alerting Rules）和记录规则（Recording rules）：

* <a target="_blank" rel="noopener noreferrer" href="https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/">告警规则</a>：基于 PromQL（Prometheus 查询语言） 设置一些告警规则，警报触发时，Prometheus 会产生对应的告警信息。
* <a target="_blank" rel="noopener noreferrer" href="https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/#recording-rules">记录规则</a>：Recording rules 允许你将经常用到的或计算量大的 PromQL 提前计算出来，并将结果保存为一组新的时间序列数据。例如：你可以将 `count (up == 1)` 记录为 `count:up`，查询 `count:up` 得到的结果与查询 `count (up == 1)` 得到的结果一样。

### 查看配置

运行下列命令可以查看与本系统的告警规则：

```bash
kubectl get prometheusrule -A -l tensorstack.dev/metrics-collected-by=t9k-monitoring
```

### 修改配置

运行下列命令可以修改 PrometheusRule：

```bash
kubectl -n <namespace> edit prometheusrule  <name>
```

### 创建配置

创建 PrometheueRule 的示例：

```bash
kubectl apply -f - << EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  labels:
    tensorstack.dev/metrics-collected-by: t9k-monitoring
  name: t9k
  namespace: t9k-monitoring
spec:
  groups:
  - name: t9k-workflow-alerts
    rules:
    - alert: T9kWorkflowTooManyFailures
      annotations:
        description: '{{ $value }} WorkflowRuns failed in last 1m.'
      expr: sum(t9k_workflow_failed_workflowruns - (t9k_workflow_failed_workflowruns
        offset 1m)) > 10
      for: 1m
      labels:
        origin: t9k-user
        severity: warning
  - name: t9k-common-rules
    rules:
    - expr: (kube_pod_status_phase{phase=~"Pending|Running|Unknown"} == 1) * on(namespace,pod)
        group_left kube_pod_info{node!=""}
      record: t9k_pod_resources_allocated
    - expr: DCGM_FI_DEV_XID_ERRORS * on(pod,namespace) group_left(node) kube_pod_info
      record: t9k_dcgm_xid_errors_with_node
EOF
```

创建 PrometheusRule 时，必须添加 label `tensorstack.dev/metrics-collected-by: t9k-monitoring` 以表明告警规则作用于 t9k-monitoring。

这个 PrometheusRule 定义了：

1. 一个告警规则：当 expr 定义的表达式成立，并且持续时间超过一分钟时，Prometheus 会产生名为 `T9kWorkflowTooManyFailures` 的警告信息，这个警告信息会被添加相应的 annotations 和 labels。
1. 两个记录规则：记录规则名称是 `t9k_pod_resources_allocated` 和 `t9k_dcgm_xid_errors_with_node`。这两个记录规则中的 expr 查询表达式会被提前计算并保存，当用户输入记录规则名称进行查询时，Prometheus 会返回对应的数据。

更多细节请参考 API Reference：<a target="_blank" rel="noopener noreferrer" href="https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.PrometheusRule">PrometheusRule</a>

## 告警通知

管理员可以通过 CRD AlertmanagerConfig 来配置 Alertmanager 将哪些警告信息通过邮件等方式发送给运维人员。Alertmanager  支持多种订阅警报消息的方式，包括邮件、企业微信等等。

AlertmanagerConfig 需要与 Alertmanger 服务在同一个 namespace 中， 并且包含以下 label，才能被系统识别：

```
tensorstack.dev/component: alertmanager-config
tensorstack.dev/component-type: system
```

API Reference：<a target="_blank" rel="noopener noreferrer" href="https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1alpha1.AlertmanagerConfig">AlertmanagerConfig</a>

### 查看配置

查看告警通知规则：

```bash
kubectl -n t9k-monitoring get alertmanagerconfig  \
  -l tensorstack.dev/component=alertmanager-config,tensorstack.dev/component-type=system
```

### 邮件接收配置

想要通过邮件接受警报消息，管理员需要创建两个资源对象：

* Secret：存储 SMTP 用户密码
* AlertmanagerConfig

示例：

<details><summary><code class="hljs">amc-email.yaml</code></summary>

```yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
metadata:
labels:
  tensorstack.dev/component: alertmanager-config
  tensorstack.dev/component-type: system
name: email
namespace: t9k-monitoring
spec:
 receivers:
 - emailConfigs:
   - authPassword:
       key: password
       name: email-password
     authUsername: <username-for-authentication>
     from: <sender-address>
     smarthost: <SMTP-server-host>
     to: <alert-recipient-address>
   name: t9k-sre
 route:
   groupBy:
   - alertname
   matchers:
   - name: severity
     value: critical
   - name: origin
     value: t9k-user
     matchType: !=
   - name: namespace
     value: "|ceph.*|gatekeeper-system|gpu-operator|ingress-nginx|istio-system|keycloak-operator|knative-serving|kube-system|kubernetes-dashboard|t9k-monitoring|t9k-system"
     matchType: "=~"
   groupInterval: 5m
   groupWait: 30s
   receiver: t9k-sre
   repeatInterval: 6h
---
apiVersion: v1
kind: Secret
metadata:
 name: email-password
 namespace: t9k-monitoring
type: Opaque 
data:
 password: <base64-encoded-password-for-authentication>
```

</details>

与邮件认证相关的配置：

1. 你需要设置 AlertmanagerConfig 的 `spec.receivers.emailConfig` 字段的下列信息：
    * `<SMTP-server-host>`：SMTP 服务器地址。
    * `<username-for-authentication>`：用于 SMTP 服务认证的用户名。
    * `<sender-address>`：警报消息的发送方邮件地址。
    * `<alert-recipient-address>`：警报消息的接收者的邮件地址。
1. 设置 Secret 时，你需要将 SMTP 服务器的密码经过 base64 编码后填写在 `data.password` 字段。

上面 AlertmanagerConfig 表明将 labels 满足 route.matchers 的警告信息通过邮件发送给用户。

### 企业微信接收配置

想要通过企业微信接受警报消息，管理员需要创建两个资源对象：

* Secret：存储企业微信 API Secret
* AlertmanagerConfig

示例：

<details><summary><code class="hljs">amc-wechat-test.yaml</code></summary>

```yaml
apiVersion: monitoring.coreos.com/v1alpha1
kind: AlertmanagerConfig
metadata:
 labels:
   tensorstack.dev/component: alertmanager-config
   tensorstack.dev/component-type: system
 name: wechat-test
 namespace: t9k-monitoring
spec:
 receivers:
 - wechatConfigs:
   - corpID: <corpID>
     agentID: <agentID>
     toUser: <toUser>
     message: '{{ template "wechat.t9k.message" . }}'
     apiSecret:
       name: wechat-apisecret
       key: apiSecret
   name: 'wechat'
 route:
   groupBy:
   - alertname
   matchers:
   - name: severity
     value: critical|warning
     matchType: =~
   - name: origin
     value: t9k-user
     matchType: !=
   - name: namespace
     value: "|ceph.*|gatekeeper-system|gpu-operator|ingress-nginx|istio-system|keycloak-operator|knative-serving|kube-system|kubernetes-dashboard|t9k-monitoring|t9k-system"
   groupInterval: 5m
   groupWait: 10s
   receiver: wechat
   repeatInterval: 6h
---

apiVersion: v1
kind: Secret
metadata:
 name: wechat-apisecret
 namespace: t9k-monitoring
type: Opaque
data:
 apiSecret: <base64-encoded-apiSecret-for-authentication>
```
</details>

与企业微信相关的配置：

1. 你需要设置 AlertmanagerConfig 的 `spec.receivers.wechatConfig` 字段的下列信息：
    * `<corpID>`：企业微信的 Company ID
    * `<agentID>`：企业微信应用对应的 agentID
    * `<toUser>`：optional，想要发送给哪些用户，值是 @all 时表明发送给所有用户。
1. 设置 Secret 的 `data.apiSecret` 字段，将企业微信的 API Secret 经 base64 编码后填写在这个字段上。具体如何获取 API Secret 请见 [附录：配置企业微信](./appendix/configure-wecom.md)。

上述示例将 `spec.receivers[0].wechatConfigs[0].message` 字段设置为 '{{ template "wechat.t9k.message" . }}'，直接使用 wechat.t9k.message 消息模版，简化消息格式。

运行下列命令可以查看 T9k monitoring 默认部署的消息模版：

```bash
kubectl -n t9k-monitoring get cm alertmanager-template  -o yaml
```

## 参考

<https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.PodMonitor>

<https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.ServiceMonitor>

<https://prometheus.io/docs/prometheus/latest/configuration/recording_rules/>

<https://prometheus.io/docs/prometheus/latest/configuration/alerting_rules/>

<https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.PrometheusRule>

[附录：配置企业微信](./appendix/configure-wecom.md)
