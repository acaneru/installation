# 监控相关

为了使监控系统正常工作，还需要创建额外的 K8s 资源。

## 目的

确保系统 namespace `kube-system` 中存在 `svc/kube-scheduler svc/kube-controller-manager`。 

## kube-system service

在创建之前，请先确认系统中是否已经存在相应的 service。以下展示的 k8s cluster，由于已经创建了相应的 Service，则无需创建。

```bash
kubectl -n kube-system get svc/kube-scheduler svc/kube-controller-manager
```

```console
NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)     AGE
kube-scheduler            ClusterIP   10.233.18.162   <none>        10259/TCP   39m
kube-controller-manager   ClusterIP   10.233.19.17    <none>        10257/TCP   32m
```

如果并无上述 service， 则可手工创建：

```bash
kubectl apply -n kube-system -f ../ks-clusters/additionals/monitoring/kube-system-svc.yaml
```
