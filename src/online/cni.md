# CNI 配置

本文说明如何为 K8s 集群安装不同的 CNI（Container Network Interface）。

<aside class="note">
<div class="title">注意</div>

在应用本文档中提供的配置时，请先在 inventory 中查找是否已经存在相应的变量设置。如果存在，进行确认或者修改；如果不存在，需要在 inventory 中添加相应的变量设置。
</aside>

## Calico

设置 CNI 为 Calico：

```yaml
kube_network_plugin: calico
```

### 下载设置

设置 Calico 的版本及镜像地址：

```yaml
calico_version: "v3.25.1"
calico_node_image_repo: "{{ docker_image_repo }}/calico-node"
calico_cni_image_repo: "{{ docker_image_repo }}/calico-cni"
calico_flexvol_image_repo: "{{ docker_image_repo }}/calico-pod2daemon-flexvol"
calico_policy_image_repo: "{{ docker_image_repo }}/calico-kube-controllers"
```

## Cilium

Cilium 官方支持的安装方式为 Helm，通过 values.yaml 传入不同的参数来相应地改变所安装的 YAML 配置文件。Kubespray 在自己的仓库中维护了一份安装 Cilium 的 YAML 配置文件，但无法及时跟进 Cilium 的新特性，例如 L2 Annoucement、Gateway API 等。因此，这里选择在 Kubespray 安装 K8s 集群时先不安装 CNI，Kubespray 运行完毕后，再通过 Helm 安装 Cilium。

### 安装 K8s 集群

设置 `kube_network_plugin` 的值为 `cni`，Kubespray 将仅完成一些基本配置，而不实际安装一个具体的 CNI：

```yaml
kube_network_plugin: cni
```

Cilium 要求设置 `kube_owner` 的值为 `root`：

```yaml
kube_owner: root
```

如需启用 Cilium 的 L2 Annoucement、Gateway API 等高级功能，不能安装 kube-proxy：

```yaml
kube_proxy_remove: true
```

运行 Kubespray 安装 K8s 集群，安装完成后，所有 Node 和 Pod 将处于 not ready 状态，因为没有可用的 CNI。

### 安装 Cilium

#### 基本功能安装

如果只需要 Cilium 作为 CNI 的基本功能，运行以下命令通过 Helm 安装 Cilium：

```bash
cd ks-clusters
cd additionals/cilium

helm repo add cilium https://helm.cilium.io/
helm repo update
helm install cilium cilium/cilium --version 1.15.5 -n kube-system --values ./values-basic.yaml
```

<aside class="note">
<div class="title">注意</div>

注意检查 `values-basic.yaml` 的内容，确保符合实际安装环境。
</aside>

`values-basic.yaml` 示例如下：

```yaml
containerRuntime: # only needed when container runtime is cri-o
  integration: crio
image:
  repository: "quay.io/cilium/cilium"
  tag: "v1.15.5"
operator:
  image:
    repository: "quay.io/cilium/operator"
    tag: "v1.15.5"
ipam:
  operator:
    clusterPoolIPv4PodCIDRList: ["10.233.64.0/18"] # must equal to {{ kube_pods_subnet }}
    clusterPoolIPv4MaskSize: 24 # must equal to {{ kube_network_node_prefix }}
```

查看 Cilium 运行状态：

```bash
kubectl get pod -n kube-system -l app.kubernetes.io/part-of=cilium
```

#### 高级功能安装

如果需要安装 Cilium 的 L2 Annoucement、Gateway API 等高级功能，运行以下命令通过 Helm 安装 Cilium：

```bash
cd ks-clusters
cd additionals/cilium

kubectl create -f ./gateway-api

helm repo add cilium https://helm.cilium.io/
helm repo update
helm install cilium cilium/cilium --version 1.15.5 -n kube-system --values ./values-advanced.yaml
```

<aside class="note">
<div class="title">注意</div>

注意检查 `values-advanced.yaml` 的内容，确保符合实际安装环境。
</aside>

`values-advanced.yaml` 示例如下：

```yaml
containerRuntime: # only needed when container runtime is cri-o
  integration: crio
image:
  repository: "quay.io/cilium/cilium"
  tag: "v1.15.5"
operator:
  image:
    repository: "quay.io/cilium/operator"
    tag: "v1.15.5"
ipam:
  operator:
    clusterPoolIPv4PodCIDRList: ["10.233.64.0/18"] # must equal to {{ kube_pods_subnet }}
    clusterPoolIPv4MaskSize: 24 # must equal to {{ kube_network_node_prefix }}
kubeProxyReplacement: true
k8sServiceHost: x.x.x.x # PLEASE CHANGE THIS: must equal to {{ kube_apiserver_ip }}
k8sServicePort: 6443 # must equal to {{ kube_apiserver_port }}
k8sClientRateLimit:
  qps: 50
  burst: 100
l2announcements:
  enabled: true
gatewayAPI:
  enabled: true
```

查看 Cilium 运行状态：

```bash
kubectl get gatewayclass cilium
kubectl get pod -n kube-system -l app.kubernetes.io/part-of=cilium
```


## 参考

* <https://github.com/kubernetes-sigs/kubespray/blob/master/docs/CNI/calico.md>
* <https://github.com/kubernetes-sigs/kubespray/blob/master/docs/CNI/cilium.md>
* <https://github.com/kubernetes-sigs/kubespray/blob/master/docs/CNI/cni.md>
