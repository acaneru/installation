# 燧原

## 总览

下面是在集群中部署燧原产品的文档，以支持在 Kubernetes 中使用燧原 GCU。需要部署的燧原产品版本：
1. TopsRider 软件栈：版本 TopsRider_i3x_3.3.20250314_deb_amd64。
2. TopsCloud：版本 3.3.20。

安装步骤分为 3 步：
1. 在 GCU 节点上安装 GCU 驱动（TopsRider）
2. 安装部署 GCU Operator（TopsCloud）
3. [安装后]监控配置：完成上述步骤后，后续安装 T9k 产品时，需要设置针对燧原 GCU 资源的监控配置。

注：安装包由燧原提供。

## 环境

下面是经过验证的环境：
1. K8s 集群版本：v1.30.4
2. GCU 节点：
    1. OS：Ubuntu 22.04.5
    2. Kernel：5.15.0-130-generic
    3. 容器运行时：containerd://1.7.21
3. Harbor 本地镜像仓库：
    1. 服务地址：harbor.example.cn
    2. Harbor 版本：v2.11.2
4. 准备镜像的节点 prepare-node：
    1. OS：Ubuntu 22.04.5
    2. Kernel：5.15.0-126-generic
    3. docker：27.4.1
    4. ctr：1.7.24
    5. helm: v3.15.4
    6. ansible: core 2.16.14

## 安装 GCU 驱动

### 安装包

安装包 TopsRider_i3x_3.3.20250314_deb_amd64.run 由燧原提供，存放在 `prepare-node:/data/enflame`。

```bash
(base) ubuntu@prepare-node:~$ ls /data/enflame/
topscloud_3.3.20.tar.gz  TopsRider_i3x_3.2.203_deb_amd64.run  TopsRider_i3x_3.3.20250314_deb_amd64.run
```

### ansible 配置

创建文件 inventory/gcu-update.ini，创建 group all 记录目标 GCU 节点，下面是一个操作示例：
```bash
(kubespray) ubuntu@prepare-node:~/ansible/qingyang$ vi inventory/gcu-update.ini
(kubespray) ubuntu@prepare-node:~/ansible/qingyang$ cat inventory/gcu-update.ini 
[all]
worker-78 ansible_host=10.52.2.78
worker-79 ansible_host=10.52.2.79
```

### 拷贝 GCU 驱动安装包

使用 ansible 将 GCU 驱动安装包拷贝到目标 GCU 节点。

```bash
(kubespray) ubuntu@prepare-node:~/ansible/qingyang$ ansible -i inventory/gcu-update.ini all -m shell -a "uname -r"  
worker-79 | CHANGED | rc=0 >>
5.15.0-130-generic
worker-78 | CHANGED | rc=0 >>
5.15.0-130-generic

(kubespray) ubuntu@prepare-node:~/ansible/qingyang$ ansible -i inventory/gcu-update.ini all -m copy -a "src=/data/enflame/TopsRider_i3x_3.3.20250314_deb_amd64.run dest=/home/ubuntu" --become -K
BECOME password: 
worker-78 | CHANGED => {
    "changed": true,
    "checksum": "804ea8c92d2aa662c6c58b47c5c37c81366efb08",
    "dest": "/home/ubuntu/TopsRider_i3x_3.3.20250314_deb_amd64.run",
    "gid": 0,
    "group": "root",
    "md5sum": "3fcaa3bb55221dc73605a2da4ed4d798",
    "mode": "0644",
    "owner": "root",
    "size": 3929136495,
    "src": "/home/ubuntu/.ansible/tmp/ansible-tmp-1742975581.3291142-3869069-188209929684094/source",
    "state": "file",
    "uid": 0
}
…
(kubespray) ubuntu@prepare-node:~/ansible/qingyang$ ansible -i inventory/gcu-update.ini all -m shell -a "chmod +x TopsRider_i3x_3.3.20250314_deb_amd64.run" --become -K
BECOME password: 
(kubespray) ubuntu@prepare-node:~/ansible/qingyang$ ansible -i inventory/gcu-update.ini all -m shell -a "ls TopsRider_i3x_3.3.20250314_deb_amd64.run"   
worker-79 | CHANGED | rc=0 >>
TopsRider_i3x_3.3.20250314_deb_amd64.run
worker-78 | CHANGED | rc=0 >>
TopsRider_i3x_3.3.20250314_deb_amd64.run
```

### 安装 GCU 驱动

运行下列命令在目标节点上安装 GCU 驱动：
```bash
(kubespray) ubuntu@prepare-node:~/ansible/qingyang$ ansible -i inventory/gcu-update.ini all -m shell -a "./TopsRider_i3x_3.3.20250314_deb_amd64.run --silence" --become -K
BECOME password: 
worker-78 | CHANGED | rc=0 >>
Verifying archive integrity... All good.
Uncompressing ENFLAME TOPSRIDER PACKAGE
Logging file: /tmp/topsinstaller/TopsRider20250326-163331.log
[1/3] Install TopsPlatform Package
[2/3] Install Dockerfile to /usr/local/topsrider/dockerfile
[3/3] Install Data Center Toolkit to /usr/local/topsrider/data_center_toolkit
Install Finished. 3 installed.  100%   MD5 checksums are OK.  100%  
worker-79 | CHANGED | rc=0 >>
Verifying archive integrity... All good.
Uncompressing ENFLAME TOPSRIDER PACKAGE
Logging file: /tmp/topsinstaller/TopsRider20250326-163331.log
[1/3] Install TopsPlatform Package
[2/3] Install Dockerfile to /usr/local/topsrider/dockerfile
[3/3] Install Data Center Toolkit to /usr/local/topsrider/data_center_toolkit
Install Finished. 3 installed.  100%   MD5 checksums are OK.  100%  
...
```

### 验证

运行下列命令，节点上有对应的 GCU 状态输出说明 GCU 驱动正常工作：
```bash
(kubespray) ubuntu@prepare-node:~/ansible/qingyang$ ansible -i inventory/gcu-update.ini all -m shell -a "efsmi"  
worker-78 | CHANGED | rc=0 >>
------------------------------------------------------------------------------
-------------------- Enflame System Management Interface ---------------------
--------- Enflame Tech, All Rights Reserved. 2024-2025 Copyright (C) ---------
------------------------------------------------------------------------------
                                                                              
+2025-03-31, 15:35:44 CST----------------------------------------------------+
| EFSMI    1.4.0.3         Driver Ver: 1.4.0.3                               |
|----------------------------------------------------------------------------|
|----------------------------------------------------------------------------|
| DEV    NAME                 | FW VER           | BUS-ID      ECC           |
| TEMP   Dpm   Pwr(Usage/Cap) | Mem     GCU Virt | DUsed       SN            |
|----------------------------------------------------------------------------|
| 0      Enflame S60          | 33.6.5           | 00:23:00.0  Enable        |
| 71℃    Sleep    118W / 300W | 42976MiB Disable | 0%          C807B40520388 |
+----------------------------------------------------------------------------+
|----------------------------------------------------------------------------|
| 1      Enflame S60          | 33.6.5           | 00:24:00.0  Enable        |
| 74℃    Sleep    121W / 300W | 42976MiB Disable | 0%          C806S40510352 |
+----------------------------------------------------------------------------+
|----------------------------------------------------------------------------|
| 2      Enflame S60          | 33.6.5           | 00:25:00.0  Enable        |
| 65℃    Sleep    113W / 300W | 42976MiB Disable | 0%          C807140510404 |
+----------------------------------------------------------------------------+
|----------------------------------------------------------------------------|
| 3      Enflame S60          | 33.6.5           | 00:26:00.0  Enable        |
| 70℃    Sleep    113W / 300W | 42976MiB Disable | 0%          C807B40520524 |
+----------------------------------------------------------------------------+
|----------------------------------------------------------------------------|
| 4      Enflame S60          | 33.6.5           | 00:33:00.0  Enable        |
| 66℃    Sleep    113W / 300W | 42976MiB Disable | 0%          C807140510017 |
+----------------------------------------------------------------------------+
|----------------------------------------------------------------------------|
| 5      Enflame S60          | 33.6.5           | 00:34:00.0  Enable        |
| 68℃    Sleep    114W / 300W | 42976MiB Disable | 0%          C807B40520261 |
+----------------------------------------------------------------------------+
|----------------------------------------------------------------------------|
| 6      Enflame S60          | 33.6.5           | 00:35:00.0  Enable        |
| 63℃    Sleep    109W / 300W | 42976MiB Disable | 0%          C807B40520523 |
+----------------------------------------------------------------------------+
|----------------------------------------------------------------------------|
| 7      Enflame S60          | 33.6.5           | 00:36:00.0  Enable        |
| 66℃    Sleep    114W / 300W | 42976MiB Disable | 0%          C806S40510031 |
+----------------------------------------------------------------------------+
...
```

## 安装 GCU Operator

### 安装包

安装包 topscloud_3.3.20 由燧原提供，存放在 `prepare-node:/data/enflame`。

```bash
(base) ubuntu@prepare-node:~$ ls /data/enflame/
topscloud_3.3.20.tar.gz  TopsRider_i3x_3.2.203_deb_amd64.run  TopsRider_i3x_3.3.20250314_deb_amd64.run
```

