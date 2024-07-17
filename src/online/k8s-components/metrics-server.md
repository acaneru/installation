# Metrics Server

Istio 依赖于  <a target="_blank" rel="noopener noreferrer" href="https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/"> HPA(Horizontal Pod Autoscaler)</a>，而 HPA 依赖 <a target="_blank" rel="noopener noreferrer" href="https://github.com/kubernetes-sigs/metrics-server#kubernetes-metrics-server">kubernetes metrics server</a>，所以需要部署 metrics server。

## 目的

确保集群中 Metrics Server 安装正确。

## 正确性检查

查看 Istio 的 HPA：

```bash
kubectl -n istio-system get hpa
```

输出：

```console
NAME                   REFERENCE                         TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
istio-ingressgateway   Deployment/istio-ingressgateway   67%/80%   1         5         5          221d
istiod                 Deployment/istiod                 13%/80%   1         5         1          221d
```

查看 APIService：

```bash
# 查看当前版本
kubectl get APIService v1beta1.metrics.k8s.io
```

确认 metrics server 可用：

```bash
kubectl top node
```

输出：

```
NAME    CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
node01    1113m        13%    14691Mi         46%       
node02    1336m        11%    13375Mi         42%       
```

## 参考

- <https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/>
- <https://github.com/kubernetes-sigs/metrics-server#kubernetes-metrics-server>
