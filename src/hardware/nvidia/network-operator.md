# 安装 NVIDIA Network Operator

```
TODO:
    1. GPU operator 的 version 当提供灵活性。
```

## 前提条件

硬件：

1. 节点上安装了支持 RDMA 的硬件设备，并正确连接了网线。
2. 节点上的 GPU 支持 GPUDirect 功能。

软件：

1. 节点加载了 kernel module `nvidia_peermem`。
2. 节点已经加入到 K8s 集群中。
3. 安装了 [GPU Operator v22.9.2](./gpu-operator.md)。
4. 安装了 Node Feature Discovery v0.10.1（安装 GPU Operator 时启用了该功能）。

### 验证

下面提供部分前提条件的验证方式。

节点上安装了支持 RDMA 的硬件设备，这里以 InfiniBand 为例：

``` bash
lspci -nn | grep -i infini
```

```
98:00.0 Infiniband controller [0207]: Mellanox Technologies MT28908 Family [ConnectX-6] [15b3:101b]
```
需要注意这里的 `[15b3:101b]`，他们分别代表设备供应商代码和设备 ID。

节点正确连接了 IB 网线，例如：
``` bash
ip a | grep -i ib
```

```
5: ibs102: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 2044 qdisc mq state UP group default qlen 256
    link/infiniband 00:00:0d:86:fe:80:00:00:00:00:00:00:e8:eb:d3:03:00:a6:19:aa brd 00:ff:ff:ff:ff:12:40:1b:ff:ff:00:00:00:00:00:00:ff:ff:ff:ff
    inet 10.20.65.13/24 brd 10.20.65.255 scope global ibs102
```
这里的状态可以是 UP 或者 DOWN，但不能有 NO-CARRIER。

节点启用了 kernel module `nvidia_peermem`：

``` bash
lsmod | grep nvidia_peermem
```

参考输出：

```
nvidia_peermem         16384  0
ib_core               348160  9 rdma_cm,ib_ipoib,nvidia_peermem,iw_cm,ib_umad,rdma_ucm,ib_uverbs,mlx5_ib,ib_cm
nvidia              56344576  492 nvidia_uvm,nvidia_peermem,nvidia_modeset
```

 如果未启动，可手动启用：

```
sudo modprobe nvidia_peermem
```

通过供应商代码 (15b3) 查看含有 Mellanox Infinity Band NIC 的节点：

``` bash
kubectl get nodes  -l feature.node.kubernetes.io/pci-15b3.present
```

```
NAME    STATUS    ROLES                          AGE    VERSION
a101    Ready     compute                        16d    v1.24.10
a102    Ready     compute                        16d    v1.24.10
a31     Ready     compute                        45d    v1.24.10
a41     Ready     compute,ingress                92d    v1.24.10
a42     Ready     compute                        177d   v1.24.10
a43     Ready     compute                        177d   v1.24.10
a44     Ready     compute                        16d    v1.24.10
a45     Ready     compute                        7d3h   v1.24.10
login   Ready     control-plane,ingress,master   178d   v1.24.10
```

查看含有 NVIDIA GPU (供应商代码 10de) 的节点：

``` bash
kubectl get nodes  -l feature.node.kubernetes.io/pci-10de.present
```

```
NAME    STATUS    ROLES             AGE    VERSION
a101    Ready     compute           16d    v1.24.10
a102    Ready     compute           16d    v1.24.10
a31     Ready     compute           45d    v1.24.10
a41     Ready     compute,ingress   92d    v1.24.10
a42     Ready     compute           177d   v1.24.10
a43     Ready     compute           177d   v1.24.10
a44     Ready     compute           16d    v1.24.10
a45     Ready     compute           7d3h   v1.24.10
```

确认节点上安装了 GPU Operator v22.9.2，并确认 NFD （GPU Operator 部署的）可以正常运行：

``` bash
kubectl -n gpu-operator get ds
```