运行下列命令解压安装包：
```bash
(base) ubuntu@prepare-node:~$ cd /data/enflame/
(base) ubuntu@prepare-node:/data/enflame$ ls
topscloud_3.3.20.tar.gz  TopsRider_i3x_3.2.203_deb_amd64.run  TopsRider_i3x_3.3.20250314_deb_amd64.run
(base) ubuntu@prepare-node:/data/enflame$ tar -xzf topscloud_3.3.20.tar.gz 
(base) ubuntu@prepare-node:/data/enflame$ ls
topscloud_3.3.20  topscloud_3.3.20.tar.gz  TopsRider_i3x_3.2.203_deb_amd64.run  TopsRider_i3x_3.3.20250314_deb_amd64.run
(base) ubuntu@prepare-node:/data/enflame$ cd topscloud_3.3.20/
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20$ ls
documents                         gcu-feature-discovery_1.3.20  gcushare_1.2.15           k8s-driver-manager_1.0.21  node-feature-discovery_1.2.20
enflame-container-toolkit_2.0.48  gcu-monitor-examples_1.1.7    go-eflib_1.5.1            k8s-installer_1.1.7        node-problem-detector_1.0.18
gcu-exporter_1.5.1                gcu-operator_2.4.6            k8s-device-plugin_2.0.30  node-exporter_1.0.22       README.md
```

### 构建镜像

#### [可选]拷贝基础镜像

<aside class="note">
<div class="title">注意</div>

当 prepare-node 可以访问外网时，跳过本步骤。

</aside>

制作镜像的 Dockerfile 使用的基础镜像来源于 dockerhub，当 prepare-node 无法连接外网时，需要：在能访问外网的机器下载基础镜像 -> 保存为离线文件 -> 离线文件上传到 prepare-node -> prepare-node 从离线文件加载镜像。

首先，在节点 prepare-node 上运行下列命令，查询所需的基础镜像：
```bash
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20$ cd gcu-operator_2.4.6/
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ ls
build-component-image.sh  build-operator-image.sh  config.json              delete-operator.sh  dockerfiles        example             g_version.txt  tools
build-image.conf          component-images         copy-and-load-images.sh  deploy-operator.sh  enflame-resources  gcu-operator-chart  manager
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ cat dockerfiles/Dockerfile.ubuntu | grep FROM
FROM ubuntu:18.04
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 22.04.5 LTS
Release:	22.04
Codename:	jammy
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ cat component-images/toolkit/dockerfiles/Dockerfile.ubuntu22.04 | grep FROM
FROM ubuntu:22.04
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ cat ../gcu-exporter_1.5.1/dockerfiles/Dockerfile.ubuntu | grep FROM
FROM ubuntu:18.04
```

在能访问外网的机器上下载镜像、保存离线文件、拷贝到节点 prepare-node：
```bash
$ docker pull ubuntu:18.04
18.04: Pulling from library/ubuntu
7c457f213c76: Already exists 
Digest: sha256:152dc042452c496007f07ca9127571cb9c29697f42acbfad72324b2bb2e43c98
Status: Downloaded newer image for ubuntu:18.04
$ docker save -o ubuntu-18.04.tar ubuntu:18.04
$ scp ubuntu-18.04.tar prepare-node:/data/image/
ubuntu-18.04.tar                                                                                                             100%   63MB   5.6MB/s   00:11 

$ docker pull ubuntu:22.04
22.04: Pulling from library/ubuntu
9cb31e2e37ea: Pull complete 
Digest: sha256:ed1544e454989078f5dec1bfdabd8c5cc9c48e0705d07b678ab6ae3fb61952d2
Status: Downloaded newer image for ubuntu:22.04
$ docker save -o ubuntu-22.04.tar ubuntu:22.04
$ scp ubuntu-22.04.tar prepare-node:/data/image/
ubuntu-22.04.tar                                                                                         100%   77MB   5.8MB/s   00:13 
```

在节点 prepare-node 使用 docker 加载镜像：
```bash
(base) ubuntu@prepare-node:/data/image$ ls
ubuntu-18.04.tar  ubuntu-22.04.tar
(base) ubuntu@prepare-node:/data/image$ sudo docker load -i ubuntu-18.04.tar 
548a79621a42: Loading layer [==================================================>]  65.53MB/65.53MB
Loaded image: ubuntu:18.04
(base) ubuntu@prepare-node:/data/image$ sudo docker load -i ubuntu-22.04.tar 
270a1170e7e3: Loading layer [==================================================>]  80.41MB/80.41MB
(base) ubuntu@prepare-node:~$ sudo docker images | grep ubuntu
harbor.example.cn/topsrider/ubuntu                                     amd64-22.04-3.3.112   8bc60905e5fb   4 weeks ago     4.19GB
ubuntu                                                                       22.04                 a24be041d957   8 weeks ago     77.9MB
ubuntu                                                                       18.04                 f9a80a55f492   22 months ago   63.2MB
```

#### 制作 GCU Operator 镜像的准备工作

将 Device Plugin DaemonSet YAML 的环境变量 CUSTOM_REGISTER_RESOURCE 的值修改为 `enflame.com/gcu`,`enflame.com/vgcu`：
1. 背景：
    1. gcu device plugin 通过环境变量 CUSTOM_REGISTER_RESOURCE 设置要注册的扩展资源名称，默认值是 `enflame.com/gcu`,`enflame-tech.com/gcu`,`enflame.com/vgcu`。
    2. 在非虚拟化环境下，Device Plugin 会在集群内创建两个扩展资源名称 `enflame.com/gcu`,`enflame-tech.com/gcu`。
    3. 这两个扩展资源名称是等价的，即一个 GCU 硬件对应一个 `enflame.com/gcu` 和一个 `enflame-tech.com/gcu`。
2. 修改目的：
    1. T9k 希望集群内只有扩展资源 `enflame.com/gcu`。
    2. 制作 GCU Operator 组件镜像前修改环境变量，可以使得部署 GCU Operator 时，无需额外配置，就能让集群内只产生扩展资源 `enflame.com/gcu`。
3. 目标文件：下列文件设置了环境变量 `CUSTOM_REGISTER_RESOURCE=“enflame.com/gcu,enflame-tech.com/gcu,enflame.com/vgcu”`，需要对这些文件进行修改
    1. enflame-resources/k8s-device-plugin/v2/base/enflame-device-plugin.yaml
    2. enflame-resources/k8s-device-plugin/v2/cdi/enflame-device-plugin-cdi.yaml
    3. enflame-resources/k8s-device-plugin/v2/cpu-manager/enflame-device-plugin-compat-with-cpumanager.yaml

```bash
(base) ubuntu@prepare-node:/data/enflame$ cd topscloud_3.3.20/
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20$ cd gcu-operator_2.4.6/
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ ls
build-component-image.sh  build-operator-image.sh  config.json              delete-operator.sh  dockerfiles        example             g_version.txt  tools
build-image.conf          component-images         copy-and-load-images.sh  deploy-operator.sh  enflame-resources  gcu-operator-chart  manager
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ ls enflame-resources/
container-toolkit  gcu-exporter           gcushare-config-manager  gcushare-scheduler-extender  k8s-driver-manager  node-feature-discovery
driver             gcu-feature-discovery  gcushare-device-plugin   k8s-device-plugin            node-exporter
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ tree enflame-resources/k8s-device-plugin/
Command 'tree' not found, but can be installed with:
sudo snap install tree  # version 2.1.3+pkg-5852, or
sudo apt  install tree  # version 2.0.2-1
See 'snap info tree' for additional versions.
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ sudo apt  install tree
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages were automatically installed and are no longer required:
  libflashrom1 libftdi1-2
Use 'sudo apt autoremove' to remove them.
The following NEW packages will be installed:
  tree
0 upgraded, 1 newly installed, 0 to remove and 6 not upgraded.
Need to get 47.9 kB of archives.
After this operation, 116 kB of additional disk space will be used.
Get:1 http://mirrors.gsesgpucloud.com/ubuntu jammy/universe amd64 tree amd64 2.0.2-1 [47.9 kB]
Fetched 47.9 kB in 0s (891 kB/s)
Selecting previously unselected package tree.
(Reading database ... 93735 files and directories currently installed.)
Preparing to unpack .../tree_2.0.2-1_amd64.deb ...
Unpacking tree (2.0.2-1) ...
Setting up tree (2.0.2-1) ...
Processing triggers for man-db (2.10.2-1) ...
Scanning processes...                                                                                                                                                                            
Scanning linux images...                                                                                                                                                                         
No services need to be restarted.
No containers need to be restarted.
No user sessions are running outdated binaries.
No VM guests are running outdated hypervisor (qemu) binaries on this host.
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ tree enflame-resources/k8s-device-plugin/
enflame-resources/k8s-device-plugin/
├── v1
│   ├── base
│   │   └── enflame-device-plugin.yaml
│   └── pcie-switch
│       ├── clusterrolebinding.yaml
│       ├── clusterrole.yaml
│       ├── daemonset.yaml
│       └── serviceaccount.yaml
└── v2
    ├── base
    │   └── enflame-device-plugin.yaml
    ├── cdi
    │   └── enflame-device-plugin-cdi.yaml
    ├── cpu-manager
    │   └── enflame-device-plugin-compat-with-cpumanager.yaml
    └── pcie-switch
        ├── clusterrolebinding.yaml
        ├── clusterrole.yaml
        ├── daemonset.yaml
        └── serviceaccount.yaml
8 directories, 12 files
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ sed -i 's/enflame\.com\/gcu,enflame-tech\.com\/gcu,enflame\.com\/vgcu/enflame\.com\/gcu,enflame\.com\/vgcu/g' enflame-resources/k8s-device-plugin/v2/base/enflame-device-plugin.yaml
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ sed -i 's/enflame\.com\/gcu,enflame-tech\.com\/gcu,enflame\.com\/vgcu/enflame\.com\/gcu,enflame\.com\/vgcu/g' enflame-resources/k8s-device-plugin/v2/cdi/enflame-device-plugin-cdi.yaml
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ sed -i 's/enflame\.com\/gcu,enflame-tech\.com\/gcu,enflame\.com\/vgcu/enflame\.com\/gcu,enflame\.com\/vgcu/g' enflame-resources/k8s-device-plugin/v2/cpu-manager/enflame-device-plugin-compat-with-cpumanager.yaml
```

