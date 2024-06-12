# 燧原

## 简介

在集群内部署下列内容即可实现在 Kubernetes 中使用燧原 GPU。

### 燧原驱动

详情参考<a href="https://support.enflame-tech.com/onlinedoc_dev_2.5.115/4-develop/kmd/kernel_module_guide/content/source/kernel_module_guide.html#kmd" target="_blank">KMD 用户使用手册</a>

### TopsCloud 产品

燧原 TopsCloud 用于提供在 K8s 上使用 GCU 的解决方案，包括下面几个组件：
* 资源管理：
    * <a href="https://support.enflame-tech.com/onlinedoc_dev_2.5.115/6-k8s/k8s/k8s-device-plugin/content/source/enflame_gcu_k8s_plugin_user_guide.html#k8s-device-plugin" target="_blank">K8s Device Plugin</a>：将节点上的 GCU 硬件注册为 K8s 扩展资源。
    * <a href="https://support.enflame-tech.com/onlinedoc_dev_2.5.115/6-k8s/k8s/GCUshare/content/source/index.html" target="_blank">GCUShare</a> 相关的组件：GCUShare 用于支持多个 Pod 共享 GCU，主要包含下列组件：
        * gcushare-scheduler-extender：kube-scheduler 插件，增加调度器功能，使得调度器可以为使用 share GCU 的 Pod 提供调度支持。
        * gcushare-device-plugin：将节点上的 GCU 硬件注册为 K8s 扩展资源。
    * <a href="https://support.enflame-tech.com/onlinedoc_dev_2.5.115/6-k8s/k8s/Container-toolkit/content/source/index.html" target="_blank">Container Toolkit</a>：使得容器可以使用 GCU 卡。主要包含一个 container-runtime，可以自动为容器挂载 GCU 设备、注入运行环境。
    * <a href="https://support.enflame-tech.com/onlinedoc_dev_2.5.115/6-k8s/k8s/GCU-feature-discovery/content/source/index.html" target="_blank">GCU Feature Discovery</a>：给 GCU 节点添加设备属性标签。
    * [third-party] <a href="https://support.enflame-tech.com/onlinedoc_dev_2.5.115/6-k8s/k8s/Node-feature-discovery/content/source/index.html" target="_blank">Node Feature Discovery</a>：给节点添加硬件属性标签的 Kubernetes 插件。
* 监控管理：
    * <a href="https://support.enflame-tech.com/onlinedoc_dev_2.5.115/6-k8s/k8s/GCU-Exporter/content/source/index.html" target="_blank">GCU-Exporter</a>：采集 GCU 运行指标，并以 Prometheus metrics 形式暴露出来。
* 部署运维：
    * <a href="https://support.enflame-tech.com/onlinedoc_dev_2.5.115/6-k8s/k8s/GCU-operator/content/source/index.html" target="_blank">GCU-Operator</a>：可以自动化部署上述组件 + GCU 驱动的 Operator。
    * <a href="https://support.enflame-tech.com/onlinedoc_dev_2.5.115/6-k8s/k8s/KubeOne/content/source/index.html" target="_blank">KubeOne</a>：基于 sealer 进行定制二次开发的 K8s 集群部署工具。
* 二次开发库：
    * <a href="https://support.enflame-tech.com/onlinedoc_dev_2.5.115/6-k8s/k8s/Go-eflib/content/source/index.html" target="_blank">Go-Eflib</a>：支持 GCU 设备管理的 Golang API
* 设备管理工具：
    * <a href="https://support.enflame-tech.com/onlinedoc_dev_2.5.115/6-k8s/efml/EFSMI/content/source/index.html" target="_blank">EFSMI</a>：管理 GCU 设置的命令行工具。

## 安装部署

参考<a href="https://support.enflame-tech.com/onlinedoc_dev_2.5.115/6-k8s/k8s/GCU-operator/content/source/enflame_gcu_operator_2_0_user_guide.html#gcu-operator" target="_blank">燧原官方文档</a>，使用 GCU Operator 安装部署燧原驱动和 TopsCloud 产品。

## 参考

[TopsCloud 用户使用指南](https://support.enflame-tech.com/onlinedoc_dev_2.5.115/6-k8s/index.html)
