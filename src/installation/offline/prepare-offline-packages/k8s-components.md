# K8s 组件

## K8s 组件离线安装准备

下面的操作在 `ks-clusters/tools/offline-additionals` 中进行：

```bash
$ cd ~/ansible/ks-clusters/tools/offline-additionals
```

下面准备的离线文件一览：

| 内容              | 存放路径                           |
| ----------------- | ---------------------------------- |
| 1. 镜像（images） | 可修改，默认值为 container-images/ |
| 2. charts         | charts/                            |
| 3. 其他           | misc/                              |

“其他”中包含 istio 的命令行工具，minio 的 apt 包。

### 下载镜像

查看镜像列表，镜像列表的生成方式见[附录：生成 K8s 文件和镜像列表](../../appendix/generate-k8s-file-and-image-list.md)：

```bash
$ cat imagelist/k8s-${K8S_VER}.list
```

根据 images.list 下载 images，并指定下载目录为 container-images：

```bash
$ ./manage-offline-container-images.sh --option create \
    --config imagelist/k8s-${K8S_VER}.list --dir container-images
```

### 下载 Helm Chart 

查看下载版本：

```bash
$ cat productlist/k8s-${K8S_VER}.list
```

下载 Helm Chart，下载目录为 charts：

```bash
$ ./download-charts.sh --config productlist/k8s-${K8S_VER}.list
```

### 其他

#### minio 的 apt 包

下载 minio：

```bash
$ mkdir misc
$ wget https://dl.min.io/server/minio/release/linux-amd64/\
archive/minio_20231007150738.0.0_amd64.deb \
    -O misc/minio.deb
```

#### istio 命令行工具

下载 istio 命令行工具：

```bash
wget https://mirror.ghproxy.com/https://github.com/\
istio/istio/releases/download/1.15.2/istio-1.15.2-linux-amd64.tar.gz \
    -O misc/istio-1.15.2-linux-amd64.tar.gz
```
