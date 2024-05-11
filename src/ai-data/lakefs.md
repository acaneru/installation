# LakeFS

## 查看运行状态

运行状态：

```bash
kubectl get deploy -n t9k-system aistore-lakefs
```

```
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
aistore-lakefs   1/1     1            1           6d
```

```bash
kubectl get svc,pods -n t9k-system -l app=lakefs
```

```
NAME                     TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/aistore-lakefs   ClusterIP   10.233.49.231   <none>        80/TCP    6d

NAME                                  READY   STATUS    RESTARTS       AGE
pod/aistore-lakefs-7d4d68d89c-5zvg4   1/1     Running   0              6d
```


Ingress：

```bash
kubectl -n t9k-system get ing  aistore-lakefs -o yaml
```

<details><summary><code class="hljs">output</code></summary>

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: aistore-lakefs
  namespace: t9k-system
spec:
  rules:
  - host: <YOUR-DNS>
    http:
      paths:
      - backend:
          service:
            name: aistore-lakefs
            port:
              number: 80
        pathType: ImplementationSpecific
  tls:
  - hosts:
    - <YOUR-DNS>
    secretName: <SECRET-NAME>
```

</details>


日志：

```bash
kubectl logs -n t9k-system -l app=lakefs --tail=100 -f
```

<details><summary><code class="hljs">output</code></summary>

```
...
time="2023-10-11T09:21:33Z" level=info msg="Configuration file" func=github.com/treeverse/lakefs/cmd/lakefs/cmd.initConfig file="/build/cmd/lakefs/cmd/root.go:80" fields.file=/etc/lakefs/config.yaml file="/build/cmd/lakefs/cmd/root.go:80" phase=startup
time="2023-10-11T09:21:33Z" level=info msg="Config loaded" func=cmd/lakefs/cmd.initConfig file="cmd/root.go:122" fields.file=/etc/lakefs/config.yaml file="cmd/root.go:122" phase=startup
time="2023-10-11T09:21:33Z" level=info msg=Config func=cmd/lakefs/cmd.initConfig file="cmd/root.go:130" actions.enabled=true auth.api.endpoint="" auth.api.supports_invites=false
...
```


</details>

## 查看配置

命令行参数、环境变量：

```bash
kubectl get deploy -n t9k-system aistore-lakefs -o jsonpath="{.spec.template.spec.containers[0]['args', 'env']}"  |jq
```


<details><summary><code class="hljs"> args and env</code></summary>

```json
[
  "run",
  "--config",
  "/etc/lakefs/config.yaml"
]
[
  {
    "name": "LAKEFS_AUTH_ENCRYPT_SECRET_KEY",
    "value": "XXXXXXXXXXXXXXXXXX"
  }
]
```

> 其中 `LAKEFS_AUTH_ENCRYPT_SECRET_KEY` 是加密用的 key。参考：<a target="_blank" rel="noopener noreferrer" href="https://docs.lakefs.io/reference/configuration.html#:~:text=auth.encrypt.secret_key">lakeFS Server Configuration</a>

</details>

配置文件：

```bash
kubectl get cm -n t9k-system aistore-lakefs -o yaml
```

<details><summary><code class="hljs">配置示例：cm-aistore-lakefs.yaml</code></summary>

```yaml
apiVersion: v1
data:
  config.yaml:
  |
    database:
      type: postgres
      postgres: 
        connection_string: "postgres://postgres:XXXXXXXX@aistore-postgresql.t9k-system:5432/lakefs"
    blockstore:
      type: s3
      s3:
        force_path_style: true
        endpoint: http://100.64.24.104
        discover_bucket_region: false
        credentials:
          access_key_id: <xxxxxxxxx>
          secret_access_key: <yyyyyyyyyyyyyyy>
kind: ConfigMap
metadata:
  name: aistore-lakefs
  namespace: t9k-system
```
</details>


## 参考

<https://docs.lakefs.io/>

<https://docs.lakefs.io/reference/configuration.html>
