# Istio


T9k 产品需要使用 Istio 的 routing API (e.g. Gateway, VirtualService) 以及 Knative 也依赖 Istio。

## 安装

文档 [Support status of Istio releases](https://istio.io/latest/docs/releases/supported-releases/#support-status-of-istio-releases) 记录了各个 Istio 版本兼容的 K8s 版本。

结合上述文档和之前的使用经验，我们提供以下安装建议：

* Kubernetes v1.22 到 v1.25，安装 Istio 1.15.2。
* Kubernetes v1.26 到 v1.28，安装 Istio 1.20.6。
* Kubernetes v1.29 到 v1.30，安装 Istio 1.23.0。

### 下载 istio

以安装 Istio 1.15.2 为例，其他版本的 Istio 安装只需要修改下载的 istioctl 版本即可。

```bash
cd ~/ansible/$T9K_CLUSTER

# online install, istio-1.15.2
curl -LO https://github.com/istio/istio/releases/download/1.15.2/istio-1.15.2-linux-amd64.tar.gz

# offline install, istio-1.15.2
cp ../ks-clusters/tools/offline-additionals/misc/istio-1.15.2-linux-amd64.tar.gz ./

tar zxvf istio-1.15.2-linux-amd64.tar.gz
cd istio-1.15.2
export PATH=$PWD/bin:$PATH
cd ..
```

再提供一个 Istio 1.20.6 的例子：

```bash
cd ~/ansible/$T9K_CLUSTER

# online install, istio-1.20.6
curl -LO https://github.com/istio/istio/releases/download/1.20.6/istio-1.20.6-linux-amd64.tar.gz

# offline install, istio-1.20.6
cp ../ks-clusters/tools/offline-additionals/misc/istio-1.20.6-linux-amd64.tar.gz ./

tar zxvf istio-1.20.6-linux-amd64.tar.gz
cd istio-1.20.6
export PATH=$PWD/bin:$PATH
cd ..
```

后续操作适用于不同版本的 Istio，不需要额外的修改。

### 修改配置

```bash
vim ../ks-clusters/additionals/istio/config.yaml
```

文件中的配置解释，参考 <a target="_blank" rel="noopener noreferrer" href="https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/">IstioOperator Options</a>：

1. `autoInject: disabled` 默认禁止自动注入 sidecar，仅在 Pod 或者 Pod 所在的 namespace 配置中要求了注入。我们不希望使用 istio 的 sidecar 注入功能。
1. `sidecarInjectorWebhook.enableNamespacesByDefault: false` 新创建的命名空间默认禁用自动注入。同上，我们不希望使用 istio 的 sidecar 注入功能。
1. `hub: docker.io/t9kpublic` 用于指定 docker image 的前缀。
1. `addonComponents.pilot.enabled: true` 启用 Pilot 组件。Pilot 负责管理和配置所有的 Istio 服务网格。
1. `components.ingressGateways` 定义了一个名为 istio-ingressgateway 的 ingress gateway，用于从服务网格外部访问内部服务。

<aside class="note">
<div class="title">离线安装</div>

如果采用本地容器镜像服务器，需要修改镜像仓库的设置：

```bash
# for example, using 192.168.101.159:5000/t9kpublic as registry
sed -i "s|hub: docker.io/t9kpublic|hub: 192.168.101.159:5000/t9kpublic|g" \
  ../ks-clusters/additionals/istio/config.yaml
```
</aside>

### 启动安装

```bash
istioctl install -f ../ks-clusters/additionals/istio/config.yaml
```
istioctl install 过程中会自动检查对应的 Pod 存在，且处于正常的 running 状态：

```console
This will install the Istio 1.15.2 default profile with ["Istio core" "Istiod" "Ingress gateways"] components into the cluster. Proceed? (y/N) y
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ Installation complete
```

## 验证

进一步检查 logs：

```bash
# inspect logs
# warning: logs can be very long
kubectl -n istio-system logs -l app=istiod --tail=-1 -f

# warning: logs can be very long
kubectl -n istio-system logs -l app=istio-ingressgateway --tail=-1 -f
```

检查 injection policy 配置：

```bash
# default injection policy 
kubectl -n istio-system get configmap istio-sidecar-injector \
  -o jsonpath='{.data.config}' | grep policy:
```

输出：

```console
policy: disabled
```

检查 `rewriteAppHTTPProbe` 设置：

```bash
# side-car injector
kubectl -n istio-system get cm istio-sidecar-injector -o jsonpath='{.data.values}' \
  | grep rewriteAppHTTPProbe
```
输出：

```console
    "rewriteAppHTTPProbe": true,
```

<aside class="note">
<div class="title">注意</div>


在 ConfigMap istio-sidecar-injector 中，我们关心下面这两个配置参数：

1. `.data.config` 中的 `policy`：
    1. 值应该是 `disabled；`
    1. 意义：控制 sidecar injection 的 default policy，影响 istio sidecar-injection-webhook 是否为 Pod 注入 sidecar container；
    1. 参考 <a target="_blank" rel="noopener noreferrer" href="https://istio.io/v1.1/help/ops/setup/injection/#:~:text=Check%20default%20policy">Check default policy</a>；
1. `.data.values` 中的 `rewriteAppHTTPProbe`：
    1. 值应该是 `true`
    1. 意义：`rewriteAppHTTPProbe` 是 `true` 时，被注入 sidecar container 的 Pod 的 readiness/liveness probe 字段会被 istio 重写，使得 probe request 被发送到 sidecar agent。
    1. 参考：<a target="_blank" rel="noopener noreferrer" href="https://istio.io/latest/docs/ops/configuration/mesh/app-health-check/">Health Checking of Istio Services</a>

</aside>

```bash
# TODO: 其他 cm，命令行参数等
kubectl -n istio-system  get cm
```

输出：

```console
NAME                                  DATA   AGE
istio                                 2      225d
istio-ca-root-cert                    1      225d
istio-gateway-deployment-leader       0      225d
istio-gateway-leader                  0      225d
istio-gateway-status-leader           0      225d
istio-leader                          0      225d
istio-namespace-controller-election   0      225d
istio-sidecar-injector                2      225d
kube-root-ca.crt                      1      225d
```

## 参考

<https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/>
