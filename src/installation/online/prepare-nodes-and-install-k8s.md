# 准备节点与安装 K8s

## 准备工作

准备好物理主机，获得其 IP 地址，获得适当的访问凭证，然后准备 ansible 运行环境和 [inventory](./prepare-inventory.md)。

## 节点配置

运行 kubespray 安装 K8s 之前，需要做如下准备工作：

1. 禁用 Ubuntu 自动更新
1. 设置自动同步系统时钟
1. 网络
    1. 基本设置检查
    1. 如果是 IB 网络，配置并验证正确
1. GPU 驱动程序安装
    1. 确保硬件正常

```bash
# 进入 kubespray 专用的文件夹
$ cd ~/ansible
```

### 获取节点基本信息

运行脚本：

```bash
$ ansible-playbook ../ks-clusters/t9k-playbooks/0-gather-information.yml \
  -i inventory/inventory.ini \
  --become -K
```

在控制节点中查看保存的信息：

```bash
$ ls /tmp/facts/
nc11  nc12  nc13  nc14  nuc
```

### 禁用 Ubuntu 自动更新

<aside class="note">
<div class="title">注意</div>

该脚本中包含重启节点的操作。

</aside>

运行脚本：

```bash
$ ansible-playbook ../ks-clusters/t9k-playbooks/1-disable-auto-upgrade.yml \
  -i inventory/inventory.ini \
  --become -K
```

### 设置时钟同步

运行脚本：

```bash
$ ansible-playbook ../ks-clusters/t9k-playbooks/2-sync-time.yml \
    -i inventory/inventory.ini \
    --become -K \
    -e <chrony_server_ip> \
    -e chrony_client_ip_range=<chrony_client_ip_range_1>,<chrony_client_ip_range_2>
```

其中的变量说明如下：

1. chrony_server_ip：运行 chrony server 节点的 IP 地址。
1. chrony_client_ip_range_1：chrony 生效的 IP 地址网段，您可以设置一个或多个网段，使用逗号分割。

您也可以直接在 YAML 中设置变量（在 ks-clusters/t9k-playbooks/group_vars/all/all.yml 中）：

```bash
chrony_server_ip: <chrony_server_ip> # 1.2.3.4
chrony_client_ip_range:
- <chrony_client_ip_range_1> # 1.2.3.4/24
- <chrony_client_ip_range_2> # 100.0.0.1/8
```

## 安装 K8s 集群

### 前提条件

准备一个用于运行 Ansible 的控制节点：

