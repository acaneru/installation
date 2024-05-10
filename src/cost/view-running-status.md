# 查看运行状态

## Cost Server

查看 Cost Web 运行状态：

```bash
kubectl get pod -n t9k-system -l app=cost-web
```

```
NAME                        READY   STATUS    RESTARTS   AGE
cost-web-7b899f4b8c-jkhnk   2/2     Running   0          3d22h
```

查看 Cost Server 运行状态：

```bash
kubectl get pod -n t9k-system -l app=cost-server
```

```
NAME                          READY   STATUS    RESTARTS        AGE
cost-server-cc67588bd-mmplv   2/2     Running   2 (3d22h ago)   3d22h
```

## 数据服务

查看 PostgreSQL 运行状态：

```bash
kubectl get pod -n t9k-system -l app.kubernetes.io/instance=cost-server-postgresql
```

```
NAME                       READY   STATUS    RESTARTS   AGE
cost-server-postgresql-0   1/1     Running   0          3d22h
```

查看 Prometheus 运行状态：

```bash
kubectl get pod -n t9k-system -l prometheus=cost-server
```

```
NAME                       READY   STATUS    RESTARTS   AGE
prometheus-cost-server-0   2/2     Running   0          3d22h
prometheus-cost-server-1   2/2     Running   0          3d22h
```

## 定时任务

另外，Cost Server 还会定期运行一些任务，包括：

* 每天计算一次费用，存储到数据库中
* 每小时计算一次费用，存储到数据库中
* 清除数据库中 30 天（可配置）以前的小时级别的数据

查看每天计算费用的任务：

```bash
kubectl get pod -n t9k-system -l app=cost-server-save-daily
```

```
NAME                                      READY   STATUS      RESTARTS        AGE
cost-server-save-daily-28500030-jkb6m     0/1     Completed   0               2d20h
cost-server-save-daily-28501470-tw62v     0/1     Completed   0               44h
cost-server-save-daily-28502910-4lplz     0/1     Completed   0               20h
```

查看每小时计算费用的任务：

```bash
kubectl get pod -n t9k-system -l app=cost-server-save-hourly
```

```
NAME                                       READY   STATUS      RESTARTS        AGE
cost-server-save-hourly-28504025-hvrvb     0/1     Completed   0               135m
cost-server-save-hourly-28504085-qfqmc     0/1     Completed   0               75m
cost-server-save-hourly-28504145-s7nzc     0/1     Completed   0               15m
```

查看清除过时数据的任务：

```bash
kubectl get pod -n t9k-system -l app=cost-server-clean-hourly
```

```
NAME                                        READY   STATUS      RESTARTS        AGE
cost-server-clean-hourly-28500010-bfz96     0/1     Completed   0               2d21h
cost-server-clean-hourly-28501450-qjgnx     0/1     Completed   0               45h
cost-server-clean-hourly-28502890-dt5k7     0/1     Completed   0               21h
```
