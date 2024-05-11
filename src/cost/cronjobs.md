# CronJob

计费系统会定期运行一些任务，包括：

* 每天计算一次费用，存储到 PostgreSQL 数据库中。
* 每小时计算一次费用，存储到 PostgreSQL 数据库中。
* 每天清除 PostgreSQL 数据库中 30 天以前的小时级别的数据。

## 查看运行状态

### 费用计算 - 每天

运行状态：

```bash
kubectl get cronjob -n t9k-system cost-server-save-daily 
```

```
NAME                     SCHEDULE     SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cost-server-save-daily   30 0 * * *   False     0        21h             127d
```

```bash
kubectl get pod -n t9k-system -l app=cost-server-save-daily
```

```
NAME                                      READY   STATUS      RESTARTS        AGE
cost-server-save-daily-28500030-jkb6m     0/1     Completed   0               2d20h
cost-server-save-daily-28501470-tw62v     0/1     Completed   0               44h
cost-server-save-daily-28502910-4lplz     0/1     Completed   0               20h
```

### 费用计算 - 每小时

运行状态：

```bash
kubectl get cronjob -n t9k-system cost-server-save-hourly
```

```
NAME                      SCHEDULE    SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cost-server-save-hourly   5 * * * *   False     0        43m             127d
```

```bash
kubectl get pod -n t9k-system -l app=cost-server-save-hourly
```

```
NAME                                       READY   STATUS      RESTARTS        AGE
cost-server-save-hourly-28504025-hvrvb     0/1     Completed   0               135m
cost-server-save-hourly-28504085-qfqmc     0/1     Completed   0               75m
cost-server-save-hourly-28504145-s7nzc     0/1     Completed   0               15m
```

### 数据清除 - 每天

运行状态：

```bash
kubectl get cronjob -n t9k-system cost-server-clean-hourly
```

```
NAME                       SCHEDULE     SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cost-server-clean-hourly   10 0 * * *   False     0        21h             127d
```

```bash
kubectl get pod -n t9k-system -l app=cost-server-clean-hourly
```

```
NAME                                        READY   STATUS      RESTARTS        AGE
cost-server-clean-hourly-28500010-bfz96     0/1     Completed   0               2d21h
cost-server-clean-hourly-28501450-qjgnx     0/1     Completed   0               45h
cost-server-clean-hourly-28502890-dt5k7     0/1     Completed   0               21h
```

## 查看配置

### 费用计算 - 每天

查看配置：

```bash
kubectl get cronjob -n t9k-system cost-server-save-daily -o yaml
```

修改配置：

```bash
kubectl edit cronjob -n t9k-system cost-server-save-daily
```

<details><summary><code class="hljs">配置示例：cronjob-cost-server-save-daily.yaml</code></summary>

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: cost-server-save-daily
  namespace: t9k-system
spec:
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - args:
            - cost-model
            - save-daily
            env:
            - name: TZ
              value: Asia/Shanghai
            - name: T9K_SECURITY_SERVER_URL
              value: https://security-console-server.t9k-system:8081
            - name: T9K_POSTGRES_HOST
              value: cost-server-postgresql
            ...
            image: tsz.io/t9k/cost-server:1.79.1
            imagePullPolicy: IfNotPresent
            name: cost-server-save-daily
  schedule: 30 0 * * *
  timeZone: Asia/Shanghai
...
```

</details>

其中：

* `spec.jobTemplate.spec.template.spec.containers.env` 字段表示服务的基础配置，与 [Cost Server 配置](cost-server.md#查看配置) 完全一致。
* `spec.schedule` 字段表示定期任务的时间表，格式参考 <a target="_blank" rel="noopener noreferrer" href="https://en.wikipedia.org/wiki/Cron">Cron format</a>。
* `spec.timeZone` 字段表示定期任务时间表的执行时区，与上述 `env` 中名称为 `TZ` 的值一致，国内环境通常设置为 `Asia/Shanghai`。

### 费用计算 - 每小时

```bash
kubectl get cronjob -n t9k-system cost-server-save-hourly
```
查看配置、修改同上。

### 数据清除 - 每天

```bash
kubectl get cronjob -n t9k-system cost-server-clean-hourly
```

查看配置、修改同上。
