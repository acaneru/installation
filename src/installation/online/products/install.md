# 安装产品

```
TODO:
    1. 增加 github 上 产品 release 链接
    2. 减少 TensorStack 产品之间的依赖，并更新推荐的产品安装顺序
```

## 目的

在 K8s 集群中安装 T9k 产品。

## 前置条件

* 完成 [安装前准备](./pre-install.md)。
* 可以访问 Registry `tsz.io`，否则应当参考[离线安装](../../offline/index.md)文档

## 安装

登录 OCI Registry：

```bash
# 要求 helm version >= v3.8.0
helm registry login tsz.io

# 在完成安装后，可以通过以下命令登出
helm registry logout tsz.io
```

使用 [安装前准备](./pre-install.md) 中准备的 `values.yaml` 安装。

这里以 Chart `t9k-core` 为例：

```bash
# --version 指定的参数为 Helm Chart 的版本，如果省略则安装最新版本
helm install t9k-core \
   oci://tsz.io/t9kcharts/t9k-core \
   -f values.yaml \
   -n t9k-system \
   --version <version>
```


**推荐的安装顺序**

建议按照以下顺序进行产品模块的安装和检查，安装完列表中的所有产品后，再检查产品是否正常运行：

```
t9k-core
t9k-security-console
t9k-landing-page
t9k-notebook
t9k-jobs
t9k-scheduler
t9k-services
t9k-tools
t9k-csi-s3
t9k-monitoring # 安装在 t9k-monitoring namespace 中
t9k-cost
t9k-build-console
t9k-deploy-console
t9k-workflow-manager
t9k-cluster-admin
```

可选，安装 t9k AI Data 系列的产品模块：
```
t9k-aistore
t9k-asset-hub
t9k-experiment-management
```

> 注意：产品模块 "t9k-monitoring" 需要安装在 namespace `t9k-monitoring` 中；其他所有产品都安装在 namespace `t9k-system` 中。


## 基本检查

等待并确认集群中所有的 Pod 都正常工作。等待的时间取决于是否预先拉取了镜像、网络情况等，可能需要 5~60 分钟不等：

```bash
# 持续查看 K8s 集群中的所有 Pod 状态
kubectl get pod -A -w

# 查看 K8s 集群中是否有异常状态的 Pod
kubectl get pod -A -o wide | grep -Eiv "running|complete"
```

查看产品模块的安装信息（helm chart releas），以 t9k-core 为例：

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
