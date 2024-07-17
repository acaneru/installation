# K8s 组件离线安装准备

```
TODO:
    1. 增加验证部分；
```

本文准备的离线文件：

| 内容              | 存放路径                           |
| ----------------- | ---------------------------------- |
| 容器镜像（images） | 可修改，默认值为 container-images/ |
| Helm Charts         | charts/                            |
| 其他           | misc/                              |

> 说明：“其他” 中包含 `istio` 的命令行工具，`minio` 的 apt 包。

## 准备

切换目录，设置 K8s 版本：

```bash
cd ~/ansible/ks-clusters/tools/offline-additionals

K8S_VER=1.22.0
```

## 下载


### 容器镜像


查看镜像列表，镜像列表的生成方式见 [附录：生成 K8s 文件和镜像列表](../../appendix/generate-k8s-file-and-image-list.md)：

```bash
cat imagelist/k8s-${K8S_VER}.list
```

根据 `images.list` 下载 images，并指定下载目录为 `container-images`：

```bash
./manage-offline-container-images.sh \
  --option create \
  --config imagelist/k8s-${K8S_VER}.list \
  --dir container-images
```

### Helm Charts

查看下载版本：

```bash
cat productlist/k8s-${K8S_VER}.list
```

下载 Helm Chart，下载目录为 `charts`：

```bash
./download-charts.sh --config productlist/k8s-${K8S_VER}.list
```

### minio 的 apt 包

下载 minio：

```bash
mkdir misc
wget https://dl.min.io/server/minio/release/linux-amd64/archive/minio_20231007150738.0.0_amd64.deb \
    -O misc/minio.deb
```

### istio 命令行工具

下载 istio 命令行工具：

```bash
wget https://mirror.ghproxy.com/https://github.com/istio/istio/releases/download/1.15.2/istio-1.15.2-linux-amd64.tar.gz \
    -O misc/istio-1.15.2-linux-amd64.tar.gz
```

## 验证
