# 准备

## 前提条件

执行安装命令的环境要求：

| 条件 | 说明                                                                                                     |
| ---- | -------------------------------------------------------------------------------------------------------- |
| 软件 | 安装了以下软件，建议的版本如下：<ul><li>kubectl，v1.25.9</li><li>helm，v3.9.0</li></ul>                  |
| 网络 | <ul><li>可以使用 kubectl 访问 K8s 集群</li><li>能够访问存放安装包的网络服务，以下载 Helm chart</li></ul> |

网络联通要求：

* “执行安装命令” 的环境应当能够通过网络访问 “K8s 集群”。
* “K8s 集群” 应当能够访问安装过程中使用的容器镜像服务（一般在公网上，可支持本地 mirror）。
* “执行安装命令” 的环境应当能够访问存放安装包的网络服务（一般在公网上，可支持本地 mirror）。
* T9k 产品使用者应当能够访问 “K8s 集群” 上部署的服务。

## Pre-Install

### 域名相关设置

准备可用域名、设置域名解析、获得域名证书。

### 域名

域名：用户应当以合适的途径获得域名，并正确配置其解析。下文假设用户选择使用 DNS sample.t9kcloud.cn 部署产品，各个具体的模块的子 DNS 如下表。

| 域名                         | 说明                                |
| ---------------------------- | ----------------------------------- |
| `home.sample.t9kcloud.cn`    | 平台主入口                          |
| `auth.sample.t9kcloud.cn`    | 安全系统                            |
| `lakefs.sample.t9kcloud.cn`  | AI 资产和实验管理服务的 S3 接口地址 |
| `\*.ksvc.sample.t9kcloud.cn` | 模型推理服务                        |

注意事项：

1. 具体安装时，应当替换 sample.t9kcloud.cn 为实际的名称。
1. 为了简化安装流程，可配置 `*.sample.t9kcloud.cn` 的域名证书和域名解析，而不是分开配置上面多个域名。
1. 也可以选择不同模块使用不同的 DNS 后缀，具体细节见“其他场景”部分。
1. knative 服务使用的域名应该在**前提条件**-安装 **K8s 及必要组件**的步骤中配置，具体细节见“其他场景”部分。
1. 如果要在中国公有云服务中部署 TensorStack AI 平台，域名一般需要备案才能使用。备案细节请咨询云服务提供商。

### 解析

在域名服务商处设置域名解析。为 `*.sample.t9kcloud.cn` 域名添加一条 A （或者 CNAME）记录，使其最终正确指向 K8s 集群的 [ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/#what-is-ingress) 服务的 IP 地址。

验证为期望值：

```bash
dig home.sample.t9kcloud.cn +short
```

### 证书

用于支持 HTTPS 的证书可以在服务商处购买，也可以使用免费证书服务（如 <https://freessl.cn/>， <https://letsencrypt.org/>，<https://zerossl.com/>）。

证书以 2 个文件（具体名字可变）的形式提供，公钥证书（public key certificate）和私钥（private key）：

```
server.crt
server.key
```

可以使用如下命令对证书进行验证：

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

### 创建前置 K8s 资源

#### namespace

您需要创建以下 namespace：

| Resource name  | Resource Namespace | 说明                        |
| -------------- | ------------------ | --------------------------- |
| t9k-system     | \-                 | TensorStack AI 平台控制平面 |
| t9k-syspub     | \-                 | 用于存储公共配置            |
| t9k-monitoring | \-                 | 用于监控及告警系统          |

确认以下 namespace 存在，如果不存在则创建：

```bash
$ kubectl get ns t9k-system
$ kubectl get ns t9k-syspub
$ kubectl get ns t9k-monitoring

$ for ns in "t9k-system" "t9k-syspub" "t9k-monitoring"; do
  kubectl create ns "$ns"
done
```

#### Set namespace label

为运行 TensorStack AI 平台系统功能的 Namespace 设置 label: `control-plane="true"`。

没有 `control-plane` label（Key 值相同就行，Value 可以是任意值）的 Namespace 会受到 Admission Control 产品的检查。运行 TensorStack AI 平台服务的 Namespace 中的 Pod 并不需要这些检查。添加这个 label 可以防止 Admission Control 的影响：

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

#### 证书 Secret

您需要创建以下 Secret：

| Resource name     | Resource Namespace | 说明                                                                              |
| ----------------- | ------------------ | --------------------------------------------------------------------------------- |
| cert.landing-page | istio-system       | 平台主入口的 ingress 使用（`home.sample.t9kcloud.cn`）                            |
| cert.keycloak     | t9k-system         | 安全系统的 ingress 使用（`auth.sample.t9kcloud.cn`）                              |
| cert.lakefs       | t9k-system         | AI 资产和实验管理服务的 S3 接口地址的 ingress 使用（`lakefs.sample.t9kcloud.cn`） |

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

1. 如果使用单独的证书，需要在上面的命令中使用不同的文件分别创建 secret。
1. 目前模型推理服务的 ingress (*.ksvc.sample.t9kcloud.cn) 使用 HTTP 协议，不需要配置 cert/secret

#### Ingress

安装过程中需要创建以下 ingress：

| Resource name    | Resource Namespace | 说明                            |
| ---------------- | ------------------ | ------------------------------- |
| t9k.landing-page | istio-system       | 平台主入口                      |
| t9k.keycloak     | t9k-system         | 安全系统                        |
| t9k.lakefs       | t9k-system         | AI 资产和实验管理服务的 S3 接口 |
| t9k.serving      | istio-system       | 模型推理服务                    |

运行以下命令创建 ingress `t9k.landing-page`：

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

1. 其他 ingress 将在后续安装过程中自动创建

### 设置 

#### 配置 values.yaml

从 <https://github.com/t9k/ks-clusters/tree/master/values> 获取 values.yaml，并参考 values.yaml 中的注释进行修改。

<aside class="note">
<div class="title">注意</div>

带有注释 MUST 的设置必须检查。

</aside>

#### Pre-Pull Image

[可选] 预先下载 T9k 产品需要的所有镜像。

从 github 上获取与产品对应的<a target="_blank" rel="noopener noreferrer" href="https://github.com/t9k/ks-clusters/tree/master/tools/offline-t9k/imagelist">镜像列表</a>，拉取列表中的镜像：

```bash
for image in $(cat t9k-2024-02-01.list); do
    docker pull $image
done
```

如果您计划安装的产品尚未生成镜像列表，则需要根据文档[生成 T9k 产品镜像列表](../appendix/generate-t9k-product-image-list.md)。