```
NAME                                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                      AGE
gpu-feature-discovery                        10        10        10      10           10          nvidia.com/gpu.deploy.gpu-feature-discovery=true   173d
nvidia-container-toolkit-daemonset           10        10        10      10           10          nvidia.com/gpu.deploy.container-toolkit=true       173d
nvidia-dcgm-exporter                         10        10        10      10           10          nvidia.com/gpu.deploy.dcgm-exporter=true           173d
nvidia-device-plugin-daemonset               10        10        10      10           10          nvidia.com/gpu.deploy.device-plugin=true           173d
nvidia-mig-manager                           5         5         5       5            5           nvidia.com/gpu.deploy.mig-manager=true             173d
nvidia-operator-validator                    10        10        10      10           10          nvidia.com/gpu.deploy.operator-validator=true      173d
release-name-node-feature-discovery-worker   11        11        11      11           11          <none>                                             173d
```

```bash
k -n gpu-operator get ds nvidia-operator-validator  -o yaml | grep image:
```

```
                f:image: {}
                f:image: {}
                f:image: {}
                f:image: {}
                f:image: {}
        image: nvcr.io/nvidia/cloud-native/gpu-operator-validator:v22.9.2
        image: nvcr.io/nvidia/cloud-native/gpu-operator-validator:v22.9.2
        image: nvcr.io/nvidia/cloud-native/gpu-operator-validator:v22.9.2
        image: nvcr.io/nvidia/cloud-native/gpu-operator-validator:v22.9.2
        image: nvcr.io/nvidia/cloud-native/gpu-operator-validator:v22.9.2
```

## 安装

### MLNX_OFED 驱动

```bash
# 进入为此次安装准备的 inventory 目录
cd ~/ansible/$T9K_CLUSTER
```

根据以下格式设置 group `ib_node`，将需要安装 IB 驱动的节点都添加到这个 group 中。

``` YAML
## install ib driver on ib_node
[ib_node]
a31 ansible_host=x.x.x.x
a41 ansible_host=x.x.x.x
a42 ansible_host=x.x.x.x
```

运行脚本安装驱动：

```bash
ansible-playbook ../ks-clusters/t9k-playbooks/4-install-ib-driver.yml \
  -i inventory/inventory.ini \
  --become \
  -e "@~/ansible/$T9K_CLUSTER/vault.yml" \
  --vault-password-file=~/ansible/.vault-password.txt
```

<aside class="note warning">
<div class="title">注意</div>

本脚本暂不支持离线安装，可以参考 [附录：手动安装 MLNX_OFED 驱动](../../appendix/manually-install-mlnx-ofed-driver.md) 来手动安装 MLNX_OFED 驱动。

</aside>

安装后，查看 OFED driver 信息的命令：

``` bash
ofed_info -s
```

```
MLNX_OFED_LINUX-5.9-0.5.6.0:
```

查看节点上的设备信息：

```bash
ls /dev/infiniband
```

```
issm0  rdma_cm  umad0  uverbs0
```


### Network Operator

运行脚本在 K8s 集群中创建 Network Operator， 选择一种方式：

```bash
# 1. 通常的在线安装方式
ansible-playbook ks-clusters/t9k-playbooks/4-install-network-operator.yml \
  -i inventory/inventory.ini \
  --become \
  -e "@~/ansible/$T9K_CLUSTER/vault.yml" \
  --vault-password-file=~/ansible/.vault-password.txt \
  -e rdma_shared_device_name=rdma_shared_device_a \
  -e rdma_shared_device_vendor=15b3 \
  -e rdma_shared_device_id=101b,101d \
  -e network_operator_version="23.10.0"

# 2. 不使用 ansible vault，而是交互式输入 become password
ansible-playbook ks-clusters/t9k-playbooks/4-install-network-operator.yml \
  -i inventory/inventory.ini \
  --become --ask-become-pass
  -e rdma_shared_device_name=rdma_shared_device_a \
  -e rdma_shared_device_vendor=15b3 \
  -e rdma_shared_device_id=101b \
  -e network_operator_version="23.10.0"

# 3. 离线安装时，需要根据实际情况
# 设置 network_operator_charts 参数和 network_operator_image_registry 参数
ansible-playbook ks-clusters/t9k-playbooks/4-install-network-operator.yml \
  -i inventory/inventory.ini \
  --become \
  -e "@~/ansible/$T9K_CLUSTER/vault.yml" \
  --vault-password-file=~/ansible/.vault-password.txt \
  -e network_operator_charts=../ks-clusters/tools/offline-additionals/charts/network-operator-23.10.0.tgz \
  -e network_operator_image_registry=192.168.101.159:5000/t9kpublic

```

