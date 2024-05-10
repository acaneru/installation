# AIStore

## 查看运行状态

运行状态：

```bash
kubectl get deploy -n t9k-system aistore-server
```

```
NAME             READY   UP-TO-DATE   AVAILABLE   AGE
aistore-server   1/1     1            1           6d
```

```bash
kubectl get pods -n t9k-system -l app=aistore-server
```

```
NAME                              READY   STATUS    RESTARTS   AGE
aistore-server-747d84854f-hc9nq   2/2     Running   0          6d
```

日志：

```bash
kubectl logs -n t9k-system -l app=aistore-server -c aistore-server --tail=100 -f
```

<details><summary><code class="hljs">output</code></summary>

[read client config] {Log:{V:4 LogColors:false ShowErrorTrace:true} Postgres:{Host:aistore-postgresql.t9k-system Database:aistore Port:5432 User:postgres Password:******} LakeFS:{ServiceName:aistore-lakefs Address: Bucket:t9k-aistore-new AccessID:****** SecretKey:****** UnderlyingAddress:http://100.64.4.104 UnderlyingAccessID:****** UnderlyingSecretKey:****** ExternalAddress:https://lakefs.nc201.t9kcloud.cn} Token:{JWKsURI:https://kc.kube.tensorstack.net/auth/realms/t9k-realm/protocol/openid-connect/certs UserKey:******} SysNamespace:t9k-system}
[init logger] {V:4 LogColors:false ShowErrorTrace:true}
[new jwk client] jwks: https://kc.kube.tensorstack.net/auth/realms/t9k-realm/protocol/openid-connect/certs
[create sql client] {Host:aistore-postgresql.t9k-system Database:aistore Port:5432 User:postgres Password:******}
[get lakefs address in cluster] http://10.233.49.231:80
[create lakeFS client] {ServiceName:aistore-lakefs Address:http://10.233.49.231:80 Bucket:t9k-aistore-new AccessID:****** SecretKey:****** UnderlyingAddress:http://100.64.4.104 UnderlyingAccessID:****** UnderlyingSecretKey:****** ExternalAddress:https://lakefs.nc201.t9kcloud.cn}
I0 12/26 03:02:22 client.go:185 aistore/LakeFS [underlying s3 bucket already exists] bucket=t9k-aistore-new
I4 12/26 03:02:22 logger.go:28 aistore/LakeFS [LakeFS Request] method=GET reqHeader.Authorization=Basic QUtJQUpHQ1RIVTVTVEY2Q09SS1E6TG43RHZoSlhrUDFrRFRsVThNYWV2YXRUaVlQWWhZUlhQNXdUSEorbA== reqHeader.User-Agent=gentleman/2.0.5 resHeader.Content-Length=127 resHeader.Content-Type=application/json resHeader.Date=Tue, 26 Dec 2023 03:02:22 GMT resHeader.X-Content-Type-Options=nosniff resHeader.X-Request-Id=b55b9f59-031b-403d-9aec-75f9fa160b34 url={"Scheme":"http","Opaque":"","User":null,"Host":"10.233.49.231:80","Path":"/api/v1/repositories/t9k-aistore","RawPath":"","ForceQuery":false,"RawQuery":"","Fragment":"","RawFragment":""}
I0 12/26 03:02:22 client.go:128 aistore/LakeFS [global repository already exists] repository={"creation_date":1697014131,"default_branch":"main","id":"t9k-aistore","storage_namespace":"s3://t9k-aistore-new/t9k-aistore"}
...
```

</details>

## 查看配置

查看 AI-Store 的配置：

```bash
$ kubectl get cm -n t9k-system aistore-server-config -o yaml
```

修改 AI-Store 的配置：

```bash
$ kubectl edit cm -n t9k-system aistore-server-config
```

配置示例：

```yaml
apiVersion: v1
data:
  server-config.json: |-
    {
      "log": {
        "v": 4
      },
      "postgres": {
        "host": "aistore-postgresql.t9k-system",
        "port": "5432",
        "database": "aistore",
        "user": "postgres",
        "password": "f2ddL6yMS4"
      },
      "lakefs":{
        "serviceName": "aistore-lakefs",
        "externalAddress": "https://lakefs.nc201.t9kcloud.cn",
        "bucket": "t9k-aistore-new",
        "accessID": "<xxxxxxxxxxxxxx>",
        "secretKey": "<yyyyyyyyyyyyyy>",
        "underlyingAddress": "http://100.64.4.104",
        "underlyingAccessID": "<aaaaaaaaaaaaaaaaa>",
        "underlyingSecretKey": "<bbbbbbbbbbbbbbbbbbbbbb>"
      },
      "token": {
        "jwksURI": "https://kc.kube.tensorstack.net/auth/realms/t9k-realm/protocol/openid-connect/certs",
        "userKey": "preferred_username"
      }
    }
kind: ConfigMap
metadata:
  name: aistore-server-config
  namespace: t9k-system
```

其中：

* log 字段表示日志级别，一般从 0 到 5，数字越大打印的日志越详细。
* postgres 字段表示 AIStore 连接底层 PostgreSQL 数据库时所需要的信息。
* lakefs 字段表示 AIStore 连接 LakeFS 以及 LakeFS 底层的 S3 服务时需要的信息。
* token 字段表示校验用户信息时需要的配置。
* 配置中所有信息，都可以通过配置文件、参数和环境变量三种方式设置，其优先级为 参数 > 环境变量 > 配置文件。

一般只有 log 字段需要修改。

在修改过配置后，需重启 AIStore 服务使配置生效：

```bash
$ kubectl rollout restart -n t9k-system deploy/aistore-server
$ kubectl logs -n t9k-system -l app=aistore-server -c aistore-server --tail=-1 -f
```
