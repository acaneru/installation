# 安装 K8s

## 目的

完成一个最基本的 K8s 集群安装。

## 前提条件

准备好了 inventory 并且服务器节点满足要求，可按照前述 [准备 ansible inventory](./inventory/index.md) 和 [准备节点](./prepare-nodes.md) 步骤执行。

## 配置

本章描述如何设置 K8s 安装使用的版本, 容器运行时, CNI 插件, Ingress, LoadBalancer 等选项。你可以通过修改 inventory 中的变量来配置上述选项。这些变量位于 inventory 目录中 `inventory/group_vars/`。

### 配置总览

> 详细说明请参考 Kubespray 文档 [Configurable Parameters in Kubespray](https://github.com/kubernetes-sigs/kubespray/blob/master/docs/ansible/vars.md)。下面仅列出较为重要的一些设置。

#### k8s-cluster.yml

* `kube_version`: 设置 K8s 版本。
* `container_manager`: 设置容器运行时。
* `kube_network_plugin`: 设置 CNI 插件。
* `kube_proxy_mode`: 设置 Kube proxy 代理模式。
* `kube_service_addresses`: 分配给 service 的 IP 地址范围。
* `kube_pods_subnet`: 分配给 Pod 的 IP 地址范围。
* `kube_vip_enabled`: 启用 kube-vip，详见 [kube-vip](https://github.com/kubernetes-sigs/kubespray/blob/master/docs/ingress/kube-vip.md)。
* `loadbalancer_apiserver`: 设置 apiserver 的负载均衡器，详见 [HA endpoints for K8s](https://github.com/kubernetes-sigs/kubespray/blob/master/docs/operations/ha-mode.md)。

#### addons.yml

* `ingress_nginx_enabled`: 启用 Ingress NGINX 功能（在安装 K8s 集群后自动安装 Ingress NGINX 作为 ingress 控制器）。
* `helm_enabled`: 在 K8s 控制节点安装 helm 命令行工具。
* `metrics_server_enabled`: 启用 Metrics Server 功能。

#### all.yml

* `upstream_dns_servers`: 设置集群使用的上游 DNS 服务器，建议与当前环境中的 DNS 配置一致。

### 设置代理

如果你需要为包管理工具、容器运行时设置代理。

在 `all.yml` 中设置如下参数即可：

```yaml
http_proxy: "<proxy-server>"
https_proxy: "<proxy-server>"
https_proxy_cert_file: ""
no_proxy: "127.0.0.0/8,localhost,192.168.0.0/16,..."
```

如果仅需要为容器运行时设置代理，则增加以下设置：

```yaml
skip_http_proxy_on_os_packages: true
```

### 设置 CRI

使用不同的容器运行时，请参考 [CRI 配置](./cri.md)。

如需使用 <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/concepts/workloads/pods/user-namespaces/">User Namespaces</a>，请参考 [设置 User Namespace](./k8s-userns.md)。

### 设置 CNI

使用不同的容器网络实现，请参考 [CNI 配置](./cni.md)。

### 设置 Ingress

如果你需要安装 Ingress 控制器，Kubespray 目前支持 [NGINX Ingress 控制器](https://kubernetes.github.io/ingress-nginx/)。

在 `addons.yml` 中设置如下参数即可：

```yaml
ingress_nginx_enabled: true
```

### 设置 Load Balancer

如果你需要为 K8s API Server 配置一个 Load Balancer，Kubespray 目前支持 [kube-vip](https://kube-vip.io/)。

在 `k8s-cluster.yml` 中设置如下参数即可：

```yaml
# Kube-proxy proxyMode configuration.
# Can be ipvs, iptables
kube_proxy_mode: ipvs

# configure arp_ignore and arp_announce to avoid answering ARP queries from kube-ipvs0 interface
# must be set to true for MetalLB, kube-vip(ARP enabled) to work
kube_proxy_strict_arp: true

# reference: https://github.com/kubernetes-sigs/kubespray/blob/master/docs/ingress/kube-vip.md#kube-vip
# Enable kube vip as HA for control-plane, requires a Virtual IP
kube_vip_enabled: true
kube_vip_controlplane_enabled: true
kube_vip_address: <your-virtual-ip-address>
loadbalancer_apiserver:
  address: "{{ kube_vip_address }}"
  port: 6443

# use ARP mode :
kube_vip_arp_enabled: true
```

上述各项参数的含义详见 [Kubespray 文档](https://github.com/kubernetes-sigs/kubespray/blob/master/docs/ingress/kube-vip.md)，其中：

* 为了使 kube-vip 能够正常工作，当 `kube_proxy_mode` 为 `ipvs` 时，`kube_proxy_strict_arp` 必须为 `true`
* `kube_vip_enabled` 为 `true` 表示启用 kube-vip
* `kube_vip_controlplane_enabled` 为 `true` 表示启用 kube-vip 针对 K8s 控制平面的高可用功能，即分配一个虚拟 IP 地址作为各个 K8s API Server 实例的外部负载均衡器
* `kube_vip_address` 表示一个可用的虚拟 IP 地址，kube-vip 将发送 ARP 广播，将发送给该虚拟 IP 地址的请求转发给一个 K8s API Server 实例
* `loadbalancer_apiserver` 表示其他服务将通过该虚拟 IP 地址及 6443 端口来访问 K8s API Server
* `kube_vip_arp_enabled` 为 `true` 表示启用 kube-vip 的 ARP 模式


## 安装 K8s

进入为此次安装准备的 inventory 目录：

```bash
cd ~/ansible/$T9K_CLUSTER 
```

运行 ansible 脚本，以安装 K8s 集群。

方法 1 - 交互式输入 become password：

```bash
ansible-playbook ../kubespray/cluster.yml \
  -i inventory/inventory.ini \
  --become -K
```

方法 2 - 使用 ansible vault 中保存的 become password：

```bash
ansible-playbook ../kubespray/cluster.yml \
    -i inventory/inventory.ini \
    --become \
    -e "@~/ansible/$T9K_CLUSTER/vault.yml" \
    --vault-password-file=~/ansible/.vault-password.txt
```

<aside class="note">
<div class="title">参数解释</div>

```
--become: 使用其他用户运行操作，默认使用 root 用户。
-K: 询问 become 所需的权限升级密码 (become password)。
-e: 设置额外的变量，@说明通过文件传入。
--vault-password-file: 保存了 vault 密码的文件。
```
</aside>

> 使用 ansible 安装 K8s 过程的更多详情，请参考：[安装 K8s 注释 > 过程解释](../appendix/k8s-install-notes.md#过程解释)


## 获取 kubeconfig

集群安装成功之后，可获取其 kubeconfig，以开始使用。

### 从 inventory 获取

如果设置了安装过程中复制 kubeconfig（`kubeconfig_localhost: true`，文件 `group_vars/k8s_cluster/k8s-cluster.yml`），可以在 `inventory/artifacts` 目录中找到 `admin.conf`（cluster-admin 权限）：

```bash
cp inventory/artifacts/admin.conf \
    ~/.kube/example-cluster.conf
```

<aside class="note">
<div class="title">注意</div>

ks-clusters 的 git repo 里已经配置了 `.gitignore` 文件以避免 `admin.conf` 文件被保存到 git repo 中，但仍需要谨慎操作，避免错误地把 `admin.conf` 放入 git 中，造成安全隐患。

</aside>

### 从 control-plane 节点获取

无论是否设置了 `kubeconfig_localhost`，都可以直接从 control-plane 节点获取 kubeconfig。

假设 `master01` 是一个 control-plane 节点，其 IP 为 `100.64.100.11`。

1. 复制 kubeconfig 文件

    ```bash
    ssh -t master01 'sudo cat /root/.kube/config' |tee ~/.kube/example-cluster.conf
    sed -i "1d" $HOME/.kube/example-cluster.conf
    ```

2. 替换 kubeconfig 中的 server 地址
   
   如果未配置 HA 模式，则直接使用 control-plane 节点的 IP 地址 + 端口（`100.64.100.11:6443`）：

    ```bash
    sed -i 's|^    server: https://.*|    server: https://100.64.100.11:6443|' \
        ~/.kube/example-cluster.conf
    ```

   如果通过 kube-vip 配置了 HA 模式，则应当使用 kube-vip 的虚拟 IP 地址 + 端口，或其他 HA 场景的适当设置。


##  集群检查

验证 kubeconfig 可用，并查看集群中的节点信息：

```bash
KUBECONFIG=~/.kube/example-cluster.conf kubectl get node
```

## 下一步

- [设置集群存储](./k8s-storage.md)

## 参考

- [使用 ansible 安装 K8s 过程的注释](../appendix/k8s-install-notes.md)
