# PostgreSQL 备份

平台部署有以下 PostgreSQL 实例：

| 名称        | PostgreSQL 版本 | 用途                                        |
| ----------- | --------------- | ------------------------------------------- |
| keycloak    | 15.3.0          | 存储用户名、密码、apikey 等信息             |
| aistore     | 15.3.0          | 存储 aistore 和 lakefs 的相关信息           |
| cost server | 15.3.0          | 存储各个 Project 使用资源产生的费用统计信息 |

我们支持两种数据备份方式：

* pg_dump：局部备份，备份粒度为 postgresql 中一个 database。应用场景为：只更新 security console 的情况下，则只需要备份 database apikey。
* pg_basebackup：完整备份，会备份 postgresql 的所有数据（包括用户信息和用户密码等）。在局部产品更新时，不建议用这种备份/恢复方式。

在更新产品时，应同时使用这两种方式备份数据。在产品完成更新后，先用第一种方式尝试恢复；如果 postgresql 出现问题，再尝试使用第二种方式，重新创建 postgresql 并恢复完整数据。

## 用 pg_dump 命令备份

以 aistore 为例，在本地 terminal 执行以下命令备份/恢复 postgresql 数据库：

```bash
# 将集群中的服务暴露到本地：
kubectl port-forward service/aistore-postgresql -n t9k-system 5432:5432

# 数据备份
pg_dump -h localhost -p 5432 -U postgres -d aistore > back_up

# 数据恢复
psql -h localhost -p 5432 -U postgres -d aistore < back_up
```

其中：

* 在恢复数据前，需在目标 postgresql 中创建对应 database，即上例中的 `-d aistore`。
* 如果一个数据库的 owner 不是 postgres，那么在恢复数据前，需要创建该用户，并在恢复数据时使用该用户名，即上例中的 `-U postgres`。

    ```sql
    -- 在 terminal 中执行 psql -h localhost -p 5432 -U postgres -d postgres 进入 postgres 终端

    -- 创建用户
    CREATE USER security_console WITH PASSWORD 'tensorstack';
    -- 创建数据库
    CREATE DATABASE apikey;
    -- 设置数据库的 owner
    ALTER DATABASE apikey OWNER TO security_console;
    ```

<aside class="note tip">
<div class="title">提示</div>

psql 和 pg_dump 等工具可在 <a target="_blank" rel="noopener noreferrer" href="https://www.postgresql.org/download/">PostgreSQL 官网</a>下载（推荐使用和服务器相同版本的 cli 工具）。

</aside>

### keycloak postgresql

数据库对应集群中的资源：

```bash
kubectl get pods -n t9k-system -l app=keycloak -l component=database
```

```
NAME                                   READY   STATUS    RESTARTS   AGE
keycloak-postgresql-76b66864bd-dlddd   1/1     Running   0          2d20h
```

```bash
kubectl get service -n t9k-system keycloak-postgresql
```
```
NAME                  TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
keycloak-postgresql   ClusterIP   10.233.5.90   <none>        5432/TCP   55d
```

keycloak postgresql 中有以下 5 个数据库：

```sql
postgres=> \l
                                                          List of databases
   Name    |      Owner       | Encoding | Locale Provider |  Collate   |   Ctype   
-----------+------------------+----------+-----------------+------------+------------
 apikey    | postgres | UTF8     | libc            | en_US.utf8 | en_US.utf8
 postgres  | postgres         | UTF8     | libc            | en_US.utf8 | en_US.utf8
 root      | postgres         | UTF8     | libc            | en_US.utf8 | en_US.utf8
 template0 | postgres         | UTF8     | libc            | en_US.utf8 | en_US.utf8
 template1 | postgres         | UTF8     | libc            | en_US.utf8 | en_US.utf8
(5 rows)
```

其中 postgres、template0 和 template1 是部署 postgresql 服务时自动创建的数据库，我们不使用也不需要备份这三个数据库。

恢复数据时，需要注意 apikey 和 root 两个数据库的 Owner。

**apikey database** 用于存储 security console 中的 apikey 信息，其中有以下表：

```sql
apikey=> \d
             List of relations
 Schema |  Name  | Type  |      Owner
--------+--------+-------+------------------
 public | client | table | security_console
 public | key    | table | security_console
 public | token  | table | security_console
(3 rows)
```

**root database** 用于存储 keycloak 中各项信息，其中有以下表：

