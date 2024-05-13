# 安装前准备

```
TODO:  
  1. 更换 `lakefs.sample.t9kcloud.cn` 为更明确的名字，例如 `s3.sample.t9kcloud.cn`?
  2. 为啥 landingpage ingress 需要手工创建？
  3. Use ansible to automate step "Pre-pull Image"
```

## 目的

为安装 T9k 产品做安装前的准备工作，包括获取 DNS，证书，预先创建一些 K8s 资源等。

## 前提条件

执行安装命令的环境要求：

* 可用的 K8s 集群
  * 已安装前述的各种 [k8s 组件](../k8s-components/index.md);
  * 可使用 `kubectl`，具备 cluster-admin 权限；
  * 可访问安装过程中使用的容器镜像服务（一般在公网上，可支持本地 mirror）；
* 能够访问存放安装包的网络服务（一般在公网上，可支持本地 mirror）。
* `kubectl`, >= v1.25.x+; `helm`, >= v3.9.x；

## 域名及证书

准备产品的域名、设置域名解析、获取域名证书。

### 获取域名

> 应当以合适的途径获得域名，并配置其解析。

下文假设用户选择使用 DNS `sample.t9kcloud.cn` 部署产品，各个具体的模块的子 DNS 如下表。

| 域名                         | 说明                                |
| ---------------------------- | ----------------------------------- |
| `home.sample.t9kcloud.cn`    | 平台主入口                          |
| `auth.sample.t9kcloud.cn`    | 安全系统                            |
| `lakefs.sample.t9kcloud.cn`  | AI 资产和实验管理服务的 S3 接口地址 |
| `*.ksvc.sample.t9kcloud.cn` | 模型推理服务                        |

注意事项：

1. 具体安装时，应当替换 `sample.t9kcloud.cn` 为实际的名称；
1. 可使用 `*.sample.t9kcloud.cn` 的域名证书简化流程；
1. 如果要在公网使用 TensorStack AI 平台，域名一般需要备案才能使用。

### 设置解析

为 `*.sample.t9kcloud.cn` 域名添加一条 A （或者 CNAME）记录，使其最终正确指向 K8s 集群的 <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/concepts/services-networking/ingress/#what-is-ingress">Ingress</a> 服务的 IP 地址。

验证：

```bash
# 注意：需要使用实际的 DNS
dig home.sample.t9kcloud.cn +short
```

### 获取证书

<aside class="note info">
<div class="title">获取 TLS 证书</div>

用于支持 HTTPS 的证书可以在服务商处购买，也可以使用免费证书服务（如 <https://freessl.cn/>， <https://letsencrypt.org/>，<https://zerossl.com/>）。

[管理域名证书](../../appendix/manage-domain-certificate.md) 中提供了获取证书的更多详情。
</aside>


证书为 2 个文件，分别为 ：

- `server.crt`，公钥证书（public key certificate）；
- `server.key`，私钥（private key）。

查看证书内容：

```bash
# 验证公钥证书有效期：
cat server.crt  | openssl x509 -noout -enddate

# 确认公钥证书对应的域名：
cat server.crt  | openssl x509 -noout -text \
  |grep -A 1 -i "Subject Alternative Name"

# 输出公钥证书所有内容：
cat server.crt  | openssl x509 -noout -text

# 确认私钥的 RSA 格式正确：
cat server.key |  openssl rsa -check
```

## 创建 K8s 资源

### namespace

需要创建以下 namespace：

| 名称  |  说明                        |
| -------------- |  --------------------------- |
| t9k-system     |  TensorStack AI 平台控制平面 |
| t9k-syspub     |  存储公共配置            |
| t9k-monitoring |  监控及告警系统          |

确认以下 namespace 存在，如果不存在则创建：

```bash
kubectl get ns t9k-system
kubectl get ns t9k-syspub
kubectl get ns t9k-monitoring
```

创建：

```
for ns in "t9k-system" "t9k-syspub" "t9k-monitoring"; do
  kubectl create ns "$ns"
done
```

### 设置 label

> 说明：没有 `control-plane` label 的 namespace 会受到系统 Admission Control 模块的检查，但运行 TensorStack AI 平台服务（系统控制平面）的 namespace 中的工作负载不应当接受这些检查。

为运行 TensorStack AI 平台系统功能的 namespace 设置 label: `control-plane="true"`：

