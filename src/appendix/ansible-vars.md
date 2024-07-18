## 修改变量配置文件

参考：<https://github.com/kubernetes-sigs/kubespray/blob/master/docs/ansible/vars.md>

inventory sample 已经在 kubespray 提供的 inventory 范例基础上配置了常用场景的方案。下文将以使用 inventory sample-HA-1.25.9 安装高可用的 v1.25.9 K8s 集群为例，说明其中较为重要的配置。

下面是一些词语的解释：

1. 默认值：kubespray 提供的 inventory sample 中设置的值。
1. 预设值：T9k 提供的 inventory sample 中设置的值。预设值可能不等于默认值。
1. 惯例配置：安装 K8s 集群时约定俗成的配置，例如 apiserver 使用 6443 端口。除非有明确的理由，否则不应该修改这些配置值。

### group_vars/k8s_cluster/k8s-cluster.yml

K8s 集群的设置：

1. K8s 版本 (kube_version)
    1. 预设值：v1.25.9
    1. 原因：根据需要安装的 K8s 版本设置
1. 容器运行时 (container_manager)
    1. 预设值：docker
    1. 原因：有其他模块（Ceph、Harbor）需要使用 docker；如无相关需求，也可以选择其他容器运行时
1. 安装使用的路径设置
    1. kube_config_dir 设置为 /etc/kubernetes
    1. kube_manifest_dir 设置为 "{{ kube_config_dir }}/manifests"
    1. kube_cert_dir 设置为 "{{ kube_config_dir }}/ssl"
    1. kube_token_dir 设置为 "{{ kube_config_dir }}/tokens"
    1. kube_script_dir 设置为 "{{ bin_dir }}/kubernetes-scripts"
    1. local_release_dir （下载可执行文件使用）设置为 "/tmp/releases"
1. 下载文件、镜像时的重试次数 (retry_stagger)
    1. 预设值：5
    1. 原因：默认值
1. K8s 网络插件相关
    1. K8s 网络插件 (kube_network_plugin)
        1. 预设值：calico
        1. 原因：有更多 calico 使用经验
    1. K8s 网络插件 multus (kube_network_plugin_multus)
        1. 预设值：false
        1. 作用：选择是否安装 <a target="_blank" rel="noopener noreferrer" href="https://github.com/k8snetworkplumbingwg/multus-cni">multus-cni</a>，false 为不安装
        1. 原因：默认值
1. K8s IP 地址及端口相关配置
    1. 分配给 service 的 IP 地址范围 (kube_service_addresses)
        1. 预设值：10.233.0.0/18
        1. 原因：惯例配置
    1. 分配给非 hostnetwork 的 Pod 的 IP 地址范围 (kube_pods_subnet)
        1. 预设值：10.233.64.0/18
        1. 原因：惯例配置
    1. 节点的内部网络大小分配 (kube_network_node_prefix)
        1. 预设值：24
        1. 作用：分配给每个节点用于 Pod IP 地址分配的范围大小，详细说明见<a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/v2.22.1/inventory/sample/group_vars/k8s_cluster/k8s-cluster.yml#L83">注释</a>
        1. 原因：默认值
    1. apiserver 的服务地址 (kube_apiserver_ip)
        1. 预设值：kube_service_addresses 的第一个地址，默认设置下是 10.233.0.1
        1. 原因：惯例配置
    1. apiserver 的监听端口 (kube_apiserver_port)
        1. 预设值：6443
        1. 原因：惯例配置
1. kube proxy 相关
    1. kube proxy 代理模式 (kube_proxy_mode)
        1. 预设值：ipvs
        1. 原因：ipvs 专为大量服务的负载均衡而设计，其性能不会随着集群规模扩大、service 后端 Pod 数量增加而下降
    1. kube proxy 是否启用严格的 arp 模式 (kube_proxy_strict_arp)
        1. 预设值：true
        1. 原因：为了使用 kube vip 的 ARP 模式，需要设置为 true
