# 监控告警系统

监控告警系统（简称 t9k-monitoring）收集并存储集群的监控数据，当集群触发告警规则时，告警系统会产生警告信息通知管理员。

本系统主要包含下列组件：

* <a target="_blank" rel="noopener noreferrer" href="https://prometheus.io/">Prometheus</a>：负责收集及保存集群服务的各种指标数据，并提供 API 供其他服务使用。
* <a target="_blank" rel="noopener noreferrer" href="https://grafana.com/">Grafana</a>：图形化展示监控数据的组件，监控数据来自于 Prometheus。
* <a target="_blank" rel="noopener noreferrer" href="https://prometheus.io/docs/alerting/latest/alertmanager/">Alertmanager</a>：处理并发送告警通知。当告警规则被触发之后，Prometheus 会产生告警信息，然后 Alertmanager 会收集告警信息并将其发送给运维人员。
* 产生监控数据的服务：
    * <a target="_blank" rel="noopener noreferrer" href="https://github.com/prometheus/node_exporter">node-exporter</a>：提供集群中单个节点的指标数据。 
    * <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes/kube-state-metrics">kube-state-metrics</a>：产生并暴露 K8s 集群级别的监控指标。
    * t9k-state-metrics：产生并暴露集群中与 T9k 相关的为监控指标。

监控告警系统的架构如下：

<figure class="architecture">
  <img alt="architecture" src="../assets/monitoring-and-log-system/monitoring-system/architecture.png" />
  <figcaption>图 1：TensorStack AI 平台的监控告警系统概览。1）集群服务需要通过 http endpoint 提供 <a target="_blank" rel="noopener noreferrer" href="https://prometheus.io/docs/instrumenting/writing_exporters/#metrics">metrics</a> 以供 Prometheus 收集监控数据。 2）T9k Product UI 会从 Prometheus 查询到监控数据并展示给用户</figcaption>
</figure>

本系统通过 <a target="_blank" rel="noopener noreferrer" href="https://prometheus-operator.dev/">Prometheus Operator</a> 来部署、配置 Prometheus 和 Alertmanager。Prometheus Operator 提供了多种 CRD 来简化安装、配置方法：

* `Prometheus`：用于部署 Prometheus。
* `Alertmanager`：用于部署 Alertmanager。
* `ServiceMonitor`：用于配置 Prometheus 监听 Service 资源对象。
* `PodMonitor`：用于配置 Prometheus 监听 Pod 资源对象。
* `PrometheusRule`：用于配置 Prometheus 的告警规则。
* `AlertmanagerConfig`：用于配置 Alertmanager 发送警告信息的规则。

管理员可以进行下列配置操作：

* 设置监控目标：配置 Prometheus 收集哪些集群服务产生的监控数据。
* 设置告警规则：Prometheus 会根据告警规则来判断如何产生告警信息。
* 设置告警通知：配置 AlertManager 如何将告警信息发送出去。
* 自定义 Grafana Dashboard：创建新的 Grafana Dashboard 来展示监控信息。

## 下一步

- 查看系统的 [运行状态](./sys-status.md)。

- 查看和修改 [系统配置](./sys-config.md)。

## 参考

<https://prometheus-operator.dev/>
