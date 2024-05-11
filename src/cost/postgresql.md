# PostgreSQL

## 查看运行状态

运行状态：

```bash
kubectl get pod -n t9k-system -l app.kubernetes.io/instance=cost-server-postgresql
```

```
NAME                       READY   STATUS    RESTARTS   AGE
cost-server-postgresql-0   1/1     Running   0          3d22h
```

日志：

```bash
kubectl logs -n t9k-system -l app.kubernetes.io/instance=cost-server-postgresql --tail=100 -f
```

<details><summary><code class="hljs">output</code></summary>

```
postgresql 08:41:49.90
postgresql 08:41:49.91 Welcome to the Bitnami postgresql container
postgresql 08:41:49.92 Subscribe to project updates by watching https://github.com/bitnami/containers
postgresql 08:41:49.92 Submit issues and feature requests at https://github.com/bitnami/containers/issues
postgresql 08:41:49.93
postgresql 08:41:49.98 INFO  ==> ** Starting PostgreSQL setup **
postgresql 08:41:50.01 INFO  ==> Validating settings in POSTGRESQL_* env vars..
postgresql 08:41:50.03 INFO  ==> Cleaning stale /bitnami/postgresql/data/postmaster.pid file
postgresql 08:41:50.04 INFO  ==> Loading custom pre-init scripts...
postgresql 08:41:50.06 INFO  ==> Initializing PostgreSQL database...
postgresql 08:41:50.12 INFO  ==> pg_hba.conf file not detected. Generating it...
postgresql 08:41:50.12 INFO  ==> Generating local authentication configuration
postgresql 08:41:50.17 INFO  ==> Deploying PostgreSQL with persisted data...
postgresql 08:41:50.21 INFO  ==> Configuring replication parameters
postgresql 08:41:50.28 INFO  ==> Configuring fsync
postgresql 08:41:50.30 INFO  ==> Configuring synchronous_replication
postgresql 08:41:50.37 INFO  ==> Loading custom scripts...
postgresql 08:41:50.38 INFO  ==> Enabling remote connections
postgresql 08:41:50.40 INFO  ==> ** PostgreSQL setup finished! **

postgresql 08:41:50.44 INFO  ==> ** Starting PostgreSQL **
2024-05-11 08:41:50.608 GMT [1] LOG:  pgaudit extension initialized
2024-05-11 08:41:50.638 GMT [1] LOG:  starting PostgreSQL 15.3 on x86_64-pc-linux-gnu, compiled by gcc (Debian 10.2.1-6) 10.2.1 20210110, 64-bit
2024-05-11 08:41:50.640 GMT [1] LOG:  listening on IPv4 address "0.0.0.0", port 5432
2024-05-11 08:41:50.640 GMT [1] LOG:  listening on IPv6 address "::", port 5432
2024-05-11 08:41:50.654 GMT [1] LOG:  listening on Unix socket "/tmp/.s.PGSQL.5432"
2024-05-11 08:41:50.733 GMT [96] LOG:  database system was interrupted; last known up at 2024-05-11 08:07:42 GMT
2024-05-11 08:41:50.977 GMT [96] LOG:  database system was not properly shut down; automatic recovery in progress
2024-05-11 08:41:51.136 GMT [96] LOG:  redo starts at 0/AE7EC10
2024-05-11 08:41:51.136 GMT [96] LOG:  invalid record length at 0/AE7ECF8: wanted 24, got 0
2024-05-11 08:41:51.136 GMT [96] LOG:  redo done at 0/AE7ECC0 system usage: CPU: user: 0.00 s, system: 0.00 s, elapsed: 0.00 s
2024-05-11 08:41:51.278 GMT [94] LOG:  checkpoint starting: end-of-recovery immediate wait
2024-05-11 08:41:52.062 GMT [94] LOG:  checkpoint complete: wrote 3 buffers (0.0%); 0 WAL file(s) added, 0 removed, 0 recycled; write=0.002 s, sync=0.183 s, total=0.800 s; sync files=2, longest=0.168 s, average=0.092 s; distance=0 kB, estimate=0 kB
2024-05-11 08:41:52.078 GMT [1] LOG:  database system is ready to accept connections
...
```

</details>

## 查看配置

查看配置：

```bash
kubectl get secret -n t9k-system cost-server-postgresql -o yaml
```

配置示例：

```yaml
apiVersion: v1
data:
  postgres-password: <xxxxxxxxxx>
kind: Secret
metadata:
  name: cost-server-postgresql
  namespace: t9k-system
type: Opaque
```

PostgresQL 初始化后，一般不需要修改密码。

## 查看数据库

连接数据库：

```bash
kubectl -n t9k-system exec -it cost-server-postgresql-0
  -- psql 'postgresql://<username>:<password>@localhost:5432/cost_server'
```

进入数据库交互终端：

```
psql (15.3)
Type "help" for help.

cost_server=#
```

在数据库交互终端查看表的列表：

```
cost_server=# \d
                  List of relations
 Schema |         Name         |   Type   |  Owner
--------+----------------------+----------+----------
 public | cost_daily           | table    | postgres
 public | cost_hourly          | table    | postgres
 public | resource_type        | table    | postgres
 public | resource_type_id_seq | sequence | postgres
(4 rows)
```

其中：

* `cost_daily` 表保存历史上每天的费用统计数据。
* `cost_hourly` 表保存最近 30 天每小时的费用统计数据。
* `resource_type` 表保存所有的资源类型。
* `resource_type_id_seq` 序列用于表 `resource_type` 的主键自增，系统自动创建。

在数据库交互终端查看表的详情：

```
cost_server=# \d cost_daily
                       Table "public.cost_daily"
   Column   |           Type           | Collation | Nullable | Default
------------+--------------------------+-----------+----------+---------
 start_time | timestamp with time zone |           | not null |
 project    | character varying(64)    |           | not null |
 owner      | character varying(256)   |           |          |
 res_type   | integer                  |           | not null |
 res_usage  | numeric                  |           |          |
 res_price  | numeric                  |           |          |
 res_cost   | numeric                  |           |          |
Indexes:
    "cost_daily_pkey" PRIMARY KEY, btree (start_time, project, res_type)
```

其中：

* `start_time` 列表示计费的起始时间。
* `project` 列表示项目的名称。
* `owner` 列表示项目的所有者名称。
* `res_type` 列表示资源类型，指向表 `resource_type` 的主键 `id`。
* `res_usage` 列表示该项目内的所有容器在该计费窗口内使用该种资源的平均使用量之和。
* `res_price` 列表示该计费窗口内该种资源的平均单价。
* `res_cost` 列表示该项目内的所有容器在该计费窗口内使用该种资源产生的总费用。

其他表的查询同上。

## 备份及恢复

详情：[数据备份 > PostgreSQL 备份](../data-backup/postgres-backup.md)
