# Gatekeeper

集群管理模块（`t9k-cluster-admin`） 依赖于 Gatekeeper，因此在安装 `t9k-cluster-admin` 之前，应当预先安装 Gatekeeper。

## 目的

安装 Gatekeeper 于 namespace `t9k-system` 中。

## 安装

创建 namespace：

```bash
kubectl create ns t9k-system
```

确保 namespace `t9k-system ` 的 label `kubernetes.io/metadata.name` 存在：

```bash
kubectl get ns t9k-system -o jsonpath='{.metadata.labels}'
```

```
{"kubernetes.io/metadata.name":"t9k-system"}
```

如不存在此 label，需要手工创建它：

```bash
kubectl label ns  t9k-system kubernetes.io/metadata.name=t9k-system
```

运行以下命令安装 gatekeeper，2 选 1。

1. 可直接访问 registry

    ```bash
    # For K8s v1.24 or v1.25
    helm -n t9k-system install t9k-gatekeeper oci://tsz.io/t9kcharts/gatekeeper \
      --version 3.11.0 \
      -f ../ks-clusters/additionals/gatekeeper/values.yaml

    # For K8s v1.22
    helm -n t9k-system install t9k-gatekeeper oci://tsz.io/t9kcharts/gatekeeper \
      --version 3.11.0-1 \
      -f ../ks-clusters/additionals/gatekeeper/values.yaml
    ```

2. 离线安装
    
    <aside class="note">
    <div class="title">离线安装</div>

    修改镜像仓库的设置，示例为 `192.168.101.159:5000`：

    ```bash
    sed -i "s|docker.io/t9kpublic|192.168.101.159:5000/t9kpublic|g" \
      ../ks-clusters/additionals/gatekeeper/values.yaml
    ```
    </aside>

    ```bash
    # offline install for K8s v1.24 or v1.25 
    helm -n t9k-system install t9k-gatekeeper \
      ../ks-clusters/tools/offline-additionals/charts/gatekeeper-3.11.0.tgz \
      -f ../ks-clusters/additionals/gatekeeper/values.yaml

    # offline install for K8s v1.22
    helm -n t9k-system install t9k-gatekeeper \
      ../ks-clusters/tools/offline-additionals/charts/gatekeeper-3.11.0-1.tgz \
      -f ../ks-clusters/additionals/gatekeeper/values.yaml
    ```

等待约 1-3 分钟，gatekeeper 安装完成后会返回信息。

## 验证

查看状态：

```bash
helm status -n t9k-system t9k-gatekeeper 
```

```console
NAME: t9k-gatekeeper
LAST DEPLOYED: Tue Nov  7 13:05:55 2023
NAMESPACE: t9k-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

确认 Gatekeeper Pod 运行正常：

```bash
kubectl -n t9k-system get pod -l app=gatekeeper
```

```console
NAME                                           READY STATUS RESTARTS AGE
gatekeeper-audit-549bcc6775-2fcd8              1/1 Running 1 (2m22s ago) 2m29s
gatekeeper-controller-manager-7997dc9df8-kmnlk 1/1 Running 0 2m29s
gatekeeper-controller-manager-7997dc9df8-phx8s 1/1 Running 0 2m29s
gatekeeper-controller-manager-7997dc9df8-snr7g 1/1 Running 0 2m29s
```

查看日志：

```bash
# audit controller
kubectl -n t9k-system logs -l app=gatekeeper,control-plane=audit-controller --tail=50

# controller-manager, multiple pods
kubectl -n t9k-system logs deploy/gatekeeper-controller-manager --tail=50
```

## 参考

<https://github.com/open-policy-agent/gatekeeper>