#### 制作 GCU Operator 镜像

运行下列命令构建 Operator 组件镜像：

```bash
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ sudo ./build-operator-image.sh --cli ctr 
################## config build-image.conf if need #####################
 OS=ubuntu 
 CLI_NAME=ctr 
 REPO_NAME=artifact.enflame.cn/enflame_docker_images/enflame
 IMAGE_NAME=gcu-operator 
 TAG=latest 
 NAMESPACE=k8s.io
########################################################################
Clear old image if exist.
Building image: artifact.enflame.cn/enflame_docker_images/enflame/gcu-operator:latest start...
[+] Building 1.0s (10/10) FINISHED                                                                                                                                                docker:default
 => [internal] load build definition from Dockerfile.ubuntu                                                                                                                                 0.0s
 => => transferring dockerfile: 335B                                                                                                                                                        0.0s
 => [internal] load metadata for docker.io/library/ubuntu:18.04                                                                                                                             0.0s
 => [internal] load .dockerignore                                                                                                                                                           0.0s
 => => transferring context: 2B                                                                                                                                                             0.0s
 => [internal] load build context                                                                                                                                                           0.2s
 => => transferring context: 49.44MB                                                                                                                                                        0.2s
 => [1/6] FROM docker.io/library/ubuntu:18.04                                                                                                                                               0.0s
 => [2/6] COPY manager /                                                                                                                                                                    0.3s
 => [3/6] RUN mkdir -p /opt/gcu-operator                                                                                                                                                    0.2s
 => [4/6] COPY enflame-resources /opt/gcu-operator/                                                                                                                                         0.0s
 => [5/6] COPY g_version.txt /tmp/                                                                                                                                                          0.1s
 => exporting to image                                                                                                                                                                      0.1s
 => => exporting layers                                                                                                                                                                     0.1s
 => => writing image sha256:931aa3d67ca3fd96e4e3669312d9c95ee6ead339be182bf6ce07b5884147a04f                                                                                                0.0s
 => => naming to artifact.enflame.cn/enflame_docker_images/enflame/gcu-operator:latest                                                                                                      0.0s
The image built successfully.
Save image package to ./images
unpacking artifact.enflame.cn/enflame_docker_images/enflame/gcu-operator:latest (sha256:1f304a0a2f88f48d1c75239aece3e273a6986ae3844789787333fe0a5f050132)...done
List images...
artifact.enflame.cn/enflame_docker_images/enflame/gcu-operator:latest        application/vnd.oci.image.manifest.v1+json           sha256:1f304a0a2f88f48d1c75239aece3e273a6986ae3844789787333fe0a5f050132 109.7 MiB linux/amd64 - 
```
离线镜像文件保存在 gcu-operator.tar 中
```bash
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ ls images/
gcu-operator.tar
```

#### 制作其他组件镜像

运行下列命令构建软件栈镜像：

