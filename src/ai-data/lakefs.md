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
kubectl get pods -n t9k-system -l app=lakefs
```

```
NAME                              READY   STATUS    RESTARTS       AGE
aistore-lakefs-7d4d68d89c-5zvg4   1/1     Running   0              6d
```

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

查看 LakeFS 的配置：

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
        connection_string: "postgres://postgres:f2ddL6yMS4@aistore-postgresql.t9k-system:5432/lakefs"
    blockstore:
      type: s3
      s3:
        force_path_style: true
        endpoint: http://100.64.4.104
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