<aside class="note info">
<div class="title">参数说明</div>

命令行中设置的 vars：

* `rdma_shared_device_name`: Network Operator 在集群中注册的扩展资源的名称，通常不需要修改。
* `rdma_shared_device_vendor`: 设备供应商代码，可以通过 `lspci -nn | grep -i infini` 命令获得。
* `rdma_shared_device_id`: 设备 ID，可以通过 `lspci -nn | grep -i infini` 命令获得。如果集群中的节点中有不同的设备 ID，需要将所有的设备 ID 都添加到设置中（逗号分隔），例如：`rdma_shared_device_id=101b,101c,101d`
* `network_operator_version`: 安装的 Network Operator 版本。
* `network_operator_charts`: 安装 Network Operator 时使用的 Helm Chart 来源。在离线安装时必须设置。
* `network_operator_image_registry`: 安装 Network Operator 时使用的镜像仓库。在离线安装时必须设置。

</aside>

安装完成后，通过下述命令查看安装的产品组件：

``` bash
kubectl -n network-operator get pods -o wide
```

通过下述命令查看 Network Operator 配置：

``` bash
kubectl get  NicClusterPolicy  nic-cluster-policy -o yaml
```


## 验证

### RDMA

运行下列命令来创建两个 Pod rdma-test-pod-1 和 rdma-test-pod-2，通过 nodeSelector 来保证他们运行在两个不同的含有 IB NIC 的节点上（需要将 a31 和 a42 替换为你的集群节点）：

``` bash
kubectl create -f - << EOF
apiVersion: v1
kind: Pod
metadata:
  name: rdma-test-pod-1
spec:
  nodeSelector:
    # Note: Replace hostname or remove selector altogether
    kubernetes.io/hostname: a31
  restartPolicy: OnFailure
  containers:
  - image: mellanox/rping-test
    name: rdma-test-ctr
    securityContext:
      capabilities:
        add: [ "IPC_LOCK" ]
    resources:
      limits:
        rdma/rdma_shared_device_a: 1
    command:
    - sh
    - -c
    - |
      sleep infinity
EOF
```

``` bash
kubectl create -f - << EOF
apiVersion: v1
kind: Pod
metadata:
  name: rdma-test-pod-2
spec:
  nodeSelector:
    # Note: Replace hostname or remove selector altogether
    kubernetes.io/hostname: a42
  restartPolicy: OnFailure
  containers:
  - image: mellanox/rping-test
    name: rdma-test-ctr
    securityContext:
      capabilities:
        add: [ "IPC_LOCK" ]
    resources:
      limits:
        rdma/rdma_shared_device_a: 1
    command:
    - sh
    - -c
    - |
      sleep infinity
EOF
```

创建完成后，查看 Pod 状态，等 Pod Ready 后进入下一步：
``` bash
kubectl get pod -o wide | grep rdma-test
```

```
rdma-test-pod-1       1/1     Running     0          69s     10.233.84.218   a31    <none>           <none>
rdma-test-pod-2       1/1     Running     0          31s     10.233.118.5    a42    <none>           <none>
```

进入 pod rdma-test-pod-1 和 rdma-test-pod-2 中查看 infiniband 设备文件：

``` bash
kubectl exec -ti pod/rdma-test-pod-1  -- bash
```

