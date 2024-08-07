# 安装产品

## 目的

在 K8s 集群中以 User Console 模式安装 T9k 产品。

## 前置条件

* 完成了 [安装前准备](./pre-install.md)。
* 可以访问 Registry `tsz.io`，或者通过其它方式获得需要的 Helm Charts。

## 安装产品模块

安装以下产品模块：

```console
t9k-core
t9k-security-console-api
t9k-monitoring
t9k-build-console-api
t9k-cost
t9k-jobs
t9k-notebook
t9k-services
t9k-csi-s3
t9k-workflow-manager-api
t9k-cluster-admin
t9k-user-console
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
│   ├── t9k-build-console-api-1.79.5.tgz
│   ├── t9k-cluster-admin-1.79.5.tgz
│   ├── t9k-core-1.79.5.tgz
│   ├── t9k-cost-1.79.2.tgz
│   ├── t9k-csi-s3-1.79.5.tgz
│   ├── t9k-jobs-1.79.5.tgz
│   ├── t9k-monitoring-1.79.5.tgz
│   ├── t9k-notebook-1.79.5.tgz
│   ├── t9k-security-console-api-1.79.5.tgz
│   ├── t9k-services-1.79.5.tgz
│   ├── t9k-user-console-1.79.5.tgz
│   └── t9k-workflow-manager-api-1.79.5.tgz
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
    charts/t9k-core-1.79.5.tgz -f values.yaml

helm -n t9k-system install t9k-security-console-api \
    charts/t9k-security-console-api-1.79.5.tgz -f values.yaml

helm -n t9k-monitoring install t9k-monitoring \
    charts/t9k-monitoring-1.79.5.tgz -f values.yaml

helm -n t9k-system install t9k-build-console-api \
    charts/t9k-build-console-api-1.79.5.tgz -f values.yaml

helm -n t9k-system install t9k-cost \
    charts/t9k-cost-1.79.2.tgz -f values.yaml

helm -n t9k-system install t9k-jobs \
    charts/t9k-jobs-1.79.5.tgz -f values.yaml

helm -n t9k-system install t9k-notebook \
    charts/t9k-notebook-1.79.5.tgz -f values.yaml

helm -n t9k-system install t9k-services \
    charts/t9k-services-1.79.5.tgz -f values.yaml

helm -n t9k-system install t9k-csi-s3 \
    charts/t9k-csi-s3-1.79.5.tgz -f values.yaml

helm -n t9k-system install t9k-workflow-manager-api \
    charts/t9k-workflow-manager-api-1.79.5.tgz -f values.yaml

helm -n t9k-system install t9k-cluster-admin \
    charts/t9k-cluster-admin-1.79.5.tgz -f values.yaml

helm -n t9k-system install t9k-user-console \
    charts/t9k-user-console-1.79.5.tgz -f values.yaml
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
    oci://tsz.io/t9kcharts/t9k-core \
    -f values.yaml

helm -n t9k-system install t9k-security-console-api \
    oci://tsz.io/t9kcharts/t9k-security-console-api \
    -f values.yaml

helm -n t9k-monitoring install t9k-monitoring \
    oci://tsz.io/t9kcharts/t9k-monitoring \
    -f values.yaml

helm -n t9k-system install t9k-build-console-api \
    oci://tsz.io/t9kcharts/t9k-build-console-api \
    -f values.yaml

helm -n t9k-system install t9k-cost \
    oci://tsz.io/t9kcharts/t9k-cost \
    -f values.yaml

helm -n t9k-system install t9k-jobs \
    oci://tsz.io/t9kcharts/t9k-jobs \
    -f values.yaml

helm -n t9k-system install t9k-notebook \
    oci://tsz.io/t9kcharts/t9k-notebook \
    -f values.yaml

helm -n t9k-system install t9k-services \
    oci://tsz.io/t9kcharts/t9k-services \
    -f values.yaml

helm -n t9k-system install t9k-csi-s3 \
    oci://tsz.io/t9kcharts/t9k-csi-s3 \
    -f values.yaml

helm -n t9k-system install t9k-workflow-manager-api \
    oci://tsz.io/t9kcharts/t9k-workflow-manager-api \
    -f values.yaml

helm -n t9k-system install t9k-cluster-admin \
    oci://tsz.io/t9kcharts/t9k-cluster-admin \
    -f values.yaml

helm -n t9k-system install t9k-user-console \
    oci://tsz.io/t9kcharts/t9k-user-console \
    -f values.yaml
```

