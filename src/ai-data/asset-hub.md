# Asset-Hub

## 查看运行状态

查看 Asset Hub Web 和 Server 的运行状态：

```bash
$ kubectl get deploy -n t9k-system -l app=asset-hub-web
NAME            READY   UP-TO-DATE   AVAILABLE   AGE
asset-hub-web   1/1     1            1           26d
$ kubectl get deploy -n t9k-system -l app=asset-hub-server
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
asset-hub-server   1/1     1            1           26d
```

查看 Asset Hub Server 的日志：

```bash
$ kubectl logs -n t9k-system -l app=asset-hub-server -c asset-hub-server --tail=200 -f
[read client config] {Log:{V:4 LogColors:false ShowErrorTrace:true} Token:{JWKsURI:https://kc.kube.tensorstack.net/auth/realms/t9k-realm/protocol/openid-connect/certs UserKey:preferred_username} AIStore:http://aistore-server.t9k-system:8080}
[init logger] {V:4 LogColors:false ShowErrorTrace:true}
[new jwk client] jwks: https://kc.kube.tensorstack.net/auth/realms/t9k-realm/protocol/openid-connect/certs
[init kube config] config path: .kube/config
I3 10/11 09:25:23 aistore.go:22 security console/Init AIStore [Init AIStore] user=demo
I3 10/11 09:25:36 aistore.go:22 security console/Init AIStore [Init AIStore] user=demo
I0 10/11 09:33:54 asset_hub_components.go:52 security console [get component versions] component list={"Components":[{"Name":"AssetHub Web","Description":"AssetHub Web.","ObjectGroup":"apps","ObjectVersion":"v1","ObjectResource":"deployments","ObjectName":"asset-hub-web"},{"Name":"AssetHub Server","Description":"AssetHub Server.","ObjectGroup":"apps","ObjectVersion":"v1","ObjectResource":"deployments","ObjectName":"asset-hub-server"},{"Name":"Workflow","Description":"Operator for WorkflowTemplates and WorkflowRuns","ObjectGroup":"apps","ObjectVersion":"v1","ObjectResource":"statefulsets","ObjectName":"workflow-ctl"}]} ns=t9k-system result={"components":[{"name":"AssetHub Web","description":"AssetHub Web.","version":"1.77.2"},{"name":"AssetHub Server","description":"AssetHub Server.","version":"1.77.2"},{"name":"Workflow","description":"Operator for WorkflowTemplates and WorkflowRuns","version":"1.77.1"}]}
```

查看 Asset Hub Web 的日志 （日志目前为空）：

```bash
$ kubectl logs -n t9k-system -l app=asset-hub-web -c web-console --tail=200 -f
```

## 查看配置

查看 Asset Hub Server 的配置：

```bash
$ kubectl get cm -n t9k-system asset-hub-server-config -o yaml
```

编辑 Asset Hub Server 的配置：

```bash
$ kubectl edit cm -n t9k-system asset-hub-server-config
```

配置示例：

```yaml
apiVersion: v1
data:
  client-config.json: |-
    {
      "log": {
        "v": 4
      },
      "token": {
        "jwksURI": "https://auth.sample.t9kcloud.cn/auth/realms/t9k-realm/protocol/openid-connect/certs",
        "userKey": "preferred_username"
      },
      "aistore": "http://aistore-server.t9k-system:8080"
    }
kind: ConfigMap
metadata:
  name: asset-hub-server-config
  namespace: t9k-system
```

其中：

* log.v 表示日志级别，一般从 0 到 5，数字越大打印的日志越详细。
* token 字段用于声明如何解析用户身份令牌
    * jwksURI：提供 jwt 验证密钥的地址
    * userKey：在 Token 中，使用哪个字段表示用户 ID
* aistore：AIStore 服务器地址，参考[AIStore](./ai-store.md)
* 配置中所有信息，都可以通过配置文件、参数和环境变量三种方式设置，其优先级为参数 > 环境变量 > 配置文件。

在修改过配置后，需重启 Asset-Hub 服务使配置生效：

```bash
$ kubectl rollout restart -n t9k-system deploy/app=asset-hub-server
$ kubectl logs -n t9k-system -l app=asset-hub-server -c asset-hub-server --tail=200 -f
```
