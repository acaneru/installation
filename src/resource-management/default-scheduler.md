# 默认调度器

在 Kubernetes 中，调度是指将 Pod 放置到合适的节点上，以便对应节点上的 [Kubelet](https://kubernetes.io/docs/reference/command-line-tools-reference/kubelet/) 能够运行这些 Pod。Kubernetes 集群的默认调度器是 [kube-scheduler](https://kubernetes.io/zh-cn/docs/concepts/scheduling-eviction/kube-scheduler/#kube-scheduler)。

## 工作原理

kube-scheduler 每次调度一个 Pod 的尝试都分为[两个阶段](https://kubernetes.io/zh-cn/docs/concepts/scheduling-eviction/scheduling-framework/#scheduling-cycle-and-binding-cycle)：
1. 调度阶段：执行下列步骤，为 Pod 选择一个最适合的节点。
    1. 过滤：将所有满足 Pod 调度需求的节点选出来，这些节点称为可调度节点。如果没有节点满足需求，则无法调度 Pod，Pod 会保持在 Pending 状态，直到集群中有节点可以满足 Pod 的调度需求。
    2. 打分：为每一个可调度节点打分，分数越高，则更加适合当前 Pod。
2. 绑定阶段：将步骤 1 得出的调度决定通知给 kube-apiserver，然后 Pod 会被集群分配到目标节点上运行。

## 调度器配置

kube-scheduler 的调度行为是通过一系列的扩展点 ([扩展点列表](https://kubernetes.io/zh-cn/docs/reference/scheduling/config/#extensions-points)) 实现的，用户可以配置调度器在每个扩展点可以使用哪些插件（[默认插件列表](https://kubernetes.io/zh-cn/docs/reference/scheduling/config/#scheduling-plugins)），从而可以控制调度器的行为。

调度器的配置文件通常放置在集群的 Master 节点主机上的 `/etc/kubernetes/kubescheduler-config.yaml` 文件中，你可以查看 Pod kube-scheduler YAML 的命令行参数 --config 来确定配置文件路径。

配置示例：
```yaml
apiVersion: kubescheduler.config.k8s.io/v1
kind: KubeSchedulerConfiguration
profiles:
- plugins:
   score:
     disabled:
     - name: PodTopologySpread
     enabled:
     - name: MyCustomPluginA
       weight: 2
     - name: MyCustomPluginB
       weight: 1
```

在上述配置中，禁用了扩展点 score 的插件 PodTopologySpread，新增了插件 MyCustomPluginA 和 MyCustomPluginB，并且他们对 score 扩展点的影响权重分布是 2 和 1。

更多请见 [Kubernetes 文档](https://kubernetes.io/zh-cn/docs/reference/scheduling/config/)

## Coscheduling

coscheduling 代表同时调度一组 Pod 使他们可以一起执行。在某些场景下，用户部署多个 Pod 需要同时协作以完成任务，缺少任何一个 Pod 都会导致任务无法进行，此时 coscheduling 可以避免只有部分 Pod 被分配资源却无法完成工作，从而浪费资源的情况。

默认调度器原生并不支持 coscheduling，如果你想启用 coscheduling 功能，你需要参考下列步骤来安装 scheduler-plugins：
1. 查看[版本兼容](https://github.com/kubernetes-sigs/scheduler-plugins/tree/v0.28.9?tab=readme-ov-file#compatibility-matrix)，选择兼容的 scheduler-plugins 版本
2. 参考[安装文档](https://github.com/kubernetes-sigs/scheduler-plugins/blob/v0.28.9/doc/install.md#install-release-v0288-and-use-coscheduling)，安装 scheduling-plugins
3. [测试 coscheduling](https://github.com/kubernetes-sigs/scheduler-plugins/blob/v0.28.9/doc/install.md#test-coscheduling)

## 设置节点污点

节点污点（taints）的作用是避免不适合的 Pod 被分配到这个节点上。只有容忍度（tolerations）与节点污点相匹配的 Pod 可以被分配到节点上。

管理员可以使用下列命令给节点增加一个污点：
```bash
kubectl taint nodes node1 key1=value1:NoSchedule
```

上述命令给节点 node1 增加一个污点，它的键名是 key1，键值是 value1，效果是 NoSchedule。 这表示只有拥有和这个污点相匹配的容忍度的 Pod 才能够被分配到 node1 这个节点。

节点 node1 会增加下列字段：
```yaml
spec:
  taints:
  - effect: NoSchedule
    key: key1
    value: value1
```

## 参考

* [kube-scheduler](https://kubernetes.io/zh-cn/docs/concepts/scheduling-eviction/kube-scheduler/#kube-scheduler)
* [kube-scheduler 配置](https://kubernetes.io/zh-cn/docs/reference/scheduling/config/)
* [coscheduling](https://github.com/kubernetes-sigs/scheduler-plugins/blob/v0.28.9/pkg/coscheduling/README.md)