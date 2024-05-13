# 产品

```
TODO:
    1. 增加验证部分；
```

本文准备的离线文件：

| 内容             | 存放路径                       |
| -------------- | -------------------------- |
| Helm Charts | charts/                    |
| 容器镜像（images） | 可修改，默认值为 container-images/ |
| 域名证书       | certs/                     |
| 其他         | misc/                      |

> 说明：“其他” 中包含 Serving 使用的镜像，kubectl 和 helm 命令行工具，用于保障单独部署 T9k 产品时这些功能可以正常使用。

## 准备

```bash
cd ~/ansible/ks-clusters/tools/offline-t9k
```

## 下载

### Helm Chart

查看下载版本：

```bash
cat productlist/t9k-2024-01-12.list
```

下载 Helm Chart，下载目录为 `charts`：

```bash
./download-charts.sh --config productlist/t9k-2024-02-01.list
```

### 镜像

<aside class="note">
<div class="title">注意</div>

1. 如果您需要修改 values.yaml 中对容器镜像的设置，您需要自行[准备 T9k 产品镜像列表](../../appendix/generate-t9k-product-image-list.md)。
1. 这个步骤的下载耗时很长，建议使用 root 用户下载，以避免多次输入 sudo 密码的需求。
1. 需要确保剩余的可用存储空间大于 200 GB。

</aside>

查看镜像列表：

```bash
cat imagelist/t9k-2024-02-01.list
```

下载镜像，下载目录为 `container-images`：

```bash
./manage-offline-container-images.sh \
  --option create \
  --config imagelist/t9k-2024-01-12.list \
  --dir container-images
```

### 域名证书

准备一份域名证书。参考[管理域名证书](../../appendix/manage-domain-certificate.md)生成域名证书。然后复制到目录中：

```bash
mkdir certs
cp -r ~/.acme.sh/\*.sample.t9kcloud.cn_ecc  certs/
```


### Registry 镜像

下载 Registry 镜像：

```bash
mkdir misc && cd misc
sudo docker pull docker.io/t9kpublic/registry:offline-2023-09
sudo docker save docker.io/t9kpublic/registry:offline-2023-09 \
    -o docker.io-t9kpublic-registry-offline-2023-09.tar
```

### 命令行工具

下载 `kubectl` 和 `helm` ：

```bash
wget -O kubectl \
  https://storage.googleapis.com/kubernetes-release/release/v1.25.9/bin/linux/amd64/kubectl

wget -O helm-v3.12.0-linux-amd64.tar.gz \
  https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz 
```

## 验证
