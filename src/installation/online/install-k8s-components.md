# 安装 K8s 组件

## Istio

### 依赖

T9k 产品需要使用 Istio 的 routing 功能 （e.g. Gateway, VirtualService）以及 Knative 会依赖 Istio。

### 安装

根据 Support status of Istio releases 以及之前的使用经验，这里我们选择安装 Istio-1.15.2。

下载 istio 命令行工具：

```bash
$ cd ~/ansible/$T9K_CLUSTER

# online install
$ curl -LO \
https://github.com/istio/istio/releases/download/1.15.2/istio-1.15.2-linux-amd64.tar.gz

# offline install
$ cp ../ks-clusters/tools/offline-additionals/misc/istio-1.15.2-linux-amd64.tar.gz ./

$ tar zxvf istio-1.15.2-linux-amd64.tar.gz
$ cd istio-1.15.2
$ export PATH=$PWD/bin:$PATH
$ cd ..
```

[离线安装场景] 修改镜像仓库的设置：

```bash
# for example, using 192.168.101.159:5000/t9kpublic as registry
$ sed -i "s|hub: docker.io/t9kpublic|hub: 192.168.101.159:5000/t9kpublic|g" \
    ../ks-clusters/additionals/istio/config.yaml
```

安装 istio：

```bash
$ istioctl install -f ../ks-clusters/additionals/istio/config.yaml
```

文件中的配置解释（参考 IstioOperator Options）：

1. `autoInject: disabled` 默认禁止自动注入 sidecar，仅在 Pod 或者 Pod 所在的 namespace 配置中要求了注入。我们不希望使用 istio 的 sidecar 注入功能。
1. `sidecarInjectorWebhook.enableNamespacesByDefault: false` 新创建的命名空间默认禁用自动注入。同上，我们不希望使用 istio 的 sidecar 注入功能。
1. `hub: docker.io/t9kpublic` 用于指定 docker image 的前缀。
1. `addonComponents.pilot.enabled: true` 启用 Pilot 组件。Pilot 负责管理和配置所有的 Istio 服务网格。
1. `components.ingressGateways` 定义了一个名为 istio-ingressgateway 的 ingress gateway，用于从服务网格外部访问内部服务。

### 验证

istioctl install 过程中会自动检查对应的 Pod 存在，且处于正常的 running 状态：

```bash
$ istioctl install -f ../ks-clusters/additionals/istio/config.yaml
This will install the Istio 1.15.2 default profile with ["Istio core" "Istiod" "Ingress gateways"] components into the cluster. Proceed? (y/N) y
✔ Istio core installed
✔ Istiod installed
✔ Ingress gateways installed
✔ Installation complete
```

进一步检查 logs：

```bash
# inspect logs; logs can be very long
$ kubectl -n istio-system logs -l app=istiod --tail=-1 -f

# warning: logs can be very long
$ kubectl -n istio-system logs -l app=istio-ingressgateway --tail=-1 -f
```

检查配置：

```bash
# default injection policy 
$ kubectl -n istio-system get configmap istio-sidecar-injector \
  -o jsonpath='{.data.config}' | grep policy:


policy: disabled

# side-car injector
$ kubectl -n istio-system get cm istio-sidecar-injector -o jsonpath='{.data.values}' \
  | grep rewriteAppHTTPProbe

    "rewriteAppHTTPProbe": true,
```

在 ConfigMap istio-sidecar-injector 中，我们关心下面这两个配置参数：

1. .data.config 中的 policy：
    1. 值应该是 disabled；
    1. 意义：控制 sidecar injection 的 default policy，影响 istio sidecar-injection-webhook 是否为 Pod 注入 sidecar container；
    1. 参考 <a target="_blank" rel="noopener noreferrer" href="https://istio.io/v1.1/help/ops/setup/injection/#:~:text=Check%20default%20policy">check default policy</a>；
1. .data.values 中的 rewriteAppHTTPProbe：
    1. 值应该是 true
    1. 意义：rewriteAppHTTPProbe 是 true 时，被注入 sidecar container 的 Pod 的 readiness/liveness probe 字段会被 istio 重写，使得 probe request 被发送到 sidecar agent。
    1. 参考：<https://istio.io/latest/docs/ops/configuration/mesh/app-health-check/>

