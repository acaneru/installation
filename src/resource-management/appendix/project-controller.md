# 项目控制器

项目控制器 (Project Controller）负责监听每个 Project 的 `spec`，如 Network Policy，Resource Quota 等的设置，然后自动化的生成对应的资源以实施这些配置。

## 运行状态

```bash
kubectl -n t9k-system get pods -l tensorstack.dev/component=project
```

```
NAME                                                   READY   STATUS    RESTARTS   AGE
project-operator-controller-manager-74c9568997-dbmqt   1/1     Running   0          5d
```

查看 logs：

```
kubectl -n t9k-system logs -l tensorstack.dev/component=project -f
```

<details><summary><code class="hljs">output</code></summary>

```
I1 05/09 17:32:56 project_controller.go:93 project-operator/project-controller [reconcile project] name=hfc
I1 05/09 17:32:56 controller.go:270 project-operator/controller [Successfully Reconciled] controller=project name=hfc namespace=hfc reconcilerGroup=tensorstack.dev reconcilerKind=Project
I1 05/09 17:32:56 project_controller.go:93 project-operator/project-controller [reconcile project] name=skj-test
I1 05/09 17:32:56 controller.go:270 project-operator/controller [Successfully Reconciled] controller=project name=skj-test namespace=skj-test reconcilerGroup=tensorstack.dev reconcilerKind=Project...
```

</details>

## 配置

执行以下命令，查看项目控制器（Project controller）的 deployment：

```bash
kubectl -n t9k-system get deploy project-operator-controller-manager   \
  -o jsonpath-as-json='{.spec.template.spec.containers[].args}'
```

```json
[
    [
        "--health-probe-bind-address=:8081",
        "--metrics-bind-address=0.0.0.0:8080",
        "--leader-elect",
        "--show-error-trace",
        "--v=3",
        "--event-ctl-image=t9kpublic/event-controller:1.79.0",
        "--event-ctl-config=/event-ctl/config.json",
        "--quota-warning-percentage=80",
        "--disable-cert-rotation=false"
    ]
]
```

参数说明：

* `health-probe-bind-address`：服务健康检查 API 的地址，请勿修改；
* `metrics-bind-address`：服务指标 API 的地址，请勿修改；
* `leader-elect`：控制器使用 “选举机制”，用于避免运行多个实例控制器时导致对同一个资源事件的重复处理；
* `show-error-trace` 和 `v` ：日志设置，分别是打印 error 的产生途径、日志等级；
* `event-ctl-image` 和 `event-ctl-config`：项目控制器会在每一个项目中会创建一个事件控制器，来收集当前项目下的资源变化。这两个字段为事件控制器配置，分别指定事件控制器的镜像和配置文件；
* `quota-warning-percentage`：资源配额警告水位线，该实例中当资源使用量达到配额的 80% 以上时，会在项目状态中提示“资源使用量过高”的信息，该参数的取值范围是 [0, 100]；
* `disable-quota-profile`：禁用 QuotaProfile；
* `disable-cert-rotation`：
    * `false`，默认值，此时 cert-rotation 负责自动管理生成 webhook 的 ssl 证书，并正确设置 validatingwebhookconfiguration
    * `true`，表明禁用 cert-rotation，管理员需要改用其他方式来管理 webhook 的 ssl 证书，并需要正确配置 validatingwebhookconfiguration。


> TODO: Clarify args: disable-quota-profile, leader-elect, show-error-trace.

