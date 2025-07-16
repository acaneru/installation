# 离线安装 Harbor Registry

```
TODO:
    1. "运行 NGINX 和上传镜像" 中需明确如何启动本地 Registry
    2. “手动设置” 部分，为支持很多节点集群，改为使用 ansible
```

## 检查离线安装包

`ks-clusters/offline/k8s` 中准备的离线文件一览：

| 内容                           | 存放路径          |
| ------------------------------ | ----------------- |
| 1. apt packages                | apt-packages/     |
| 2. pypi 包                     | python-packages/  |
| 3. 运行 Server 的镜像和工具      | servers/    |
| 4. 容器镜像（其他）              | container-images/ |
| 5. 一些可执行文件                | offline-files/    |

## 运行 NGINX 和上传镜像

1）如果 “控制节点” 未安装 docker，请先使用 dpkg 命令安装 Docker：

```bash
cd ~/ansible/ks-clusters/offline/k8s/apt-packages/debs/local/pkgs

# 查看其中 apt 包的版本
ls
# 根据看到的版本进行安装
sudo dpkg -i containerd.io_1.6.25-1_amd64.deb
sudo dpkg -i docker-ce-cli_5%3a24.0.7-1~ubuntu.20.04~focal_amd64.deb
sudo dpkg -i docker-ce_5%3a24.0.7-1~ubuntu.20.04~focal_amd64.deb
```

启用 docker：

```bash
sudo systemctl enable --now docker
```

验证：

```bash
sudo docker info
```

2）进入 offline/k8s 目录：

```bash
cd ~/ansible/ks-clusters/offline/k8s
```

3）装载 NGINX 镜像：

```bash
sudo docker load \
  -i ./server-images/docker.io-t9kpublic-nginx-offline-2023-09.tar
```

4）运行一个 nginx（默认 8080 端口），来 serve 保存在 offline-files 的文件和 apt 包：

```bash
./serve-offline-files.sh
```

5）运行本地 Regsitry

`servers` 目录中保存了 Harbor 的离线安装包，例如：`harbor-offline-installer-v2.11.2.tgz` 文件。

参考 [安装 Harbor](../../online/registry/harbor.md) 文档。

6）上传 K8s 安装需要的镜像到 registry 的 t9kpublic 项目中，其中 `<registry>` 为上一步运行的 Registry 的域名：

```bash
$ ./manage-offline-container-images.sh \
    --option register --registry <registry>
```

## 验证 NGINX 和 Registry 服务

在 “控制节点” 进行测试，验证 NGINX 和 Registry 的可用性。

### 验证 apt 服务

获取 apt 包的信息，其中 `<control-node-ip>` 为控制节点的 IP 地址：

```bash
curl http://<control-node-ip>:8080/debs/local/Packages
```

### 验证文件下载服务

通过查看文件夹和文件名称，来确认节点上 cri-tools 的版本信息：

```bash
ls offline-files/github.com/kubernetes-sigs/cri-tools/releases/download
```

根据上文获得的版本信息（例如 `v1.25.0/crictl-v1.25.0-linux-amd64.tar.gz`），下载 crictl 的压缩包：

```bash
curl http://<control-node-ip>:8080/github.com/kubernetes-sigs/cri-tools/releases/download/v1.25.0/crictl-v1.25.0-linux-amd64.tar.gz \
    -o ./crictl-v1.25.0-linux-amd64.tar.gz
```

### 验证 Registry 服务

查看 etcd 镜像版本：

```bash
ls container-images | grep etcd
```

下载镜像：

```bash
sudo docker pull <registry>/t9kpublic/etcd:v3.5.6
```

## 配置 kubespray 运行环境

1）如果控制节点未安装 python 和 pip，请先进行安装。首先确认是否已经安装了 python：

```bash
python3 --version
```

配置 apt 设置：

```bash
sudo cat > /etc/apt/sources.list.d/offline.list << EOF
deb [trusted=yes] http://<control-node-ip>:8080/debs/local/ ./
EOF

sudo mv /etc/apt/sources.list ~/
```

安装：

```bash
sudo apt update && sudo apt install python3 python3-venv python3-pip
```

[可选]在完成离线安装后，可以运行以下命令恢复 apt 配置：

```bash
sudo rm -rf /etc/apt/sources.list.d/offline.list
sudo mv ~/sources.list /etc/apt/ 
sudo apt update
```

2）将 kubespray 切换到合适分支：

```bash
# 将 kubespray 切换到合适分支，例如 origin/kubernetes-offline-1.25.9
cd ~/ansible/kubespray
git checkout -b kubernetes-offline-<version> \
    origin/kubernetes-offline-<version>
cd ..
```

3）然后参考[基本设置](../../online/inventory/basic-settings.md)，完成安装 ansible 和准备 inventory。

如果离线环境中没有 conda，则使用下面命令安装 ansible 运行环境：

```bash
python3 -m venv kubespray-venv
source kubespray-venv/bin/activate

python3 -m pip install --no-index \
  --find-links=python-packages -r kubespray/requirements.txt
```