1. 配置 kube vip 以支持高可用集群，参考 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/docs/operations/ha-mode.md#ha-endpoints-for-k8s">HA endpoints for K8s</a> 及 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/docs/ingress/kube-vip.md">kube-vip</a>
    1. 启用 kube vip (kube_vip_enabled)
        1. 预设值：true
        1. 原因：需要启用 kube vip
    1. 启用 kube vip 作为 control-plane 之间的 load balancer (kube_vip_controlplane_enabled)
        1. 预设值：true
        1. 原因：为了支持高可用的集群
    1. kube vip 的 virtual IP 地址 (kube_vip_address)
        1. 预设值：100.64.4.202
        1. 原因：T9k 办公室网络默认配置，需根据实际情况调整
    1. 通过 load balancer 访问 apiserver 的地址 (loadbalancer_apiserver)
        1. address，预设值同 kube_vip_address
        1. port，预设值 6443
        1. 原因：惯例配置
    1. 启用 kube vip 作为 service 的 load balancer (kube_vip_services_enabled)
        1. 预设值：false
    1. 启用 service election (kube_vip_enableServicesElection)
        1. 预设值: true
    1. kube vip 使用 ARP 模式 (kube_vip_arp_enabled)
        1. 预设值：true
        1. 原因：ARP 模式可以在不需要路由器支持的情况下工作
1. 加密 secret 中的数据 (kube_encrypt_secret_data)
    1. 预设值：false
    1. 作用：静态加密 Secret，参考 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/docs/operations/encrypting-secret-data-at-rest.md">Encrypting Secret Data at Rest</a>
    1. 原因：未修改默认值
    1. 补充：考虑以后的安装中设置为 true，即使用默认的 secretbox 算法进行加密
1. 集群 DNS 相关设置
    1. 集群名称 (cluster_name)
        1. 预设值：cluster.local
        1. 作用：K8s 集群名称，也被用作 DNS domain
        1. 原因：默认值
    1. ndots
        1. 预设值：2
        1. 作用：解析主机名时，如果主机名中包含的点号 "." 数量少于 ndots，则会在主机名后面添加搜索域并进行解    析。本配置会通过 /etc/resolv.conf 影响使用 host network 的 Pod
        1. 原因：默认值 
        1. 补充：这一条目前和主机实际情况不符合，需要调查   
    1. dns_mode 选择 coredns，参考 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/docs/advanced/dns-stack.md#dns-modes-supported-by-kubespray">DNS mode</a>
        1. 原因：惯例配置
1. nodelocaldns 相关配置，参考 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/docs/advanced/dns-stack.md#nodelocal-dns-cache">Nodelocal DNS cache</a>
    1. 启用 nodelocal dns cache (enable_nodelocaldns)
        1. 预设值：true
        1. 原因：能够提高集群 DNS 性能
    1. Node local dns 服务地址 (nodelocaldns_ip)
        1. 预设值：169.254.25.10
        1. 原因：惯例配置
1. 域名解析模式 (resolvconf_mode)
    1. 预设值: true
    1. 原因：默认值
1. kubernetes 审计 (kubernetes_audit)
    1. 预设值: true
    1. 原因: Kubernetes 审计提供了一个与安全相关的、按时间顺序排列的记录集
1. K8s 镜像拉取策略 (k8s_image_pull_policy)
    1. 预设值: IfNotPresent
    1. 原因: 避免重复拉取镜像。生产环境中，如需更改镜像必须使用不同的 tag。
1. 自动更新证书 (auto_renew_certificates)
    1. 预设值: true
    1. 原因: 每个月第一个周一自动更新 K8s 控制平面证书。

### group_vars/k8s_cluster/addons.yml

K8s 附加组件设置：

1. 安装 helm (helm_enabled)
    1. 预设值: true
    1. 作用：在节点上安装 helm 命令行工具
1. 安装 registry (registry_enabled)
    1. 预设值: false
    1. 原因: 不符合需求，Kubespray 的方案是通过创建 Replica set 来运行 docker.io/library/registry 镜像作为 registry 服务
1. 安装 metrics server (metrics_server_enabled)
    1. 预设值: true
    1. 作用：安装 metrics server
1. 启用 ingress-nginx 作为 ingress 控制器 (ingress_nginx_enabled)
    1. 预设值: true
    1. 原因：有更多 ingress-nginx 使用经验。
    1. 设置为仅在具有 `"node-role.kubernetes.io/ingress"` label 的节点运行。

### group_vars/all/all.yml

