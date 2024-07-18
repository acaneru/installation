# 安装 K8s 组件

在最基本的 K8s 安装完成之后，我们需要在 K8s 集群上安装一些额外的组件，以支持 TensorStack AI 计算平台的安装。

本部分安装的模块如下：

- [Istio](./istio.md) - Service Mesh 和 Gateway API
- [Knative](./knative.md) - Serverles 框架
- [Metrics Server](./metrics-server.md) - 确保其设置正确
- [Elastic Search](./elastic-search.md) - 存储集群的 log
- [监控相关](./monitoring.md) - 一些设置
- [Gatekeeper](./gatekeeper.md) - 准入控制

## 下一步

完成 K8s 组件安装之后，根据需要安装必要的[硬件支持](../../hardware/index.md)。
