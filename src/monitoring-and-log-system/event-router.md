# Event Router

Event Router 将集群中所有事件以日志形式，打印到标准输出中，将 Event 转换为 log，以便被集群的 logging 系统收集。

查看 Event Router 运行状态：

```bash
kubectl -n t9k-monitoring get deploy eventrouter
```

```
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
eventrouter   1/1     1            1           239d
```

Pod：

```bash
kubectl -n t9k-monitoring get pod -l app=eventrouter
```

```
NAME                           READY   STATUS    RESTARTS   AGE
eventrouter-5dfd7bbcb6-s7gq9   1/1     Running   0          2d
```

Event 被转换为 json，从 stdout 输出：

```bash
# 最新的 2 个 Events
kubectl logs -n t9k-monitoring -l app=eventrouter --tail=2 |jq
```

<details><summary><code class="hljs">output</code></summary>

```json
{
  "verb": "UPDATED",
  "event": {
    "metadata": {
      "name": "managed-explorer-codeserver-c9644-0.17cd82847da96f5f",
      "namespace": "demo",
      "uid": "43b06d05-aa4e-4ee9-80fa-a028655ea9f8",
      "resourceVersion": "931177370",
      "creationTimestamp": "2024-05-08T12:15:38Z",
      "managedFields": [
        {
          "manager": "kubelet",
          "operation": "Update",
          "apiVersion": "v1",
          "time": "2024-05-08T12:15:38Z"
        }
      ]
    },
    "involvedObject": {
      "kind": "Pod",
      "namespace": "demo",
      "name": "managed-explorer-codeserver-c9644-0",
      "uid": "75793111-b110-4723-a5de-a7b98d9b1f31",
      "apiVersion": "v1",
      "resourceVersion": "926283690",
      "fieldPath": "spec.containers{code-server}"
    },
    "reason": "Unhealthy",
    "message": "Readiness probe failed: HTTP probe failed with statuscode: 404",
    "source": {
      "component": "kubelet",
      "host": "nc07"
    },
    "firstTimestamp": "2024-05-08T12:15:38Z",
    "lastTimestamp": "2024-05-10T11:05:28Z",
    "count": 19096,
    "type": "Warning",
    "eventTime": null,
    "reportingComponent": "",
    "reportingInstance": ""
  },
  "old_event": {
    "metadata": {
      "name": "managed-explorer-codeserver-c9644-0.17cd82847da96f5f",
      "namespace": "demo",
      "uid": "43b06d05-aa4e-4ee9-80fa-a028655ea9f8",
      "resourceVersion": "931168681",
      "creationTimestamp": "2024-05-08T12:15:38Z",
      "managedFields": [
        {
          "manager": "kubelet",
          "operation": "Update",
          "apiVersion": "v1",
          "time": "2024-05-08T12:15:38Z"
        }
      ]
    },
    "involvedObject": {
      "kind": "Pod",
      "namespace": "demo",
      "name": "managed-explorer-codeserver-c9644-0",
      "uid": "75793111-b110-4723-a5de-a7b98d9b1f31",
      "apiVersion": "v1",
      "resourceVersion": "926283690",
      "fieldPath": "spec.containers{code-server}"
    },
    "reason": "Unhealthy",
    "message": "Readiness probe failed: HTTP probe failed with statuscode: 404",
    "source": {
      "component": "kubelet",
      "host": "nc07"
    },
    "firstTimestamp": "2024-05-08T12:15:38Z",
    "lastTimestamp": "2024-05-10T11:00:28Z",
    "count": 19062,
    "type": "Warning",
    "eventTime": null,
    "reportingComponent": "",
    "reportingInstance": ""
  }
}
{
  "verb": "UPDATED",
  "event": {
    "metadata": {
      "name": "cdi.17c79a6ac650e6c0",
      "namespace": "default",
      "uid": "60411b0c-0637-42d1-a0ad-f111a829307f",
      "resourceVersion": "931178624",
      "creationTimestamp": "2024-04-19T06:26:06Z",
      "managedFields": [
        {
          "manager": "cdi-operator",
          "operation": "Update",
          "apiVersion": "v1",
          "time": "2024-04-19T06:26:06Z"
        }
      ]
    },
    "involvedObject": {
      "kind": "CDI",
      "name": "cdi",
      "uid": "a700ed6c-a058-430c-8181-ae913acf810c",
      "apiVersion": "cdi.kubevirt.io/v1beta1",
      "resourceVersion": "781402391"
    },
    "reason": "CreateResourceSuccess",
    "message": "Successfully ensured SecurityContextConstraint exists",
    "source": {
      "component": "operator-controller"
    },
    "firstTimestamp": "2024-04-19T06:26:06Z",
    "lastTimestamp": "2024-05-10T11:06:12Z",
    "count": 23824,
    "type": "Normal",
    "eventTime": null,
    "reportingComponent": "",
    "reportingInstance": ""
  },
  "old_event": {
    "metadata": {
      "name": "cdi.17c79a6ac650e6c0",
      "namespace": "default",
      "uid": "60411b0c-0637-42d1-a0ad-f111a829307f",
      "resourceVersion": "931171588",
      "creationTimestamp": "2024-04-19T06:26:06Z",
      "managedFields": [
        {
          "manager": "cdi-operator",
          "operation": "Update",
          "apiVersion": "v1",
          "time": "2024-04-19T06:26:06Z"
        }
      ]
    },
    "involvedObject": {
      "kind": "CDI",
      "name": "cdi",
      "uid": "a700ed6c-a058-430c-8181-ae913acf810c",
      "apiVersion": "cdi.kubevirt.io/v1beta1",
      "resourceVersion": "781402391"
    },
    "reason": "CreateResourceSuccess",
    "message": "Successfully ensured SecurityContextConstraint exists",
    "source": {
      "component": "operator-controller"
    },
    "firstTimestamp": "2024-04-19T06:26:06Z",
    "lastTimestamp": "2024-05-10T11:02:09Z",
    "count": 23819,
    "type": "Normal",
    "eventTime": null,
    "reportingComponent": "",
    "reportingInstance": ""
  }
}
```

</details>