```
[root@rdma-test-pod-1 /]# ls -al /sys/class/infiniband
total 0
drwxr-xr-x  2 root root 0 Aug  9 11:00 .
drwxr-xr-x 84 root root 0 Aug  9 11:00 ..
lrwxrwxrwx  1 root root 0 Aug  9 11:00 mlx5_0 -> ../../devices/pci0000:16/0000:16:02.0/0000:17:00.0/0000:18:04.0/0000:1d:00.0/infiniband/mlx5_0
```

```bash
kubectl exec -ti pod/rdma-test-pod-2  -- bash
```

```
[root@rdma-test-pod-2 /]# ls -al /sys/class/infiniband
total 0
drwxr-xr-x  2 root root 0 Aug  9 11:02 .
drwxr-xr-x 83 root root 0 Aug  9 11:02 ..
lrwxrwxrwx  1 root root 0 Aug  9 11:02 mlx5_0 -> ../../devices/pci0000:16/0000:16:02.0/0000:17:00.0/0000:18:04.0/0000:1d:00.0/infiniband/mlx5_0
```

在 Pod rdma-test-pod-1 和 rdma-test-pod-2 中进行 RDMA 测试。

在 Pod rdma-test-pod-1 中运行 test server：

``` bash
kubectl exec -ti pod/rdma-test-pod-1  -- bash
```

```
[root@rdma-test-pod-1 /]# ip a show eth0
3: eth0@if5331: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default
    link/ether c6:be:41:50:d5:65 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.233.84.218/32 scope global eth0
       valid_lft forever preferred_lft forever
[root@rdma-test-pod-1 /]# ib_write_bw -a -F --report_gbits
************************************
* Waiting for client to connect... *
************************************
---------------------------------------------------------------------------------------
                    RDMA_Write BW Test
 Dual-port       : OFF		Device         : mlx5_0
 Number of qps   : 1		Transport type : IB
 Connection type : RC		Using SRQ      : OFF
 CQ Moderation   : 100
 Mtu             : 4096[B]
 Link type       : IB
 Max inline data : 0[B]
 rdma_cm QPs	 : OFF
 Data ex. method : Ethernet
---------------------------------------------------------------------------------------
 local address: LID 0x04 QPN 0x01df PSN 0x8627f0 RKey 0x1802e2 VAddr 0x007f6c3c08f000
 remote address: LID 0x03 QPN 0x0027 PSN 0x28ccf6 RKey 0x1805e5 VAddr 0x007fe46b172000
---------------------------------------------------------------------------------------
 #bytes     #iterations    BW peak[Gb/sec]    BW average[Gb/sec]   MsgRate[Mpps]
 8388608    5000             98.38              98.38  		   0.001466
```

在 Pod rdma-test-pod-2 中运行 test client：

``` bash
kubectl exec -ti pod/rdma-test-pod-2  -- bash
```