```bash
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ sudo ./build-component-image.sh --cli ctr build
Building component images for system nameID: ubuntu22.04, arch: x86_64 start...
./build-component-image.sh : cli=ctr, os=ubuntu
###################### NFD ###########################
clean node-feature-discovery building files...
clean success
Building artifact.enflame.cn/enflame_docker_images/enflame/node-feature-discovery:1.2.20 for system nameID: ubuntu22.04, arch: x86_64 start...
################## config build-image.conf if need #####################
 OS=ubuntu 
 CLI_NAME=ctr 
 REPO_NAME=artifact.enflame.cn/enflame_docker_images/enflame
 IMAGE_NAME=node-feature-discovery 
 TAG=1.2.20 
 NAMESPACE=k8s.io
########################################################################
Clear old image if exist.
Building image: artifact.enflame.cn/enflame_docker_images/enflame/node-feature-discovery:1.2.20 start...
[+] Building 0.7s (9/9) FINISHED                                                                                                                                                  docker:default
 => [internal] load build definition from Dockerfile.ubuntu                                                                                                                                 0.0s
 => => transferring dockerfile: 354B                                                                                                                                                        0.0s
 => WARN: WorkdirRelativePath: Relative workdir "." can have unexpected results if the base image changes (line 8)                                                                          0.0s
 => [internal] load metadata for docker.io/library/ubuntu:18.04                                                                                                                             0.0s
 => [internal] load .dockerignore                                                                                                                                                           0.0s
 => => transferring context: 2B                                                                                                                                                             0.0s
 => CACHED [1/5] FROM docker.io/library/ubuntu:18.04                                                                                                                                        0.0s
 => [internal] load build context                                                                                                                                                           0.3s
 => => transferring context: 87.20MB                                                                                                                                                        0.3s
 => [2/5] COPY ./bin/nfd-master /usr/bin/                                                                                                                                                   0.1s
 => [3/5] COPY ./bin/nfd-topology-updater /usr/bin/                                                                                                                                         0.1s
 => [4/5] COPY ./bin/nfd-worker /usr/bin/                                                                                                                                                   0.0s
 => exporting to image                                                                                                                                                                      0.1s
 => => exporting layers                                                                                                                                                                     0.1s
 => => writing image sha256:2c22beb6bad1cad7f84258f87f3e8243d74ee8f6e2dc2d1728f4bcde56e042ce                                                                                                0.0s
 => => naming to artifact.enflame.cn/enflame_docker_images/enflame/node-feature-discovery:1.2.20                                                                                            0.0s
 1 warning found (use docker --debug to expand):
 - WorkdirRelativePath: Relative workdir "." can have unexpected results if the base image changes (line 8)
The image built successfully.
Save image package to ./images
unpacking artifact.enflame.cn/enflame_docker_images/enflame/node-feature-discovery:1.2.20 (sha256:2ea99a278937b89658559b24b5bd10b6a147c727fcbcd25a0d719efa5d2972ba)...done
List images...
artifact.enflame.cn/enflame_docker_images/enflame/node-feature-discovery:1.2.20 application/vnd.oci.image.manifest.v1+json           sha256:2ea99a278937b89658559b24b5bd10b6a147c727fcbcd25a0d719efa5d2972ba 145.6 MiB linux/amd64 -      
/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6/component-images/nfd
/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6
################# CONTAINER TOOLKIT ##################
clean container-toolkit building files...
clean success
Building artifact.enflame.cn/enflame_docker_images/enflame/container-toolkit:2.0.48 for system nameID: ubuntu22.04 start...
docker build -t artifact.enflame.cn/enflame_docker_images/enflame/container-toolkit:2.0.48 --file dockerfiles/Dockerfile.ubuntu22.04 .
[+] Building 1.3s (10/10) FINISHED                                                                                                                                                docker:default
 => [internal] load build definition from Dockerfile.ubuntu22.04                                                                                                                            0.0s
 => => transferring dockerfile: 300B                                                                                                                                                        0.0s
 => [internal] load metadata for docker.io/library/ubuntu:22.04                                                                                                                             0.0s
 => [internal] load .dockerignore                                                                                                                                                           0.0s
 => => transferring context: 2B                                                                                                                                                             0.0s
 => [1/5] FROM docker.io/library/ubuntu:22.04                                                                                                                                               0.0s
 => [internal] load build context                                                                                                                                                           0.2s
 => => transferring context: 47.30MB                                                                                                                                                        0.2s
 => [2/5] COPY ./binary/enflame-toolkit /work/                                                                                                                                              0.6s
 => [3/5] RUN chmod 755 /work/enflame-toolkit                                                                                                                                               0.3s
 => [4/5] WORKDIR /work                                                                                                                                                                     0.0s
 => [5/5] COPY ./enflame-container-toolkit_*.run /work/                                                                                                                                     0.1s
 => exporting to image                                                                                                                                                                      0.1s
 => => exporting layers                                                                                                                                                                     0.1s
 => => writing image sha256:c0c8ed4565f05ebf2797ccf51c91b3982db44f533c6fe8a50d5b84b15191cbcb                                                                                                0.0s
 => => naming to artifact.enflame.cn/enflame_docker_images/enflame/container-toolkit:2.0.48                                                                                                 0.0s
unpacking artifact.enflame.cn/enflame_docker_images/enflame/container-toolkit:2.0.48 (sha256:ceb8afd006ff0120b1d68b0937a3fe12b0eef605fcec1c939d40e0958e6edb66)...done
/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6
################# K8S PLUGIN ##################
clean k8s-device-plugin building files...
clean success
Building artifact.enflame.cn/enflame_docker_images/enflame/k8s-device-plugin:2.0.30 for system nameID: ubuntu22.04, arch: x86_64 start...
################## config build-image.conf if need #####################
 OS=ubuntu 
 CLI_NAME=ctr 
 REPO_NAME=artifact.enflame.cn/enflame_docker_images/enflame
 IMAGE_NAME=k8s-device-plugin 
 TAG=2.0.30 
 NAMESPACE=k8s.io
########################################################################
Clear old image if exist.
Building image: artifact.enflame.cn/enflame_docker_images/enflame/k8s-device-plugin:2.0.30 start...
[+] Building 1.9s (9/9) FINISHED                                                                                                                                                  docker:default
 => [internal] load build definition from Dockerfile.ubuntu                                                                                                                                 0.0s
 => => transferring dockerfile: 296B                                                                                                                                                        0.0s
 => [internal] load metadata for docker.io/library/ubuntu:18.04                                                                                                                             0.0s
 => [internal] load .dockerignore                                                                                                                                                           0.0s
 => => transferring context: 2B                                                                                                                                                             0.0s
 => [internal] load build context                                                                                                                                                           0.4s
 => => transferring context: 114.68MB                                                                                                                                                       0.4s
 => CACHED [1/4] FROM docker.io/library/ubuntu:18.04                                                                                                                                        0.0s
 => [2/4] COPY bin/enflame-device-plugin /usr/bin/                                                                                                                                          0.8s
 => [3/4] COPY bin/config-manager /usr/bin/                                                                                                                                                 0.2s
 => [4/4] COPY bin/cdi-manager /usr/bin/                                                                                                                                                    0.3s
 => exporting to image                                                                                                                                                                      0.1s
 => => exporting layers                                                                                                                                                                     0.1s
 => => writing image sha256:e4b9dc64c22a17ce2a594c534cca69fd7106b83261c93ab7912177d499a92f06                                                                                                0.0s
 => => naming to artifact.enflame.cn/enflame_docker_images/enflame/k8s-device-plugin:2.0.30                                                                                                 0.0s
The image built successfully.
Save image package to ./images
unpacking artifact.enflame.cn/enflame_docker_images/enflame/k8s-device-plugin:2.0.30 (sha256:c4757a310bf25e26ebbb2b051f2e382b3c767439a3dfbba379cd5b5ca00b3d01)...done
List images...
artifact.enflame.cn/enflame_docker_images/enflame/k8s-device-plugin:2.0.30      application/vnd.oci.image.manifest.v1+json           sha256:c4757a310bf25e26ebbb2b051f2e382b3c767439a3dfbba379cd5b5ca00b3d01 171.8 MiB linux/amd64 -      
/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6/component-images/plugin
/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6
################# NODE EXPORTER ##################
clean node-exporter building files...
clean success
Building artifact.enflame.cn/enflame_docker_images/enflame/node-exporter:1.0.22 for system nameID: ubuntu22.04, arch: x86_64 start...
################## config build-image.conf if need #####################
 OS=ubuntu 
 CLI_NAME=ctr 
 REPO_NAME=artifact.enflame.cn/enflame_docker_images/enflame
 IMAGE_NAME=node-exporter 
 TAG=1.0.22 
 NAMESPACE=k8s.io
########################################################################
Clear old image if exist.
Building image: artifact.enflame.cn/enflame_docker_images/enflame/node-exporter:1.0.22 start...
[+] Building 0.7s (7/7) FINISHED                                                                                                                                                  docker:default
 => [internal] load build definition from Dockerfile.ubuntu                                                                                                                                 0.0s
 => => transferring dockerfile: 215B                                                                                                                                                        0.0s
 => WARN: WorkdirRelativePath: Relative workdir "." can have unexpected results if the base image changes (line 5)                                                                          0.0s
 => [internal] load metadata for docker.io/library/ubuntu:18.04                                                                                                                             0.0s
 => [internal] load .dockerignore                                                                                                                                                           0.0s
 => => transferring context: 2B                                                                                                                                                             0.0s
 => [internal] load build context                                                                                                                                                           0.1s
 => => transferring context: 19.93MB                                                                                                                                                        0.1s
 => CACHED [1/3] FROM docker.io/library/ubuntu:18.04                                                                                                                                        0.0s
 => [2/3] COPY ./bin/node_exporter /usr/bin/                                                                                                                                                0.5s
 => exporting to image                                                                                                                                                                      0.1s
 => => exporting layers                                                                                                                                                                     0.1s
 => => writing image sha256:18f5c04a825905ab9399b6a1af21f5285b96baf0e5c8a79f5db5b1ef67d65705                                                                                                0.0s
 => => naming to artifact.enflame.cn/enflame_docker_images/enflame/node-exporter:1.0.22                                                                                                     0.0s
 1 warning found (use docker --debug to expand):
 - WorkdirRelativePath: Relative workdir "." can have unexpected results if the base image changes (line 5)
The image built successfully.
Save image package to ./images
unpacking artifact.enflame.cn/enflame_docker_images/enflame/node-exporter:1.0.22 (sha256:501ada9c868be52cd4fe581d81b305719b55e14853432c4f46d2678dd07ca6b7)...done
List images...
artifact.enflame.cn/enflame_docker_images/enflame/node-exporter:1.0.22          application/vnd.oci.image.manifest.v1+json           sha256:501ada9c868be52cd4fe581d81b305719b55e14853432c4f46d2678dd07ca6b7 81.5 MiB  linux/amd64 -      
/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6/component-images/node-exporter
/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6
################# GCU EXPORTER ##################
clean gcu-exporter building files...
clean success
Building artifact.enflame.cn/enflame_docker_images/enflame/gcu-exporter:1.5.1 for system nameID: ubuntu22.04, arch: x86_64 start...
################## config build-image.conf if need #####################
 OS=ubuntu 
 CLI_NAME=ctr 
 REPO_NAME=artifact.enflame.cn/enflame_docker_images/enflame
 IMAGE_NAME=gcu-exporter 
 TAG=1.5.1 
 NAMESPACE=k8s.io
########################################################################
Clear old image if exist.
Building image: artifact.enflame.cn/enflame_docker_images/enflame/gcu-exporter:1.5.1 start...
[+] Building 9.4s (8/8) FINISHED                                                                                                                                                  docker:default
 => [internal] load build definition from Dockerfile.ubuntu                                                                                                                                 0.0s
 => => transferring dockerfile: 248B                                                                                                                                                        0.0s
 => [internal] load metadata for docker.io/library/ubuntu:18.04                                                                                                                             0.0s
 => [internal] load .dockerignore                                                                                                                                                           0.0s
 => => transferring context: 2B                                                                                                                                                             0.0s
 => CACHED [1/3] FROM docker.io/library/ubuntu:18.04                                                                                                                                        0.0s
 => [internal] load build context                                                                                                                                                           0.1s
 => => transferring context: 19.45MB                                                                                                                                                        0.1s
 => [2/3] RUN apt-get update && apt-get install -y dmidecode                                                                                                                                9.1s
 => [3/3] COPY gcu-exporter /usr/bin/                                                                                                                                                       0.1s
 => exporting to image                                                                                                                                                                      0.1s 
 => => exporting layers                                                                                                                                                                     0.1s 
 => => writing image sha256:c2a84e6ac6c5d169e50fd38d274819fa8f8ffbb7ab3b3f040363926ec9d39653                                                                                                0.0s 
 => => naming to artifact.enflame.cn/enflame_docker_images/enflame/gcu-exporter:1.5.1                                                                                                       0.0s 
The image built successfully.                                                                                                                                                                    
Save image package to ./images
unpacking artifact.enflame.cn/enflame_docker_images/enflame/gcu-exporter:1.5.1 (sha256:6e000c82aba1cd15ed59c5a4bae32ea911b14c5c51e02928e01570677d772498)...done
List images...
artifact.enflame.cn/enflame_docker_images/enflame/gcu-exporter:1.5.1            application/vnd.oci.image.manifest.v1+json           sha256:6e000c82aba1cd15ed59c5a4bae32ea911b14c5c51e02928e01570677d772498 125.6 MiB linux/amd64 -      
/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6/component-images/gcu-exporter
/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6
################## GFD ##########################
clean gcu-feature-discovery building files...
clean success
Building artifact.enflame.cn/enflame_docker_images/enflame/gcu-feature-discovery:1.3.20 for system nameID: ubuntu22.04, arch: x86_64 start...
################## config build-image.conf if need #####################
 OS=ubuntu 
 CLI_NAME=ctr 
 REPO_NAME=artifact.enflame.cn/enflame_docker_images/enflame
 IMAGE_NAME=gcu-feature-discovery 
 TAG=1.3.20 
 NAMESPACE=k8s.io
########################################################################
Clear old image if exist.
Building image: artifact.enflame.cn/enflame_docker_images/enflame/gcu-feature-discovery:1.3.20 start...
[+] Building 0.2s (9/9) FINISHED                                                                                                                                                  docker:default
 => [internal] load build definition from Dockerfile.ubuntu                                                                                                                                 0.0s
 => => transferring dockerfile: 301B                                                                                                                                                        0.0s
 => [internal] load metadata for docker.io/library/ubuntu:18.04                                                                                                                             0.0s
 => [internal] load .dockerignore                                                                                                                                                           0.0s
 => => transferring context: 2B                                                                                                                                                             0.0s
 => CACHED [1/4] FROM docker.io/library/ubuntu:18.04                                                                                                                                        0.0s
 => [internal] load build context                                                                                                                                                           0.0s
 => => transferring context: 2.37MB                                                                                                                                                         0.0s
 => [2/4] COPY ./config/gfd.json /tmp/                                                                                                                                                      0.0s
 => [3/4] COPY ./config/topscloud.json /tmp/                                                                                                                                                0.0s
 => [4/4] COPY ./gcu-feature-discovery /usr/bin/                                                                                                                                            0.0s
 => exporting to image                                                                                                                                                                      0.0s
 => => exporting layers                                                                                                                                                                     0.0s
 => => writing image sha256:b1447487dfdc4d476a1f6689ff76939b85f2a1d6a4439459ef2b0d38c1f171f5                                                                                                0.0s
 => => naming to artifact.enflame.cn/enflame_docker_images/enflame/gcu-feature-discovery:1.3.20                                                                                             0.0s
The image built successfully.
Save image package to ./images
unpacking artifact.enflame.cn/enflame_docker_images/enflame/gcu-feature-discovery:1.3.20 (sha256:fd5871556f382f36168edd5bf8bae082aefd569627793f2a3b50873a0c7141ef)...done
List images...
artifact.enflame.cn/enflame_docker_images/enflame/gcu-feature-discovery:1.3.20  application/vnd.oci.image.manifest.v1+json           sha256:fd5871556f382f36168edd5bf8bae082aefd569627793f2a3b50873a0c7141ef 64.8 MiB  linux/amd64 -      
/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6/component-images/gfd
/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6
Build all images success!
(base) ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ ls -al images/
total 840664
drwxr-xr-x 2 root   root        4096 Mar 26 12:52 .
drwxr-xr-x 9 ubuntu ubuntu      4096 Mar 26 12:29 ..
-rw------- 1 root   root   127725568 Mar 26 12:52 container-toolkit.tar
-rw------- 1 root   root   131739648 Mar 26 12:52 gcu-exporter.tar
-rw------- 1 root   root    67921920 Mar 26 12:52 gcu-feature-discovery.tar
-rw------- 1 root   root   115021824 Mar 26 12:29 gcu-operator.tar
-rw------- 1 root   root   180206592 Mar 26 12:52 k8s-device-plugin.tar
-rw------- 1 root   root    85471232 Mar 26 12:52 node-exporter.tar
-rw------- 1 root   root   152738304 Mar 26 12:51 node-feature-discovery.tar
```

