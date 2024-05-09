# 事件控制器

创建一个 project 之后，Project 控制器会在相应的 namespace 中运行一个事件控制器以观测 project 中有关对象的变化，并产生相应的 K8s events。

## 运行状态

查看项目 demo 的 event-controller 的 logs：

```bash
kubectl -n demo logs -l app=event-controller --tail=100 -f
```

```
...
I1 10/09 16:52:19 controller.go:105 event-controller/workflowtemplates [start to watch] from=902283628
I1 10/09 16:58:25 controller.go:105 event-controller/notebooks [start to watch] from=454541178
...
```

监听会因为网络错误、链接超时等原因而中断，上述日志中 `event-controller/notebooks [start to watch] from=454541178` 表示事件控制器从 `454541178` 这个 resource version 开始继续监听 `notebooks` 资源，resource version 字段在资源定义中的位置如下：

```yaml
apiVersion: tensorstack.dev/v1beta1
kind: Notebook
metadata:
  creationTimestamp: "2023-10-18T06:09:49Z"
  generation: 3
  name: kaniko
  resourceVersion: "479109581"
  uid: 4c9ba5f8-08af-42ef-ac46-4d92a10a8cc2
```

## 配置

> 项目控制器中指定了事件控制器的 image 和配置，查看 [项目控制器的配置](./project-controller.md#配置)。


查看事件控制器（event controller）的配置（所有 project 的 event controller 配置一样）：

```bash
kubectl -n t9k-system get cm project-operator-event-ctl-config -o yaml
```

<details><summary><code class="hljs">cm-project-operator-event-ctl-config.yaml</code></summary>


```yaml
apiVersion: v1
data:
  config.json: |-
    {
      "resources": [
        {
          "group": "tensorstack.dev",
          "version": "v1beta1",
          "resource": "notebooks"
        },
        ...
      ]
    }
kind: ConfigMap
metadata:
  name: project-operator-event-ctl-config
  namespace: t9k-system
```

</details>

`config.json` 中 resources 的每一个元素都是事件控制器监控的一种资源，事件控制器会检测这些资源的变化，产生对应的事件（创建、删除等）。

运行下列命令可以修改事件控制器的配置文件：

```bash
kubectl -n t9k-system edit cm project-operator-event-ctl-config
```

如果需要添加新资源的监控，扩展 `config.json` 中的 resources 字段即可。如增加对 resource `imagebuilders.tensorstack.dev/v1beta1` 的监控：

```yaml
apiVersion: v1
data:
  config.json: |-
    {
      "resources": [
        {
          "group": "tensorstack.dev",
          "version": "v1beta1",
          "resource": "imagebuilders"
        },
        ...
      ]
    }
kind: ConfigMap
metadata:
  name: project-operator-event-ctl-config
  namespace: t9k-system
```

修改过配置后，需重新启动 Project 控制器使配置生效：

```bash
kubectl -n t9k-system rollout restart deploy/project-operator-controller-manager

# optionally, watch for restart process
kubectl -n t9k-system get pods -l control-plane=project-ctl -w
```
