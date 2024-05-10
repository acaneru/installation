# Event Controller

Event controller 负责监听系统中一些资源的生命周期变化，然后生成相应的 Events，以方便在前端展示、Event Router 收集等。

### 查看配置

在 project-operator-event-ctl-config 中配置 Event Controller 要监控的集群资源，通过以下命令查看 Event Controller 配置：

```bash
kubectl -n t9k-system get configmap project-operator-event-ctl-config -o yaml
```

### 修改配置

```bash
kubectl edit configmap -n t9k-system project-operator-event-ctl-config
```

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
```

配置修改后，需要重启 project operator 使配置生效：

```bash
kubectl -n t9k-system rollout restart deploy/project-operator-controller-manager 
```

查看 Pod：

```
kubectl -n t9k-system get pod -l control-plane=project-ctl -w
```

确认 log 正常：

```bash
kubectl -n t9k-system logs -l control-plane=project-ctl -f
```
