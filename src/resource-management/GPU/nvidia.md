# 配置 NVIDIA GPU

## 前置条件

集群已[安装 NVIDIA GPU Operator](../../installation/hardware/nvidia/gpu-operator.md)。

## 总览

当集群内安装 GPU Operator 之后，用户就可以在集群内创建使用 NVIDIA GPU 的 Pod 了。除了以单个物理 GPU 为单位分配使用 GPU，NVIDIA GPU Operator 还支持共享 GPU 的使用方式。

下文会介绍：
1. 有哪些共享 GPU 的使用方式
2. 如何配置 NVIDIA GPU 的使用方法

## 共享 GPU 介绍

### time slicing

[时间切片（Time Slicing）](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-sharing.html)，也称为时间共享（Temporal Sharing），是指将多个 CUDA 程序分配到同一个 GPU 上运行，即一个简单的超额订阅（oversubscription）策略。NVIDIA 在 Pascal 架构（GP100，2016 年首发）之上提供了对此技术的支持。这些 GPU 卡上的调度器提供了指令粒度（不再需要等待 CUDA kernel 执行完成）的计算抢占（Compute Premption）技术。当抢占发生时， 当前 CUDA 程序的执行上下文（execution context：寄存器、共享内存等）被交换（swapped）到 GPU DRAM，以便另一个 CUDA 程序运行。

优点：
* 非常容易设置。
* 对分区数量无限制。
* 可在众多 GPU 架构上部署。

缺点：
* 上下文切换引起的效率降低。
* 共享 GPU 设备导致的的隔离不足、潜在的 GPU OOM 等。
* 时间片周期恒定，且无法为每个工作负载设置可用资源的优先级或大小。

### MIG

