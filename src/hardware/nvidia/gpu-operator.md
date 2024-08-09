# 安装 NVIDIA GPU Operator

```
TODO: 1. 支持更多 OS/Kernel 版本组合
```

## 目标

在集群中安装 NVIDIA GPU Operator v24.3.0<sup><a href="#参考">[1]</a></sup>，以支持在集群内使用 NVIDIA GPU。

## 前置条件

节点需要满足以下条件：

1. 已安装 K8s 集群
2. 集群中含有安装了 NVIDIA GPU 硬件的节点

## 兼容性

### GPU Operator v24.3.0

GPU Operator v24.3.0 兼容性<sup><a href="#参考">[2]</a></sup>如下所示：

|Operating System|Kubernetes|Red Hat OpenShift|VMWare vSphere with Tanzu|Rancher Kubernetes Engine2|HPE Ezmeral Runtime Enterprise| Canonical MicroK8s |
|--------------|--------------|--------------|--------------|--------------|--------------| -------------- |
|Ubuntu 20.04 LTS|1.22—1.30| |7.0 U3c, 8.0 U2|1.22—1.30| | |
|Ubuntu 22.04 LTS|1.22—1.30| |8.0 U2|1.22—1.30| |1.26|
|Red Hat Core OS| |4.12—4.15| | | | |
| Red Hat Enterprise Linux 8.4,8.6—8.9|1.22—1.30| | |1.22—1.30| | |
|Red Hat Enterprise Linux 8.4, 8.5| | | | |5.5| |

### 驱动兼容性

