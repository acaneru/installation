# 安装 K8s

K8s 安装采用运行 ansible 脚本的形式，步骤如下：

1. [基本设置](./k8s-install.md)，完成一个最基本的 K8s 安装；
2. [集群存储](./k8s-storage.md)，为 K8s 集群设置存储服务，配置 StorageClass。

本节其它部分可选，例如增加/减少集群节点，常见的集群设置问题等。

完成 K8s 安装之后，需要进行 [安装 K8s 组件](./install-k8s-components/index.md) 的步骤，以在 K8s 安装其它必须的服务。