```sql
                     List of relations
 Schema |             Name              | Type  |  Owner
--------+-------------------------------+-------+----------
 public | admin_event_entity            | table | keycloak
 public | associated_policy             | table | keycloak
 public | authentication_execution      | table | keycloak
 .........
 .........
 public | user_session_note             | table | keycloak
 public | username_login_failure        | table | keycloak
 public | web_origins                   | table | keycloak
(92 rows)
```

### aistore postgresql

数据库对应集群中的资源：

```bash
kubectl get pods -n t9k-system -l app.kubernetes.io/instance=aistore-postgresql
```

```
NAME                   READY   STATUS    RESTARTS   AGE
aistore-postgresql-0   1/1     Running   0          11d
```
```bash
kubectl get service -n t9k-system aistore-postgresql
```
```
NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
aistore-postgresql   ClusterIP   10.233.48.204   <none>        5432/TCP   53d
```

aistore postgresql 中有以下 5 个数据库：

```sql
postgres=# \l
                           List of databases
   Name    |  Owner   | Encoding | Locale Provider |   Collate   |    Ctype   
-----------+----------+----------+-----------------+-------------+-------------
 aistore   | postgres | UTF8     | libc            | en_US.UTF-8 | en_US.UTF-8 
 lakefs    | postgres | UTF8     | libc            | en_US.UTF-8 | en_US.UTF-8 
 postgres  | postgres | UTF8     | libc            | en_US.UTF-8 | en_US.UTF-8 
 template0 | postgres | UTF8     | libc            | en_US.UTF-8 | en_US.UTF-8 
 template1 | postgres | UTF8     | libc            | en_US.UTF-8 | en_US.UTF-8 
(5 rows)
```

其中 postgres、template0 和 template1 是部署 postgresql 服务时自动创建的数据库，我们不使用也不需要备份这三个数据库。

**aistore database** 用于存储 aistore 中节点的组织信息，其中有以下表：

```sql
aistore=# \d
             List of relations
 Schema |     Name      | Type  |  Owner
--------+---------------+-------+----------
 public | acl           | table | postgres
 public | label         | table | postgres
 public | node          | table | postgres
 public | node_deleted  | table | postgres
 public | node_extra    | table | postgres
 public | node_graph    | table | postgres
 public | s3_credential | table | postgres
 public | tree          | table | postgres
(8 rows)
```

**lakefs database** 用于存储 lakefs 中 repo、access key 等信息，其中有以下表：

```sql
               List of relations
 Schema | Name  |       Type        |  Owner
--------+-------+-------------------+----------
 public | kv    | partitioned table | postgres
 public | kv_0  | table             | postgres
 .........
 .........
 public | kv_98 | table             | postgres
 public | kv_99 | table             | postgres
 public | kv_v  | view              | postgres
(102 rows)
```

### cost server postgresql

数据库对应集群中的资源：

```bash
kubectl get pods -n t9k-system -l app.kubernetes.io/instance=cost-server-postgresql
```

```
NAME                       READY   STATUS    RESTARTS   AGE
cost-server-postgresql-0   1/1     Running   0          9d
```

```bash
kubectl get service -n t9k-system cost-server-postgresql
```

```
NAME                     TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
cost-server-postgresql   ClusterIP   10.233.25.58   <none>        5432/TCP   9d
```

cost server postgresql 中有以下 4 个数据库：

```sql
postgres=# \l
                           List of databases
    Name     |  Owner   | Encoding | Locale Provider |   Collate   |    Ctype   
-------------+----------+----------+-----------------+-------------+-------------
 cost_server | postgres | UTF8     | libc            | en_US.UTF-8 | en_US.UTF-8 
 postgres    | postgres | UTF8     | libc            | en_US.UTF-8 | en_US.UTF-8 
 template0   | postgres | UTF8     | libc            | en_US.UTF-8 | en_US.UTF-8 
 template1   | postgres | UTF8     | libc            | en_US.UTF-8 | en_US.UTF-8 
(4 rows)
```

其中 postgres、template0 和 template1 是部署 postgresql 服务时自动创建的数据库，我们不使用也不需要备份这三个数据库。

**cost_server database** 用于存储集群中每天以及近期每小时的费用、计算资源的种类等信息，其中有以下表：

```sql
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

## 用 pg_basebackup 命令进行备份

deprecated
