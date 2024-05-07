# 安装

## 环境要求

TensorStack AI 平台的离线部署对环境有以下要求：

1. 一个或多个“目标节点”，这些节点用来组建 K8s 集群。
    1. 这些节点的操作系统要求是 Ubuntu；
    1. 这些节点和“控制节点”之间可以通过网络访问。
1. 一个“控制节点”（ansible 的控制节点，与 K8s 无关），用来运行 ansible 脚本，并在离线环境中提供所有下载内容。
    1. OS 是 Ubuntu (推荐 22.04）；
    1. 可以不连接外部网络，支持通过移动硬盘、本地网络等途径从外部传入数据（离线安装包）即可；
    1. 和 “目标节点” 之间可以通过网络访问；
    1. 如需离线部署 K8s，则该节点不能加入 K8s 集群；
    1. 可用存储空间大于 500 GB。
1. 非测试部署时，离线环境中应存在一个可用的 DNS server。
    1. TensorStack AI 平台的服务需要通过域名访问，因此需要域名解析服务。

## 复制离线安装包

通过移动硬盘等途径，将[准备的离线安装包](../prepare-offline-packages/index.md)传输到 “控制节点” 的 `~/ansible` 路径。

复制命令：

```bash
mkdir ~/ansible && cd ~/ansible

# 从移动硬盘复制离线安装包到控制节点中
rsync -aP <path-to-media>/ks-clusters ~/ansible/
rsync -aP <path-to-media>/kubespray ~/ansible/
```

其中 `./ks-clusters` 包含 <a target="_blank" rel="noopener noreferrer" href="https://github.com/t9k/ks-clusters">ks-clusters</a> + [准备的离线安装包](../prepare-offline-packages/index.md)。
