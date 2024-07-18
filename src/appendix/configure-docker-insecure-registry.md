# 配置 Docker Insecure Registry

局域网环境内运行的 Registry 没有使用域名证书，从该 Registry 拉取镜像时可能遇到 `server gave HTTP response to HTTPS client` 的错误信息。此时可以通过修改 Docker 守护进程的配置来解决该问题。

确认 daemon.json 文件是否存在：

```bash
$ sudo ls /etc/docker/daemon.json
```

如果文件不存在：

```bash
$ sudo mkdir -p /etc/docker
$ sudo cat > /etc/docker/daemon.json << EOF
{
  "insecure-registries" : ["<IP or hostname>:5000"]
}
EOF
```

如果文件存在，则在 json 中增加一行内容：

```json
  "insecure-registries" : ["<IP or hostname>:5000"],
```

重启 Docker 使配置生效：

```bash
$ sudo systemctl restart docker
```