#### 上传镜像到本地镜像仓库

在本地镜像仓库创建 Project enflame。

登陆庆阳集群本地镜像仓库
```bash
(base) ubuntu@prepare-node:~$ sudo docker login harbor.example.cn
```

运行下列命令，将构建的镜像上传到本地镜像仓库：
```bash
(base) ubuntu@prepare-node:~/tmp$ sudo docker images | grep artifact.enflame.cn
artifact.enflame.cn/enflame_docker_images/enflame/gcu-feature-discovery      1.3.20                b1447487dfdc   4 minutes ago    65.5MB
artifact.enflame.cn/enflame_docker_images/enflame/gcu-exporter               1.5.1                 c2a84e6ac6c5   4 minutes ago    129MB
artifact.enflame.cn/enflame_docker_images/enflame/node-exporter              1.0.22                18f5c04a8259   4 minutes ago    83.1MB
artifact.enflame.cn/enflame_docker_images/enflame/k8s-device-plugin          2.0.30                e4b9dc64c22a   4 minutes ago    178MB
artifact.enflame.cn/enflame_docker_images/enflame/container-toolkit          2.0.48                c0c8ed4565f0   4 minutes ago    167MB
artifact.enflame.cn/enflame_docker_images/enflame/node-feature-discovery     1.2.20                2c22beb6bad1   5 minutes ago    150MB
artifact.enflame.cn/enflame_docker_images/enflame/gcu-operator               latest                931aa3d67ca3   27 minutes ago   113MB
(base) ubuntu@prepare-node:~/tmp$ sudo docker images | grep artifact.enflame.cn | awk '{print $1":"$2}' > images.txt
(base) ubuntu@prepare-node:~/tmp$ cat images.txt 
artifact.enflame.cn/enflame_docker_images/enflame/gcu-feature-discovery:1.3.20
artifact.enflame.cn/enflame_docker_images/enflame/gcu-exporter:1.5.1
artifact.enflame.cn/enflame_docker_images/enflame/node-exporter:1.0.22
artifact.enflame.cn/enflame_docker_images/enflame/k8s-device-plugin:2.0.30
artifact.enflame.cn/enflame_docker_images/enflame/container-toolkit:2.0.48
artifact.enflame.cn/enflame_docker_images/enflame/node-feature-discovery:1.2.20
artifact.enflame.cn/enflame_docker_images/enflame/gcu-operator:latest
(base) ubuntu@prepare-node:~/tmp$ sudo docker login harbor.example.cn
Authenticating with existing credentials...
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credential-stores
Login Succeeded
(base) ubuntu@prepare-node:~/tmp$ while read -r image; do 
    new_image=$(echo "$image" | sed 's#artifact.enflame.cn/enflame_docker_images/enflame#harbor.example.cn/enflame#')
    sudo docker tag "$image" "$new_image"
    sudo docker push "$new_image"
done < images.txt
The push refers to repository [harbor.example.cn/enflame/gcu-feature-discovery]
5a182f63e4c7: Pushed 
ccb6198e1066: Pushed 
5921243a78b8: Pushed 
548a79621a42: Pushed 
1.3.20: digest: sha256:44da1863a915f432c3aac4eb6fb932f0a6720c2d43aaa871ac1d5d1f37a9c63f size: 1154
The push refers to repository [harbor.example.cn/enflame/gcu-exporter]
89976fc89a2d: Pushed 
ef95026af328: Pushed 
548a79621a42: Mounted from enflame/gcu-feature-discovery 
1.5.1: digest: sha256:1f6eb8543c475be62dfed0c6a30cd6fa461614d75fcfed29de8e3af9081c2b49 size: 952
The push refers to repository [harbor.example.cn/enflame/node-exporter]
e2703f193497: Pushed 
548a79621a42: Mounted from enflame/gcu-exporter 
1.0.22: digest: sha256:b29cb6c817d0ab487a4fe281b9f33f617f6ae22d57b5551ceafd1ec2ba745c1f size: 741
The push refers to repository [harbor.example.cn/enflame/k8s-device-plugin]
cd9e0e9b0792: Pushed 
e509e61c4fae: Pushed 
4f008ac6f108: Pushed 
548a79621a42: Mounted from enflame/node-exporter 
2.0.30: digest: sha256:7039f62c6e8826f87b37c999124f65eb542fd4e03bbad61a93c375e54d950b49 size: 1165
The push refers to repository [harbor.example.cn/enflame/container-toolkit]
d82f41325aea: Pushed 
5f70bf18a086: Mounted from t9k/homepage-web 
854134f7112a: Pushed 
270a1170e7e3: Pushed 
2.0.48: digest: sha256:09e8d1d9274e60119e8f24f8c87fe90e4c58eb5460a78ba8f0ee14baa4814be9 size: 1370
The push refers to repository [harbor.example.cn/enflame/node-feature-discovery]
fd2051d0b25c: Pushed 
040d07927a78: Pushed 
156273f1b8ad: Pushed 
548a79621a42: Mounted from enflame/k8s-device-plugin 
1.2.20: digest: sha256:e954ea41b025eba7b0a6288f34c3002d63fa3dfcfce8d7a2a974c5a71a1f52b6 size: 1164
The push refers to repository [harbor.example.cn/enflame/gcu-operator]
949db88057e0: Pushed 
c8e8c0389986: Pushed 
0d07471934f3: Pushed 
f59ac6f3091d: Pushed 
548a79621a42: Mounted from enflame/node-feature-discovery 
latest: digest: sha256:f6b7ba0e83dad3e3ffea4ad6cc9829f315ba6f56d2f909c610a465a7c9160a52 size: 1363
```

### 安装部署

#### 安装前准备

##### 访问集群的权限

在 prepare-node 节点上配置访问 K8s 集群的权限。

##### 修改 chart values.yaml

修改 gcu-operator-chart 的 values.yaml:将 repository 设置为 `harbor.example.cn/enflame`
```bash
ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ ls
build-component-image.sh  build-operator-image.sh  config.json              delete-operator.sh  dockerfiles        example             g_version.txt  manager
build-image.conf          component-images         copy-and-load-images.sh  deploy-operator.sh  enflame-resources  gcu-operator-chart  images         tools
ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ mkdir backup
ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ cp gcu-operator-chart/values.yaml backup/gcu-operator-chart-values.yaml
ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ vi gcu-operator-chart/values.yaml 
ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ diff -u --color backup/gcu-operator-chart-values.yaml gcu-operator-chart/values.yaml 
--- backup/gcu-operator-chart-values.yaml	2025-03-26 16:42:55.859131569 +0800
+++ gcu-operator-chart/values.yaml	2025-03-26 16:43:44.985810738 +0800
@@ -6,7 +6,7 @@
 replicaCount: 1
 
 image:
-  repository: artifact.enflame.cn/enflame_docker_images/enflame
+  repository: harbor.example.cn/enflame
   name: gcu-operator
   pullPolicy: IfNotPresent
   tag: latest
```

##### 修改 GCUResource

5.2.2 修改 GCUResource
修改 example/gcu-resource.json：
1. 将 image repository 修改为 `harbor.example.cn/enflame`
2. 禁止安装 nodeExporter，原因如下：
    1. 与 T9k 安装的 node exporter 冲突
    2. 没有发现 GCU Operator 其他组件依赖 nodeExporter
3. 为部分组件添加 nodeSelector `"node-role.kubernetes.io/compute": ""`，使得这些组件只运行在 worker 节点上。
4. 为部分组件添加 nodeSelector `"t9k.enflame.com/driver.installed": "true"`，避免组件在 driver 未安装之前就运行在节点上。