1. Linux/MacOS 操作系统；
1. 安装了 Python 3.8-3.10，版本参考 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/v2.22.1/docs/ansible.md">Ansible Python Compatibility</a>；
1. 可连接到目标服务器集群；
1. 已完成[准备工作](#准备工作)。

需要确保计划添加到集群中的节点已完成下面的配置：

1. 完成了[节点配置](#节点配置)；

#### 修改变量配置文件

参考：<https://github.com/kubernetes-sigs/kubespray/blob/master/docs/vars.md>

inventory sample 已经在 kubespray 提供的 inventory 范例基础上配置了常用场景的方案。下文将以使用 inventory sample-HA-1.25.9 安装高可用的 v1.25.9 K8s 集群为例，说明其中较为重要的配置。

下面是一些词语的解释：

1. 默认值：kubespray 提供的 inventory sample 中设置的值。
1. 预设值：T9k 提供的 inventory sample 中设置的值。预设值可能不等于默认值。
1. 惯例配置：安装 K8s 集群时约定俗成的配置，例如 apiserver 使用 6443 端口。除非有明确的理由，否则不应该修改这些配置值。

##### group_vars/k8s_cluster/k8s-cluster.yml

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
1. 配置 kube vip 以支持高可用集群，参考 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/docs/ha-mode.md#ha-endpoints-for-k8s">HA endpoints for K8s</a> 及 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/docs/kube-vip.md">kube-vip</a>
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
    1. 作用：静态加密 Secret，参考 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/docs/encrypting-secret-data-at-rest.md">Encrypting Secret Data at Rest</a>
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
    1. dns_mode 选择 coredns，参考 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/docs/dns-stack.md#dns-modes-supported-by-kubespray">DNS mode</a>
        1. 原因：惯例配置
1. nodelocaldns 相关配置，参考 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/docs/dns-stack.md#nodelocal-dns-cache">Nodelocal DNS cache</a>
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

##### group_vars/k8s_cluster/addons.yml

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

##### group_vars/all/all.yml

网络、证书等设置：

1. 安装使用的路径设置
    1. bin_dir 设置为 /usr/local/bin
1. 设置 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/docs/dns-stack.md#upstream_dns_servers">upstream_dns_servers</a>，选择 114.114.114.114（或其他可靠的 DNS 服务）作为上游 DNS 服务器。
    1. 原因：避免 DNS 查询循环，参考 [K8s DNS 配置](https://docs.google.com/document/d/1wPHoCcTU49jlVjFhWiQfWfQRkj5Ymzq6ovtuKHAlCuM/edit#heading=h.h1mp0pkm52wl)。

##### group_vars/all/download.yml

本文件来源于 kubespray sample 的 group_vars/all/offline.yml，结合了 download role 中的 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/v2.22.1/roles/download/defaults/main.yml">defaults/main.yml</a> 中的变量。用于指定命令行工具、镜像的下载源。部署 K8s 使用的镜像列表见文档：[[2023/08] Kubespray 测试](https://docs.google.com/document/d/1ktaFh43jI5cULvQe96GHeJBSjXpP2Kl4dQPST_Uw474/edit#heading=h.76vwdbfut8rn)。

1. 通用下载源设置
    1. files_repo: "https://ghproxy.com"
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

##### group_vars/all/docker.yml

docker 的设置，参考 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/docs/docker.md">Docker Support</a>：

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

##### group_vars/all/etcd.yml

etcd 的设置，参考 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/docs/etcd.md#etcd">etcd</a>：

1. 容器运行时 (container_manager)
    1. 预设值：docker
    1. 说明：与 k8s_cluster/k8s-cluster.yml 中设置的容器运行时作用范围不同。对于属于 k8s_cluster group 的节点，k8s_cluster/k8s-cluster.yml 中的设置会生效。否则本设置会生效（比如不加入 K8s 集群的 etcd 节点）。
1. etcd 的安装方式（etcd_deployment_type）选择 docker。
    1. 预设值: docker
    1. 原因：kubespray 推荐在容器运行时为 docker 时，使用该方式安装 etcd。

### 运行脚本

运行命令，以安装一个新的 K8s 集群：

```bash
# 方法 1：交互式输入 become password
$ ansible-playbook ../kubespray/cluster.yml \
  -i inventory/inventory.ini \
  --become -K

# 方法 2：使用 ansible vault 中保存的 become password
$ ansible-playbook ../kubespray/cluster.yml \
    -i inventory/inventory.ini \
    --become \
    -e "@~/ansible/<new-cluster-name>-<version>/vault.yml" \
    --vault-password-file=~/.vault-password.txt
```

[参数解释]

1. --become: 使用 become 功能运行操作，默认使用的是 root 用户。
1. -K: 询问 become 所需的权限升级密码 (become password)。
1. --tags download: 只执行具有 "download"  tag 的任务。
1. -e: 设置额外的变量，@说明通过文件传入。
1. --vault-password-file: 保存了 vault 密码的文件。

[运行内容]

参考：[kubespray playbook 结构](https://docs.google.com/document/d/1DGNnGftwfF62hnL-NtESlC3NVBDtrDVDZTx9_3AAib8/edit#heading=h.o263jjbqbmhn)。

[运行时间]

初始化 K8s 集群所需要的时间受网络性能、节点性能、节点当前状态影响。在 Ubuntu 节点初次运行该脚本的用时通常在 30 分钟到 1 小时范围内。其中，命令行工具、镜像等内容的下载约 25 分钟，下载之外的运行时间约 20 分钟。

[运行进度]

Ansible 在执行过程中会输出当前运行的 Task 名称（方括号中的内容），及对每个节点的运行结果。格式如下：

```
TASK [reset : reset | Restart network]********************************
changed: [nc12]
changed: [nc13]
changed: [nc11]
changed: [nuc]
changed: [nc14]
```

只要前面的运行结果没有出错，且当前 Task 没有长时间（通常任务 > 2min，下载任务 > 5 min）的卡顿，即可认为 ansible 正在正常运行中。

Kubespray cluster.yml 脚本需要执行约 1300 个 Task，可以通过下面的命令输出完整的 Task 列表：

```bash
$ ansible-playbook ../kubespray/playbooks/cluster.yml \
    -i inventory/inventory.ini \
    --list-tasks > ../task-list.txt
```

[运行结果]

Ansible playbook 在运行结束后会输出一个运行回顾，示例如下：

```
PLAY RECAP *****************************************************************************************************
localhost                  : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
nc11                       : ok=609  changed=35   unreachable=0    failed=0    skipped=1108 rescued=0    ignored=1   
nc12                       : ok=452  changed=22   unreachable=0    failed=0    skipped=758  rescued=0    ignored=1   
nc13                       : ok=610  changed=34   unreachable=0    failed=0    skipped=1107 rescued=0    ignored=1  
nc14                       : ok=452  changed=22   unreachable=0    failed=0    skipped=758  rescued=0    ignored=1   
nuc                        : ok=728  changed=45   unreachable=0    failed=0    skipped=1237 rescued=0    ignored=7
```

如果出现异常，需进一步检查：

1. unreachable: 如果有节点显示为不可达，那么您应该检查该节点状态和网络连接。
1. failed: 如果有任务失败，那么您应该检查失败原因，并尝试解决问题。
1. ignored: 如果有错误被忽略，那么您应该检查忽略原因，并确定是否需要采取进一步的措施。这一步可以参考[常见 ignored fatal](https://docs.google.com/document/d/13X6vAjNVKEtzG6H5ydSNPcMx3Sbzzh1LFaFA-UKqBIo/edit#heading=h.rkmh2bn7pw2c)。

如果安装完成后，部分节点的 unreachable 或 failed 不为 0。您需要先处理它的错误，然后使用[增删集群节点](#增删集群节点)的方式将它加入到集群中。

[常见失败原因]

Ansible playbook 在运行过程中，有以下常见失败原因：

1. 镜像、命令行工具下载失败
    1. 设置的镜像名称错误
    1. Registry 不可访问，或者网络不通、不稳定
1. 验证未通过
    1. 重启 cri-dockerd 等系统服务时，等待时间超过预设值
    1. 用户配置不符合要求，如 etcd 节点数量为偶数
1. 节点遗留设置与现有设置冲突，导致命令运行出错
    1. 节点中设置了额外的 apt 源，导致冲突
    1. 节点中已经安装了新版本 docker，导致试图安装指定版本时失败

## K8s 集群安装后的配置

### 获取 kubeconfig 及集群检查

#### 从 inventory 获取

如果设置了 `kubeconfig_localhost: true(group_vars/k8s_cluster/k8s-cluster.yml)`，可以在 `ks-clusters/inventory/<new-cluster-name>-<version>/artifacts` 目录中找到 `admin.conf`（cluster-admin 权限）：

```bash
$ cp ../ks-clusters/inventory/artifacts/admin.conf \
    ~/.kube/example-cluster.config
```

<aside class="note">
<div class="title">注意</div>

ks-clusters 项目已经配置了 gitignore 文件以避免 admin.conf 文件被保存到 git repo 中，但仍需要谨慎操作。

</aside>

然后，检查集群中所有节点的状态：

```bash
$ KUBECONFIG=~/.kube/example-cluster.config  kubectl get node
```

#### 从 control-plane 节点获取

无论是否设置了 kubeconfig_localhost，都可以直接从 control-plane 节点获取 kubeconfig。

假设 nuc 是一个 control-plane 节点：

```bash
$ ssh -t nuc 'sudo cat /root/.kube/config' |tee ~/.kube/nuc.config
$ sed -i "1d" $HOME/.kube/nuc.config
```

替换 kubeconfig 中的 server 地址。如果未配置 HA 模式，则直接使用 control-plane 节点的 IP 地址（这里的 100.64.1.1）：

```bash
$ sed -i 's|^    server: https://.*|    server: https://100.64.1.11:6443|' \
    ~/.kube/nuc.config
```

<aside class="note">
<div class="title">注意</div>

如果使用 kube vip 配置了高可用集群，则应当将 server 地址设置为 kube vip 的 virtual IP 和 port。

</aside>

最后，验证 kubeconfig 可用，并查看集群中的节点信息：

```bash
$ KUBECONFIG=~/.kube/nuc.config kubectl get node
```

### 设置集群存储

#### 使用 nfs

参考文档：[Installing NFS](https://docs.google.com/document/d/1B9s4nx1chGsFaTby8YnVXHnCc8jblxaeBA2QUQZI-zA/edit#heading=h.er81k4h8wpj1)

ks-clusters/t9k-playbooks/roles/nfs/defaults/main.yml 中定义了变量 nfs_server_ip, nfs_share_network，可在运行 playbook 时在命令行设置。

```bash
# nfs_server ip address, e.g. 1.2.3.4
nfs_server_ip: "x.x.x.x"
# only clients with IP addresses in the network can access the share, e.g. 1.2.3.4/24
nfs_share_network: "x.x.x.x/24"
```

运行脚本，并设置 NFS 相关变量：

```bash
$ ansible-playbook ../ks-clusters/t9k-playbooks/10-install-nfs.yml \
  -i inventory/inventory.ini \
  -e nfs_server_ip="x.x.x.x" \
  -e nfs_share_network="x.x.x.x/24" \
  --become -K
```

该脚本中包含了：

* 节点上安装 nfs 相关的包
* 创建 nfs 共享目录
* 在 K8s 集群中创建 NFS CSI Driver
* 运行测试案例

#### 使用 Ceph

参考：<a target="_blank" rel="noopener noreferrer" href="https://t9k.github.io/ceph-admin-docs/overview.html">Ceph 存储集群管理员手册</a>

运行脚本安装 Ceph packages：

```bash
$ ansible-playbook ../ks-clusters/t9k-playbooks/11-install-ceph-package.yml \
    -i inventory/inventory.ini \
    --become -K
```

Ceph 集群的创建需要具体考虑各个节点的情况。TODO：将 Ceph 集群的创建自动化。

设置 Ceph CSI Driver 的变量（在 ks-clusters/t9k-playbooks/roles/ceph-csi/defaults/main.yml 中）：

```yaml
ceph:
  manifests_dir: "{{ kube_config_dir }}/addons/ceph"
  set_default_storage_class: true
  namespace: cephfs-hdd
  storage_class_name: cephfs-hdd
  driver_name: cephfs-hdd.csi.ceph.com
  cluster_id: <your-cluster-id>
  fs_name: k8s_hdd
  admin_id: k8s_hdd
  admin_key: <your-admin-key>
  metrics_port: 8681
  monitors:
  - "100.0.0.1:6789"
  - "100.0.0.2:6789"
...
```

运行脚本安装 Ceph CSI Driver：

```bash
$ ansible-playbook ../ks-clusters/t9k-playbooks/12-install-ceph-csi.yml \
    -i inventory/inventory.ini
```

### 加固集群安全

<https://github.com/kubernetes-sigs/kubespray/blob/master/docs/hardening.md>

## 集群维护

### 增删集群节点

#### 增加工作节点

<https://github.com/kubernetes-sigs/kubespray/blob/master/docs/nodes.md#addingreplacing-a-worker-node>

1. 修改 inventory.ini，以增加新的节点。请先参考 [inventory 准备]()修改已有的 inventory 来增加节点。下面是一个增加节点（nc15，worker node）的示例：

```bash
$ diff -u inventory-old.ini inventory-new.ini
--- inventory-old.ini
+++ inventory-new.ini
@@ -1,6 +1,7 @@
 [all]
 nuc ansible_host=nuc
 nc11 ansible_host=nc11
 nc12 ansible_host=nc12
 nc13 ansible_host=nc13
 nc14 ansible_host=nc14
+nc15 ansible_host=nc15

@@ -18,6 +19,7 @@
 [kube_node]
 nuc
 nc11
 nc12
 nc13
 nc14
+nc15
```

2. 更新 facts：

```bash
$ ansible-playbook ../kubespray/playbooks/facts.yml \
    -i inventory/inventory.ini \
    --become --become-user root -K
```

<aside class="note">
<div class="title">注意</div>

kubespray 1.24.10 及之前的版本，需要运行 kubespray/facts.yml。1.25.9 之后 kubespray 移除了 kubespray/facts.yml 文件，作为代替的是 playbooks 文件夹中的 facts.yml。

</aside>

3. 运行 kubespray 脚本来添加节点：

```bash
$ ansible-playbook ../kubespray/scale.yml \
    -i inventory/inventory.ini \
    --become --become-user root -K --limit nc15
```

<aside class="note">
<div class="title">注意</div>

使用命令行参数 `--limit nc15` 限制 playbook 的执行范围在 nc15 节点上，保障其他节点不受影响。如果有多个节点需要添加，使用例如 `--limit nc15,nc16` 的格式指定。

</aside>

#### 移除工作节点

<https://github.com/kubernetes-sigs/kubespray/blob/master/docs/nodes.md#addingreplacing-a-worker-node>

1. 更新 facts：

```bash
$ ansible-playbook ../kubespray/playbooks/facts.yml \
    -i inventory/inventory.ini \
    --become --become-user root -K
```

2. 运行 kubespray 脚本来删除节点：

```bash
$ ansible-playbook ../kubespray/remove-node.yml \
    -i inventory/inventory.ini \
    --become --become-user root -K -e node=nc12 --limit nc12 
```

<aside class="note">
<div class="title">注意</div>

使用命令行参数 `-e` 设置 node 变量，指定要移除的节点。如果有多个节点需要移除，使用例如 `-e node=nc12,nc13 --limit nc12,nc13` 的格式指定。

</aside>

3. 修改 inventory 文件，删去已经移除的节点。

#### 增加、移除 Control Plane 节点

对 control plane 节点的修改需要运行 cluster.yml，具体请参考文档：

1. <https://github.com/kubernetes-sigs/kubespray/blob/master/docs/nodes.md#addingreplacing-a-control-plane-node>
1. <https://github.com/kubernetes-sigs/kubespray/blob/master/docs/nodes.md#replacing-a-first-control-plane-node>

#### 集群拆除

<aside class="note warning">
<div class="title">警告</div>

1. 集群的拆除是不可逆的，在运行之前请确认您已经备份了集群中的重要数据；
1. 这里描述的方法仅限于使用 kubespray 部署的集群，并且要和集群部署时使用的 kubespray 版本和 inventory 一致。

</aside>

拆除集群：

```bash
$ ansible-playbook ../kubespray/reset.yml \
    -i inventory/inventory.ini \
    --become --become-user root -K
```

#### 升级 K8s 版本

<aside class="note">
<div class="title">注意</div>

1. 在升级集群之前，查看 <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/releases/#release-history">Release History</a> 的 Changelog 以了解 K8s 做了什么修改，并判断这些修改是否会影响您集群中的工作负载。
1. 检查 kubespray 的 kubeadm_checksums 变量的值来确定目标 K8s 版本是否被支持。这个变量位于 role download 的 defaults 文件夹中，可能是 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/v2.22.1/roles/download/defaults/main.yml#L488">main.yml</a> 或者 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/roles/download/defaults/main/checksums.yml#L292">main/checksums.yml</a>。
1. 升级时，请使用 T9k 提供的 kubespray 的相邻版本进行升级，不要跨多个版本升级。

</aside>

步骤：

1. 将 kubespray 切换到合适的分支
1. 修改 inventory，指定合适的 kube_version，docker_version 等计划升级的版本
1. 运行升级脚本：

```bash
ansible-playbook ../kubespray/upgrade-cluster.yml \ 
    -i inventory/inventory.ini \
    --become \
    -e "@~/nc15-1.25.9/vault.yml" \
    --vault-password-file=~/.vault-password.txt
```

运行成功的 PLAY RECAP 示例：

```
PLAY RECAP *********************************************
localhost                  : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
nc12                       : ok=483  changed=32   unreachable=0    failed=0    skipped=814  rescued=0    ignored=1   
nc14                       : ok=483  changed=32   unreachable=0    failed=0    skipped=814  rescued=0    ignored=1   
nc15                       : ok=742  changed=61   unreachable=0    failed=0    skipped=1561 rescued=0    ignored=1
```

参考：<https://github.com/kubernetes-sigs/kubespray/blob/master/docs/upgrades.md>
