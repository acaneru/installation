# 安装产品

```
TODO:
    1. 增加 github 上 产品 release 链接
    2. 减少 TensorStack 产品之间的依赖，并更新推荐的产品安装顺序
```

## 目的

在 K8s 集群中以传统模式安装 T9k 产品。

## 前置条件

* 完成了 [安装前准备](./pre-install.md)。
* 可以访问 Registry `tsz.io`，或者通过其它方式获得需要的 Helm Charts。

## 安装产品模块

安装以下产品模块：

```console
t9k-core
t9k-security-console
t9k-landing-page
t9k-scheduler
t9k-monitoring
t9k-build-console
t9k-cost
t9k-jobs
t9k-notebook
t9k-services
t9k-tools
t9k-csi-s3
t9k-deploy-console
t9k-workflow-manager
t9k-cluster-admin
```

可选，安装 t9k AI Data 系列的产品模块：

```console
t9k-aistore
t9k-asset-hub
t9k-experiment-management
```

### 使用本地 Helm Charts 安装

首先，确认当前路径下已经准备好了 `values.yaml`，并下载好了 Helm Charts。Helm Charts 可以联系向量栈的工程师来获取：

```bash
tree .
```

输出：

```console
.
├── charts
│   ├── t9k-build-console-<version>.tgz
│   ├── t9k-cluster-admin-<version>.tgz
│   ├── t9k-core-<version>.tgz
│   ├── t9k-cost-<version>.tgz
│   ├── t9k-csi-s3-<version>.tgz
│   ├── t9k-deploy-console-<version>.tgz
│   ├── t9k-jobs-<version>.tgz
│   ├── t9k-landing-page-<version>.tgz
│   ├── t9k-monitoring-<version>.tgz
│   ├── t9k-notebook-<version>.tgz
│   ├── t9k-scheduler-<version>.tgz
│   ├── t9k-security-console-<version>.tgz
│   ├── t9k-services-<version>.tgz
│   ├── t9k-tools-<version>.tgz
│   └── t9k-workflow-manager-<version>.tgz
└── values.yaml
```

<aside class="note">
<div class="title">注意</div>

1. 请根据实际的 Helm Chart 名称修改下文的安装命令。
1. 产品模块 `t9k-monitoring` 安装的 namespace 与其他产品模块不同，复制命令时需要注意。

</aside>

进行安装：

```bash
helm -n t9k-system install t9k-core \
    charts/t9k-core-<version>.tgz -f values.yaml

helm -n t9k-system install t9k-security-console \
    charts/t9k-security-console-<version>.tgz -f values.yaml

helm -n t9k-system install t9k-landing-page \
    charts/t9k-landing-page-<version>.tgz -f values.yaml

helm -n t9k-system install t9k-scheduler \
    charts/t9k-scheduler-<version>.tgz -f values.yaml

helm -n t9k-monitoring install t9k-monitoring \
    charts/t9k-monitoring-<version>.tgz -f values.yaml

helm -n t9k-system install t9k-build-console \
    charts/t9k-build-console-<version>.tgz -f values.yaml

helm -n t9k-system install t9k-cost \
    charts/t9k-cost-<version>.tgz -f values.yaml

helm -n t9k-system install t9k-jobs \
    charts/t9k-jobs-<version>.tgz -f values.yaml

helm -n t9k-system install t9k-notebook \
    charts/t9k-notebook-<version>.tgz -f values.yaml

helm -n t9k-system install t9k-services \
    charts/t9k-services-<version>.tgz -f values.yaml

helm -n t9k-system install t9k-tools \
    charts/t9k-tools-<version>.tgz -f values.yaml

helm -n t9k-system install t9k-csi-s3 \
    charts/t9k-csi-s3-<version>.tgz -f values.yaml

helm -n t9k-system install t9k-deploy-console \
    charts/t9k-deploy-console-<version>.tgz -f values.yaml

helm -n t9k-system install t9k-workflow-manager \
    charts/t9k-workflow-manager-<version>.tgz -f values.yaml

helm -n t9k-system install t9k-cluster-admin \
    charts/t9k-cluster-admin-<version>.tgz -f values.yaml
```

安装可选的 AI Data 系列产品模块：

```bash
helm -n t9k-system install t9k-aistore \
    charts/t9k-aistore-<version>.tgz -f values.yaml

helm -n t9k-system install t9k-asset-hub \
    charts/t9k-asset-hub-<version>.tgz -f values.yaml

helm -n t9k-system install t9k-experiment-management \
    charts/t9k-experiment-management-<version>.tgz -f values.yaml
```

### 使用在线 Helm Charts 安装

首先，确认当前路径下已经准备好了 `values.yaml`，并可以访问 Registry `tsz.io` 来在线下载 Helm Charts。验证：

```bash
helm pull oci://tsz.io/t9kcharts/t9k-core --version 1.79.5
```

<aside class="note">
<div class="title">注意</div>

1. 如果需要指定版本号，可以设置 `--version <version>` 参数。如果未设置，则默认使用最新的版本号。

</aside>

进行安装：