```bash
ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ mv example/gcu-resource.json backup/gcu-resource.json
ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ vi example/gcu-resource.json
ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ diff -u --color backup/gcu-resource.json example/gcu-resource.json 
--- backup/gcu-resource.json	2025-03-26 16:32:21.820178761 +0800
+++ example/gcu-resource.json	2025-03-26 16:58:28.742050722 +0800
@@ -13,13 +13,13 @@
 				"image": "node-feature-discovery",
 				"version": "default",
 				"imagePullPolicy": "IfNotPresent",
-				"repository": "artifact.enflame.cn/enflame_docker_images/enflame"
+				"repository": "harbor.example.cn/enflame"
 			},
 			"worker": {
 				"image": "node-feature-discovery",
 				"version": "default",
 				"imagePullPolicy": "IfNotPresent",
-				"repository": "artifact.enflame.cn/enflame_docker_images/enflame"
+				"repository": "harbor.example.cn/enflame"
 			}
 		},
 		"driver": {
@@ -40,9 +40,10 @@
 			"namespace": "kube-system",
 			"imagePullPolicy": "IfNotPresent",
 			"nodeSelector": {
+                "node-role.kubernetes.io/compute": "",
 				"enflame.com/gcu.present": "true"
 			},
-			"repository": "artifact.enflame.cn/enflame_docker_images/enflame"
+			"repository": "harbor.example.cn/enflame"
 		},
 		"containerToolkit": {
 			"env": [
@@ -69,9 +70,11 @@
 			"namespace": "kube-system",
 			"imagePullPolicy": "IfNotPresent",
 			"nodeSelector": {
+                "t9k.enflame.com/driver.installed": "true",
+                "node-role.kubernetes.io/compute": "",
 				"enflame.com/gcu.present": "true"
 			},
-			"repository": "artifact.enflame.cn/enflame_docker_images/enflame"
+			"repository": "harbor.example.cn/enflame"
 		},
 		"devicePlugin": {
 			"image": "k8s-device-plugin",
@@ -80,11 +83,13 @@
 			"namespace": "kube-system",
 			"imagePullPolicy": "IfNotPresent",
 			"nodeSelector": {
+                "t9k.enflame.com/driver.installed": "true",
+                "node-role.kubernetes.io/compute": "",
 				"enflame.com/gcu.present": "true"
 			},
 			"command": ["/usr/bin/enflame-device-plugin"],
 			"args": [],
-			"repository": "artifact.enflame.cn/enflame_docker_images/enflame"
+			"repository": "harbor.example.cn/enflame"
 		},
 		"gcuExporter": {
 			"notDeploy": false,
@@ -94,12 +99,14 @@
 			"namespace": "kube-system",
 			"imagePullPolicy": "IfNotPresent",
 			"nodeSelector": {
+                "t9k.enflame.com/driver.installed": "true",
+                "node-role.kubernetes.io/compute": "",
 				"enflame.com/gcu.present": "true"
 			},
-			"repository": "artifact.enflame.cn/enflame_docker_images/enflame"
+			"repository": "harbor.example.cn/enflame"
 		},
 		"nodeExporter": {
-			"notDeploy": false,
+			"notDeploy": true,
 			"image": "node-exporter",
 			"version": "default",
 			"name": "enflame-node-exporter",
@@ -108,7 +115,7 @@
 			"nodeSelector": {
 				"enflame.com/gcu.present": "true"
 			},
-			"repository": "artifact.enflame.cn/enflame_docker_images/enflame"
+			"repository": "harbor.example.cn/enflame"
 		},
 		"gfd": {
 			"image": "gcu-feature-discovery",
@@ -117,9 +124,11 @@
 			"namespace": "kube-system",
 			"imagePullPolicy": "IfNotPresent",
 			"nodeSelector": {
+                "t9k.enflame.com/driver.installed": "true",
+                "node-role.kubernetes.io/compute": "",
 				"enflame.com/gcu.present": "true"
 			},
-			"repository": "artifact.enflame.cn/enflame_docker_images/enflame"
+			"repository": "harbor.example.cn/enflame"
 		},
 		"gcusharePlugin": {
 			"notDeploy": true,
@@ -129,11 +138,13 @@
 			"namespace": "kube-system",
 			"imagePullPolicy": "IfNotPresent",
 			"nodeSelector": {
+                "t9k.enflame.com/driver.installed": "true",
+                "node-role.kubernetes.io/compute": "",
 				"enflame.com/gcu.present": "true"
 			},
 			"memoryUnit": "1",
 			"gcushareNodes": [],
-			"repository": "artifact.enflame.cn/enflame_docker_images/enflame"
+			"repository": "harbor.example.cn/enflame"
 		},
 		"gcushareScheduler": {
 			"notDeploy": true,
@@ -143,9 +154,11 @@
 			"namespace": "kube-system",
 			"imagePullPolicy": "IfNotPresent",
 			"nodeSelector": {
+                "t9k.enflame.com/driver.installed": "true",
+                "node-role.kubernetes.io/compute": "",
 				"enflame.com/gcu.present": "true"
 			},
-			"repository": "artifact.enflame.cn/enflame_docker_images/enflame"
+			"repository": "harbor.example.cn/enflame"
 		},
 		"gcushareConfigManager": {
 			"notDeploy": true,
@@ -154,7 +167,7 @@
 			"version": "default",
 			"namespace": "kube-system",
 			"imagePullPolicy": "IfNotPresent",
-			"repository": "artifact.enflame.cn/enflame_docker_images/enflame"
+			"repository": "harbor.example.cn/enflame"
 		},
 		"k8sDriverManager": {
 			"notDeploy": true,
@@ -164,9 +177,11 @@
 			"namespace": "kube-system",
 			"imagePullPolicy": "IfNotPresent",
 			"nodeSelector": {
+                "t9k.enflame.com/driver.installed": "true",
+                "node-role.kubernetes.io/compute": "",
 				"enflame.com/gcu.present": "true"
 			},
-			"repository": "artifact.enflame.cn/enflame_docker_images/enflame"
+			"repository": "harbor.example.cn/enflame"
 		}
 	}
 }
```

##### GCU 节点添加标签

为 GCU 节点添加标签 `t9k.enflame.com/driver.installed="true"`。

如果所有的 Compute 节点都是 GCU 节点，可以参考下列命令为节点添加标签：
```
$ kubectl get node -l node-role.kubernetes.io/compute=""
NAME         STATUS   ROLES     AGE   VERSION
worker-78    Ready    compute   25d   v1.30.4
worker-79    Ready    compute   25d   v1.30.4
$ kubectl label node $(k get node -l node-role.kubernetes.io/compute="" | awk 'NR>1 {print $1}') t9k.enflame.com/driver.installed="true"
node/worker-78 labeled
node/worker-79 labeled
```

#### 安装 GCU Operator

运行下列命令安装 GCU Operator

```bash
ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ ./deploy-operator.sh 
WARN: It is detected that KMD is not installed on the system, the following information is useful for you:
#####################
1. It is recommended that you install KMD on all GCU nodes in the k8s cluster before deploying gcu-operator
2. You can also use gcu-operator to automatically install KMD for all GCU nodes in the cluster, then you need to do two things:
            1) The gcu-resource.yaml file and gcu-resrouce.json file provided by gcu-operator do not install drivers by default. 
                * If you deploy gcuResource together with gcu-operator(values.gcuResource.deploy=true), make sure 'gcuResource.driver.notDeploy=false' in values.yaml;
                * If you deploy gcuResource after installing gcu-operator(values.gcuResource.deploy=false), make sure 'spec.driver.notDeploy=false' in example/gcu-resource.json;
            2) Specify the absolute path to your driver package via fields: driver.path and set driver.build=true in config.json,
                the driver path can usually be found in the topsrider package. This path usually contains the following:
                # ll <your-path>/x86_64-linux-rel/lib/TopsPlatform_*-*_deb_amd64/driver/
                drwxr-xr-x  2 root     root         4096 Mar 13 11:30 ./
                drwx------ 10 root     root         4096 Mar 13 11:31 ../
                -rwxr--r--  1 ci_build ci_build   197547 Mar 11 16:16 enflame_peer_mem-x86_64-gcc-*.run
                -rwxr--r--  1 ci_build ci_build   259268 Mar 11 16:16 enflame_virt-x86_64-gcc-*.run
                -rwxr--r--  1 ci_build ci_build 72207575 Mar 11 16:16 enflame-x86_64-gcc-*.run
            Next, you can build the driver image according to the user guide.
#####################
Deploy gcu-operator release start...
NAME: gcu-operator
LAST DEPLOYED: Wed Mar 26 16:59:55 2025
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
Do you want to create gcu-resource now?(y/yes, n/no)?
n
exit
note: you can execute command 'kubectl create -f ./example/gcu-resource.json' manually to create gcu resource
$ kubectl -n kube-system get pod  | grep gcu
gcu-operator-64b5c879cf-mjn6c          1/1     Running            0                66s
$ kubectl -n kube-system logs gcu-operator-64b5c879cf-mjn6c
I0326 08:59:58.292964       1 request.go:601] Waited for 1.044248505s due to client-side throttling, not priority and fairness, request: GET:https://10.233.0.1:443/apis/longhorn.io/v1beta2?timeout=32s
1.742979599145102e+09	INFO	controller-runtime.metrics	Metrics server is starting to listen	{"addr": ":8080"}
W0326 08:59:59.145419       1 client_config.go:617] Neither --kubeconfig nor --master was specified.  Using the inClusterConfig.  This might not work.
I0326 08:59:59.145794       1 leaderelection.go:248] attempting to acquire leader lease kube-system/4d4668d3.enflame.com...
1.742979599145801e+09	INFO	Starting server	{"kind": "health probe", "addr": "[::]:8081"}
1.7429795991458006e+09	INFO	Starting server	{"path": "/metrics", "kind": "metrics", "addr": "[::]:8080"}
I0326 09:00:18.231462       1 leaderelection.go:258] successfully acquired lease kube-system/4d4668d3.enflame.com
1.7429796182316618e+09	INFO	Starting EventSource	{"controller": "gcuresource", "controllerGroup": "topscloud.enflame.com", "controllerKind": "GcuResource", "source": "kind source: *v1.GcuResource"}
1.742979618231728e+09	INFO	Starting Controller	{"controller": "gcuresource", "controllerGroup": "topscloud.enflame.com", "controllerKind": "GcuResource"}
1.7429796182316408e+09	DEBUG	events	Normal	{"object": {"kind":"Lease","namespace":"kube-system","name":"4d4668d3.enflame.com","uid":"7d974ffa-bd10-4fbc-9cb0-4c40b404eef5","apiVersion":"coordination.k8s.io/v1","resourceVersion":"159563644"}, "reason": "LeaderElection", "message": "master-3_0387706f-f0fc-40ad-9315-6a3fd049baa6 became leader"}
1.7429796183326051e+09	INFO	Starting workers	{"controller": "gcuresource", "controllerGroup": "topscloud.enflame.com", "controllerKind": "GcuResource", "worker count": 1}
```