## 基本检查

等待并确认集群中所有的 Pod 都正常工作。等待的时间取决于是否预先拉取了镜像、网络情况等，可能需要 5~60 分钟不等：

```bash
# 持续查看 K8s 集群中的所有 Pod 状态
kubectl get pod -A -w
```

```bash
# 查看 K8s 集群中是否有异常状态的 Pod
kubectl get pod -A -o wide | grep -Eiv "running|complete"
```

查看产品模块的安装信息（helm chart release），以 t9k-core 为例：

```bash
helm status -n t9k-system t9k-core
```

```console
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
NAME                    	NAMESPACE     	REVISION	UPDATED                             	STATUS  	CHART                          	APP VERSION
cilium                  	kube-system   	2       	2024-06-19 14:59:01.294733 +0800 CST	deployed	cilium-1.15.5                  	1.15.5     
elasticsearch-master    	t9k-monitoring	1       	2024-07-19 18:46:08.279436 +0800 CST	deployed	elasticsearch-7.13.4           	7.13.4     
elasticsearch-client    	t9k-monitoring	1       	2024-07-19 18:46:13.609795 +0800 CST	deployed	elasticsearch-7.13.4           	7.13.4     
elasticsearch-data      	t9k-monitoring	1       	2024-07-19 18:46:18.339152 +0800 CST	deployed	elasticsearch-7.13.4           	7.13.4     
t9k-gatekeeper          	t9k-system    	1       	2024-07-19 18:46:49.341557 +0800 CST	deployed	gatekeeper-3.11.0              	v3.11.0    
t9k-security-console-api	t9k-system    	1       	2024-07-21 14:11:41.737822 +0800 CST	deployed	t9k-security-console-api-1.79.5	1.79.5     
t9k-csi-s3              	t9k-system    	1       	2024-07-21 15:38:15.055841 +0800 CST	deployed	t9k-csi-s3-1.79.5              	1.79.5     
t9k-jobs                	t9k-system    	1       	2024-07-21 15:38:34.894072 +0800 CST	deployed	t9k-jobs-1.79.5                	1.79.5     
t9k-notebook            	t9k-system    	1       	2024-07-21 15:44:47.773993 +0800 CST	deployed	t9k-notebook-1.79.5            	1.79.5     
t9k-services            	t9k-system    	1       	2024-07-21 15:45:07.225526 +0800 CST	deployed	t9k-services-1.79.5            	1.79.5     
t9k-workflow-manager-api	t9k-system    	1       	2024-07-21 15:45:49.413001 +0800 CST	deployed	t9k-workflow-manager-api-1.79.5	1.79.5     
t9k-monitoring          	t9k-monitoring	1       	2024-07-21 15:47:45.142087 +0800 CST	deployed	t9k-monitoring-1.79.5          	1.79.5     
t9k-cluster-admin       	t9k-system    	1       	2024-07-21 15:50:23.983369 +0800 CST	deployed	t9k-cluster-admin-1.79.5       	1.79.5     
t9k-cost                	t9k-system    	2       	2024-07-21 15:55:27.888551 +0800 CST	deployed	t9k-cost-1.79.2                	1.79.2     
t9k-user-console        	t9k-system    	1       	2024-07-21 15:56:39.249047 +0800 CST	deployed	t9k-user-console-1.79.5        	1.79.5     
t9k-core                	t9k-system    	6       	2024-07-21 16:07:27.06814 +0800 CST 	deployed	t9k-core-1.79.5                	1.79.5     
t9k-build-console-api   	t9k-system    	2       	2024-07-21 17:18:05.392658 +0800 CST	deployed	t9k-build-console-api-1.79.5   	1.79.5 
```

</details>

## 下一步

进行 [安装后配置](./post-install.md)。

## 参考

<https://helm.sh/docs/>