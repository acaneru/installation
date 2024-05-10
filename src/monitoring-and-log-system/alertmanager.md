# Alertmanager

Alertmanager 负责将告警信息发送给运维人员，一般在集群内部署一个 Alertmanager 即可。

## 部署设置

运行下列命令可以查看部署的 Alertmanager 详情（<a target="_blank" rel="noopener noreferrer" href="https://prometheus-operator.dev/docs/operator/api/#monitoring.coreos.com/v1.Alertmanager">API Reference</a>）：

```bash
kubectl -n t9k-monitoring get alertmanager main -o yaml
```

除非必要，不要对 Alertmanager 的 `spec` 字段进行修改。

## Web UI

Alertmanager 成功运行之后，你可以通过浏览器查看 Alertmanager 的 Web UI。

Alertmanager Web 首页，在这个页面你可以看见集群内产生的告警信息：`https://<host>/t9k-monitoring/alertmanager`

Alertmanager 的 Config，创建的 [告警通知](./sys-config.md#告警通知) 会被添加到这个 Config 中：`https://<host>/t9k-monitoring/alertmanager/#/status`

## 参考

<https://prometheus.io/docs/alerting/latest/alertmanager/>