运行下列命令，创建 GCUResource，配置 GCU Operator 部署组件：
```bash
ubuntu@prepare-node:/data/enflame/topscloud_3.3.20/gcu-operator_2.4.6$ kubectl create -f example/gcu-resource.json 
gcuresource.topscloud.enflame.com/enflame-gcu-resource created
```

稍等一会，查看 GCU Operator 组件运行情况：
```bash
$ kubectl -n kube-system get pod -o wide | grep enflame
enflame-container-toolkit-8bspz        1/1     Running            0                7m43s   10.233.78.69    worker-78    <none>           <none>
enflame-container-toolkit-lp2jk        1/1     Running            0                7m43s   10.233.86.237   worker-79    <none>           <none>
enflame-gcu-exporter-62ml7             1/1     Running            0                7m19s   10.52.2.78      worker-78    <none>           <none>
enflame-gcu-exporter-cw8vn             1/1     Running            0                7m19s   10.52.2.79      worker-79    <none>           <none>
enflame-gcu-feature-discovery-7w2n7    1/1     Running            0                5m6s    10.233.78.11    worker-78    <none>           <none>
enflame-gcu-feature-discovery-tmdrn    1/1     Running            0                5m6s    10.233.86.28    worker-79    <none>           <none>
enflame-k8s-device-plugin-25cs2        1/1     Running            0                7m25s   10.233.78.70    worker-78    <none>           <none>
enflame-k8s-device-plugin-lkr4m        1/1     Running            0                7m25s   10.233.86.87    worker-79    <none>           <none>
enflame-node-feature-discovery-5j62g   2/2     Running            0                7m46s   10.233.86.158   worker-79    <none>           <none>
enflame-node-feature-discovery-5nd2d   2/2     Running            0                7m46s   10.233.64.9     ingress-3    <none>           <none>
enflame-node-feature-discovery-6vs4j   2/2     Running            0                7m46s   10.233.78.19    worker-78    <none>           <none>
enflame-node-feature-discovery-726kv   2/2     Running            0                7m46s   10.233.72.83    master-3     <none>           <none>
enflame-node-feature-discovery-96h9q   2/2     Running            0                7m46s   10.233.67.241   master-1     <none>           <none>
enflame-node-feature-discovery-hjqxg   2/2     Running            0                7m46s   10.233.68.201   ingress-1    <none>           <none>
enflame-node-feature-discovery-spwgt   2/2     Running            0                7m46s   10.233.66.44    ingress-2    <none>           <none>
enflame-node-feature-discovery-w67dt   2/2     Running            0                7m46s   10.233.69.107   master-2     <none>           <none>
$ kubectl -n kube-system get node -o json | jq .items[].status.allocatable | grep enflame
  "enflame.com/gcu": "8",
  "enflame.com/gcu": "8",
```

#### 安装后配置

##### 配置 systemdCgroup

当 kubelet 的 cgroup 配置与容器运行时的 cgroup 配置不一致时，需要修改 containerd 配置 systemdCgroup。

下面是配置 systemdCgroup 的示例：

查看集群 kubelet 的 cgroup 配置：cgroup 驱动使用 systemd
```bash
$ kubectl -n kube-system get cm kubelet-config  -o yaml | grep cgroupDriver
    cgroupDriver: systemd
```

对比 container toolkit 对 containerd 的配置：`[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.enflame.options]` 未设置 `systemdCgroup = true`，containred 使用的 cgroup 驱动是 cgroupfs，与 kubelet cgroup 配置不一致。

```bash
ubuntu@worker-78:~$ sudo cat /etc/containerd/config.toml
oom_score = 0
root = "/var/lib/containerd"
state = "/run/containerd"
version = 2
[debug]
  address = ""
  format = ""
  gid = 0
  level = "info"
  uid = 0
[grpc]
  max_recv_message_size = 16777216
  max_send_message_size = 16777216
[metrics]
  address = ""
  grpc_histogram = false
[plugins]
  [plugins."io.containerd.grpc.v1.cri"]
    disable_apparmor = false
    disable_hugetlb_controller = true
    enable_selinux = false
    enable_unprivileged_icmp = false
    enable_unprivileged_ports = false
    image_pull_progress_timeout = "5m"
    max_container_log_line_size = -1
    sandbox_image = "registry.cn-hangzhou.aliyuncs.com/t9k/pause:3.9"
    tolerate_missing_hugetlb_controller = true
    [plugins."io.containerd.grpc.v1.cri".containerd]
      default_runtime_name = "enflame"
      discard_unpacked_layers = true
      snapshotter = "overlayfs"
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.enflame]
          privileged_without_host_devices = false
          runtime_engine = ""
          runtime_root = ""
          runtime_type = "io.containerd.runc.v2"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.enflame.options]
            BinaryName = "/usr/bin/enflame-container-runtime"
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          base_runtime_spec = "/etc/containerd/cri-base.json"
          runtime_engine = ""
          runtime_root = ""
          runtime_type = "io.containerd.runc.v2"
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            binaryName = "/usr/local/bin/runc"
            systemdCgroup = true
```

在上述情况下，需要修改所有 GCU 节点的 containerd 配置：为 `[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.enflame.options]` 添加参数 systemdCgroup = true

运行下列命令，使用 ansible 修改所有 GCU 节点的 containerd 配置：
```bash
(kubespray) ubuntu@prepare-node:~/ansible/qingyang$ ansible -i inventory/gcu-update.ini all -m shell -a "sudo sed -i 's/^\(\s*\)\(\[plugins\.\"io\.containerd\.grpc\.v1\.cri\"\.containerd\.runtimes\.enflame\.options\]\)/\1\2\n\1  systemdCgroup = true/' /etc/containerd/config.toml" -b -K
BECOME password: 
(kubespray) ubuntu@prepare-node:~/ansible/qingyang$ ansible -i inventory/gcu-update.ini all -m shell -a "systemctl daemon-reload"  --become 
(kubespray) ubuntu@prepare-node:~/ansible/qingyang$ ansible -i inventory/gcu-update.ini all -m shell -a "systemctl restart containerd.service"  --become 
```

#### 验证

运行下列命令，验证 GCU Operator 是否正常运行，需要确保：
1. 组件正常运行
2. GCU 节点的 node `status.allocatable` 含有扩展资源 `enflame.com/gcu`，并且扩展资源的数量与节点上的 GCU 数量一致。

```bash
$ kubectl -n kube-system get pod -o wide | grep enflame
enflame-container-toolkit-8bspz        1/1     Running   0                4d21h   10.233.78.69    worker-78    <none>           <none>
enflame-container-toolkit-lp2jk        1/1     Running   0                4d21h   10.233.86.237   worker-79    <none>           <none>
enflame-gcu-exporter-62ml7             1/1     Running   0                4d21h   10.52.2.78      worker-78    <none>           <none>
enflame-gcu-exporter-cw8vn             1/1     Running   0                4d21h   10.52.2.79      worker-79    <none>           <none>
enflame-gcu-feature-discovery-7w2n7    1/1     Running   0                4d21h   10.233.78.11    worker-78    <none>           <none>
enflame-gcu-feature-discovery-tmdrn    1/1     Running   0                4d21h   10.233.86.28    worker-79    <none>           <none>
enflame-k8s-device-plugin-25cs2        1/1     Running   0                4d21h   10.233.78.70    worker-78    <none>           <none>
enflame-k8s-device-plugin-lkr4m        1/1     Running   0                4d21h   10.233.86.87    worker-79    <none>           <none>
enflame-node-feature-discovery-5j62g   2/2     Running   0                4d21h   10.233.86.158   worker-79    <none>           <none>
enflame-node-feature-discovery-5nd2d   2/2     Running   0                4d21h   10.233.64.9     ingress-3    <none>           <none>
enflame-node-feature-discovery-6vs4j   2/2     Running   0                4d21h   10.233.78.19    worker-78    <none>           <none>
enflame-node-feature-discovery-726kv   2/2     Running   0                4d21h   10.233.72.83    master-3     <none>           <none>
enflame-node-feature-discovery-96h9q   2/2     Running   0                4d21h   10.233.67.241   master-1     <none>           <none>
enflame-node-feature-discovery-hjqxg   2/2     Running   0                4d21h   10.233.68.201   ingress-1    <none>           <none>
enflame-node-feature-discovery-spwgt   2/2     Running   0                4d21h   10.233.66.44    ingress-2    <none>           <none>
enflame-node-feature-discovery-w67dt   2/2     Running   0                4d21h   10.233.69.107   master-2     <none>           <none>
$ kubectl get node -l t9k.enflame.com/driver.installed="true" -o json | jq .items[].status.allocatable 
{
  "cpu": "119900m",
  "enflame.com/gcu": "8",
  "ephemeral-storage": "456449947712",
  "hugepages-1Gi": "0",
  "hugepages-2Mi": "0",
  "memory": "469376488Ki",
  "pods": "110"
}
...
```

