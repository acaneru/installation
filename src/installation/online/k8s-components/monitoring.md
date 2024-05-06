# 监控相关

为了使监控系统正常工作，还需要创建额外的 K8s 资源。

## kube-system service

<aside class="note">
<div class="title">注意</div>

有些 kubernetes 的安装需要手动在 namespace kube-system 中为 kube-scheduler 和 kube-controller-manager 创建 service。

</aside>

在创建之前，请先确认系统中是否已经存在相应的 service。以下展示的 k8s cluster，由于已经创建了相应的 Service，则无需创建。

```bash
$ kubectl -n kube-system get svc/kube-scheduler svc/kube-controller-manager
NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)     AGE
kube-scheduler            ClusterIP   10.233.18.162   <none>        10259/TCP   39m
kube-controller-manager   ClusterIP   10.233.19.17    <none>        10257/TCP   32m
```

如果并无上述 service， 则可手工创建，如下所示：

```bash
$ kubectl apply -n kube-system -f ../ks-clusters/additionals/monitoring/kube-system-svc.yaml
```

## cAdvisor

cAdvisor 的安装依赖 t9k-monitoring 产品。已经移动到 [Post Install](../install-products.md#安装-cadvisor-服务)。