验证：

```bash
ansible --version
```

## 手动设置

在每个计划安装 K8s 的 “目标节点”中，做以下 apt source 设置，使得他们可以从控制节点获取 apt 包。其中 <control-node-ip> 为“控制节点”的 IP 地址：

```bash
sudo cat > /etc/apt/sources.list.d/offline.list << EOF
deb [trusted=yes] http://<control-node-ip>:8080/debs/local/ ./
EOF

sudo mv /etc/apt/sources.list ~/
```

### 安装容器运行时

配置 Kubespray ，为节点安装容器运行时：

```bash
# 容器运行时为 docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo systemctl enable --now docker

# 容器运行时为 containerd
sudo apt update
sudo apt install -y containerd.io
sudo systemctl enable --now containerd
```

测试拉取镜像（根据 [验证 Registry 服务](#验证-registry-服务)的结果灵活调整 etcd 镜像的 tag）：

```bash
sudo docker pull <control-node-ip>:5000/t9kpublic/etcd:v3.5.6
```

### [可选] 安装 NVIDIA Driver

如需离线安装 NVIDIA Driver，可以运行以下命令（要求在 [准备离线安装包](../prepare-offline-packages/kubespray.md#下载-apt-包)时包含了该 package）：

```bash
sudo apt install -y nvidia-driver-525-server
```

安装完成后，需要参考 [NVIDIA GPU Operator](../../online/) 进行 Post Install 设置。

## 安装 K8s 集群

1）编辑 (`~/ansible/$T9K_CLUSTER/inventory/group_vars/all/download.yml`)，设置以下变量。其中 `<control-node-ip>` 为“控制节点”的 IP 地址：

```yaml
files_repo: "http://<control-node-ip>:8080"
gcr_image_repo: "<control-node-ip>:5000/t9kpublic"
kube_image_repo: "<control-node-ip>:5000/t9kpublic"
docker_image_repo: "<control-node-ip>:5000/t9kpublic"
quay_image_repo: "<control-node-ip>:5000/t9kpublic"

kubeadm_download_url: "http://<control-node-ip>:8080/storage.googleapis.com/kubernetes-release/release/{{ kubeadm_version }}/bin/linux/{{ image_arch }}/kubeadm"
kubelet_download_url: "http://<control-node-ip>:8080/storage.googleapis.com/kubernetes-release/release/{{ kube_version }}/bin/linux/{{ image_arch }}/kubelet"
kubectl_download_url: "http://<control-node-ip>:8080/storage.googleapis.com/kubernetes-release/release/{{ kube_version }}/bin/linux/{{ image_arch }}/kubectl"
helm_download_url: "http://<control-node-ip>:8080/get.helm.sh/helm-{{ helm_version }}-linux-{{ image_arch }}.tar.gz"
```

另外，需要考虑离线环境的特殊设置，例如修改 `upstream_dns_servers` 的设置。

2）参考 [准备节点](../../online/prepare-nodes.md) 与 [安装 K8s](../../online/k8s-index.md)，完成节点配置和安装 K8s 集群。

## 设置 KUBECONFIG 并验证

1）若“控制节点”未安装命令行工具 kubectl 和 Helm，需要先行安装。

Kubespray 会为 K8s 集群 master 节点的 root 用户安装 kubectl 和 helm。但是不会为 ansible 控制节点安装 kubectl 和 helm。我们需要为 ansible 控制节点安装 kubectl 和 helm。

安装 kubectl（如果使用的不是 `storage.googleapis.com` 下载源，请相应地更换路径，例如 `dl.k8s.io`）：

```bash
# 复制本地文件
cp ~/ansible/ks-clusters/tools/offline/offline-files/storage.googleapis.com/kubernetes-release/release/v1.25.9/bin/linux/amd64/kubectl  .
```

或者通过 nginx 服务下载：

```bash
wget http://<control-node-ip>:8080/storage.googleapis.com/kubernetes-release/release/v1.25.9/bin/linux/amd64/kubectl
```

添加可执行权限，并移动 kubectl 到 `/usr/local/bin` 目录中：

```
chmod +x kubectl
sudo mv kubectl /usr/local/bin/kubectl
```

安装 helm（请根据版本、操作系统的不同灵活修改路径）：

```bash
# 复制本地文件
cp ~/ansible/ks-clusters/tools/offline/offline-files/get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz .
```

或者通过 nginx 服务下载：

```bash
wget http://<control-node-ip>:8080/get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz
```

解压并移动到 `/usr/local/bin` 目录中：
```
tar zxvf helm-v3.12.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
rm -rf linux-amd64/
```

2）设置 KUBECONFIG：

```bash
mkdir -p ~/.kube/

cp ~/ansible/$T9K_CLUSTER/inventory/artifacts/admin.conf \
  ~/.kube/sample.conf
export KUBECONFIG=~/.kube/sample.conf
```

3）验证：

```bash
kubectl get pod -A -o wide
kubectl get node -o wide
```
