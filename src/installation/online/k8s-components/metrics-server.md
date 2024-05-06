# Metrics Server

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