网络、证书等设置：

1. 安装使用的路径设置
    1. bin_dir 设置为 /usr/local/bin
1. 设置 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/docs/advanced/dns-stack.md#upstream_dns_servers">upstream_dns_servers</a>，选择 114.114.114.114（或其他可靠的 DNS 服务）作为上游 DNS 服务器。
    1. 原因：避免 DNS 查询循环，参考 [K8s DNS 配置](https://docs.google.com/document/d/1wPHoCcTU49jlVjFhWiQfWfQRkj5Ymzq6ovtuKHAlCuM/edit#heading=h.h1mp0pkm52wl)。

### group_vars/all/download.yml

本文件来源于 kubespray sample 的 group_vars/all/offline.yml，结合了 download role 中的 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/v2.22.1/roles/download/defaults/main.yml">defaults/main.yml</a> 中的变量。用于指定命令行工具、镜像的下载源。部署 K8s 使用的镜像列表见文档：[[2023/08] Kubespray 测试](https://docs.google.com/document/d/1ktaFh43jI5cULvQe96GHeJBSjXpP2Kl4dQPST_Uw474/edit#heading=h.76vwdbfut8rn)。

1. 通用下载源设置
    1. files_repo: "https://mirror.ghproxy.com"
        1. 作用：指定 github 的文件的下载源
    1. gcr_image_repo: "docker.io/t9kpublic"
        1. 作用：指定 gcr registry 中镜像的下载源
    1. kube_image_repo: "docker.io/t9kpublic"
        1. 作用：指定 K8s registry 中镜像的下载源
    1. docker_image_repo: "docker.io/t9kpublic"
        1. 作用：指定 docker registry 中镜像的下载源
    1. quay_image_repo: "quay.io"
        1. 作用：指定 quay registry 中镜像的下载源
1. K8s 命令行工具下载链接
    1. kubectl_download_url: 指定 kubectl 的下载链接
    1. kubelet_download_url: 指定 kubelet 的下载链接
    1. kubeadm_download_url: 指定 kubeadm 的下载链接
1. 其他组件的下载链接，包括 coredns、calico 等组件的下载链接

### group_vars/all/docker.yml

docker 的设置，参考 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/docs/CRI/docker.md">Docker Support</a>：

1. Docker 数据存储路径 (docker_daemon_graph)
    1. 预设值: "/var/lib/docker"
    1. 原因：docker 默认的存储路径，可以根据具体文件系统挂载情况进行调整
1. docker 日志设置 (docker_log_opts)
    1. 预设值: "--log-opt max-size=50m --log-opt max-file=5"
    1. 原因：默认设置
1. 设置 docker registry mirrors (docker_registry_mirrors)
    1. 原因：加速国内拉取 docker hub 镜像的速度。
    1. 设置的镜像源为:
        1. https://dockerproxy.com/
        1. https://hub-mirror.c.163.com/
        1. https://mirror.baidubce.com/
        1. https://ccr.ccs.tencentyun.com/
1. 其他 docker 设置 (docker_options)
    1. 预设值: "--default-ulimit=memlock=-1:-1 --default-ulimit=stack=67108864:67108864"
    1. 原因：参考 <https://github.com/awslabs/benchmark-ai/issues/17>，但是其中 shared memory size 的设置对 K8s 无效（[测试记录](https://docs.google.com/document/d/1jJ6cfRvwQaWFk2G0F4_RvNOlfTw5ic2Ae_ozsEnfxvI/edit#heading=h.gvmpht24z67q)），因此没有增加。

### group_vars/all/etcd.yml

etcd 的设置，参考 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/docs/operations/etcd.md#etcd">etcd</a>：

1. 容器运行时 (container_manager)
    1. 预设值：docker
    1. 说明：与 k8s_cluster/k8s-cluster.yml 中设置的容器运行时作用范围不同。对于属于 k8s_cluster group 的节点，k8s_cluster/k8s-cluster.yml 中的设置会生效。否则本设置会生效（比如不加入 K8s 集群的 etcd 节点）。
1. etcd 的安装方式（etcd_deployment_type）选择 docker。
    1. 预设值: docker
    1. 原因：kubespray 推荐在容器运行时为 docker 时，使用该方式安装 etcd。
