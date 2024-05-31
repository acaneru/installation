# 集群管理 UI

管理员可以使用集群管理 UI 来查看、管理 Tensorstack AI 平台，主要包含下面几个方面：
* 查看资源：查看集群内节点、存储等资源信息。
* 资源管理：管理资源调度、回收等机制。
* 权限控制：管理项目、用户权限等。
* 监控告警：监控集群异常情况，可以通过企业微信、邮件订阅告警信息。

<aside class="note info">
<div class="title">资源</div>

API 资源和计算资源都常被简称为“资源”，一般可根据上下文判断其具体所指。

<strong>API 资源（API resources，Kubernetes API 资源，Kubernetes API resources）</strong>代表 Kubernetes 集群中的资源对象，包括原生的资源对象，如 `Pod`、`Deployment`、`Service`、`ConfigMap`，以及通过 CRD 定义的资源对象，例如 TensorStack AI 平台提供的 `Notebook`。

<strong>计算资源（compute resources）</strong>是应用程序运行所需的 CPU、内存、GPU 等。

</aside>