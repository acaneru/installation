# Cost Web

## 查看运行状态

运行状态：

```bash
kubectl get pod -n t9k-system -l app=cost-web
```

```
NAME                        READY   STATUS    RESTARTS   AGE
cost-web-7b899f4b8c-jkhnk   2/2     Running   0          3d22h
```

## 查看配置

查看配置：

```bash
kubectl get cm -n t9k-system t9k-cost-web -o yaml
```

修改配置：

```bash
kubectl edit cm -n t9k-system t9k-cost-web
```

<details><summary><code class="hljs">配置示例：cm-t9k-cost-web.yaml</code></summary>

```yaml
apiVersion: v1
data:
  cost-web-config.json: |-
    {
      "currencySign": "¥",
      "billingStartTime": "2023-01-01T00:00:00+08:00"
    }
kind: ConfigMap
metadata:
  name: t9k-cost-web
  namespace: t9k-system
```

</details>

其中：

* `currencySign` 字段表示货币符号，价格和费用的货币单位均使用该符号进行标识。
* `billingStartTime` 字段表示计费开始时间，通常指计费系统安装生效的时间，用户在查询费用时起始时间不得早于该时间。

一般只有在安装时需要修改 `billingStartTime` 字段。

修改配置后，需重启 Cost Web 服务使配置生效：

```bash
kubectl rollout restart -n t9k-system deploy/cost-web
```
