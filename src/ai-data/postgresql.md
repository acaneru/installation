# PostgreSQL

## 查看运行状态

查看 PostgreSQL 运行状态：

```bash
$ kubectl get sts -n t9k-system aistore-postgresql
NAME                 READY   AGE
aistore-postgresql   1/1     26d
```

查看 PostgreSQL 的日志：

```bash
$ kubectl logs -n t9k-system -l app.kubernetes.io/instance=aistore-postgresql --tail=100 -f
postgresql 09:20:39.02
postgresql 09:20:39.02 Welcome to the Bitnami postgresql container
postgresql 09:20:39.03 Subscribe to project updates by watching https://github.com/bitnami/containers
postgresql 09:20:39.03 Submit issues and feature requests at https://github.com/bitnami/containers/issues
postgresql 09:20:39.04
postgresql 09:20:39.10 INFO  ==> ** Starting PostgreSQL setup **
postgresql 09:20:39.13 INFO  ==> Validating settings in POSTGRESQL_* env vars..
postgresql 09:20:39.15 INFO  ==> Cleaning stale /bitnami/postgresql/data/postmaster.pid file
postgresql 09:20:39.16 INFO  ==> Loading custom pre-init scripts...
postgresql 09:20:39.17 INFO  ==> Initializing PostgreSQL database...
...
```

## 查看配置

查看 PostgresQL 的配置：

```bash
$ kubectl get secret -n t9k-system aistore-postgresql  -o yaml
```

配置示例：

```yaml
apiVersion: v1
data:
  postgres-password: <xxxxxxxxxx>
kind: Secret
metadata:
  name: aistore-postgresql
  namespace: t9k-system
type: Opaque
```
