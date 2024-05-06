# Knative

TODO: 修改此文档以支持各种版本的 k8s/istio 安装。

## 目的

安装 Knative，版本 v1.9.0

## 前置条件

1. Kubernetes 集群版本：v1.25.9
1. <a target="_blank" rel="noopener noreferrer" href="https://istio.io/">Istio</a>，v1.15.2
1. <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.github.io/ingress-nginx/deploy/">NGINX Ingress Controller</a>，v1.7.1

## 安装


<aside class="note">
<div class="title">离线安装</div>

如需要使用本地镜像仓库（替换 `192.168.101.159:5000` 为实际的地址）：

```bash
# verify t9kpublic is only used in image name
grep t9kpublic ../ks-clusters/additionals/knative/v1.9.0/*

# replace image registry
sed -i "s|t9kpublic|192.168.101.159:5000/t9kpublic|g" \
    ../ks-clusters/additionals/knative/v1.9.0/*
```
</aside>

运行以下命令在 K8s 集群中安装 Knative：

```bash
kubectl apply -f ../ks-clusters/additionals/knative/v1.9.0/serving-crds.yaml
kubectl apply -f ../ks-clusters/additionals/knative/v1.9.0/serving-core.yaml
kubectl apply -f ../ks-clusters/additionals/knative/v1.9.0/net-istio.yaml
```

## 安装后配置

### 修改 config

修改 knative config-domain 来配置 DNS 的 domain suffix。

下面的示例会将 domain suffix 设置为 `ksvc.sample.t9kcloud.cn`。

```bash
kubectl patch configmap/config-domain \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"ksvc.sample.t9kcloud.cn":""}}'
```

<aside class="note">
<div class="title">离线安装</div>

如果你使用的是基于 HTTP 的镜像仓库，则还需要添加额外设置：

```bash
kubectl patch configmap/config-deployment \
  --namespace knative-serving \
  --type merge \
  --patch '{"data":{"registries-skipping-tag-resolving":"192.168.101.159:5000"}}'
```
</aside>

### 配置 Ingress

创建如下所示的 Ingress，需要注意：

1. `spec.rules[0].host` 应该与前述步骤的 domain suffix 一致。
1. 需要配置 DNS，让 `*.ksvc.sample.t9kcloud.cn` 能够映射到 ingress 所在的节点的 IP。

```bash
kubectl -n istio-system create -f ../ks-clusters/additionals/knative/v1.9.0/ingress.yaml

# verify it's there
kubectl -n istio-system get ing/t9k.serving
```

## 验证

确认 pods running：

```bash
kubectl -n knative-serving get pods
```

输出：

```console
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
kubectl -n default create -f ../ks-clusters/additionals/knative/v1.9.0/hello-ksvc.yaml
```

等待 knative service 就绪：

```bash
kubectl -n default get ksvc
```

输出：

```console
NAME         URL                                                 LATESTCREATED      LATESTREADY        READY   REASON
helloworld   http://helloworld.default.ksvc.sample.t9kcloud.cn   helloworld-00001   helloworld-00001   True 
```

使用 curl 进行测试：

```bash
# 如果已经创建了域名解析
curl helloworld.default.ksvc.sample.t9kcloud.cn

# 如果尚未创建域名解析
curl -H "Host: helloworld.default.ksvc.sample.t9kcloud.cn" <ingress-nginx-ip>
```

输出：

```console
Hello World!
```

## 参考

<https://knative.dev/docs/install/yaml-install/serving/install-serving-with-yaml/>
