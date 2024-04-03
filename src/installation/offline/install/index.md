# 安装

## 环境要求

TensorStack AI 平台的离线部署对环境有以下要求：

1. 存在一个“控制节点”（ansible 的控制节点，与 K8s 无关），用来运行 ansible 脚本，并在离线环境中提供所有下载内容。
    1. 该节点的操作系统要求是 Ubuntu (推荐 22.04）；
    1. 该节点可以不连接外部网络，支持通过移动硬盘、本地网络等途径从外部传入数据（离线安装包）即可；
    1. 该节点和“目标节点”之间可以通过网络访问；
    1. 如需离线部署 K8s，则该节点不能加入 K8s 集群；
    1. 该节点可用存储空间大于 500 GB。
1. 一个或多个“目标节点”，这些节点用来组建 K8s 集群。
    1. 这些节点的操作系统要求是 Ubuntu；
    1. 这些节点和“控制节点”之间可以通过网络访问。
1. 非测试部署时，离线环境中应存在一个可用的 DNS server。
    1. TensorStack AI 平台的服务需要通过域名访问，因此需要 DNS server 提供域名解析服务。

## 复制离线安装包

通过移动硬盘等途径，将[准备的离线安装包](../prepare-offline-packages/index.md)传输到“控制节点”的 ~/ansible 路径。其中包含以下 repository：

```bash
$ ls
ks-clusters  kubespray
```

传输使用的命令：

```bash
# 从移动硬盘复制离线安装包到控制节点中
$ mkdir ~/ansible && cd ~/ansible
$ rsync -aP <path-to-media>/ks-clusters ~/ansible
$ rsync -aP <path-to-media>/kubespray ~/ansible
```

其中 <a target="_blank" rel="noopener noreferrer" href="https://github.com/t9k/ks-clusters">ks-clusters</a> 包含已经下载的离线安装包。

`ks-clusters/tools/offline-k8s` 中准备的离线文件一览：

| 内容                            | 存放路径          |
| ------------------------------- | ----------------- |
| 1. apt packages                | apt-packages/     |
| 2. pypi 包                     | python-packages/  |
| 3. 容器镜像（nginx, registry） | server-images/    |
| 4. 容器镜像（其他）            | container-images/ |
| 5. 一些可执行文件              | offline-files/    |

`ks-clusters/tools/offline-additionals` 中提前准备的离线文件一览：

| 内容              | 存放路径          |
| ----------------- | ----------------- |
| 1. 镜像（images） | container-images/ |
| 2. Helm Chart     | charts/           |
| 3. 其他           | misc/             |

“其他”中包含 istioctl 命令行工具，minio 的 apt 包。

`ks-clusters/tools/offline-t9k` 中提前准备的离线文件一览：

| 内容              | 存放路径          |
| ----------------- | ----------------- |
| 1. Helm Chart     | charts/           |
| 2. 镜像（images） | container-images/ |
| 3. 域名证书       | certs/            |
| 4. 其他           | misc/             |

说明：

1. “其他”中包含 Serving 使用的镜像，kubectl 和 helm 命令行工具，用于保障单独部署 T9k 产品时这些功能可以正常使用。