```
[root@rdma-test-pod-2 /]# ib_write_bw -a -F --report_gbits 10.233.84.218
---------------------------------------------------------------------------------------
                    RDMA_Write BW Test
 Dual-port       : OFF		Device         : mlx5_0
 Number of qps   : 1		Transport type : IB
 Connection type : RC		Using SRQ      : OFF
 TX depth        : 128
 CQ Moderation   : 100
 Mtu             : 4096[B]
 Link type       : IB
 Max inline data : 0[B]
 rdma_cm QPs	 : OFF
 Data ex. method : Ethernet
---------------------------------------------------------------------------------------
 local address: LID 0x03 QPN 0x0027 PSN 0x28ccf6 RKey 0x1805e5 VAddr 0x007fe46b172000
 remote address: LID 0x04 QPN 0x01df PSN 0x8627f0 RKey 0x1802e2 VAddr 0x007f6c3c08f000
---------------------------------------------------------------------------------------
 #bytes     #iterations    BW peak[Gb/sec]    BW average[Gb/sec]   MsgRate[Mpps]
 2          5000           0.060665            0.059098            3.693631
 4          5000             0.11               0.11   		   3.449869
 8          5000             0.19               0.19   		   2.891324
 16         5000             0.50               0.50   		   3.878476
 32         5000             0.94               0.83   		   3.259774
 64         5000             1.86               1.83   		   3.565836
 128        5000             4.04               3.98   		   3.883562
 256        5000             8.04               7.51   		   3.668285
 512        5000             16.01              15.78  		   3.851526
 1024       5000             31.60              30.90  		   3.772522
 2048       5000             54.11              53.34  		   3.255410
 4096       5000             87.54              86.35  		   2.635233
 8192       5000             98.19              98.01  		   1.495541
 16384      5000             98.29              98.20  		   0.749223
 32768      5000             98.28              98.24  		   0.374774
 65536      5000             98.33              98.32  		   0.187536
 131072     5000             98.36              98.36  		   0.093805
 262144     5000             98.35              98.35  		   0.046895
 524288     5000             98.37              98.37  		   0.023453
 1048576    5000             98.38              98.38  		   0.011728
 2097152    5000             98.35              98.35  		   0.005862
 4194304    5000             98.38              98.38  		   0.002932
 8388608    5000             98.38              98.38  		   0.001466
---------------------------------------------------------------------------------------
```

最后删除上述用于测试的 Pods：

``` bash
kubectl delete pod rdma-test-pod-1 rdma-test-pod-2
```

```
pod "rdma-test-pod-1" deleted
pod "rdma-test-pod-2" deleted
```

### 测试 GPUDirect RDMA

运行下列命令来创建两个 Pod rdma-gpu-test-pod-1 和 rdma-gpu-test-pod-2，通过 nodeSelector 来保证他们运行在两个不同的且含有 IB NIC、NVIDIA GPU(GPU 需支持 RDMA) 的节点上（需要将 a101 和 a102 替换为你的集群节点）：

``` bash
$ kubectl create -f - << EOF
apiVersion: v1
kind: Pod
metadata:
  name: rdma-gpu-test-pod-1
spec:
  nodeSelector:
    # Note: Replace hostname or remove selector altogether
    kubernetes.io/hostname: a101
  restartPolicy: OnFailure
  containers:
  - image: mellanox/cuda-perftest
    name: rdma-gpu-test-ctr
    securityContext:
      capabilities:
        add: [ "IPC_LOCK" ]
    resources:
      limits:
        nvidia.com/gpu: 1
        rdma/rdma_shared_device_a: 1
EOF
```

``` bash
$ kubectl create -f - << EOF
apiVersion: v1
kind: Pod
metadata:
  name: rdma-gpu-test-pod-2
spec:
  nodeSelector:
    # Note: Replace hostname or remove selector altogether
    kubernetes.io/hostname: a102
  restartPolicy: OnFailure
  containers:
  - image: mellanox/cuda-perftest
    name: rdma-gpu-test-ctr
    securityContext:
      capabilities:
        add: [ "IPC_LOCK" ]
    resources:
      limits:
        nvidia.com/gpu: 1
        rdma/rdma_shared_device_a: 1
EOF
```

创建完成后，查看 Pod 状态，等 Pod Ready 后进入下一步：

``` bash
kubectl get pod -o wide | grep rdma-gpu
```

```
rdma-gpu-test-pod-1   1/1     Running     0          15s     10.233.120.114   a101    <none>           <none>
rdma-gpu-test-pod-2   1/1     Running     0          12s     10.233.71.205    a102    <none>           <none>
```

进入 pod rdma-gpu-test-pod-1 和 rdma-gpu-test-pod-2 中查看 infiniband 设备文件、GPU 设备文件：

``` bash
kubectl exec -ti rdma-gpu-test-pod-1 -- bash
```