```bash
# TODO: 其他 cm，命令行参数等
$ kubectl -n istio-system  get cm
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

## Knative

安装 Knative，版本 v1.9.0

### 前置条件

* Kubernetes 集群版本：v1.25.9
* <a target="_blank" rel="noopener noreferrer" href="https://istio.io/">Istio</a>，v1.15.2
* <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.github.io/ingress-nginx/deploy/">NGINX Ingress Controller</a>，v1.7.1

参考 knative <a target="_blank" rel="noopener noreferrer" href="https://knative.dev/docs/install/yaml-install/serving/install-serving-with-yaml/">Install Serving with YAML</a>

### 安装

[离线安装场景] 修改镜像仓库的设置：

```bash
# verify t9kpublic is only used in image name
$ grep t9kpublic ../ks-clusters/additionals/knative/v1.9.0/*
# replace image
$ sed -i "s|t9kpublic|192.168.101.159:5000/t9kpublic|g" \
    ../ks-clusters/additionals/knative/v1.9.0/*
```

运行以下命令在 K8s 集群中安装 Knative：

```bash
$ kubectl apply -f ../ks-clusters/additionals/knative/v1.9.0/serving-crds.yaml
$ kubectl apply -f ../ks-clusters/additionals/knative/v1.9.0/serving-core.yaml
$ kubectl apply -f ../ks-clusters/additionals/knative/v1.9.0/net-istio.yaml
```

### 修改 config

修改 knative config-domain 来配置 DNS 的 domain suffix。

下面的示例会将 domain suffix 设置为 `ksvc.sample.t9kcloud.cn`。

```bash
kubectl patch configmap/config-domain \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ksvc.sample.t9kcloud.cn":""}}'
```

[离线安装场景] 如果你使用的是基于 HTTP 的镜像仓库，则还需要添加设置：

```bash
kubectl patch configmap/config-deployment \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"registries-skipping-tag-resolving":"192.168.101.159:5000"}}'
```

### 配置 Ingress

创建如下所示的 Ingress，需要注意：

1. spec.rules[0].host 应该与前述步骤的 domain suffix 一致。
1. 需要配置 DNS，让 `*.ksvc.sample.t9kcloud.cn` 能够映射到 ingress 所在的节点的 IP。

```bash
kubectl -n istio-system create -f ../ks-clusters/additionals/knative/v1.9.0/ingress.yaml

# verify it's there
$ kubectl -n istio-system get ing/t9k.serving
```

### 验证

确认 pods running：

```bash
$ kubectl -n knative-serving get pods
NAME                                     READY   STATUS    RESTARTS   AGE
activator-5cc89f4c4d-w6hdz               1/1     Running   0          6m44s
autoscaler-6fb596f4bb-vw4q8              1/1     Running   0          6m44s
controller-6b5874c54-j5gc4               1/1     Running   0          6m44s
domain-mapping-5b6c878f85-v7zqs          1/1     Running   0          6m43s
domainmapping-webhook-59f98dc77b-6rtbp   1/1     Running   0          6m42s
net-istio-controller-777b6b4d89-j7qg4    1/1     Running   0          6m33s
net-istio-webhook-78665d59fd-86kxq       1/1     Running   0          6m33s
webhook-79f8449d8f-8cdc7                 1/1     Running   0          6m40s
```

创建一个 knative service 进行测试：

```bash
$ kubectl -n default create -f ../ks-clusters/additionals/knative/v1.9.0/hello-ksvc.yaml
```

等待 knative service 就绪：

```bash
$ kubectl -n default get ksvc
NAME         URL                                                 LATESTCREATED      LATESTREADY        READY   REASON
helloworld   http://helloworld.default.ksvc.sample.t9kcloud.cn   helloworld-00001   helloworld-00001   True 
```

使用 curl 进行测试：

```bash
# 如果已经创建了域名解析
$ curl helloworld.default.ksvc.sample.t9kcloud.cn
Hello World!

# 如果尚未创建域名解析
$ curl -H "Host: helloworld.default.ksvc.sample.t9kcloud.cn" <ingress-nginx-ip>
Hello World!
```

## Metrics Server 安装正确性检查

Istio 依赖于 HPA（HorizontalPodAutoscaler），而 HPA 依赖 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/metrics-server#kubernetes-metrics-server">kubernetes metrics server</a>，所以需要部署 metrics server。

查看 Istio 的 HPA：

```bash
$ kubectl -n istio-system get hpa
NAME                   REFERENCE                         TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
istio-ingressgateway   Deployment/istio-ingressgateway   67%/80%   1         5         5          221d
istiod                 Deployment/istiod                 13%/80%   1         5         1          221d
```

查看 APIService：

```bash
# 查看当前版本
$ kubectl get APIService v1beta1.metrics.k8s.io
```

确认 metrics server 可用：

```bash
$ kubectl top node
NAME    CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
nc01    1113m        13%    14691Mi         46%       
nc04    1336m        11%    13375Mi         42%       
```

## Elastic Search

Install ES into t9k-monitoring.

### 安装

如果 namespace t9k-monitoring 不存在，则需创建：

```bash
$ kubectl create ns t9k-monitoring
```

[离线安装场景]修改镜像仓库的设置：

```bash
$ cat >> ../ks-clusters/additionals/elasticsearch/master.yaml << EOF
image: "192.168.101.159:5000/t9kpublic/elasticsearch"
EOF
$ cat >> ../ks-clusters/additionals/elasticsearch/client.yaml << EOF
image: "192.168.101.159:5000/t9kpublic/elasticsearch"
EOF
$ cat >> ../ks-clusters/additionals/elasticsearch/data.yaml << EOF
image: "192.168.101.159:5000/t9kpublic/elasticsearch"
EOF
$ cat >> ../ks-clusters/additionals/elasticsearch/single.yaml << EOF
image: "192.168.101.159:5000/t9kpublic/elasticsearch"
EOF
```

多节点 K8s 集群中的安装方式：

```bash
# online installation
$ helm install elasticsearch-master \
    oci://tsz.io/t9kcharts/elasticsearch \
    -n t9k-monitoring \
    -f ../ks-clusters/additionals/elasticsearch/master.yaml

$ helm install elasticsearch-client \
    oci://tsz.io/t9kcharts/elasticsearch \
    -n t9k-monitoring \
    -f ../ks-clusters/additionals/elasticsearch/client.yaml

$ helm install elasticsearch-data \
    oci://tsz.io/t9kcharts/elasticsearch \
    -n t9k-monitoring \
    -f ../ks-clusters/additionals/elasticsearch/data.yaml

# offline install
$ helm install elasticsearch-master \
    ../ks-clusters/tools/offline-additionals/charts/elasticsearch-7.13.4.tgz \
    -n t9k-monitoring \
    -f ../ks-clusters/additionals/elasticsearch/master.yaml

$ helm install elasticsearch-client \
    ../ks-clusters/tools/offline-additionals/charts/elasticsearch-7.13.4.tgz \
    -n t9k-monitoring \
    -f ../ks-clusters/additionals/elasticsearch/client.yaml

$ helm install elasticsearch-data \
    ../ks-clusters/tools/offline-additionals/charts/elasticsearch-7.13.4.tgz \
    -n t9k-monitoring \
    -f ../ks-clusters/additionals/elasticsearch/data.yaml
```

其中 Helm Chart 的来源参考：[Elastic Search 的 Helm Chart 修改]()

单节点安装方式：

```bash
# online installation
$ helm install elasticsearch-single \
    oci://tsz.io/t9kcharts/elasticsearch \
    -n t9k-monitoring \
    -f ../ks-clusters/additionals/elasticsearch/single.yaml

# offline install
$ helm install elasticsearch-single \
    ../ks-clusters/tools/offline-additionals/charts/elasticsearch-7.13.4.tgz \
    -n t9k-monitoring \
    -f ../ks-clusters/additionals/elasticsearch/single.yaml
```

<aside class="note">
<div class="title">注意</div>

单节点安装方式仅在只有一个 K8s 节点的测试场景中适用。

</aside>

### 验证

验证 elasticsearch Pod 正常运行：

```bash
$ kubectl -n t9k-monitoring get pod
NAME                                   READY   STATUS    RESTARTS        AGE
elasticsearch-client-0                 1/1     Running   43 (200d ago)   200d
elasticsearch-client-1                 1/1     Running   1 (100d ago)    190d
elasticsearch-data-0                   1/1     Running   1 (100d ago)    190d
elasticsearch-data-1                   1/1     Running   0               99d
elasticsearch-data-2                   1/1     Running   0               221d
elasticsearch-master-0                 1/1     Running   1 (100d ago)    190d
elasticsearch-master-1                 1/1     Running   0               23h
elasticsearch-master-2                 1/1     Running   0               221d
```

<aside class="note">
<div class="title">注意</div>

在 Post Install 流程中，我们还需要为 Elasticsearch 配置 Index。

</aside>

## 监控相关

为了使监控系统正常工作，还需要创建额外的 K8s 资源。

### kube-system service

<aside class="note">
<div class="title">注意</div>

有些 kubernetes 的安装需要手动在 namespace kube-system 中为 kube-scheduler 和 kube-controller-manager 创建 service。

</aside>

在创建之前，请先确认系统中是否已经存在相应的 service。以下展示的 k8s cluster，由于已经创建了相应的 Service，则无需创建。

```bash
$ kubectl -n kube-system get svc/kube-scheduler svc/kube-controller-manager
NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)     AGE
kube-scheduler            ClusterIP   10.233.18.162   <none>        10259/TCP   39m
kube-controller-manager   ClusterIP   10.233.19.17    <none>        10257/TCP   32m
```

如果并无上述 service， 则可手工创建，如下所示：

```bash
$ kubectl apply -n kube-system -f ../ks-clusters/additionals/monitoring/kube-system-svc.yaml
```

### cAdvisor

cAdvisor 的安装依赖 t9k-monitoring 产品。已经移动到 [Post Install]()。

## Gatekeeper

t9k-cluster-admin 依赖于 Gatekeeper，因此在安装 t9k-cluster-admin 之前，应当预先安装 Gatekeeper 到 t9k-system。完整文档参考：[T9k 产品安装手册-gatekeeper]()。

### 安装

Gatekeeper 安装于 namespace t9k-system 中，因此，需要预先创建它：

```bash
$ kubectl create ns t9k-system
```

验证：

```bash
$ kubectl get ns t9k-system
NAME       STATUS AGE
t9k-system Active 3d1h

$ kubectl get ns t9k-system -o jsonpath='{.metadata.labels}'
{"kubernetes.io/metadata.name":"t9k-system"}
```

[离线安装场景]修改镜像仓库的设置：

```bash
$ sed -i "s|docker.io/t9kpublic|192.168.101.159:5000/t9kpublic|g" \
    ../ks-clusters/additionals/gatekeeper/values.yaml
```

运行以下命令安装 gatekeeper：

```bash
# For K8s v1.24 or v1.25
$ helm -n t9k-system install t9k-gatekeeper oci://tsz.io/t9kcharts/gatekeeper \
    --version 3.11.0 \
    -f ../ks-clusters/additionals/gatekeeper/values.yaml

# For K8s v1.22
$ helm -n t9k-system install t9k-gatekeeper oci://tsz.io/t9kcharts/gatekeeper \
    --version 3.11.0-1 \
    -f ../ks-clusters/additionals/gatekeeper/values.yaml

# offline install for K8s v1.24 or v1.25 
$ helm -n t9k-system install t9k-gatekeeper \
    ../ks-clusters/tools/offline-additionals/charts/gatekeeper-3.11.0.tgz \
    -f ../ks-clusters/additionals/gatekeeper/values.yaml

# offline install for K8s v1.22
$ helm -n t9k-system install t9k-gatekeeper \
    ../ks-clusters/tools/offline-additionals/charts/gatekeeper-3.11.0-1.tgz \
    -f ../ks-clusters/additionals/gatekeeper/values.yaml
```

等待约 1-3 分钟，gatekeeper 安装完成后会返回信息。

### 验证

查看状态：

```bash
$ helm status -n t9k-system t9k-gatekeeper 
NAME: t9k-gatekeeper
LAST DEPLOYED: Tue Nov  7 13:05:55 2023
NAMESPACE: t9k-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

验证 Gatekeeper Pod 运行正常：

```bash
$ kubectl -n t9k-system get pod -l gatekeeper.sh/system="yes"
NAME                                           READY STATUS RESTARTS AGE
gatekeeper-audit-549bcc6775-2fcd8              1/1 Running 1 (2m22s ago) 2m29s
gatekeeper-controller-manager-7997dc9df8-kmnlk 1/1 Running 0 2m29s
gatekeeper-controller-manager-7997dc9df8-phx8s 1/1 Running 0 2m29s
gatekeeper-controller-manager-7997dc9df8-snr7g 1/1 Running 0 2m29s
```

## GPU Operator

### 安装

需要先确认节点安装了 GPU 驱动。

运行命令安装 GPU Operator：

```bash
$ cd ~/ansible/$T9K_CLUSTER

# online install
$ ansible-playbook ../ks-clusters/t9k-playbooks/3-install-gpu-operator.yml \
    -i inventory/inventory.ini \
    --become -K

# offline install
$ ansible-playbook ../ks-clusters/t9k-playbooks/3-install-gpu-operator.yml \
    -i inventory/inventory.ini \
    --become -K \
    -e nvidia_gpu_operator_charts=\
../ks-clusters/tools/offline-additionals/charts/gpu-operator-v22.9.2.tgz \
    -e nvidia_gpu_operator_image_registry=192.168.101.159:5000/t9kpublic \
    -e nvidia_node_feature_discovery_repo=192.168.101.159:5000/t9kpublic/node-feature-discovery
```

### 验证及更多配置

GPU Operator 安装完成后，在 namespace gpu-operator 中查看 GPU Operator 安装的组件：

```bash
$ kubectl -n gpu-operator get deploy
NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
gpu-operator                        1/1     1            1           18d
t9k-node-feature-discovery-master   1/1     1            1           18d

$ kubectl -n gpu-operator get ds
NAME                                         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                      AGE
gpu-feature-discovery                        8         8         8       8            8           nvidia.com/gpu.deploy.gpu-feature-discovery=true   18d
nvidia-container-toolkit-daemonset           8         8         8       8            8           nvidia.com/gpu.deploy.container-toolkit=true       18d
nvidia-dcgm-exporter                         8         8         8       8            8           nvidia.com/gpu.deploy.dcgm-exporter=true           18d
nvidia-device-plugin-daemonset               8         8         8       8            8           nvidia.com/gpu.deploy.device-plugin=true           18d
nvidia-mig-manager                           3         3         3       3            3           nvidia.com/gpu.deploy.mig-manager=true             18d
nvidia-operator-validator                    8         8         8       8            8           nvidia.com/gpu.deploy.operator-validator=true      18d
release-name-node-feature-discovery-worker   8         8         8       8            8           <none>                                             18d
```

查看 gpu operator 的配置：

```bash
$ kubectl -n gpu-operator get clusterpolicy cluster-policy  
NAME             AGE
cluster-policy   2d18h
```

安装后的配置请参考文档：[NVIDIA GPU Operator]()。

## Network Operator

### 安装

需要先确认节点安装了 IB 驱动。

运行命令安装 network operator：

```bash
$ cd ~/ansible/$T9K_CLUSTER

# online install
$ ansible-playbook ../ks-clusters/t9k-playbooks/4-install-network-operator.yml \
    -i inventory/inventory.ini \
    --become -K

# offline install
$ ansible-playbook ../ks-clusters/t9k-playbooks/4-install-network-operator.yml \
    -i inventory/inventory.ini \
    --become -K \
    -e network_operator_charts=\
../ks-clusters/tools/offline-additionals/charts/network-operator-23.10.0.tgz \
    -e network_operator_image_registry=192.168.101.159:5000/t9kpublic
```

### 验证

Network Operator 安装完成后，在 namespace network-operator 中查看 GPU Operator 安装的组件：

```bash
$ kubectl -n network-operator get deploy
NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
nvidia-network-operator   1/1     1            1           373d

$ kubectl -n network-operator get ds    
NAME                DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                                                                   AGE
cni-plugins-ds      8         8         8       8            8           <none>                                                                                          373d
kube-multus-ds      8         8         8       8            8           <none>                                                                                          373d
rdma-shared-dp-ds   9         9         9       9            9           feature.node.kubernetes.io/pci-15b3.present=true,network.nvidia.com/operator.mofed.wait=false   373d
whereabouts         8         8         8       8            8           beta.kubernetes.io/arch=amd64                                                                   373d
```