[MIG](https://docs.nvidia.com/datacenter/tesla/mig-user-guide/index.html) 可以把一个 GPU 划分为最多 7 个独立的 GPU 实例，从而为多个 CUDA 程序提供专用的 GPU 资源，包括流式多处理器（Streaming Multiprocessors）和 GPU 引擎。这些 MIG 实例可以为不同的 GPU 客户端（例如进程、容器或 VM）提供更加高级的故障隔离能力和 QoS。

优点：
* 硬件隔离，并发进程安全运行且互不影响。
* 在分区级别提供监控和遥测（monitoring & telemetry）数据。
* 每个分区可以叠加使用其他共享技术，例如 vGPU、time-slicing、MPS。

缺点：
* 仅在最新的 GPU 架构（Ampere，Hopper）上提供。
* 重新配置分区布局需在 GPU 空闲（驱逐所有正在运行的进程）时。
* 一些分区配置会导致部分 SM / DRAM 无法被利用。

### MPS

CUDA [MPS](https://docs.nvidia.com/deploy/mps/index.html)（Multi-Process Service，多进程服务）是 CUDA API 的客户端-服务器架构的实现，用于提供同一 GPU 同时给多个进程使用。MPS 是一个 “AI 史前”（深度学习尚未在 GPU 上运行）的方案，是 NVIDIA 为了解决在科学计算领域单个 MPI 进程无法有效利用 GPU 的计算能力而推出的技术。

与时间切片（Time Slicing）相比，MPS 通过在多个客户端之间共享一个 CUDA Context 消除了多个 CUDA 应用之间上下文切换的开销，从而带来更好的计算性能。 此外，MPS 为每个 CUDA 程序提供了单独的内存地址空间，因而可以实现对单个 CUDA 程序实施内存大小使用限制，克服了 Time Slicing 机制在这方面的不足。

优点：
* 可以控制单个应用的内存大小使用限制。
* 由于消除了多个 CUDA 应用之间 context swtich 的代价，具有更好的性能。
* 是一个 CUDA 层面的方案，不依赖于 GPU 的特定架构，支持较早的 GPU 硬件。

缺点：
* CUDA 应用之间隔离不足：单个应用的错误可以导致整个 GPU 重置（reset）。

## 配置方法

下面是在 Kubernete 集群中，三种共享 GPU 的配置方法。

### time slicing

配置 time slicing GPU 使用方法的流程<sup><a href="#参考">[1]</a></sup>是：
1. 创建一个 ConfigMap，定义以 time slicing 共享 GPU 的配置。
2. 修改 GPU Operator 的配置 ClusterPolicy，将步骤1 创建的 ConfigMap 名称填写在 ClusterPolicy 中。
3. 设置 time-slicing：修改节点标签，将节点上的 GPU 以 time slicing 形式提供给用户使用。


#### 创建 ConfigMap

首先创建 config.yaml 文件来定义 time-slicing config，内容如下：
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
 name: device-plugin-config
 namespace: gpu-operator
data:
   common: |-
       version: v1
       sharing:
         timeSlicing:
           renameByDefault: true
           resources:
           - name: nvidia.com/gpu
             replicas: 4
   a100-40gb: |-
       version: v1
       sharing:
         timeSlicing:
           renameByDefault: true
           resources:
           - name: nvidia.com/gpu
             replicas: 8
           - name: nvidia.com/mig-1g.5gb
             replicas: 2
```

这个 ConfigMap 中定义了 2 个 time-slicing config（config 设置[参考](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-sharing.html#applying-multiple-node-specific-configurations)）：a100-40gb 和 common。
1. common：只定义了一种划分 time-slicing GPU 的方式，即每一个 NVIDIA GPU 会被划分为 4 个 time-slicing GPU；renameByDefault 设置为 true，GPU 扩展资源名称会被修改为 `nvidia.com/gpu.shared`。
2. a100-40gb：定义了两种划分 GPU 的方式
    1. 如果节点没有启用 MIG GPU，每个 GPU 会被划分为 8 个 time-slicing GPU。
    2. 如果节点启用了 MIG GPU，并且 GPU 扩展资源名称是 `nvidia.com/mig-1g.5gb`，那么每个 `nvidia.com/mig-1g.5gb` 会被划分为 2 个 time-slicing GPU。这种共享方式是 MIG（strategy 需要设为 mixed） 和 time-slicing 同时作用来实现的。

然后运行下列命令，创建 ConfigMap device-plugin-config：
```bash
kubectl create -f config.yaml
```

#### 修改 ClusterPolicy

运行下列命令，修改 ClusterPolicy cluster-policy，将他的 `spec.devicePlugin.config.name` 字段设置为 device-plugin-config：
```bash
kubectl patch clusterpolicy/cluster-policy \
  -n gpu-operator --type merge \
  -p '{"spec": {"devicePlugin": {"config": {"name": "device-plugin-config"}}}}'
```

修改完成后，GPU Operator 会将 ConfigMap device-plugin-config 中定义的内容当作 NVIDIA Device Plugin 的配置。

#### 设置 time-slicing

在安装有 NVIDIA GPU 的节点上添加标签 `nvidia.com/device-plugin.config=<config-name>`，可以表明采用哪个 Device Plugin 的具体配置，目前可用 <config-name> 是 a100-40gb 或 common。

例如：

运行下列命令，在节点 z02 上实施配置 common。
```bash
kubectl label node z02 nvidia.com/device-plugin.config=common
```

z02 上只有一个物理 GPU，启用 config common 后，你可以看见 4 个 K8s GPU 扩展资源:
```bash
$ kubectl get node z02 -o json | jq .status.capacity
{
  …
  "nvidia.com/gpu.shared": "4",
  …
}
```

用户创建 Pod 时，可以通过设置扩展资源 `nvidia.com/gpu.shared: 1` 来表明想以 time-slicing 方式共享使用 GPU：
```yaml
   resources:
     limits:
       cpu: 100m
       memory: 100Mi
       nvidia.com/gpu.shared: 1
```

#### 取消 time-slicing

删除节点的标签 `nvidia.com/device-plugin.config`，即可取消 time-slicing
```bash
kubectl label nodes z02 nvidia.com/device-plugin.config-
```

#### 局限性

在 K8s 中以 time slicing 方式共享使用 GPU 有一些局限性：
1. 显存的安全没有保证（[参考](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-sharing.html#understanding-time-slicing-gpus:~:text=there%20is%20no%20memory%20or%20fault%2Disolation%20between%20replicas)）
2. 无法限制使用 time slicing GPU 的 Pod 占用的 GPU 资源量。time slicing 只能在进程层面共享 GPU，当用户在 Pod 中创建多个使用 GPU 的进程时，这些进程都能以 time slicing 形式共享 GPU 资源，从而这个 Pod 可以占用更多的 GPU 资源。例如：一个 GPU 被划分为两个 time-slicing GPU，对应集群内的两个扩展资源 `“nvidia.com/gpu.shared”: 2`。Pod A 声明了扩展资源 `“nvidia.com/gpu.shared”: 1`，Pod B 声明了扩展资源 `“nvidia.com/gpu.shared”: 1`。Pod A 中有两个进程使用 GPU，Pod B 中有 1 个进程使用 GPU，那么 Pod A 会占用这个 GPU ⅔  的计算能力，Pod B 会占用这个 GPU ⅓ 的计算能力。

### MIG

配置 MIG GPU 使用方法的流程<sup><a href="#参考">[2]</a></sup>是：
1. 修改 ConfigMap default-mig-parted-config，定义 MIG GPU 的配置。
2. 设置 MIG：修改节点标签，将节点上的 GPU 以 MIG 形式提供给用户使用。

#### 背景

MIG<sup><a href="#参考">[3]</a></sup> 可以根据显存和 GPU 计算能力来将一个物理 GPU 划分为多个 GPU Instance。

以 A100-40GB 为例，显存以整体的 1/8 （5GB）为最小粒度，计算能力以整体的 1/7 为最小粒度。

下面划分出一个 GPU Instance 1g.5gb，他的显存是 5GB，计算能力是 1/7。

<figure class="screenshot">
  <img alt="list" src="../../assets/resource-management/nvidia-gpu/mig-partitioning-ex2.png" />
</figure>

下面划分出一个 GPU Instance 4g.20gb，他的显存是 20GB，计算能力是 4/7。

<figure class="screenshot">
  <img alt="list" src="../../assets/resource-management/nvidia-gpu/mig-partitioning-ex3.png" />
</figure>

MIG 针对不同型号 GPU 所支持的 GPU instance 划分方式请参考文档 [MIG—Supported MIG Profiles](https://docs.nvidia.com/datacenter/tesla/mig-user-guide/index.html#supported-profiles)。

#### 修改 ConfigMap

部署 GPU Operator 之后，GPU Operator 默认创建 ConfigMap default-mig-parted-config 来作为 MIG 的配置文件。

下面是 MIG 默认配置内容，你可以按需修改：
```bash
$ kubectl -n gpu-operator get cm default-mig-parted-config -o yaml
apiVersion: v1
data:
  config.yaml: |
    version: v1
    mig-configs:
      all-disabled:
        - devices: all
          mig-enabled: false

      # A100-40GB
      all-1g.5gb:
        - devices: all
          mig-enabled: true
          mig-devices:
            "1g.5gb": 7

      all-2g.10gb:
        - devices: all
          mig-enabled: true
          mig-devices:
            "2g.10gb": 3

      all-3g.20gb:
        - devices: all
          mig-enabled: true
          mig-devices:
            "3g.20gb": 2

      all-7g.40gb:
        - devices: all
          mig-enabled: true
          mig-devices:
            "7g.40gb": 1
      ...
kind: ConfigMap
metadata:
  name: default-mig-parted-config
  namespace: gpu-operator
```

#### 设置 MIG

你可以在节点上添加标签 `nvidia.com/mig.config=<config-name>` 来表明采用哪种 MIG 划分 GPU Instance 的方式。

例如：

运行下列命令，会在节点 sm02 上启用配置 all-1g.5gb（需要先停用 sm02 上所有使用 GPU 的进程）。根据上述 ConfigMap 内容可知，配置 all-1g.5gb 会将 GPU 划分为 7 个 1g.5gb 的 GPU instance。

MIG Manager 按照配置来划分 MIG GPU，并在节点上添加 label mig.config.state 表明进度：
```bash
"nvidia.com/mig.config": "all-1g.5gb",
"nvidia.com/mig.config.state": "pending"
```

当 MIG Manager 完成配置更新后，节点上会有下列标签：
```bash
"nvidia.com/gpu.deploy.mig-manager": "true",
"nvidia.com/gpu.product": "A100-SXM4-40GB-MIG-1g.5gb",
"nvidia.com/gpu.slices.ci": "1",
"nvidia.com/gpu.slices.gi": "1",
"nvidia.com/mig.config": "all-1g.5gb",
"nvidia.com/mig.config.state": "success",
"nvidia.com/mig.strategy": "single"
```

查看 sm02 节点上的扩展资源，节点上有 1 个 A100-40GB，扩展资源名称是 `nvidia.com/gpu`。 通过 ClusterPolicy 将 mig strategy 改为 mixed，扩展资源名称会是 `nvidia.com/mig-1g.5gb`（[参考](https://github.com/NVIDIA/k8s-device-plugin/tree/v0.15.1?tab=readme-ov-file#configuration-option-details:~:text=Note%3A%20With%20a%20MIG_STRATEGY%20of%20mixed%2C%20you%20will%20have%20additional%20resources%20available%20to%20you%20of%20the%20form%20nvidia.com/mig%2D%3Cslice_count%3Eg.%3Cmemory_size%3Egb%20that%20you%20can%20set%20in%20your%20pod%20spec%20to%20get%20access%20to%20a%20specific%20MIG%20device.)）：

```bash
$ kubectl get node sm02 -o json | jq .status.capacity
{
  ...
  "nvidia.com/gpu": "7",
  ...
}
```

在节点 sm02 上运行下列命令：
```bash
$ nvidia-smi 
Mon Jul  1 18:01:37 2024       
+---------------------------------------------------------------------------------------+
| NVIDIA-SMI 535.161.08             Driver Version: 535.161.08   CUDA Version: 12.2     |
|-----------------------------------------+----------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |         Memory-Usage | GPU-Util  Compute M. |
|                                         |                      |               MIG M. |
|=========================================+======================+======================|
|   0  NVIDIA A100-PCIE-40GB          Off | 00000000:18:00.0 Off |                   On |
| N/A   51C    P0              71W / 250W |     38MiB / 40960MiB |     N/A      Default |
|                                         |                      |              Enabled |
+-----------------------------------------+----------------------+----------------------+
+---------------------------------------------------------------------------------------+
| MIG devices:                                                                          |
+------------------+--------------------------------+-----------+-----------------------+
| GPU  GI  CI  MIG |                   Memory-Usage |        Vol|      Shared           |
|      ID  ID  Dev |                     BAR1-Usage | SM     Unc| CE ENC DEC OFA JPG    |
|                  |                                |        ECC|                       |
|==================+================================+===========+=======================|
|  0    7   0   0  |               5MiB /  4864MiB  | 14      0 |  1   0    0    0    0 |
|                  |               0MiB /  8191MiB  |           |                       |
+------------------+--------------------------------+-----------+-----------------------+
|  0    8   0   1  |               5MiB /  4864MiB  | 14      0 |  1   0    0    0    0 |
|                  |               0MiB /  8191MiB  |           |                       |
+------------------+--------------------------------+-----------+-----------------------+
|  0    9   0   2  |               5MiB /  4864MiB  | 14      0 |  1   0    0    0    0 |
|                  |               0MiB /  8191MiB  |           |                       |
+------------------+--------------------------------+-----------+-----------------------+
|  0   10   0   3  |               5MiB /  4864MiB  | 14      0 |  1   0    0    0    0 |
|                  |               0MiB /  8191MiB  |           |                       |
+------------------+--------------------------------+-----------+-----------------------+
|  0   11   0   4  |               5MiB /  4864MiB  | 14      0 |  1   0    0    0    0 |
|                  |               0MiB /  8191MiB  |           |                       |
+------------------+--------------------------------+-----------+-----------------------+
|  0   12   0   5  |               5MiB /  4864MiB  | 14      0 |  1   0    0    0    0 |
|                  |               0MiB /  8191MiB  |           |                       |
+------------------+--------------------------------+-----------+-----------------------+
|  0   13   0   6  |               5MiB /  4864MiB  | 14      0 |  1   0    0    0    0 |
|                  |               0MiB /  8191MiB  |           |                       |
+------------------+--------------------------------+-----------+-----------------------+
```

用户创建使用 MIG GPU 的 Pod 时，需要设置 nodeSelector
```yaml
spec:
  restartPolicy: OnFailure
  containers:
  - name: vectoradd
    image: nvidia/samples:vectoradd-cuda11.2.1
    resources:
      limits:
        nvidia.com/gpu: 1
  nodeSelector:
    nvidia.com/gpu.product: A100-SXM4-40GB-MIG-1g.5gb
```

#### 取消 MIG

如果想取消以 MIG 形式共享 GPU，运行下列命令，将节点的 mig 配置改为 all-disabled 即可：
```bash
kubectl label nodes sm02 nvidia.com/mig.config=all-disabled --overwrite
```

配置 all-disabled 定义如下，会禁用 MIG 模式：
```yaml
apiVersion: v1
data:
  config.yaml: |
    version: v1
    mig-configs:
      all-disabled:
        - devices: all
          mig-enabled: false
      ...
kind: ConfigMap
metadata:
  name: default-mig-parted-config
  namespace: gpu-operator
```

### MPS

配置 MPS GPU 使用方法的流程与 time slicing 类似，下面的教程通过修改 time-slicing 创建的 ConfigMap device-plugin-config 来定义 MPS GPU 配置。

#### 修改 ConfigMap

修改 ConfigMap device-plugin-config，在 data 字段中添加下列内容：
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: device-plugin-config
  namespace: gpu-operator
data:
  mps: |-
      version: v1
      sharing:
        mps:
          renameByDefault: true
          resources:
          - name: nvidia.com/gpu
            replicas: 4
...
```

上述修改新增了名称是 mps 的配置，这个配置会将一个 NVIDIA GPU 划分为 4 个以 MPS 方式共享使用的 GPU。

#### 设置 MPS

在安装有 NVIDIA Volta+ GPU 的节点上添加标签 `nvidia.com/device-plugin.config=<mps-config-name>`，配置 NVIDIA Device Plugin 以 mpa 方式共享 GPU。

例如：

运行下列命令，使节点 sm03 应用 ConfigMap 中新增的 [mps 配置](https://docs.google.com/document/d/1l0LhLWoEx6AhBmR-KWSAfmhjJLpKJIH5T820Gtoplf4/edit#heading=h.qk1cloax0alo)：
```bash
k label node sm03 nvidia.com/device-plugin.config=mps 
```

查看节点 sm03 上运行的 GPU Operator 组件，会发现增加了一个组件 mps-control-daemon：
```bash
$ k -n gpu-operator get pod -o wide | grep sm03
gpu-feature-discovery-zttwv                                   2/2     Running     0                13m     10.234.3.100    sm03    <none>           <none>
nvidia-container-toolkit-daemonset-p92vl                      1/1     Running     6 (6d23h ago)    41d     10.234.3.133    sm03    <none>           <none>
nvidia-cuda-validator-dxjst                                   0/1     Completed   0                12m     10.234.3.58     sm03    <none>           <none>
nvidia-dcgm-exporter-x9h7m                                    1/1     Running     0                13m     10.234.3.153    sm03    <none>           <none>
nvidia-device-plugin-daemonset-j8bp2                          2/2     Running     0                13m     10.234.3.107    sm03   <none>           <none>
nvidia-device-plugin-mps-control-daemon-jw8ml                 2/2     Running     0                2m47s   10.234.3.43     sm03    <none>           <none>
nvidia-mig-manager-r99nv                                      1/1     Running     0                45m     10.234.3.182    sm03    <none>           <none>
nvidia-operator-validator-h4rqh                               1/1     Running     0                13m     10.234.3.46     sm03    <none>           <none>
release-name-node-feature-discovery-worker-hlbmp              1/1     Running     23 (6d23h ago)   41d     10.234.3.166    sm03    <none>           <none>
```

sm03 上只有一个物理 GPU，启用 config mps 后，你可以看见 4 个 K8s GPU 扩展资源:
```bash
$ kubectl get node sm03 -o json | jq .status.capacity
{
  …
  "nvidia.com/gpu.shared": "4",
  …
}
```

#### 取消 MPS

删除节点的标签 nvidia.com/device-plugin.config，即可取消 MPS
```bash
kubectl label nodes sm03 nvidia.com/device-plugin.config-
```

#### 局限性

在 K8s 中以 MPS 方式共享使用 GPU 有一些局限性：
1. 只能在 Volta+ NVIDIA GPU 上生效（[参考](https://github.com/NVIDIA/k8s-device-plugin/issues/647#issuecomment-2124122930)）
2. 用户可以在 Pod 中创建多个使用共享 GPU 的进程，从而超出声明的扩展资源限制。例：当一个 GPU 被分为 4 块共享 GPU 时，声明了扩展资源 `nvidia.com/gpu.shared=1` 的 Pod 可以最多创建 4 个进程，每个进程使用一个共享 GPU。(参考 [issue](https://github.com/NVIDIA/k8s-device-plugin/issues/720))

## 参考

* [1] [Time-Slicing GPUs in Kubernetes](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-sharing.html#)
* [2] [GPU Operator with MIG](https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/gpu-operator-mig.html)
* [3] [MIG](https://docs.nvidia.com/datacenter/tesla/mig-user-guide/index.html)
* [4] [NVIDIA Device Plugin MPS](https://github.com/NVIDIA/k8s-device-plugin/tree/v0.15.0?tab=readme-ov-file#with-cuda-mps)