```
root@rdma-gpu-test-pod-1:~# ls -al /sys/class/infiniband
total 0
drwxr-xr-x  2 root root 0 Aug  9 11:18 .
drwxr-xr-x 75 root root 0 Aug  9 11:18 ..
lrwxrwxrwx  1 root root 0 Aug  9 11:18 mlx5_0 -> ../../devices/pci0000:4a/0000:4a:02.0/0000:4b:00.0/0000:4c:04.0/0000:50:00.0/0000:51:10.0/0000:53:00.0/infiniband/mlx5_0
root@rdma-gpu-test-pod-1:~# ls /dev | grep nvidia
nvidia-modeset
nvidia-uvm
nvidia-uvm-tools
nvidia3
nvidiactl
```

``` bash
kubectl exec -ti rdma-gpu-test-pod-2 -- bash
```

```
root@rdma-gpu-test-pod-2:~# ls -al /sys/class/infiniband
total 0
drwxr-xr-x  2 root root 0 Aug  9 11:21 .
drwxr-xr-x 76 root root 0 Aug  9 11:21 ..
lrwxrwxrwx  1 root root 0 Aug  9 11:21 mlx5_0 -> ../../devices/pci0000:4a/0000:4a:02.0/0000:4b:00.0/0000:4c:04.0/0000:50:00.0/0000:51:10.0/0000:53:00.0/infiniband/mlx5_0
root@rdma-gpu-test-pod-2:~# ls /dev | grep nvidia
nvidia-modeset
nvidia-uvm
nvidia-uvm-tools
nvidia6
nvidiactl
```

在 Pod rdma-gpu-test-pod-1 和 rdma-gpu-test-pod-2 中进行 GPUDirect RDMA 测试。

在 Pod rdma-gpu-test-pod-1 中运行 test server：

``` bash
kubectl exec -ti rdma-gpu-test-pod-1 -- bash
```

```
root@rdma-gpu-test-pod-1:~# ip a show eth0
3: eth0@if29: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default
    link/ether 6a:99:3a:2e:82:c7 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.233.120.114/32 scope global eth0
       valid_lft forever preferred_lft forever
root@rdma-gpu-test-pod-1:~# ib_write_bw -a -F --report_gbits -q 2 --use_cuda 0
************************************
* Waiting for client to connect... *
************************************
initializing CUDA
Listing all CUDA devices in system:
CUDA device 0: PCIe address is 57:00
Picking device No. 0
[pid = 69, dev = 0] device name = [NVIDIA A100-SXM4-80GB]
creating CUDA Ctx
making it the current CUDA Ctx
cuMemAlloc() of a 33554432 bytes GPU buffer
allocated GPU buffer address at 00007f2418000000 pointer=0x7f2418000000
---------------------------------------------------------------------------------------
                    RDMA_Write BW Test
 Dual-port       : OFF		Device         : mlx5_0
 Number of qps   : 2		Transport type : IB
 Connection type : RC		Using SRQ      : OFF
 PCIe relax order: ON
 ibv_wr* API     : ON
 CQ Moderation   : 100
 Mtu             : 4096[B]
 Link type       : IB
 Max inline data : 0[B]
 rdma_cm QPs	 : OFF
 Data ex. method : Ethernet
---------------------------------------------------------------------------------------
 local address: LID 0x08 QPN 0x00dc PSN 0xf0a0c8 RKey 0x1fdfd1 VAddr 0x007f2419000000
 local address: LID 0x08 QPN 0x00dd PSN 0x860249 RKey 0x1fdfd1 VAddr 0x007f2419800000
 remote address: LID 0x02 QPN 0x064b PSN 0x21791 RKey 0x1fdfff VAddr 0x007fb29d000000
 remote address: LID 0x02 QPN 0x064c PSN 0x83b8a7 RKey 0x1fdfff VAddr 0x007fb29d800000
---------------------------------------------------------------------------------------
 #bytes     #iterations    BW peak[Gb/sec]    BW average[Gb/sec]   MsgRate[Mpps]
 8388608    10000            81.02              80.96  		   0.001206
---------------------------------------------------------------------------------------
deallocating RX GPU buffer 00007f2418000000
destroying current CUDA Ctx
```


