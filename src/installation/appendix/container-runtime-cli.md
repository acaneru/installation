# CRI 命令行工具

Docker、containerd 和 CRI-O 是三个主流的 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes/cri-api"> K8s 容器运行时（CRI）</a>。本文介绍几个常用命令行工具，用于管理镜像、容器的生命周期等。

## crictl

<a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/cri-tools/blob/master/docs/crictl.md">crictl</a> 是项目 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/cri-tools/"> K8s cri-tools </a>提供的命令行工具。它基于容器运行时接口 (CRI) 运行，适用于所有与 CRI 兼容的容器运行时。

> 参考：<a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/tasks/debug/debug-cluster/crictl/">Debugging Kubernetes nodes with crictl</a> 介绍使用 `crictl` 检查和调试 K8s 节点上的容器运行时和应用程序。

### Pod

查看运行中的 Pod：

```bash
crictl pods
```

查看 Pod 详细信息：

```bash
crictl inspectp <pod-id>
```

将本地转口转发到 Pod：

```bash
crictl port-forward <pod-id> <[local_port:]remote_port>
```

### 容器

查看所有容器：

```bash
crictl ps -a
```

查看容器详细信息：

```bash
crictl inspect <container-id>
```

查看容器日志：

```bash
crictl logs <container-id>
```

停止容器：

```bash
crictl stop <container-id>
```

在容器中执行命令：

```bash
crictl exec <container-id> ls
```

### 镜像

查看镜像：

```bash
crictl images
```

拉取镜像：

```bash
crictl pull <image>
```

查看镜像详细信息：

```bash
crictl inspecti <image>
```

## nerdctl

<a target="_blank" rel="noopener noreferrer" href="https://github.com/containerd/nerdctl">nerdctl</a> 是一个与 Docker CLI 风格兼容的 containerd 的客户端工具。它的命令与 Docker 非常相似，因此从 Docker 迁移到 containerd 的用户使用 nerdctl 会感到非常熟悉与方便。

> containerd 提供了一套完善的 <a target="_blank" rel="noopener noreferrer" href="https://github.com/containerd/containerd/blob/main/docs/namespaces.md">Namespaced API</a>（containerd namespace 与 K8s namespace 完全不相关），允许多个用户使用同一个 containerd 实例而不互相冲突。K8s CRI 默认使用 `k8s.io` namespace，而 Docker 默认使用 `moby` namespace。nerdctl 的默认值是 `k8s.io` namespace，你可以通过 `-n <namespace>` 参数来指定其他 namespace。

### 容器

查看 namespace 中所有容器：

```bash
nerdctl ps
```

运行一个容器：

```bash
nerdctl run --detach --name <container_name> <image>
```

在容器中执行额外命令：

```bash
nerdctl exec -ti <container_id> bash
```

查看容器详情：

```bash
nerdctl inspect <container_id>
```

查看容器日志：

```bash
nerdctl logs <container_id>
```

查看容器状态：

```bash
nerdctl stats <container_id>
```

### 镜像

查看 namespace 中所有镜像：

```bash
nerdctl image list
```

构建镜像：

```bash
nerdctl build -t <image> <dockerfile-directory>
```

下载镜像：

```bash
nerdctl pull <image>
```

导出镜像：

```bash
nerdctl save -o image_name.gz <image>
```

导入镜像：

```bash
nerdctl load -i image_name.gz
```


## ctr

<a target="_blank" rel="noopener noreferrer" href="https://github.com/containerd/containerd/tree/main/cmd/ctr">ctr</a> 是 containerd 项目自带的命令行工具。它基于 containerd API 运行，适用于管理 containerd 相关的任务、容器、镜像。

> ctr 命令的 “容器” 是一个静态的容器模板，定义了要运行的镜像和配置；“任务” 是一个容器运行的实例。

### namespace

> containerd 提供了一套完善的 <a target="_blank" rel="noopener noreferrer" href="https://github.com/containerd/containerd/blob/main/docs/namespaces.md">Namespaced API</a>（containerd namespace 与 K8s namespace 完全不相关），允许多个用户使用同一个 containerd 实例而不互相冲突。K8s CRI 默认使用 `k8s.io` namespace，而 Docker 默认使用 `moby` namespace。

查看所有 namespace：

```bash
ctr namespace ls
```

创建一个 namespace：

```bash
ctr namespace create <name>
```

> 注意：下文所有命令实际使用时都需要添加参数 `-n <namespace>` 来指定 namespace。

### 容器和任务

查看 namespace 中运行的所有任务：

```bash
ctr task list
```

查看 namespace 中所有容器模板：

```bash
ctr task list
```

创建任务来运行一个容器模板，需要存在相应的容器模板：

```bash
# 注：--detach 代表 detach from the task
ctr task start <container> --detach
```

在任务中执行命令，并为 exec 进程指定用户 ID：

```bash
ctr task exec --exec-id=0 <task> ls
```

查看任务指标：

```bash
ctr task metrics <task>
```

结束任务：

```bash
ctr task kill <task>
```

删除任务：

```bash
# 注意：删除之前需要先结束任务，或者使用 --force
ctr task rm <task>
```

### 镜像

查看 namespace 中所有镜像：

```bash
ctr image list
```

拉取镜像：

```bash
ctr image pull <image>
```

将镜像挂载到主机的目录上：

```bash
ctr image mount <image> ./mount
```

取消挂载：

```bash
ctr image unmount ./mount
```

## 参考

<https://github.com/kubernetes/cri-api>

<https://github.com/kubernetes-sigs/cri-tools/blob/master/docs/crictl.md>

<https://github.com/containerd/nerdctl>

<https://github.com/containerd/containerd/tree/main/cmd/ctr>

<https://kubernetes.io/docs/tasks/debug/debug-cluster/crictl/>