```bash
helm -n t9k-system install t9k-core \
    oci://tsz.io/t9kcharts/t9k-core -f values.yaml

helm -n t9k-system install t9k-security-console \
    oci://tsz.io/t9kcharts/t9k-security-console -f values.yaml

helm -n t9k-system install t9k-landing-page \
    oci://tsz.io/t9kcharts/t9k-landing-page -f values.yaml

helm -n t9k-system install t9k-scheduler \
    oci://tsz.io/t9kcharts/t9k-scheduler -f values.yaml

helm -n t9k-monitoring install t9k-monitoring \
    oci://tsz.io/t9kcharts/t9k-monitoring -f values.yaml

helm -n t9k-system install t9k-build-console \
    oci://tsz.io/t9kcharts/t9k-build-console -f values.yaml

helm -n t9k-system install t9k-cost \
    oci://tsz.io/t9kcharts/t9k-cost -f values.yaml

helm -n t9k-system install t9k-jobs \
    oci://tsz.io/t9kcharts/t9k-jobs -f values.yaml

helm -n t9k-system install t9k-notebook \
    oci://tsz.io/t9kcharts/t9k-notebook -f values.yaml

helm -n t9k-system install t9k-services \
    oci://tsz.io/t9kcharts/t9k-services -f values.yaml

helm -n t9k-system install t9k-tools \
    oci://tsz.io/t9kcharts/t9k-tools -f values.yaml

helm -n t9k-system install t9k-csi-s3 \
    oci://tsz.io/t9kcharts/t9k-csi-s3 -f values.yaml

helm -n t9k-system install t9k-deploy-console \
    oci://tsz.io/t9kcharts/t9k-deploy-console -f values.yaml

helm -n t9k-system install t9k-workflow-manager \
    oci://tsz.io/t9kcharts/t9k-workflow-manager -f values.yaml

helm -n t9k-system install t9k-cluster-admin \
    oci://tsz.io/t9kcharts/t9k-cluster-admin -f values.yaml
```

安装可选的 AI Data 系列产品模块：

```bash
helm -n t9k-system install t9k-aistore \
    oci://tsz.io/t9kcharts/t9k-aistore -f values.yaml

helm -n t9k-system install t9k-asset-hub \
    oci://tsz.io/t9kcharts/t9k-asset-hub -f values.yaml

helm -n t9k-system install t9k-experiment-management \
    oci://tsz.io/t9kcharts/t9k-experiment-management -f values.yaml
```

## 基本检查

等待并确认集群中所有的 Pod 都正常工作。等待的时间取决于是否预先拉取了镜像、网络情况等，可能需要 5~60 分钟不等：

```bash
# 持续查看 K8s 集群中的所有 Pod 状态
kubectl get pod -A -w

# 查看 K8s 集群中是否有异常状态的 Pod
kubectl get pod -A -o wide | grep -Eiv "running|complete"
```

查看产品模块的安装信息（helm chart release），以 t9k-core 为例：

```bash
helm status -n t9k-system t9k-core
```

```
NAME: t9k-core
LAST DEPLOYED: November 19 04:53:53 2023
NAMESPACE: t9k-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

查看所有的产品模块安装情况（helm chart releases）：

```bash
helm list -A -d
```

<details><summary><code class="hljs">output</code></summary>

```console
NAME                            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                                   APP VERSION
elasticsearch-single            t9k-monitoring  1               2023-11-19 04:42:24.939067616 +0000 UTC deployed        elasticsearch-7.13.4                    7.13.4
t9k-gatekeeper                  t9k-system      2               2023-11-19 04:47:12.871874737 +0000 UTC deployed        gatekeeper-3.11.0                       v3.11.0
t9k-core                        t9k-system      1               2023-11-19 04:52:52.591086929 +0000 UTC deployed        t9k-core-1.78.3                         1.78.3
t9k-scheduler                   t9k-system      1               2023-11-19 04:53:22.047545558 +0000 UTC deployed        t9k-scheduler-1.78.4                    1.78.4
t9k-csi-s3                      t9k-system      1               2023-11-19 04:53:46.694820382 +0000 UTC deployed        t9k-csi-s3-1.78.3                       1.78.3
t9k-jobs                        t9k-system      1               2023-11-19 04:54:12.858122721 +0000 UTC deployed        t9k-jobs-1.78.4                         1.78.4
t9k-services                    t9k-system      1               2023-11-19 04:54:36.863984918 +0000 UTC deployed        t9k-services-1.78.4                     1.78.4
t9k-landing-page                t9k-system      1               2023-11-19 04:55:00.60533111 +0000 UTC  deployed        t9k-landing-page-1.78.4                 1.78.4
t9k-security-console            t9k-system      1               2023-11-19 04:55:19.309728043 +0000 UTC deployed        t9k-security-console-1.78.5             1.78.5
t9k-notebook                    t9k-system      1               2023-11-19 04:55:54.230482157 +0000 UTC deployed        t9k-notebook-1.78.4                     1.78.4
t9k-monitoring                  t9k-monitoring  1               2023-11-19 04:56:12.617506927 +0000 UTC deployed        t9k-monitoring-1.78.5                   1.78.5
t9k-build-console               t9k-system      1               2023-11-19 04:57:19.251309469 +0000 UTC deployed        t9k-build-console-1.78.5                1.78.5
t9k-deploy-console              t9k-system      1               2023-11-19 04:57:36.088260359 +0000 UTC deployed        t9k-deploy-console-1.78.4               1.78.4
t9k-workflow-manager            t9k-system      1               2023-11-19 04:57:56.56433641 +0000 UTC  deployed        t9k-workflow-manager-1.78.4             1.78.4
t9k-asset-hub                   t9k-system      1               2023-11-19 04:58:28.991306879 +0000 UTC deployed        t9k-asset-hub-1.78.4                    1.78.4
t9k-experiment-management       t9k-system      1               2023-11-19 04:58:49.350846324 +0000 UTC deployed        t9k-experiment-management-1.78.4        1.78.4
t9k-cluster-admin               t9k-system      1               2023-11-19 06:02:45.082613774 +0000 UTC deployed        t9k-cluster-admin-1.78.8                1.78.8
t9k-aistore                     t9k-system      3               2023-11-19 06:37:17.947109956 +0000 UTC deployed        t9k-aistore-1.78.5                      1.78.5
```

</details>

## 下一步

进行 [安装后配置](./post-install.md)。

## 参考

<https://helm.sh/docs/>
