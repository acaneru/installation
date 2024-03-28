# 更新 Security Console

本文档中，`%` 表示在本地 Terminal 中执行的操作（本地指可以连接到集群的环境），`postgres=#` 表示在 SQL 终端执行的操作。

将 SQL 服务暴露出来：

```bash
% kubectl port-forward service/keycloak-postgresql -n t9k-system 5432:5432
```

连接到 SQL 终端：

```bash
% psql -h localhost -p 5432 -U postgres -d postgres
```

查看所有的 database：

```sql
postgres=# \l
                                                List of databases
   Name    |  Owner   | Encoding |  Collate   |   Ctype    | ICU Locale | Locale Provider |   Access privileges
-----------+----------+----------+------------+------------+------------+-----------------+-----------------------
 postgres  | postgres | UTF8     | en_US.utf8 | en_US.utf8 |            | libc            |
 root      | keycloak | UTF8     | en_US.utf8 | en_US.utf8 |            | libc            |
 template0 | postgres | UTF8     | en_US.utf8 | en_US.utf8 |            | libc            | =c/postgres          +
           |          |          |            |            |            |                 | postgres=CTc/postgres
 template1 | postgres | UTF8     | en_US.utf8 | en_US.utf8 |            | libc            | =c/postgres          +
           |          |          |            |            |            |                 | postgres=CTc/postgres
(4 rows)
```

经查看，只有 root database 中有数据，template1 和 postgres database 中无数据，template0 无法连接。

备份 root database 中的数据：

```bash
% pg_dump -h localhost -p 5432 -U postgres -d root > kc_root
```

删除 security console 组件：

```bash
% helm uninstall t9k-security-console -n t9k-system
```

在 security console 完全删除后，重新创建 security console 组件：

```bash
% helm install t9k-security-console \
   oci://tsz.io/t9kcharts/t9k-security-console \
   -f values-sample-1.78.6.yaml -n t9k-system
```

（在升级产品时，应该执行 helm upgrade 操作，测试时该操作不一定会导致数据库错误，所以干脆测试删除重装）

（在产品升级时，如果 keycloak 可以正常运行，则没有必要执行后面的恢复操作）

将 keycloak 规模缩小为 0，避免在恢复数据库时出现错误：

```bash
% kubectl scale deployment -n t9k-system keycloak --replicas 0
```

清空 postgreSQL 中 root 数据库：

```bash
% psql -h localhost -p 5432 -U postgres -d postgres
psql (15.4, server 10.17)
Type "help" for help.

postgres=# drop database root;
postgres=# create database root;
CREATE DATABASE
```

* keycloak 在部署的时候会自动初始化数据库，已经初始化了的数据库无法再恢复数据（存在数据冲突），所以我们删除 root database 并重新创建

恢复数据：

```bash
% psql -h localhost -p 5432 -U postgres -d root < kc_root
```

恢复 keycloak deploy：

```bash
% kubectl scale deployment -n t9k-system keycloak --replicas 1
```
