# 设置 User Namespace

K8s <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/concepts/workloads/pods/user-namespaces/">User Namespaces</a> 功能将容器内运行的用户与主机中的用户隔离开来。

这是一个只对 Linux 有效的功能特性，且需要 Linux 支持在所用文件系统上挂载 idmap。这要求：

* 在节点上，你用于 `/var/lib/kubelet/pods/` 的文件系统，或你为此配置的自定义目录， 需要支持 idmap 挂载
* Pod 挂载的所有存储卷，其使用的文件系统支持 idmap 挂载

在实践中，这意味着你需要 Linux Kernel 的版本不低于 6.3，因为 K8s 常用的 tmpfs 在该版本中开始支持 idmap 挂载。Linux 6.3 中支持 idmap 挂载的一些比较流行的文件系统是：btrfs、ext4、xfs、fat、 tmpfs、overlayfs。

容器运行时必须支持 User Namespace：

* CRI-O：1.25 或更高版本
* containerd：2.0.0 或更高版本

其底层 OCI 运行时必须支持 User Namespace：

* crun 1.9 或更高版本（推荐 1.13+ 版本）
* runc 1.2.0 或更高版本

满足上述条件后，你可以在 `group_vars/k8s_cluster/k8s-cluster.yml` 中添加以下变量，来启动 User Namespace 功能：

```yaml
kube_apiserver_feature_gates:
  - "UserNamespacesSupport=true"

kubelet_feature_gates:
  - "UserNamespacesSupport=true"
```

## 示例

下面是一个完整的说明，基于<a target="_blank" rel="noopener noreferrer" href="https://github.com/t9k/ks-clusters/tree/master/inventory/sample-multi-1.28.6-containerd">示例 inventory</a> 修改 containerd 和 runc 的版本，并启用 User Namespace 功能：

```bash
diff -u -r sample-multi-1.28.6-containerd/group_vars/all/download.yml \
  sample-multi-1.28.6-containerd-userns/group_vars/all/download.yml
```

```diff
--- sample-multi-1.28.6-containerd/group_vars/all/download.yml
+++ sample-multi-1.28.6-containerd-userns/group_vars/all/download.yml
@@ -101,6 +101,7 @@
 # cri_dockerd_download_url: "{{ files_repo }}/github.com/Mirantis/cri-dockerd/releases/download/v{{ cri_dockerd_version }}/cri-dockerd-{{ cri_dockerd_version }}.{{ image_arch }}.tgz"
 
 # [Optional] runc: if you set container_manager to containerd or crio
+runc_version: v1.2.0-rc.1
 runc_download_url: "{{ files_repo }}/github.com/opencontainers/runc/releases/download/{{ runc_version }}/runc.{{ image_arch }}"
 
 # [Optional] cri-o: only if you set container_manager: crio
@@ -110,6 +111,8 @@
 # skopeo_download_url: "{{ files_repo }}/github.com/lework/skopeo-binary/releases/download/{{ skopeo_version }}/skopeo-linux-{{ image_arch }}"
 
 # [Optional] containerd: only if you set container_runtime: containerd
+containerd_version: 2.0.0-rc.1
 containerd_download_url: "{{ files_repo }}/github.com/containerd/containerd/releases/download/v{{ containerd_version }}/containerd-{{ containerd_version }}-linux-{{ image_arch }}.tar.gz"
 nerdctl_download_url: "{{ files_repo }}/github.com/containerd/nerdctl/releases/download/v{{ nerdctl_version }}/nerdctl-{{ nerdctl_version }}-{{ ansible_system | lower }}-{{ image_arch }}.tar.gz"
 ```


```bash
diff -u -r sample-multi-1.28.6-containerd/group_vars/k8s_cluster/k8s-cluster.yml \
  sample-multi-1.28.6-containerd-userns/group_vars/k8s_cluster/k8s-cluster.yml
```

 ```diff
--- sample-multi-1.28.6-containerd/group_vars/k8s_cluster/k8s-cluster.yml	
+++ sample-multi-1.28.6-containerd-userns/group_vars/k8s_cluster/k8s-cluster.yml
@@ -19,6 +19,12 @@
 ## Change this to use another Kubernetes version, e.g. a current beta release
 kube_version: v1.28.6
 
+kube_apiserver_feature_gates:
+  - "UserNamespacesSupport=true"
+
+kubelet_feature_gates:
+  - "UserNamespacesSupport=true"
+
 # Where the binaries will be downloaded.
 # Note: ensure that you've enough disk space (about 1G)
 local_release_dir: "/tmp/releases"
```

<aside class="note">
<div class="title">注意</div>

截止文档撰写时，containerd 只发布了 2.0.0-rc.1，runc 只发布了 1.2.0-rc.1。如可行，建议使用正式发布版本。

</aside>

此外，由于自定义了容器运行时及其组件的版本，且该版本信息不包含在 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/kubespray/blob/master/roles/kubespray-defaults/defaults/main/checksums.yml">checksums.yml</a> 中。还需要在此文件中补充 containerd 和 runc 文件的 checksum：

```yaml
runc_checksums:
  amd64:
    v1.2.0-rc.1: 57fbfc33a20ca3ee13ec0f81b2e8798a59b3f2de5e0d703609f4eb165127f0c6

containerd_archive_checksums:
  amd64:
    2.0.0-rc.1: 2a56fe585f19bdb7254192304c0dbd92e36f2b3dc695afc2bd9a0bd9d1769ae9
```