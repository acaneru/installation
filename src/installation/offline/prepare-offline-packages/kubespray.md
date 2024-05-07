# Kubespray

```
TODO:
    1. 增加验证部分；
```


本文准备的离线文件：

| 内容               | 存放路径                           |
| ------------------ | ---------------------------------- |
| apt packages   | apt-packages/                      |
| pypi 包        | python-packages/                   |
| Server 用容器镜像  | server-images/                     |
| 文件  | offline-files/                     |
| 其它容器镜像 | 可修改，默认值为 container-images/ |

## 准备

获取 <a target="_blank" rel="noopener noreferrer" href="https://github.com/t9k/ks-clusters/tree/master">ks-cluster</a> 项目：

```bash
mkdir -p ~/ansible && cd ~/ansible
git clone https://github.com/t9k/ks-clusters.git

cd ~/ansible/ks-clusters/tools/offline-k8s
```

## 下载

### apt 包

确认下载内容：

```bash
cat pkglist/ubuntu/pkgs.txt
cat pkglist/ubuntu/20.04/pkgs.txt
cat pkglist/ubuntu/22.04/pkgs.txt
```

如需离线安装 NVIDIA Driver，可以编辑 `pkglist/ubuntu/pkgs.txt`，添加以下内容：

```bash
# nvidia driver
nvidia-driver-525-server
```

运行脚本下载 apt repositories，下载目录为 `apt-packages`：

```bash
./create-repo.sh
```

如果报错 `Can't find a source to download version '5:24.0.7-1~ubuntu.20.04~focal' of 'docker-ce:amd64'`，运行以下命令，增加 docker 的 apt source 后再试一次：

```bash
cat > download_docker_com_linux_ubuntu.list << EOF
deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable
EOF

sudo mv download_docker_com_linux_ubuntu.list \
  /etc/apt/sources.list.d/download_docker_com_linux_ubuntu.list
sudo apt update
```

### Python 包

确认下载内容：

```bash
cat ~/ansible/kubespray/requirements.txt
```

下载 python packages：

```bash
# 如遇到网络联通性问题，考虑使用代理： -i https://pypi.tuna.tsinghua.edu.cn/simple
python3 -m pip download \
  -d python-packages \
  -r ~/ansible/kubespray/requirements.txt
```

### nginx / registry server 镜像

这两个镜像用于在 “控制节点” 上创建 server 来提供离线内容：

```
docker.io/t9kpublic/nginx:offline-2023-09
docker.io/t9kpublic/registry:offline-2023-09
```

为了方便使用，我们单独下载这两个镜像。

```bash
mkdir server-images && cd server-images

sudo docker pull docker.io/t9kpublic/nginx:offline-2023-09
sudo docker save docker.io/t9kpublic/nginx:offline-2023-09 \
  -o docker.io-t9kpublic-nginx-offline-2023-09.tar

sudo docker pull docker.io/t9kpublic/registry:offline-2023-09
sudo docker save docker.io/t9kpublic/registry:offline-2023-09 \
  -o docker.io-t9kpublic-registry-offline-2023-09.tar

cd ~/ansible/ks-clusters/tools/offline-k8s
```

### 文件

<aside class="note">
<div class="title">注意</div>

下面需要设置环境变量 `K8S_VER` 为实际的 k8s 发布版本，例如 `1.22.0`、`1.25.9` 等。

</aside>

查看下载文件列表，文件列表的生成方式见 [附录：生成 K8s 文件和镜像列表](../../appendix/generate-k8s-file-and-image-list.md)：

```bash
K8S_VER=1.22.0
cat filelist/k8s-${K8S_VER}.list
```

根据 files.list 下载 files，下载目录为 `offline-files`：

```bash
./download-offline-files.sh --config filelist/k8s-${K8S_VER}.list
```

如果使用了 `mirror.ghproxy.com `作为 github 的代理，需要修改目录的路径：

```bash
mv offline-files/mirror.ghproxy.com/https\:/github.com \
  offline-files/github.com
```

### 镜像

查看镜像列表，镜像列表的生成方式见 [附录：生成 K8s 文件和镜像列表](../../appendix/generate-k8s-file-and-image-list.md)：

```bash
cat imagelist/k8s-${K8S_VER}.list
```

根据 images.list 下载 images，并指定下载目录为 container-images：

```bash
./manage-offline-container-images.sh --option create \
  --config imagelist/k8s-${K8S_VER}.list --dir container-images
```

## 验证
