# 项目资源配额

通过设置项目（Project）资源配额，管理员可以限制该项目中可使用的计算资源（CPU, Memory, GPU, 存储等） 上限。

<aside class="note info">
<div class="title">信息</div>

管理员在 `Project` 中支持设置资源配额，Project 控制器（controller） 则负责具体实施这些配置。

查看详情： [项目控制器](./appendix/project-controller.md)。

</aside>



## 设置配额

Project 的资源配额可通过两种方式设置：

1. 直接设置 `.spec.resourceQuota` 字段
1. 通过设置 `.spec.quotaProfile` 字段，间接设置项目的 `.spec.resourceQuota` 字段

设置后实时生效：

* `.spec.quotaProfile`：
    * 当 Project 通过 `.spec.quotaProfile` 字段引用一个 Quota Profile，Project 控制器查看 QuotaProfile 中记录的资源配额，并将 Project `.spec.resourceQuota` 的资源配额设置为该值。
    * 若 Quota Profile 发生改变，则 Project 控制器会列举所有引用该 Quota Profile 的 Project，修改对应的 Project `.spec.resourceQuota`。
* `.spec.resourceQuota`：
    * Project 控制器观测这个字段的变化，并实时创建/修改对应的 <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/concepts/policy/resource-quotas/">Resource Quotas</a> objects。
    * K8s 系统的 <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/tasks/administer-cluster/quota-api-object/">ResourceQuota admission plugins 具体负责保证</a>一个这个 Resource Quota objects 的设置被实施。

### resourceQuota

查看 Project CRD 实例（和 project/namespace 同名）：

> Info: Project is a namespace scoped resource.

```bash
kubectl -n demo get project demo -o yaml
```

<details><summary><code class="hljs">demo.yaml</code></summary>

```yaml
apiVersion: tensorstack.dev/v1beta1
kind: Project
metadata:
  name: demo
spec:
  defaultScheduler:
    t9kScheduler:
      queue: default
  quotaProfile: demo
  resourceQuota:
    template:
      spec:
        hard:
          cpu: "200"
          memory: 1Ti
          nvidia.com/gpu: "16"
          persistentvolumeclaims: "20"
          pods: "100"
```

</details>

### quotaProfile

CRD QuotaProfile 是资源配额模版，可用于批量修改项目的资源配额，其 spec 字段设置方式与 Resource Quota 相同，请参考 <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/concepts/policy/resource-quotas/">Resource Quota 文档</a>。

> QuotaProfile is a namespaced resource and created in namespace 't9k-system'

```bash
kubectl -n t9k-system get quotaprofile demo -o yaml
```
<details><summary><code class="hljs">demo-quota.yaml</code></summary>

```yaml
apiVersion: tensorstack.dev/v1beta1
kind: QuotaProfile
metadata:
  name: demo-quota
  namespace: t9k-system
spec:
  hard:
    cpu: "200"
    memory: 1Ti
    nvidia.com/gpu: "16"
    persistentvolumeclaims: "20"
    pods: "1000"
```

</details>

```bash
kubectl -n demo get project demo -o yaml
```

<details><summary><code class="hljs">demo.yaml</code></summary>

```yaml
# project demo
apiVersion: tensorstack.dev/v1beta1
kind: Project
metadata:
  name: demo-project
spec:
  defaultScheduler:
    t9kScheduler:
      queue: default
  quotaProfile: demo-quota
  resourceQuota:
    template:
      spec:
        hard:
          cpu: "200"
          memory: 1Ti
          nvidia.com/gpu: "16"
          persistentvolumeclaims: "20"
          pods: 1k
```

</details>

如上述内容，当 Quota Profile demo-quota 中记录的资源配额发生改变，Project demo-project 会立刻修改 `.spec.resourceQuota` 字段，调整资源配额。

## ResourceQuota

无论是 `spec.resourceQuota` 或者 `quotaProfile`，这些设置最终体现在 `v1/ResourceQuota` objects:

```bash
kubectl -n demo get resourcequota demo -o yaml
```

<details><summary><code class="hljs">demo-resourcequota.yaml</code></summary>

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: demo
  namespace: demo
...
spec:
  hard:
    cpu: "200"
    memory: 1Ti
    nvidia.com/gpu: "16"
    persistentvolumeclaims: "20"
    pods: 1k
status:
  hard:
    cpu: "200"
    memory: 1Ti
    nvidia.com/gpu: "16"
    persistentvolumeclaims: "20"
    pods: 1k
  used:
    cpu: 3110m
    memory: 7244Mi
    persistentvolumeclaims: "11"
    pods: "9"
```

</details>

## 参考

<https://kubernetes.io/docs/concepts/policy/resource-quotas/>