在 Pod rdma-gpu-test-pod-2 中运行 test client：

``` bash
kubectl exec -ti rdma-gpu-test-pod-2 -- bash
```

```
root@rdma-gpu-test-pod-2:~# ib_write_bw -a -F --report_gbits -q 2 --use_cuda 0 10.233.120.114
initializing CUDA
Listing all CUDA devices in system:
CUDA device 0: PCIe address is D5:00
Picking device No. 0
[pid = 38, dev = 0] device name = [NVIDIA A100-SXM4-80GB]
creating CUDA Ctx
making it the current CUDA Ctx
cuMemAlloc() of a 33554432 bytes GPU buffer
allocated GPU buffer address at 00007fb29c000000 pointer=0x7fb29c000000
---------------------------------------------------------------------------------------
                    RDMA_Write BW Test
 Dual-port       : OFF		Device         : mlx5_0
 Number of qps   : 2		Transport type : IB
 Connection type : RC		Using SRQ      : OFF
 PCIe relax order: ON
 ibv_wr* API     : ON
 TX depth        : 128
 CQ Moderation   : 100
 Mtu             : 4096[B]
 Link type       : IB
 Max inline data : 0[B]
 rdma_cm QPs	 : OFF
 Data ex. method : Ethernet
---------------------------------------------------------------------------------------
 local address: LID 0x02 QPN 0x064b PSN 0x21791 RKey 0x1fdfff VAddr 0x007fb29d000000
 local address: LID 0x02 QPN 0x064c PSN 0x83b8a7 RKey 0x1fdfff VAddr 0x007fb29d800000
 remote address: LID 0x08 QPN 0x00dc PSN 0xf0a0c8 RKey 0x1fdfd1 VAddr 0x007f2419000000
 remote address: LID 0x08 QPN 0x00dd PSN 0x860249 RKey 0x1fdfd1 VAddr 0x007f2419800000
---------------------------------------------------------------------------------------
 #bytes     #iterations    BW peak[Gb/sec]    BW average[Gb/sec]   MsgRate[Mpps]
 2          10000           0.061867            0.060962            3.810117
 4          10000            0.13               0.13   		   3.953929
 8          10000            0.26               0.26   		   4.034568
 16         10000            0.52               0.52   		   4.029406
 32         10000            1.03               1.02   		   4.003723
 64         10000            2.07               2.06   		   4.015258
 128        10000            4.04               3.86   		   3.774170
 256        10000            8.17               8.03   		   3.921990
 512        10000            15.94              15.20  		   3.712094
 1024       10000            32.68              32.54  		   3.972166
 2048       10000            78.28              67.50  		   4.119992
 4096       10000            80.53              74.83  		   2.283757
 8192       10000            80.23              71.90  		   1.097180
 16384      10000            81.66              81.00  		   0.617974
 32768      10000            81.76              81.01  		   0.309037
 65536      10000            81.79              81.24  		   0.154945
 131072     10000            81.66              81.06  		   0.077303
 262144     10000            81.79              80.96  		   0.038603
 524288     10000            81.74              80.98  		   0.019308
 1048576    10000            81.13              80.94  		   0.009649
 2097152    10000            81.11              80.96  		   0.004825
 4194304    10000            81.01              80.97  		   0.002413
 8388608    10000            81.02              80.96  		   0.001206
---------------------------------------------------------------------------------------
deallocating RX GPU buffer 00007fb29c000000
destroying current CUDA Ctx
```

最后删除上述用于测试的 Pods：

``` bash
kubectl delete pod rdma-gpu-test-pod-1 rdma-gpu-test-pod-2
```

```
pod "rdma-gpu-test-pod-1" deleted
pod "rdma-gpu-test-pod-2" deleted
```

## 参考

<https://github.com/Mellanox/network-operator>

<https://docs.nvidia.com/networking/display/cokan10/network+operator>