```bash
namespaces=(
  "ingress-nginx"
  "istio-system"
  "knative-serving"
  "kube-system"
  "t9k-system"
  "t9k-syspub"
  "t9k-monitoring"
)

for ns in "${namespaces[@]}"; do
  kubectl label ns "$ns" control-plane="true"
done
```

### 证书 Secret

创建以下 Secret 资源以存储 Ingress 的 TLS 证书：

| Name | Namespace | Host | 说明 |
| ----------------- | ------------------ | --------- | -------------------------- |
| `cert.landing-page` | istio-system       | home.sample.t9kcloud.cn | 平台主入口 |
| `cert.keycloak`     | t9k-system         | auth.sample.t9kcloud.cn | 安全系统入口 |
| `cert.lakefs`       | t9k-system         | lakefs.sample.t9kcloud.cn | AI 资产和实验管理服务的 S3 接口地址 |

> 注意：上表中的 `Host` 字段为示意，部署时应当使用实际的域名，而不是 `*.sample.t9kcloud.cn`。

如果我们使用多域名证书，可以使用同一份 cert 文件创建这些 secret：

```bash
kubectl create secret tls cert.landing-page \
    --cert='server.crt' \
    --key='server.key' \
    -n istio-system

kubectl create secret tls cert.keycloak \
    --cert='server.crt' \
    --key='server.key' \
    -n t9k-system

kubectl create secret tls cert.lakefs \
    --cert='server.crt' \
    --key='server.key' \
    -n t9k-system
```

说明：

1. 如果使用单独的证书，需要在上面的命令中使用不同的文件分别创建 Secret。
2. 目前模型推理服务的 Ingress (*.ksvc.sample.t9kcloud.cn) 使用 HTTP 协议，不需要配置 Cert/Secret

### Ingress

产品目前使用如下 Ingress：

| Name    | Namespace | 说明                            |
| ---------------- | ------------------ | ------------------------------- |
| `t9k.landing-page` | istio-system       | 平台主入口                      |
| `t9k.keycloak`     | t9k-system         | 安全系统                        |
| `t9k.lakefs `      | t9k-system         | AI 资产和实验管理服务的 S3 接口 |
| `t9k.serving`      | istio-system       | 模型推理服务                    |

运行以下命令创建 Ingress `t9k.landing-page`：

```bash
kubectl create -f - << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: t9k.landing-page
  namespace: istio-system
  annotations:
    kubernetes.io/ingress.class: nginx
spec:
  rules:
  - host: "home.sample.t9kcloud.cn"
    http:
      paths:
      - backend:
          service:
            name: istio-ingressgateway
            port:
              number: 80
        pathType: ImplementationSpecific
  tls:
  - hosts:
    - "home.sample.t9kcloud.cn"
    secretName: "cert.landing-page"
EOF
```

说明：

1. 其他 Ingress 将在后续安装过程中自动创建
2. `host, hosts` 当使用实际的 DNS

## 准备配置

### 设置 values.yaml

<aside class="note">
<div class="title">注意</div>

1. <https://github.com/t9k/ks-clusters/tree/master/values> 提供示例 values.yaml
1. 带有注释 MUST 的设置必须检查。

</aside>

根据前述准备工作， 并参考 `values.yaml` 的注释修改此文件中的相应字段。

## Pre-Pull Image

可选，预先下载 T9k 产品需要的所有镜像。

Pre-Pull 需要在所有加入了 K8s 集群的节点上进行。在节点上预先拉取镜像有以下好处：
1. 加快部署速度，减少部署过程中等待 Pod 就绪的时间；
2. 减少 Pod 因为其依赖项尚未就绪，导致 Pod 出错、重启的风险；
3. 可以较快地判断已经部署的产品是否正常运行，并及时处理潜在的错误。

从 github 上获取与产品对应的<a target="_blank" rel="noopener noreferrer" href="https://github.com/t9k/ks-clusters/tree/master/tools/offline-t9k/imagelist">镜像列表</a>，拉取列表中的镜像：

```bash
for image in $(cat t9k-2024-03-25.list); do
    docker pull $image
done
```

> 如果计划安装的产品尚未生成镜像列表，则需要参考文档 [生成 T9k 产品镜像列表](../appendix/generate-t9k-product-image-list.md)。

## 下一步

完成本文档的准备工作后，可进行实际的 [产品安装](./install.md)。

## 参考

<https://freessl.cn/>

<https://letsencrypt.org/>

<https://zerossl.com/>