GPU Operator v24.3.0 可以通过在节点上部署 GPU 驱动容器来安装 GPU 驱动， 这种方式安装的驱动版本<sup><a href="#参考">[3]</a></sup>有：
1. [550.90.07](https://docs.nvidia.com/datacenter/tesla/tesla-release-notes-550-90-07/index.html) (推荐)
2. [550.54.15](https://docs.nvidia.com/datacenter/tesla/tesla-release-notes-550-54-15/index.html) (默认)
3. [535.183.01](https://docs.nvidia.com/datacenter/tesla/tesla-release-notes-535-183-01/index.html)
4. [470.256.02](https://docs.nvidia.com/datacenter/tesla/tesla-release-notes-470-256-02/index.html)

目前的 GPU 驱动容器兼容下列系统<sup><a href="#参考">[2]</a></sup>：
* Ubuntu 22.04 LTS, 内核版本 5.15
* Ubuntu 20.04 LTS, 内核版本 5.4 和 5.15
如果 GPU 驱动容器无法兼容你的系统，请在节点上<a href="#可选-nvidia-驱动">手动安装 GPU 驱动</a>：

## ansible 脚本安装

### NVIDIA 驱动

使用 ansible 简化 NVIDIA 驱动的安装。

首先进入 inventory 所在的目录：

```bash
cd ~/ansible/$T9K_CLUSTER
```

运行以下命令安装 GPU 驱动：

```bash
ansible-playbook ../ks-clusters/t9k-playbooks/3-install-gpu-driver.yml \
    -i inventory/inventory.ini \
    --become -K \
    -e nvidia_driver_skip_reboot=false \
    --limit node01,node02
```

<aside class="note info">
<div class="title">命令行参数说明</div>

* `-e nvidia_driver_skip_reboot=false` 参数的作用是在安装驱动完成后，重启安装了 GPU 驱动的节点（这也是默认设置）。
* `--limit node01,node02` 参数的作用是限制只在 node01 和 node02 节点上安装 GPU 驱动。

</aside>

这个 Playbook 执行的任务包括[安装 GPU 驱动](#安装)，[关闭 GSP](#关闭-gsp) 和重启节点。

### GPU Operator

使用 ansible 简化 GPU Operator 的安装。

首先进入 inventory 所在的目录：

```bash
cd ~/ansible/$T9K_CLUSTER
```

查看预设的变量：

```bash
cat ../ks-clusters/t9k-playbooks/roles/gpu-operator/defaults/main.yml
```

<aside class="note info">
<div class="title">自定义版本</div>

请参考 <a target="_blank" rel="noopener noreferrer" href="https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/release-notes.html">GPU Operator Release Notes</a> 来设置变量 `nvidia_gpu_operator_version`。你需要确保相应版本的 Helm Chart 存在于 `nvidia_gpu_operator_charts` 中，且相应版本的镜像存在于 `nvidia_gpu_operator_image_registry` 中。

GPU Operator 会用到许多镜像，你可以通过命令行参数指定这些镜像的版本（后面有实际例子）。部分镜像名称中带有操作系统的后缀，常见的有 `ubi8` 和 `ubuntu20.04`。其中 ubi 是 <a target="_blank" rel="noopener noreferrer" href="https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image">Red Hat Universal Base Image</a> 的缩写，ubi8 是 RHEL 8 的基础镜像。我们推荐使用与实际操作系统一致的镜像。

</aside>

通过命令行参数 "-e" 来指定需要修改的变量，运行以下命令安装 GPU Operator：

```bash
ansible-playbook ../ks-clusters/t9k-playbooks/3-install-gpu-operator.yml \
    -i inventory/inventory.ini \
    --become -K \
    -e nvidia_gpu_operator_charts="oci://tsz.io/t9kcharts/gpu-operator"
    -e nvidia_gpu_operator_image_registry="docker.io/t9kpublic" \
    -e nvidia_node_feature_discovery_repo="docker.io/t9kpublic/node-feature-discovery" \
    -e nvidia_gpu_operator_version="v24.3.0" \
    -e nvidia_node_feature_discovery_tag="v0.15.4" \
    -e device_plugin_version="v0.15.0" \
    -e enable_install_gpu_driver=false
```

这个 Playbook 执行的任务包括 [helm template](#helm-template)，[安装 GPU Operator](#安装-1)，以及[配置 Prometheus](#配置-prometheus)。

<aside class="note">
<div class="title">离线安装</div>

修改命令行参数，可以基于本地 Helm Chart 和镜像仓库来安装 GPU Operator：

```bash
ansible-playbook ../ks-clusters/t9k-playbooks/3-install-gpu-operator.yml \
    -i inventory/inventory.ini \
    --become -K \
    -e nvidia_gpu_operator_charts="<path/to/helm-chart>"
    -e nvidia_gpu_operator_image_registry="<registry>" \
    -e nvidia_node_feature_discovery_repo="<registry>/node-feature-discovery"
```
</aside>

## 手动安装

### [可选] NVIDIA 驱动

你可以选择在节点上手动安装 NVIDIA 驱动，然后再安装 GPU Operator。在下面的演示中，安装的驱动版本是 `nvidia-driver-525-server`，你可以根据系统兼容性、GPU 硬件兼容性自行选择驱动版本。

#### 安装

查看节点上 NVIDIA GPU 硬件：

```bash
sudo lshw -C display
```

```console
  *-display                 
       description: VGA compatible controller
       product: GP102 [TITAN X]
       vendor: NVIDIA Corporation
       physical id: 0
       bus info: pci@0000:41:00.0
       version: a1
       width: 64 bits
       clock: 33MHz
       capabilities: pm msi pciexpress vga_controller bus_master cap_list rom
       configuration: driver=nouveau latency=0
       resources: irq:58 memory:ea000000-eaffffff memory:d0000000-dfffffff memory:e0000000-e1ffffff ioport:a000(size=128) memory:c0000-dffff
```

<aside class="note">
<div class="title">注意</div>

如果计划安装 CUDA Toolkit，也可以使用 <a target="_blank" rel="noopener noreferrer" href="https://developer.nvidia.com/cuda-downloads">CUDA Toolkit 的安装包</a>同时完成 NVIDIA 驱动和 CUDA Toolkit 的安装。

</aside>

安装 NVIDIA 驱动：

```bash
sudo apt update
sudo apt list nvidia-driver-*
```

```console
...
nvidia-driver-515-server/focal-updates,focal-security 515.86.01-0ubuntu0.20.04.2 amd64
nvidia-driver-515/focal-updates,focal-security 515.86.01-0ubuntu0.20.04.1 amd64
nvidia-driver-520-open/focal-updates,focal-security 525.60.11-0ubuntu0.20.04.2 amd64
nvidia-driver-520/focal-updates,focal-security 525.60.11-0ubuntu0.20.04.2 amd64
nvidia-driver-525-open/focal-updates,focal-security 525.60.11-0ubuntu0.20.04.2 amd64
nvidia-driver-525-server/focal-updates,focal-security 525.60.13-0ubuntu0.20.04.1 amd64
...
```

```bash
sudo apt install -y nvidia-driver-525-server
sudo apt-hold mark nvidia-driver-525-server
sudo reboot
```

开启 nvidia persistenced mode：

> NVIDIA 驱动安装后，会在集群内添加 system unit `nvidia-persistenced.service`，我们需要修改这个 unit 以启用 persistenced mode。

```bash
sudo systemctl status nvidia-persistenced.service
```

```console
● nvidia-persistenced.service - NVIDIA Persistence Daemon
     Loaded: loaded (/lib/systemd/system/nvidia-persistenced.service; static; vendor preset: enabled)
     Active: active (running) since Wed 2023-08-02 05:11:57 UTC; 1h 33min ago
   Main PID: 2748 (nvidia-persiste)
      Tasks: 1 (limit: 618539)
     Memory: 1.0M
     CGroup: /system.slice/nvidia-persistenced.service
             └─2748 /usr/bin/nvidia-persistenced --user nvidia-persistenced --no-persistence-mode --verbose
```

修改 `nvidia-persistenced.service` 的启动命令，删除 --no-persistence-mode 参数。

```bash
cat /lib/systemd/system/nvidia-persistenced.service
```

修改后的文件内容：

```console
[Unit]
Description=NVIDIA Persistence Daemon
Wants=syslog.target
StopWhenUnneeded=true
Before=systemd-backlight@backlight:nvidia_0.service
[Service]
Type=forking
ExecStart=/usr/bin/nvidia-persistenced --user nvidia-persistenced --verbose
ExecStopPost=/bin/rm -rf /var/run/nvidia-persistenced
```

重启 nvidia-persistenced.service，重启之后运行 nvidia-smi 可以发现已经开启 nvidia persistenced mode：

```bash
sudo systemctl daemon-reload 
sudo systemctl restart nvidia-persistenced.service

nvidia-smi
```

<details><summary><code class="hljs">nvidia-smi output</code></summary>

```console
{{#include ../../assets/online/nvidia-gpu-operator/nvidia-smi.log}}
```

</details>


#### 关闭 GSP

<aside class="note">
<div class="title">注意</div>

510.x.x 及之后的 driver，在 nvidia driver bug 未修复前，还需要 [Disable GSP](#disable-gsp)。

</aside>

#### 验证

Driver 安装后，可使用 nvidia-smi 查看 GPU 信息：

```bash
nvidia-smi -L
```

```console
GPU 0: NVIDIA A100-SXM4-80GB (UUID: GPU-2032b4e2-30cb-f9e6-6a8a-fb0204e5b966)
GPU 1: NVIDIA A100-SXM4-80GB (UUID: GPU-656b12e4-119e-322d-3133-8a9c8e0cce83)
GPU 2: NVIDIA A100-SXM4-80GB (UUID: GPU-2c855dbe-1b55-094c-52e0-7382cfa3ea1e)
GPU 3: NVIDIA A100-SXM4-80GB (UUID: GPU-71761943-ea45-5827-0031-02c86c0c8b43)
GPU 4: NVIDIA A100-SXM4-80GB (UUID: GPU-53ddb134-1b6e-9978-e593-c3c7ff844768)
GPU 5: NVIDIA A100-SXM4-80GB (UUID: GPU-28146b32-c3b4-3184-ceb6-57690d90e386)
GPU 6: NVIDIA A100-SXM4-80GB (UUID: GPU-37809c96-b96e-5889-203a-38c24bde66d0)
GPU 7: NVIDIA A100-SXM4-80GB (UUID: GPU-95977b14-3e55-936e-b275-bb0f5bc60b39)
```

运行 <a target="_blank" rel="noopener noreferrer" href="https://github.com/NVIDIA/cuda-samples/tree/v12.2/Samples/5_Domain_Specific/p2pBandwidthLatencyTest">P2P Bandwidth Latency Test</a> 以进行进一步的测试。

首先安装 <a target="_blank" rel="noopener noreferrer" href="https://developer.nvidia.com/cuda-downloads">CUDA Toolkit</a>。如果你已经安装了 NVIDIA 驱动，建议根据 `nvidia-smi` 的结果选择相同的 CUDA Toolkit 版本，例如 <a target="_blank" rel="noopener noreferrer" href="https://developer.nvidia.com/cuda-12-2-0-download-archive">https://developer.nvidia.com/cuda-12-2-0-download-archive</a>，并且在安装过程中不要再次安装 NVIDIA Driver。根据安装后的提示信息设置适当的环境变量。

验证：

```bash
nvcc --version
```

```console
nvcc: NVIDIA (R) Cuda compiler driver
Copyright (c) 2005-2023 NVIDIA Corporation
Built on Tue_Jun_13_19:16:58_PDT_2023
Cuda compilation tools, release 12.2, V12.2.91
Build cuda_12.2.r12.2/compiler.32965470_0
```

然后下载 <a target="_blank" rel="noopener noreferrer" href="https://github.com/NVIDIA/cuda-samples/tree/master">CUDA Samples</a>，并切换到与 CUDA 版本一致的 tag：

```bash
git clone https://github.com/NVIDIA/cuda-samples.git && cd cuda-samples
git checkout tags/v12.2
```

安装必要的 Packages：

```bash
sudo apt update && sudo apt-get install -y \
    freeglut3-dev \
    build-essential \
    libx11-dev \
    libxmu-dev \
    libxi-dev \
    libgl1-mesa-glx \
    libglu1-mesa \
    libglu1-mesa-dev \
    libglfw3-dev \
    libgles2-mesa-dev
```

编译可执行文件：

```bash
cd Samples/5_Domain_Specific/p2pBandwidthLatencyTest
make
```

运行测试：

```bash
./p2pBandwidthLatencyTest
```

输出结果的示例如下：

```console
[P2P (Peer-to-Peer) GPU Bandwidth Latency Test]
Device: 0, NVIDIA A100-SXM4-80GB, pciBusID: 4f, pciDeviceID: 0, pciDomainID:0
Device: 1, NVIDIA A100-SXM4-80GB, pciBusID: 52, pciDeviceID: 0, pciDomainID:0
Device: 2, NVIDIA A100-SXM4-80GB, pciBusID: 56, pciDeviceID: 0, pciDomainID:0
Device: 3, NVIDIA A100-SXM4-80GB, pciBusID: 57, pciDeviceID: 0, pciDomainID:0
Device: 4, NVIDIA A100-SXM4-80GB, pciBusID: ce, pciDeviceID: 0, pciDomainID:0
Device: 5, NVIDIA A100-SXM4-80GB, pciBusID: d1, pciDeviceID: 0, pciDomainID:0
Device: 6, NVIDIA A100-SXM4-80GB, pciBusID: d5, pciDeviceID: 0, pciDomainID:0
Device: 7, NVIDIA A100-SXM4-80GB, pciBusID: d6, pciDeviceID: 0, pciDomainID:0
Device=0 CAN Access Peer Device=1
Device=0 CAN Access Peer Device=2
Device=0 CAN Access Peer Device=3
Device=0 CAN Access Peer Device=4
Device=0 CAN Access Peer Device=5
Device=0 CAN Access Peer Device=6
Device=0 CAN Access Peer Device=7
Device=1 CAN Access Peer Device=0
Device=1 CAN Access Peer Device=2
Device=1 CAN Access Peer Device=3
Device=1 CAN Access Peer Device=4
Device=1 CAN Access Peer Device=5
Device=1 CAN Access Peer Device=6
Device=1 CAN Access Peer Device=7
Device=2 CAN Access Peer Device=0
Device=2 CAN Access Peer Device=1
Device=2 CAN Access Peer Device=3
Device=2 CAN Access Peer Device=4
Device=2 CAN Access Peer Device=5
Device=2 CAN Access Peer Device=6
Device=2 CAN Access Peer Device=7
Device=3 CAN Access Peer Device=0
Device=3 CAN Access Peer Device=1
Device=3 CAN Access Peer Device=2
Device=3 CAN Access Peer Device=4
Device=3 CAN Access Peer Device=5
Device=3 CAN Access Peer Device=6
Device=3 CAN Access Peer Device=7
Device=4 CAN Access Peer Device=0
Device=4 CAN Access Peer Device=1
Device=4 CAN Access Peer Device=2
Device=4 CAN Access Peer Device=3
Device=4 CAN Access Peer Device=5
Device=4 CAN Access Peer Device=6
Device=4 CAN Access Peer Device=7
Device=5 CAN Access Peer Device=0
Device=5 CAN Access Peer Device=1
Device=5 CAN Access Peer Device=2
Device=5 CAN Access Peer Device=3
Device=5 CAN Access Peer Device=4
Device=5 CAN Access Peer Device=6
Device=5 CAN Access Peer Device=7
Device=6 CAN Access Peer Device=0
Device=6 CAN Access Peer Device=1
Device=6 CAN Access Peer Device=2
Device=6 CAN Access Peer Device=3
Device=6 CAN Access Peer Device=4
Device=6 CAN Access Peer Device=5
Device=6 CAN Access Peer Device=7
Device=7 CAN Access Peer Device=0
Device=7 CAN Access Peer Device=1
Device=7 CAN Access Peer Device=2
Device=7 CAN Access Peer Device=3
Device=7 CAN Access Peer Device=4
Device=7 CAN Access Peer Device=5
Device=7 CAN Access Peer Device=6

***NOTE: In case a device doesn't have P2P access to other one, it falls back to normal memcopy procedure.
So you can see lesser Bandwidth (GB/s) and unstable Latency (us) in those cases.

P2P Connectivity Matrix
     D\D     0     1     2     3     4     5     6     7
     0	     1     1     1     1     1     1     1     1
     1	     1     1     1     1     1     1     1     1
     2	     1     1     1     1     1     1     1     1
     3	     1     1     1     1     1     1     1     1
     4	     1     1     1     1     1     1     1     1
     5	     1     1     1     1     1     1     1     1
     6	     1     1     1     1     1     1     1     1
     7	     1     1     1     1     1     1     1     1
Unidirectional P2P=Disabled Bandwidth Matrix (GB/s)
   D\D     0      1      2      3      4      5      6      7 
     0 1540.93  17.55  18.02  18.12  19.68  21.03  21.01  21.00 
     1  18.17 1539.41  18.01  18.15  19.70  21.02  21.03  21.02 
     2  18.04  18.34 1548.56  18.24  20.26  21.02  20.96  21.00 
     3  18.22  18.38  18.05 1540.93  19.65  19.73  20.96  20.97 
     4  19.77  19.77  19.77  19.74 1386.42  18.14  18.14  18.14 
     5  19.81  19.80  21.01  21.05  18.13 1568.78  18.06  18.12 
     6  19.80  19.77  19.80  20.85  18.15  18.17 1575.10  18.17 
     7  19.68  19.80  19.80  19.76  18.07  18.19  18.17 1579.88 
Unidirectional P2P=Enabled Bandwidth (P2P Writes) Matrix (GB/s)
   D\D     0      1      2      3      4      5      6      7 
     0 1536.38  20.56  24.18  24.18  18.46  18.55  18.60  18.60 
     1  24.18 1550.10  20.56  24.18  18.59  18.59  18.52  18.42 
     2  24.18  24.18 1550.10  20.56  18.60  18.60  18.60  18.60 
     3  24.18  24.18  24.18 1543.97  18.51  18.54  17.32  18.59 
     4  18.57  18.60  18.58  18.60 1393.84  20.56  24.18  25.01 
     5  18.60  18.58  18.59  18.60  24.53 1587.91  20.56  25.21 
     6  18.59  18.60  18.60  18.60  25.22  25.22 1586.29  20.56 
     7  18.54  18.48  18.34  18.55  24.18  24.18  25.15 1587.91 
Bidirectional P2P=Disabled Bandwidth Matrix (GB/s)
   D\D     0      1      2      3      4      5      6      7 
     0 1560.16  19.96  20.23  20.07  29.62  29.64  29.64  29.68 
     1  20.04 1563.28  20.20  20.26  29.74  29.64  29.66  29.67 
     2  20.28  20.31 1602.56  20.25  28.36  28.36  29.60  29.66 
     3  20.16  20.09  20.11 1564.06  28.32  28.34  28.33  28.34 
     4  28.47  28.43  28.45  28.42 1414.03  20.08  20.05  20.05 
     5  27.56  28.46  29.14  29.64  19.93 1601.74  20.11  20.02 
     6  27.52  28.41  29.59  29.58  20.09  20.12 1605.86  20.04 
     7  27.53  27.44  28.12  28.30  20.07  20.12  20.12 1606.68 
Bidirectional P2P=Enabled Bandwidth Matrix (GB/s)
   D\D     0      1      2      3      4      5      6      7 
     0 1562.50  41.11  41.11  41.11  37.19  36.79  37.16  37.14 
     1  41.10 1563.28  41.10  41.10  37.15  37.19  37.18  37.12 
     2  41.11  41.10 1564.06  41.11  37.19  37.18  37.14  37.17 
     3  41.10  41.11  41.11 1560.16  37.16  37.17  36.99  37.18 
     4  37.19  37.18  37.19  37.18 1444.75  50.43  50.41  50.26 
     5  37.17  37.15  37.19  37.19  50.40 1595.20  50.43  50.41 
     6  37.16  37.19  37.17  37.19  50.42  50.40 1602.56  41.12 
     7  37.17  37.17  37.18  37.00  50.12  50.42  50.42 1596.83 
P2P=Disabled Latency Matrix (us)
   GPU     0      1      2      3      4      5      6      7 
     0   2.84  20.50  20.47  20.54  21.28  21.49  21.29  20.48 
     1  20.37   2.48  20.54  20.54  21.44  12.71  13.13  21.43 
     2  20.49  17.73   2.33  20.53  20.18  13.08  17.06  15.57 
     3  19.78  20.31  20.47   2.37  20.04  14.41  21.45  21.38 
     4  21.25  21.38  18.55  21.44   2.43  15.51  15.46  17.60 
     5  21.15  12.89  17.77  16.36  18.93   2.29  12.54  19.32 
     6  21.48  14.99  17.08  21.06  17.89  14.23   2.25  18.75 
     7  21.48  21.01  19.98  21.47  20.09  14.09  17.62   2.51 

   CPU     0      1      2      3      4      5      6      7 
     0   2.38   5.89   5.65   5.55   5.96   5.93   5.89   5.73 
     1   5.73   2.24   5.43   5.30   5.69   5.78   5.75   5.65 
     2   5.41   5.32   2.24   5.28   5.64   5.66   5.69   5.58 
     3   5.40   5.29   5.22   2.24   5.68   5.72   5.75   5.57 
     4   5.66   5.49   5.48   5.43   2.36   5.86   5.97   5.89 
     5   5.60   5.49   5.46   5.41   5.77   2.34   5.94   5.79 
     6   5.59   5.50   5.48   5.44   5.82   5.89   2.33   5.84 
     7   5.53   5.45   5.39   5.37   5.77   5.83   5.92   2.31 
P2P=Enabled Latency (P2P Writes) Matrix (us)
   GPU     0      1      2      3      4      5      6      7 
     0   2.85   1.99   1.96   1.99   2.48   2.49   2.48   2.49 
     1   1.74   2.51   1.69   1.67   2.25   2.25   2.23   2.25 
     2   1.79   1.78   2.32   1.79   2.25   2.25   2.31   2.25 
     3   1.78   1.79   1.84   2.38   2.25   2.24   2.24   2.25 
     4   2.30   2.25   2.30   2.26   2.43   1.70   1.70   1.68 
     5   2.26   2.26   2.25   2.25   1.70   2.29   1.70   1.70 
     6   2.27   2.25   2.27   2.26   1.70   1.73   2.24   1.73 
     7   2.27   2.27   2.25   2.30   1.72   1.76   1.72   2.49 

   CPU     0      1      2      3      4      5      6      7 
     0   2.26   1.59   1.63   1.60   1.62   1.60   1.63   1.56 
     1   1.74   2.30   1.65   1.66   1.68   1.69   1.65   1.63 
     2   1.76   1.68   2.34   1.67   1.69   1.64   1.59   1.59 
     3   1.68   1.63   1.65   2.30   1.67   1.64   1.69   1.66 
     4   1.88   1.76   1.79   1.77   2.39   1.75   1.76   1.77 
     5   1.91   1.80   1.80   1.80   1.77   2.38   1.71   1.72 
     6   1.84   1.75   1.76   1.83   1.81   1.79   2.40   1.75 
     7   1.92   1.79   1.79   1.77   1.76   1.79   1.78   2.44 

NOTE: The CUDA Samples are not meant for performance measurements. Results may vary when GPU Boost is enabled.
```

#### 其他

```bash
# 检查安装状态
dpkg -l nvidia-driver-525-server
```

```
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name                     Version                     Architecture Description
+++-========================-===========================-============-=================================
hi  nvidia-driver-525-server 525.125.06-0ubuntu0.20.04.2 amd64        NVIDIA Server Driver metapackage
```

### GPU Operator

#### 安装

运行下列命令即可通过 Helm Chart 安装 GPU Operator

```bash
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia 
helm repo update
helm install --wait --generate-name \
    --version v24.3.0 \
    -n gpu-operator --create-namespace \
    nvidia/gpu-operator
```

<aside class="note">
<div class="title">注意</div>

GPU Operator 安装的组件使用的镜像无法从国内直接访问，如果你的集群节点无法访问外网，请参考<a href="#集群节点无法访问外网
">附录->集群节点无法访问外网</a>，将这些镜像拷贝到国内容器镜像服务中，然后再安装 GPU Operator

</aside>

#### 验证

GPU Operator 安装完成后，运行下列命令查看安装的组件：
```bash
$ kubectl -n gpu-operator get deploy
NAME                                         READY   UP-TO-DATE   AVAILABLE   AGE
gpu-operator                                 1/1     1            1           37d
release-name-node-feature-discovery-gc       1/1     1            1           37d
release-name-node-feature-discovery-master   1/1     1            1           37d
$ kubectl -n gpu-operator get ds
NAME                                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                                          AGE
gpu-feature-discovery                        2         2         2       2            2           nvidia.com/gpu.deploy.gpu-feature-discovery=true                       37d
nvidia-container-toolkit-daemonset           2         2         2       2            2           nvidia.com/gpu.deploy.container-toolkit=true                           37d
nvidia-dcgm-exporter                         2         2         2       2            2           nvidia.com/gpu.deploy.dcgm-exporter=true                               37d
nvidia-device-plugin-daemonset               2         2         2       2            2           nvidia.com/gpu.deploy.device-plugin=true                               37d
nvidia-driver-daemonset                      0         0         0       0            0           nvidia.com/gpu.deploy.driver=true                                      37d
nvidia-mig-manager                           1         1         1       1            1           nvidia.com/gpu.deploy.mig-manager=true                                 37d
nvidia-operator-validator                    2         2         2       2            2           nvidia.com/gpu.deploy.operator-validator=true                          37d
release-name-node-feature-discovery-worker   10        10        10      10           10          <none>                                                                 37d
```

查看 GPU Operator 的配置<sup><a href="#参考">[4]</a></sup>：

```bash
$ kubectl -n gpu-operator get clusterpolicy cluster-policy  
NAME             STATUS   AGE
cluster-policy   ready    2024-05-21T07:00:15Z
```

#### 组件

GPU Operator 会在集群内安装的多个组件<sup><a href="#参考">[3]</a></sup>，下面对一些重要的组件进行说明。

##### 全局组件

Deployment gpu-operator：
* GPU Operator 的运行主体，他会在集群中部署与 NVIDIA GPU 相关的组件。
* 如何确认正常工作？Pod 运行正常，并且 NVIDIA GPU 相关的组件已经被部署在集群中。

node-feature-discovery（master & worker）：
* GPU Operator 依赖的第三方组件。运行在所有节点上，检测集群节点的硬件信息、系统信息，并将这些信息记录在节点标签上，这些标签前缀是 feature.node.kubernetes.io/。GPU Operator 依赖 node feature discovery 添加的节点标签。
* 如何确认正常工作？Pod 运行正常，并且可以在节点上查看到相关的节点标签。

##### NVIDIA GPU 节点

下面的组件只能运行在含有 NVIDIA GPU 的节点上

[gpu-feature-discovery](https://github.com/NVIDIA/gpu-feature-discovery)：
* 根据节点上的 GPU 信息来生成节点标签，标签前缀是 nvidia.com/
* 如何确认正常工作？Pod 运行正常，并且可以在节点上查看到相关的节点标签。

[nvidia-container-toolkit](https://github.com/NVIDIA/nvidia-container-toolkit):  
* 运行在含有 NVIDIA GPU 的节点上，在节点上安装 nvidia container toolkit
* 如何确认正常工作？Pod 运行正常，并且可以在节点主机上查看到安装的 nvidia container toolkit

[nvidia-dcgm-exporter](https://github.com/NVIDIA/dcgm-exporter)：
* 在节点上安装 dcgm-exporter，将 GPU 的监控数据以 [Prometheus](https://prometheus.io/) metrics 形式暴露出来。
* 如何确认正常工作？Pod 运行正常，并且可以通过 Pod 上 dcgm exporter 服务查询 GPU metrics。

[nvidia-device-plugin](https://github.com/NVIDIA/k8s-device-plugin)：
* 将 NVIDIA GPU 注册为 K8s 扩展资源。
* 如何确认正常工作？Pod 运行正常，可以在含有 GPU 的节点上查看到 NVIDIA GPU 扩展资源。
```bash
$ kubectl get node z02 -o json | jq .status.capacity
{
  "cpu": "32",
  "ephemeral-storage": "59643812Ki",
  "hugepages-1Gi": "0",
  "hugepages-2Mi": "0",
  "memory": "131942876Ki",
  "nvidia.com/gpu": "1",
  "pods": "110",
  "tensorstack.dev/test": "100"
}
```

nvidia-driver-daemonset
* nvidia-driver-daemonset 只会运行在没有安装 GPU 驱动的节点上，作用是为节点安装 GPU 驱动容器。nvidia-driver-daemonset 中运行了下列两个组件：
  * [k8s-driver-manager](https://github.com/NVIDIA/k8s-driver-manager)：为 GPU Driver Container 的安装做准备工作。
  * [GPU Driver Container](https://github.com/NVIDIA/gpu-driver-container)：通过容器提供 NVIDIA GPU 驱动。
* 如何确认正常工作？GPU 驱动容器可以正常运行在未安装 GPU 驱动的节点上。

[nvidia-mig-manager](https://github.com/NVIDIA/mig-parted)
* 只会运行在 GPU 支持 [MIG](https://docs.nvidia.com/datacenter/tesla/mig-user-guide/index.html) 模式的节点上，作用是支持以 MIG 形式共享 GPU。具体地，当节点启用 MIG GPU 共享模式时，nvidia-mig-manager 会根据配置将一个 MIG GPU 划分为多个 [MIG GPU 实例](https://docs.nvidia.com/datacenter/tesla/mig-user-guide/index.html#concepts:~:text=A%20GPU%20Instance,number%20of%20SMs.)。
* 如何确认正常工作？Pod 运行正常

[nvidia-operator-validator](https://github.com/NVIDIA/gpu-operator/tree/v24.3.0/validator)
* 验证 GPU Operator 的多个组件是否正常工作。
* 如何确认正常工作？Pod 运行正常，Pod 日志显示 all validations are successful。


## 安装后配置

### 设置 time-slicing

GPU Operator 安装完成后，可以通过以下设置，让 GPU 以 [time-slicing 方式](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/gpu-sharing.html#configuration-for-shared-access-to-gpus-with-gpu-time-slicing)被共享使用。

#### GPU Operator 配置

首先需要配置 GPU Operator 启用 time-slicing。

创建 `config.yaml` 文件来定义 time-slicing config。

<details><summary><code class="hljs">config.yaml</code></summary>

```yaml
{{#include ../../assets/online/nvidia-gpu-operator/config.yaml}}
```

</details>

在本示例中，ConfigMap 定义了 2 个 time-slicing config（config 设置[参考](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/gpu-sharing.html#configuration-for-shared-access-to-gpus-with-gpu-time-slicing)）：`a100-40gb` 和 `common`。



创建 ConfigMap time-slicing-config：

```bash
kubectl create -f config.yaml
```

然后修改 GPU Operator 配置：

```bash
kubectl patch clusterpolicy/cluster-policy \
  -n gpu-operator --type merge \
  -p '{"spec": {"devicePlugin": {"config": {"name": "time-slicing-config"}}}}'
```

#### 节点设置 time-slicing

GPU Operator 启用 time-slicing 后，你可以在 GPU 节点上添加标签 `nvidia.com/device-plugin.config=<config-name>` 来表明想要将这个节点上的 GPU 以共享形式提供给 K8s Pod 使用，<config-name> 表明节点使用的 time-slicing config，对应 ConfigMap time-slicing-config 中定义的 time-slicing config 的名称（a100-40gb 或 common）。

例如：

```bash
kubectl label node z02 nvidia.com/device-plugin.config=common
```

z02 上只有一个物理 GPU，在节点上设置了 time-slicing config common 后，你可以看见 4 个 K8s GPU extended-resources:

```bash
$ kubectl get node z02 -o json | jq .status.capacity
{
  …
  "nvidia.com/gpu.shared": "4",
  …
}
```

#### (optional) 设置 T9k Scheduler Queue

设置了共享 GPU 的节点后，你可以创建 T9k Scheduler Queue `shared-gpu`，让 Queue 中的 Pod 只运行在共享 GPU 节点上。如果你想要创建使用共享 GPU 的 Pod，你只需要在 Pod 中设置扩展资源 `nvidia.com/gpu.shared`，并设置 Pod 使用 `t9k-scheduler`，同时指定 Pod Queue 为 `shared-gpu` 即可。

Queue 的 YAML 示例如下：

```yaml
apiVersion: scheduler.tensorstack.dev/v1beta1
kind: Queue
metadata:
 name: shared-gpu
 namespace: t9k-system
spec:
 closed: false
 nodeSelector:
   matchExpressions:
   - key: nvidia.com/device-plugin.config
     operator: Exists
 preemptible: false
 priority: 80
 quota:
   requests:
     cpu: "400"
     memory: 800Gi
     nvidia.com/gpu.shared: "12"
```

### 节点禁用 GPU Operator

如果不想让 GPU Operator 运行在某个节点上，可运行下列命令：

```bash
kubectl label nodes $NODE nvidia.com/gpu.deploy.operands=false
```

参考：<https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/getting-started.html#operands>

### 配置 Prometheus

GPU Operator 默认会在集群内部署 dcgm exporter，你需要创建 CRD `ServiceMonitor ` 示例来配置 Prometheus 收集 dcgm exporter 提供的 metrics 数据。

nvidia dcgm exporter 的 service 如下所示：

```bash
kubectl -n gpu-operator get svc nvidia-dcgm-exporter  -o yaml
```

<details><summary><code class="hljs">svc-nvidia-dcgm-exporter.yaml</code></summary>

```yaml
{{#include ../../assets/online/nvidia-gpu-operator/svc-nvidia-dcgm-exporter.yaml}}
```

</details>

创建 ServiceMonitor ：

```bash
kubectl -n t9k-monitoring create -f - << EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  labels:
    tensorstack.dev/default-config: "true"
    tensorstack.dev/metrics-collected-by: t9k-monitoring
  name: nvidia-dcgm-exporter
  namespace: t9k-monitoring
spec:
  endpoints:
  - interval: 30s
    port: gpu-metrics
  jobLabel: app
  namespaceSelector:
    matchNames:
    - gpu-operator
  selector:
    matchLabels:
      app: nvidia-dcgm-exporter
EOF
```

## 附录

### Disable GSP

在 NVIDIA Driver 510.x.x 版本之后，会有一个 Bug。当 Driver 产生 "Timeout waiting for RPC from GSP!" 错误时，通过 Disable GSP 可能解决这个错误。

#### 什么是 GSP？

> Some GPUs include a GPU System Processor (GSP) which can be used to offload GPU initialization and management tasks. This processor is driven by the firmware file `/lib/firmware/nvidia/510.39.01/gsp.bin`. A few select products currently use GSP by default, and more products will take advantage of GSP in future driver releases.
> Offloading tasks which were traditionally performed by the driver on the CPU can improve performance due to lower latency access to GPU hardware internals.

#### Why disable GSP

从 510 版本开始，NVIDIA Driver 引入了 GSP Feature，但是他有 Bug。这个 Bug 可能会导致在使用/查询 GPU 时产生错误："Timeout waiting for RPC from GSP!"（详情：<https://github.com/NVIDIA/open-gpu-kernel-modules/issues/446>）。

关闭 GSP 可以解决上述 Bug。

#### How to disable GSP

命令如下：

```bash
sudo su -c 'echo options nvidia NVreg_EnableGpuFirmware=0 > /etc/modprobe.d/nvidia-gsp.conf'
sudo update-initramfs -u
sudo reboot
```

检查：

```bash
# EnableGpuFirmware is 0 means GSP feature is disabled
cat /proc/driver/nvidia/params | grep EnableGpuFirmware
```

```
EnableGpuFirmware: 0
EnableGpuFirmwareLogs: 2
```

### 集群节点无法访问外网

当你的集群节点无法下载外网的镜像时，你可以参考下面的示例，先将镜像拷贝到国内的容器镜像服务中，然后再安装 gpu operator。下面的示例使用的国内镜像仓库是 tsz.io，请将其替换为你的镜像仓库。

将下列的镜像列表放入文件 `image.mirror.txt` 中，每一行 # 前面是 GPU Operator 使用的镜像名称，# 后面是你想要复制的容器镜像名称：
```text
registry.k8s.io/nfd/node-feature-discovery:v0.15.4#tsz.io/t9kmirror/node-feature-discovery:v0.15.4
nvcr.io/nvidia/gpu-operator:v24.3.0#tsz.io/t9kmirror/gpu-operator:v24.3.0
nvcr.io/nvidia/cuda:12.4.1-base-ubi8#tsz.io/t9kmirror/cuda:12.4.1-base-ubi8
nvcr.io/nvidia/cloud-native/gpu-operator-validator:v24.3.0#tsz.io/t9kmirror/cloud-native/gpu-operator-validator:v24.3.0
nvcr.io/nvidia/driver:550.54.15-ubuntu20.04#tsz.io/t9kmirror/driver:550.54.15-ubuntu20.04
nvcr.io/nvidia/driver:550.54.15-ubuntu22.04#tsz.io/t9kmirror/driver:550.54.15-ubuntu22.04
nvcr.io/nvidia/cloud-native/k8s-driver-manager:v0.6.8#tsz.io/t9kmirror/cloud-native/k8s-driver-manager:v0.6.8
nvcr.io/nvidia/cloud-native/k8s-kata-manager:v0.2.0#tsz.io/t9kmirror/cloud-native/k8s-kata-manager:v0.2.0
nvcr.io/nvidia/cloud-native/vgpu-device-manager:v0.2.6#tsz.io/t9kmirror/cloud-native/vgpu-device-manager:v0.2.6
nvcr.io/nvidia/cloud-native/k8s-cc-manager:v0.1.1#tsz.io/t9kmirror/cloud-native/k8s-cc-manager:v0.1.1
nvcr.io/nvidia/k8s/container-toolkit:v1.15.0-ubuntu20.04#tsz.io/t9kmirror/k8s/container-toolkit:v1.15.0-ubuntu20.04
nvcr.io/nvidia/k8s-device-plugin:v0.15.0#tsz.io/t9kmirror/k8s-device-plugin:v0.15.0
nvcr.io/nvidia/cloud-native/dcgm:3.3.5-1-ubuntu22.04#tsz.io/t9kmirror/cloud-native/dcgm:3.3.5-1-ubuntu22.04
nvcr.io/nvidia/k8s/dcgm-exporter:3.3.5-3.4.1-ubuntu22.04#tsz.io/t9kmirror/k8s/dcgm-exporter:3.3.5-3.4.1-ubuntu22.04
nvcr.io/nvidia/cloud-native/k8s-mig-manager:v0.7.0-ubuntu20.04#tsz.io/t9kmirror/cloud-native/k8s-mig-manager:v0.7.0-ubuntu20.04
nvcr.io/nvidia/kubevirt-gpu-device-plugin:v1.2.7#tsz.io/t9kmirror/kubevirt-gpu-device-plugin:v1.2.7
```

然后运行下列脚本完成镜像拷贝
```bash
#!/bin/bash

# Specify the file to read
file="image.mirror.txt"

# Check if the file exists
if [[ -f "$file" ]]; then
   # Read the file line by line
   while IFS= read -r line
   do
       # Print each line
       oldImage="${line%%#*}"
       newImage="${line##*#}"
       docker pull $oldImage
       docker tag $oldImage $newImage
       docker push $newImage
   done < "$file"
else
   echo "$file not found."
fi
```

最后运行下列命令安装 GPU Operator：
```bash
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia 
helm repo update
helm install --wait --generate-name \
    --version v24.3.0 \
    -n gpu-operator --create-namespace \
 --set "node-feature-discovery.image.repository=tsz.io/t9kmirror/node-feature-discovery","node-feature-discovery.image.tag=v0.15.4" \
 --set "validator.repository=tsz.io/t9kmirror/cloud-native" \
 --set "operator.repository=tsz.io/t9kmirror" \
 --set "driver.repository=tsz.io/t9kmirror" \
 --set "driver.manager.repository=tsz.io/t9kmirror/cloud-native" \
 --set "toolkit.repository=tsz.io/t9kmirror/k8s" \
 --set "devicePlugin.repository=tsz.io/t9kmirror","devicePlugin.version=v0.15.0" \
 --set "dcgm.repository=tsz.io/t9kmirror/cloud-native" \
 --set "dcgmExporter.repository=tsz.io/t9kmirror/k8s" \
 --set "gfd.repository=tsz.io/t9kmirror" \
 --set "migManager.repository=tsz.io/t9kmirror/cloud-native" \
 --set "nodeStatusExporter.repository=tsz.io/t9kmirror/cloud-native" \
 --set "gds.repository=tsz.io/t9kmirror/cloud-native" \
 --set "vgpuManager.driverManager.repository=tsz.io/t9kmirror/cloud-native" \
 --set "vgpuDeviceManager.repository=tsz.io/t9kmirror/cloud-native" \
 --set "vfioManager.repository=tsz.io/t9kmirror" \
 --set "vfioManager.driverManager.repository=tsz.io/t9kmirror/cloud-native" \
 --set "kataManager.repository=tsz.io/t9kmirror/cloud-native" \
 --set "sandboxDevicePlugin.repository=tsz.io/t9kmirror" \
 --set "ccManager.repository=tsz.io/t9kmirror/cloud-native" \
    nvidia/gpu-operator
```

### 安装 GPU Operator 其他版本

如果你想安装其他版本的 GPU Operator，运行 helm install 命令时，添加命令行参数 --version 来指定你想要安装的版本。

```bash
helm install --wait --generate-name \
    --version <version>\
    -n gpu-operator --create-namespace \
    nvidia/gpu-operator
```

### 升级 GPU Operator

参考 NVIDIA GPU Operator [官方文档](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/upgrade.html#option-1-manually-upgrading-crds)

<aside class="note">
<div class="title">注意</div>

更新可能会导致正在使用 GPU 的工作负载出错。

</aside>

### 修改组件版本

你可以通过 ClusterPolicy 来修改 GPU Operator 组件的版本，但请先确保组件版本与 GPU Operator 版本兼容。

下面是修改 Device Plugin 版本的示例：
首先运行下列命令查看当前的 Device Plugin 版本
```bash
$ k get clusterpolicy cluster-policy  -o yaml
spec:
  devicePlugin:
    image: k8s-device-plugin
    imagePullPolicy: IfNotPresent
    repository: tsz.io/t9kmirror
    version: v0.15.0
```
然后使用 `kubectl edit clusterpolicy cluster-policy` 来修改 `spec.devicePlugin.version` 字段。

## 参考

* [NVIDIA GPU Operator/v24.3.0 Github](https://github.com/NVIDIA/gpu-operator/tree/v24.3.0)
* [GPU Operator 兼容平台](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/platform-support.html#supported-operating-systems-and-kubernetes-platforms)
* [GPU Operator Component Matrix](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/platform-support.html#gpu-operator-component-matrix)
* [ClusterPolicy 定义](https://github.com/NVIDIA/gpu-operator/blob/v24.3.0/api/v1/clusterpolicy_types.go#L1669)
