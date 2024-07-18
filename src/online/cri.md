# CRI 配置

本文档说明如何配置 inventory，以使用各种容器运行时来运行 K8s 集群。

<aside class="note">
<div class="title">注意</div>

使用说明：
1. 在应用本文档中提供的配置时，请先在 inventory 中查找是否已经存在相应的变量设置。如果存在，进行确认或者修改；如果不存在，需要在 inventory 中添加相应的变量设置。
2. inventory 的 `all/etcd.yml` 和 `k8s_cluster/k8s-cluster.yml` 文件中都包含了 `container_manager` 变量的设置。对于不加入 K8s 集群中的 etcd 节点，只有前者会生效；对于加入 K8s 集群中的节点，后者的设置优先级更高。通常我们建议同时修改这两个变量。
3. Kubespray 提供了默认的下载设置，因此你可以在 inventory 中省略版本和下载地址相关的设置。
4. 如果你需要安装自定义版本的容器运行时及其组件，除了配置下载设置外，还需要确认本地 kubespray 的 [checksums.yml](https://github.com/kubernetes-sigs/kubespray/blob/master/roles/kubespray-defaults/defaults/main/checksums.yml) 文件中已经包含了相应版本的 checksum。如果没有，你需要在 inventory 或者 `checksums.yml` 中添加相应的 checksum。
</aside>

## Docker

Docker 不兼容 Kubernetes 创建的容器运行接口（Container Runtime Interface），不过 [cri-dockerd](https://github.com/Mirantis/cri-dockerd) 项目填补了 Docker Engine 和 CRI 之间的空白。本章说明如何配置 cri-dockerd 和 Docker 作为 K8s 的容器运行时。

设置 container manager 为 Docker:

```yaml
container_manager: docker
```

### 下载设置

设置 docker 及相关组件的版本：

```yaml
docker_version: '20.10'
docker_containerd_version: 1.6.16
cri_dockerd_version: 0.3.4
```

设置下载地址：

```yaml
# Ubuntu docker-ce repo
docker_ubuntu_repo_base_url: "https://download.docker.com/linux/ubuntu"
docker_ubuntu_repo_gpgkey: 'https://download.docker.com/linux/ubuntu/gpg'
docker_ubuntu_repo_repokey: '9DC858229FC7DD38854AE2D88D81803C0EBFCD88'
# cri-dockerd download url
cri_dockerd_download_url: "{{ files_repo }}/github.com/Mirantis/cri-dockerd/releases/download/v{{ cri_dockerd_version }}/cri-dockerd-{{ cri_dockerd_version }}.{{ image_arch }}.tgz"
```

### 可选设置

设置 Docker 的存储驱动程序：

```yaml
docker_storage_options: -s overlay2
```

设置 Registry 镜像站：

```yaml
docker_registry_mirrors:
  - https://registry.dockermirror.com
```

设置 Docker 的默认 ulimit 值：

```yaml
docker_options: "--default-ulimit=memlock=-1:-1 --default-ulimit=stack=67108864:67108864"
```

设置 Docker 日志文件的大小和数量：

```yaml
# Rotate container stderr/stdout logs at 10m and keep last 5
docker_log_opts: "--log-opt max-size=10m --log-opt max-file=5"
```

<aside class="note">
<div class="title">注意</div>

Kubespray 默认设置了 `kubelet_logfiles_max_size: 10Mi`，我们建议将 `docker_log_opts` 中的 `max-size` 设置为相同的大小，以避免 [Failed ReopenContainerLog](https://github.com/Mirantis/cri-dockerd/issues/35) 的问题。

</aside>

## containerd

设置 container manager 为 containerd:

```yaml
container_manager: containerd
```

### 底层容器运行时

containerd 具有配置多个底层容器运行时的功能，可以与 Kubernetes 的 [RuntimeClass](https://kubernetes.io/docs/concepts/containers/runtime-class/) 功能一起使用。

containerd 使用 runc 作为默认的底层容器运行时，其配置如下：

```yaml
containerd_default_runtime: "runc"

containerd_runc_runtime:
  name: runc
  type: "io.containerd.runc.v2"
  engine: ""
  root: ""
  base_runtime_spec: cri-base.json
  options:
    systemdCgroup: "{{ containerd_use_systemd_cgroup | ternary('true', 'false') }}"
    binaryName: "{{ bin_dir }}/runc"
```

<aside class="note">
<div class="title">注意</div>

不推荐修改 `containerd_default_runtime`，因为 Kubespray 的相关支持不完善。

</aside>

你可以为 containerd 配置额外的底层容器运行时，例如 kata：

```yaml
kata_containers_enabled: true

containerd_additional_runtimes:
 - name: kata
   type: "io.containerd.kata.v2"
   engine: ""
   root: ""
```

可用的额外容器运行时种类，及其下载设置请参阅：[额外容器运行时设置](#附录额外容器运行时设置)。

如果你想了解更多关于 containerd 底层容器运行时的配置信息，请参考 containerd 的运行时文档 [runtime classes in containerd](https://github.com/containerd/containerd/blob/main/docs/cri/config.md#runtime-classes)。


### 下载设置

设置 containerd 及相关组件版本：

```yaml
containerd_version: 1.7.13
runc_version: v1.1.12
nerdctl_version: "1.7.1"
```

设置下载地址：

```yaml
containerd_download_url: "{{ files_repo }}/github.com/containerd/containerd/releases/download/v{{ containerd_version }}/containerd-{{ containerd_version }}-linux-{{ image_arch }}.tar.gz"
nerdctl_download_url: "{{ files_repo }}/github.com/containerd/nerdctl/releases/download/v{{ nerdctl_version }}/nerdctl-{{ nerdctl_version }}-{{ ansible_system | lower }}-{{ image_arch }}.tar.gz"
runc_download_url: "{{ files_repo }}/github.com/opencontainers/runc/releases/download/{{ runc_version }}/runc.{{ image_arch }}"
```

### 可选设置

设置 Registry 镜像站：

```yaml
containerd_registries_mirrors:
 - prefix: docker.io
   mirrors:
    - host: https://registry.dockermirror.com
      capabilities: ["pull", "resolve"]
      skip_verify: false
```

## CRI-O

CRI-O 是一个适用于 Kubernetes 的轻量级容器运行时。

设置 container manager 为 CRI-O:

```yaml
container_manager: crio
```

根据 Kubespray 文档，还需要设置以下变量：

```yaml
download_container: false
skip_downloads: false # 这一项与 Kubespray 的默认值相同，可以省略
```

### 底层容器运行时

CRI-O 具有配置多个底层容器运行时的功能，可以与 Kubernetes 的 [RuntimeClass](https://kubernetes.io/docs/concepts/containers/runtime-class/) 功能一起使用。

CRI-O 使用 runc 作为默认的底层容器运行时，其配置如下：

```yaml
crio_runtimes:
  - name: runc
    path: "{{ bin_dir }}/runc"
    type: oci
    root: /run/runc
```

<aside class="note">
<div class="title">注意</div>

不推荐修改 CRI-O 的默认容器运行时，因为 Kubespray 的相关支持不完善。

</aside>

你可以为 CRI-O 配置额外的底层容器运行时，例如启用 crun：

```yaml
crun_enabled: true
```

你不需要考虑 CRI-O 的配置。Kubespray 会根据预设的以下变量，自动将 crun 加入到 CRI-O 的底层容器运行时配置中：

```yaml
crun_runtime:
  name: crun
  path: "{{ bin_dir }}/crun"
  type: oci
  root: /run/crun
```

可用的额外容器运行时种类，及其下载设置请参阅：[额外容器运行时设置](#附录额外容器运行时设置)。

### 下载设置

设置 CRI-O 及相关组件版本：

```yaml
crio_supported_versions:
  v1.28: v1.28.1
  v1.27: v1.27.1
  v1.26: v1.26.4
crio_version: "{{ crio_supported_versions[kube_major_version] }}"
runc_version: v1.1.12
skopeo_version: "v1.13.2"
```

> 说明：变量 `kube_major_version` 是由变量 `kube_version` 派生出来的，具体来说，就是将 `kube_version` 的版本号最后一级去掉后的结果。

设置下载地址：

```yaml
crio_download_base: "download.opensuse.org/repositories/devel:kubic:libcontainers:stable"
crio_download_crio: "http://{{ crio_download_base }}:/cri-o:/"
crio_download_url: "https://storage.googleapis.com/cri-o/artifacts/cri-o.{{ image_arch }}.{{ crio_version }}.tar.gz"
skopeo_download_url: "{{ files_repo }}/github.com/lework/skopeo-binary/releases/download/{{ skopeo_version }}/skopeo-linux-{{ image_arch }}"
runc_download_url: "{{ files_repo }}/github.com/opencontainers/runc/releases/download/{{ runc_version }}/runc.{{ image_arch }}"
```

### 可选设置

设置 Registry 镜像站：

```yaml
crio_registries:
  - prefix: docker.io
    insecure: false
    blocked: false
    location: docker.io
    unqualified: false
    mirrors:
      - location: registry.dockermirror.com
        insecure: false
```

## 示例

这里列举了三个分别使用 Docker, containerd 和 CRI-O 作为容器运行时的 inventory：
* [Docker 容器运行时](https://github.com/t9k/ks-clusters/tree/master/inventory/sample-multi-1.28.6-docker)
* [containerd 容器运行时](https://github.com/t9k/ks-clusters/tree/master/inventory/sample-multi-1.28.6-containerd)
* [CRI-O 容器运行时](https://github.com/t9k/ks-clusters/tree/master/inventory/sample-multi-1.28.6-crio)

你可以做如下修改后，直接使用这些示例 inventory 安装相应的 K8s 集群：
* [修改 `inventory.ini`](./inventory/basic-settings.md#设置-inventory)
* 根据实际网络环境设置 `group_vars/all/all.yml` 中的 `upstream_dns_servers` 变量

## 附录：额外容器运行时设置

containerd 和 CRI-O 支持安装额外的底层容器运行时，本章说明这些底层容器运行时相关的变量配置。

设置是否安装该容器运行时：

```yaml
kata_containers_enabled: false
gvisor_enabled: false
crun_enabled: false
youki_enabled: false
```

容器运行时版本：

```yaml
crun_version: 1.8.5
kata_containers_version: 3.1.3
youki_version: 0.1.0
gvisor_version: 20230807
```

容器运行时下载地址：

```yaml
crun_download_url: "https://github.com/containers/crun/releases/download/{{ crun_version }}/crun-{{ crun_version }}-linux-{{ image_arch }}"
youki_download_url: "https://github.com/containers/youki/releases/download/v{{ youki_version }}/youki_{{ youki_version | regex_replace('\\.', '_') }}_linux.tar.gz"
kata_containers_download_url: "https://github.com/kata-containers/kata-containers/releases/download/{{ kata_containers_version }}/kata-static-{{ kata_containers_version }}-{{ ansible_architecture }}.tar.xz"
# gVisor only supports amd64 and uses x86_64 to in the download link
gvisor_runsc_download_url: "https://storage.googleapis.com/gvisor/releases/release/{{ gvisor_version }}/{{ ansible_architecture }}/runsc"
gvisor_containerd_shim_runsc_download_url: "https://storage.googleapis.com/gvisor/releases/release/{{ gvisor_version }}/{{ ansible_architecture }}/containerd-shim-runsc-v1"
```


## 参考

* <https://github.com/kubernetes-sigs/kubespray/blob/master/docs/CRI/cri-o.md>
* <https://github.com/kubernetes-sigs/kubespray/blob/master/docs/CRI/containerd.md>
* <https://github.com/kubernetes-sigs/kubespray/blob/master/docs/CRI/docker.md>
