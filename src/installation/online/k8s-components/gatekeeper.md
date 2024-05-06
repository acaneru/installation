# Gatekeeper

t9k-cluster-admin 依赖于 Gatekeeper，因此在安装 t9k-cluster-admin 之前，应当预先安装 Gatekeeper 到 t9k-system。完整文档参考：[T9k 产品安装手册-gatekeeper](https://docs.google.com/document/d/1tG62x4PYPDbPDAsZKoyQpioU0W3S1RCqcBUG8RlVhOU/edit#heading=h.78bnmdi8ns1n)。

## 安装

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

## 验证

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