## 监控配置

安装下列 T9k 产品时，需要启用对 Enflame GCU 的监控配置。

### T9k Monitoring

在安装 T9k Monitoring 时，可通过 Helm values.yaml 中的 `global.t9k.monitoring.gpu.enflame` 字段配置针对 Enflame GCU 的监控设置。启用 Enflame GCU 监控后：
1. T9k Monitoring 部署的 Prometheus 服务将自动收集 Enflame GCU Exporter 生成的监控数据
2. 在 T9k Monitoring 部署的 Grafana 中，可以通过 Dashboard 查看 Enflame GCU 的监控图表。

下面是一个配置示例：
```yaml
global:
  t9k:
    monitoring:
      gpu:
        enflame:
          enabled: true
          serviceMonitor:
            # namespace where service gcu-exporter is located
            namespaceMatchName: kube-system
            # port in service gcu-exporter to expose metrics
            port: exporterport
            # labels to match service gcu-exporter
            selector:
              matchLabels:
                app.kubernetes.io/instance: gcuExporter
```

### Cluster Admin

在安装 Cluster Admin 时，可通过 Helm values.yaml 中的 `global.t9k.clusterAdminWeb.gpuMonitoring.enflame` 字段配置 Enflame GCU 的监控设置。启用 Enflame GCU 监控后：
1. 管理员可以在 Cluster Admin Web 的工作负载详情页面查看 Enflame GCU 的资源监控图表。
2. 管理员可以在节点详情页面查看节点上的 Enflame GCU 信息。

下面是一个配置示例，配置的字段说明请参考 <a target="_blank" rel="noopener noreferrer" href="https://github.com/t9k/admin-manuals/blob/master/src/cluster-admin-ui/config.md#gpu-%E7%9B%91%E6%8E%A7%E9%85%8D%E7%BD%AE">管理员文档</a>：

```yaml
global:
  t9k:
    clusterAdminWeb:
      gpuMonitoring:
        enflame:
          charts:
          - legend: '{{uuid}}'
            promQLFormat: avg(label_replace(label_replace(enflame_gcu_memory_used_bytes{job="gcuExporter",pod_namespace="${namespace}",pod_name=~"${pods}",pod_name!=""},"pod","$1","pod_name","(.+)"),"namespace","$1","pod_namespace","(.+)")    *
              on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
            title:
              en: GPU Memory Used
              zh: "GPU 已用显存"
            unit: B
          - legend: '{{uuid}}'
            promQLFormat: avg(label_replace(label_replace(enflame_gcu_memory_usage{job="gcuExporter",pod_namespace="${namespace}",pod_name=~"${pods}",pod_name!=""},"pod","$1","pod_name","(.+)"),"namespace","$1","pod_namespace","(.+)")    *
              on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid) * 100
            title:
              en: GPU Memory Usage
              zh: GPU 显存使用率
            unit: '%'
          - legend: '{{uuid}}'
            promQLFormat: avg(label_replace(label_replace(enflame_gcu_power_usage{job="gcuExporter",pod_namespace="${namespace}",pod_name=~"${pods}",pod_name!=""},"pod","$1","pod_name","(.+)"),"namespace","$1","pod_namespace","(.+)")    *
              on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
            title:
              en: GPU Power Usage
              zh: GPU 功率使用率
            unit: '%'
          - legend: '{{uuid}}'
            promQLFormat: avg(label_replace(label_replace(enflame_gcu_power_consumption{job="gcuExporter",pod_namespace="${namespace}",pod_name=~"${pods}",pod_name!=""},"pod","$1","pod_name","(.+)"),"namespace","$1","pod_namespace","(.+)")    *
              on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
            title:
              en: GPU Power
              zh: GPU 功率
            unit: W
          - legend: '{{uuid}}'
            promQLFormat: avg(label_replace(label_replace(enflame_gcu_temperatures{job="gcuExporter",pod_namespace="${namespace}",pod_name=~"${pods}",pod_name!=""},"pod","$1","pod_name","(.+)"),"namespace","$1","pod_namespace","(.+)")    *
              on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
            title:
              en: GPU Temperature
              zh: GPU 温度
            unit: °C
          - legend: '{{uuid}}'
            promQLFormat: avg(label_replace(label_replace(enflame_gcu_usage{job="gcuExporter",pod_namespace="${namespace}",pod_name=~"${pods}",pod_name!=""},"pod","$1","pod_name","(.+)"),"namespace","$1","pod_namespace","(.+)")    *
              on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
            title:
              en: GPU Usage
              zh: GPU 使用率
            unit: '%'
          info:
            attributes:
              count: .metadata.labels.'enflame.com/gcu.count'
              memory:
                key: .metadata.labels.'enflame.com/gcu.memory'
                unit: MiB
              product: .metadata.labels.'enflame.com/gcu.model'
            source: node_yaml
          resource:
            names:
            - enflame.com/gcu
            - enflame-tech.com/gcu
```

### Core

在安装 Core 时，可通过 Helm values.yaml 中的 `global.t9k.k8sResourceServer.gpuCharts.config.enflame` 字段配置 Enflame GCU 的监控设置。启用 Enflame GCU 监控后，普通用户可以在 Job Manager 和 Service Manager 中查看到 Enflame GCU 的资源监控图表。

下面是一个配置示例，配置的字段说明请参考<a target="_blank" rel="noopener noreferrer" href="https://github.com/t9k/admin-manuals/blob/0455c009ae0d91fa7c3aced89ad4c329b2eeb308/src/others/k8s-resource-server.md#%E9%85%8D%E7%BD%AE%E6%A0%BC%E5%BC%8F">管理员文档</a>:

```yaml
global:
  t9k:
    k8sResourceServer:
      gpuCharts:
        config:
          enflame:
            charts:
              memory_used:
                legend: '{{uuid}}'
                promQLFormat: avg(label_replace(label_replace(enflame_gcu_memory_used_bytes{job="gcuExporter",pod_namespace="%s",pod_name=~"%s",pod_name!=""},"pod","$1","pod_name","(.+)"),"namespace","$1","pod_namespace","(.+)")    *
                  on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
                title:
                  en: GPU Memory Used
                  zh: GPU 已用显存
                unit: B
              memory_usage:
                legend: '{{uuid}}'
                promQLFormat: avg(label_replace(label_replace(enflame_gcu_memory_usage{job="gcuExporter",pod_namespace="%s",pod_name=~"%s",pod_name!=""},"pod","$1","pod_name","(.+)"),"namespace","$1","pod_namespace","(.+)")    *
                  on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid) * 100
                title:
                  en: GPU Memory Usage
                  zh: GPU 显存使用率
                unit: '%'
              power_usage:
                legend: '{{uuid}}'
                promQLFormat: avg(label_replace(label_replace(enflame_gcu_power_usage{job="gcuExporter",pod_namespace="%s",pod_name=~"%s",pod_name!=""},"pod","$1","pod_name","(.+)"),"namespace","$1","pod_namespace","(.+)")    *
                  on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
                title:
                  en: GPU Power Usage
                  zh: GPU 功率使用率
                unit: '%'
              power:
                legend: '{{uuid}}'
                promQLFormat: avg(label_replace(label_replace(enflame_gcu_power_consumption{job="gcuExporter",pod_namespace="%s",pod_name=~"%s",pod_name!=""},"pod","$1","pod_name","(.+)"),"namespace","$1","pod_namespace","(.+)")    *
                  on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
                title:
                  en: GPU Power
                  zh: GPU 功率
                unit: W
              temperature:
                legend: '{{uuid}}'
                promQLFormat: avg(label_replace(label_replace(enflame_gcu_temperatures{job="gcuExporter",pod_namespace="%s",pod_name=~"%s",pod_name!=""},"pod","$1","pod_name","(.+)"),"namespace","$1","pod_namespace","(.+)")    *
                  on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
                title:
                  en: GPU Temperature
                  zh: GPU 温度
                unit: °C
              usage:
                legend: '{{uuid}}'
                promQLFormat: avg(label_replace(label_replace(enflame_gcu_usage{job="gcuExporter",pod_namespace="%s",pod_name=~"%s",pod_name!=""},"pod","$1","pod_name","(.+)"),"namespace","$1","pod_namespace","(.+)")    *
                  on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
                title:
                  en: GPU Usage
                  zh: GPU 使用率
                unit: '%'
            resource:
              names:
              - enflame.com/gcu
              - enflame-tech.com/gcu
```

## 参考

[1] <a target="_blank" rel="noopener noreferrer" href="https://support.enflame-tech.com/onlinedoc_dev_3.3/2-install/sw_install/content/source/installation.html#id7 ">TopsRider 软件栈安装手册</a>

[2] <a target="_blank" rel="noopener noreferrer" href="https://support.enflame-tech.com/onlinedoc_dev_topscloud3.3.20/topscloud/gcu_operator_2_0_user_guide/content/source/enflame_gcu_operator_2_0_user_guide.html#id6">GPU Operator 用户使用手册</a>
