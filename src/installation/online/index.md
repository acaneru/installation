# 在线安装

## 概述

如果可以访问 Internet，可方便地从 docker hub 拉取镜像，下载 Linux 的 packages 等，可采取在线安装的方式。

反之，如果网络访问受限，可采用 [离线安装](../offline/index.md) 模式。

安装过程中，我们将主要使用 ansible 安装 Kubernetes 集群和 OS 系统组件，使用 helm 安装 T9k 产品，主要步骤如下：

1. [安装基础 K8s](./k8s-index.md)；
1. [安装 K8s 的一些扩展组件](./k8s-components/index.md)，例如 Istio, Knative 等；
1. [安装 TensorStack 产品](./products/index.md)。

## 下一步

我们首先准备工具和环境：[准备 Inventory](./prepare-inventory.md)。

## 参考

- <https://www.ansible.com/>
- <https://helm.sh/>
