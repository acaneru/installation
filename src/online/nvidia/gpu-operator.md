# 安装 NVIDIA GPU Operator

```
TODO: 1. 支持更多 OS/Kernel 版本组合  
      2. 使用 ansible 或者 GPU operator 安装 nvidia driver
      3. Run `p2pBandwidthLatencyTest`
```

## 前置条件

节点应该满足以下条件：

1. 已经加入 K8s 集群
1. 安装有 NVIDIA GPU 硬件
1. 没有安装 NVIDIA Driver

节点 OS 要求：

1. Ubuntu 20.04 server
1. Kernel version: 
    * 5.4.0-144-generic
    * 5.4.0-153-generic 
    * 5.4.0-155-generic 

## 安装

### nvidia driver

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

安装 nvidia driver：

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

> nvidia driver 安装后，会在集群内添加 system unit `nvidia-persistenced.service`，我们需要修改这个 unit 以启用  persistenced mode。

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

注意：510.x.x 及之后的 driver，在 nvidia driver bug 未修复前，还需要 [Disable GSP](#disable-gsp)。


#### 验证

Driver 安装后，可使用 nvidia-smi 查看 GPU 信息：

```bash
nvidia-smi -L
```

```console
GPU 0: NVIDIA A40 (UUID: GPU-5219cc39-b9d9-48cd-b092-62e71dd15dd6)
GPU 1: NVIDIA A40 (UUID: GPU-0045dae9-1bed-16e5-dc7c-56f2a9e7e186)
GPU 2: NVIDIA A40 (UUID: GPU-132cba3f-bee7-ad56-e15b-bb0d8c855570)
GPU 3: NVIDIA A40 (UUID: GPU-5997dde0-a4b6-4d9e-bce8-7eda71997146)
GPU 4: NVIDIA A40 (UUID: GPU-1af15774-0a04-f2ec-d6a4-95e2d61ddc23)
GPU 5: NVIDIA A40 (UUID: GPU-6c67e0a5-06fe-a081-2783-a27c338b31a8)
GPU 6: NVIDIA A40 (UUID: GPU-5246cdd0-db79-cea0-eaf5-d067784e4648)
```

运行测试程序：

> TODO: Run p2pBandwidthLatencyTest.

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

### gpu-operator

#### helm template

运行 helm template 命令生成 template.yaml，并且：

1. 替换 node-feature-discovery 镜像
1. 禁用 driver

```bash
helm template -n gpu-operator oci://tsz.io/t9kcharts/gpu-operator \
  --version v22.9.2 \
  --include-crds \
  --set "node-feature-discovery.image.repository=t9kpublic/node-feature-discovery","node-feature-discovery.image.tag=v0.10.1","driver.enabled=false" \
  > template.yaml
```

其中 Helm Chart 来源见 [附录：GPU Operator 的 Helm Chart 修改](../../appendix/modify-helm-chart.md#gpu-operator)。

#### 安装

以上配置修改完成之后，就可以安装 gpu operator 了：

```bash
kubectl create ns gpu-operator
kubectl -n gpu-operator apply -f template.yaml
```

#### 验证

GPU Operator 安装完成后，在 namespace `gpu-operator` 中查看 GPU Operator 安装的组件：

```bash
kubectl -n gpu-operator get deploy
```

```
NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
gpu-operator                        1/1     1            1           18d
t9k-node-feature-discovery-master   1/1     1            1           18d
```

```bash
kubectl -n gpu-operator get ds
```

```
NAME
gpu-feature-discovery               
nvidia-container-toolkit-daemonset  
nvidia-dcgm-exporter                
nvidia-device-plugin-daemonset      
nvidia-mig-manager                  
nvidia-operator-validator           
t9k-node-feature-discovery-worker  
```

查看 gpu operator 的配置：

```bash
kubectl -n gpu-operator get clusterpolicy cluster-policy  
```

```
NAME             AGE
cluster-policy   2d18h
```

#### 安装的组件信息

##### 全局

gpu-operator：

* GPU Operator 的运行主体，他会在集群中部署与 NVIDIA GPU 相关的组件。
* 如何确认正常工作？Pod 运行正常，并且 NVIDIA GPU 相关的组件已经被部署在集群中。

[node-feature-discovery](https://github.com/kubernetes-sigs/node-feature-discovery)（master & worker）：

* 运行在所有节点上，检测集群节点的硬件信息、系统信息，并将这些信息记录在节点标签上，这些标签前缀是 `feature.node.kubernetes.io/`。GPU Operator 依赖 node feature discovery 添加的节点标签。
* 如何确认正常工作？Pod 运行正常，并且可以在节点上查看到相关的节点标签。


##### NVIDIA GPU 节点

下面这些组件只能运行在含有 NVIDIA GPU 的节点上

[gpu-feature-discovery](https://github.com/NVIDIA/gpu-feature-discovery)：

* 根据节点上的 GPU 信息来生成节点标签，标签前缀是 `nvidia.com/`
* 如何确认正常工作？Pod 运行正常，并且可以在节点上查看到相关的节点标签。

[nvidia-container-toolkit](https://github.com/NVIDIA/nvidia-container-toolkit): 

* 运行在含有 NVIDIA GPU 的节点上，在节点上安装 nvidia container toolkit
* 如何确认正常工作？Pod 运行正常，并且可以在节点主机上查看到安装的 nvidia container toolkit

nvidia-dcgm-exporter：

* 在节点上安装 [dcgm-exporter](https://github.com/NVIDIA/dcgm-exporter)，exposes GPU metrics exporter for [Prometheus](https://prometheus.io/) leveraging [NVIDIA DCGM](https://developer.nvidia.com/dcgm).
* 如何确认正常工作？Pod 运行正常，并且可以通过 Pod 上 dcgm exporter 服务查询 GPU metrics。

[nvidia-device-plugin](https://github.com/NVIDIA/k8s-device-plugin)：

* 将 NVIDIA GPU 注册为 K8s 扩展资源。
* 如何确认正常工作？Pod 运行正常，可以在含有 GPU 的节点上查看到 NVIDIA GPU 扩展资源。

```yaml
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
   
nvidia-mig-manager

* 运行在 GPU 支持 MIG 的节点上，The NVIDIA MIG manager is a Kubernetes component capable of repartitioning GPUs into different MIG configurations in an easy and intuitive way. Users simply add a label with their desired MIG configuration to a node, and the MIG manager takes all the steps necessary to make sure it gets applied. This includes shutting down all attached GPU clients, performing the MIG configuration itself, and then bringing those clients back online once the process is complete. Available configurations are stored in a configMap in the cluster, and the MIG manager uses the MIG partition editor to carry out the actual MIG configuration under the hood.
* 如何确认正常工作？Pod 运行正常

nvidia-operator-validator   

* The Validator for NVIDIA GPU Operator runs as a Daemonset and ensures that all components are working as expected on all GPU nodes. It runs through series of validations via InitContainers for each component and writes out status file as a result under /run/nvidia/validations. These status files allow each component to verify for their dependencies and start in correct order.
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

## 注意事项

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

## 参考

<https://docs.nvidia.com/datacenter/cloud-native/gpu-operator/latest/getting-started.html>
