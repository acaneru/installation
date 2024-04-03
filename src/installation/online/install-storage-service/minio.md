# MinIO

## 安装

本节说明针对测试场景，如何安装一个 Single-Node Single-Drive 的 minio 服务。参考 <a target="_blank" rel="noopener noreferrer" href="https://min.io/docs/minio/linux/operations/install-deploy-manage/deploy-minio-single-node-single-drive.html">Deploy MinIO: Single-Node Single-Drive</a>。

<aside class="note">
<div class="title">注意</div>

本文档仅介绍了一个单节点、测试目的的 minIO 安装流程；production 级别的安装请参考 minio 官方文档。

</aside>

### 安装

连接到计划安装 minio 的节点，下载并安装：

```bash
# Download from internet
$ wget https://dl.min.io/server/minio/release/linux-amd64/\
archive/minio_20231007150738.0.0_amd64.deb -O minio.deb

# 离线安装方案中，minio.deb 已经被复制到 ~/minio.deb

$ sudo dpkg -i minio.deb
```

创建 minio 用户及存储路径：

```bash
$ sudo groupadd -r minio-user
$ sudo useradd -M -r -g minio-user minio-user

$ sudo mkdir -p /data/minio
$ sudo chown minio-user:minio-user /data/minio
$ sudo chmod 750 /data/minio
```

在 /etc/default/minio 生成配置：

```bash
$ cat << EOF | sudo tee /etc/default/minio
MINIO_ROOT_USER=myminioadmin
MINIO_ROOT_PASSWORD=minio-secret-key-change-me

# MINIO_VOLUMES sets the storage volume or path to use for the MinIO server.

MINIO_VOLUMES="/data/minio"

# MINIO_SERVER_URL sets the hostname of the local machine for use with the MinIO Server
# MinIO assumes your network control plane can correctly resolve this hostname to the local machine

# Uncomment the following line and replace the value with the correct hostname for the local machine and port for the MinIO server (9000 by default).

#MINIO_SERVER_URL="http://minio.example.net:9000"
EOF
# ensure its privacy
$ sudo chmod 600 /etc/default/minio
# verify contents
$ sudo cat /etc/default/minio
```

启动 minio 系统服务：

```bash
$ sudo systemctl enable --now minio
```

查看 minio 运行状态，以确认服务正常启动：

```bash
$ sudo systemctl status minio
$ sudo journalctl -f -u minio
```

### 测试

WEB UI 的地址可以在其 log 中获得：

```bash
$ sudo journalctl -f -u minio
```

若通过 S3 协议，使用命令行访问，需要[安装 s3cmd](../../appendix/install-s3cmd.md)，并配置 s3cfg：

```bash
$ cat > ~/mytest.s3cfg << EOF
[default]
access_key = <MINIO_ROOT_USER>
host_base = <MINIO_SERVER_URL>
host_bucket = <MINIO_SERVER_URL>
secret_key = <MINIO_ROOT_PASSWORD>
use_https = False

EOF
```

使用 s3cmd：

```bash
# make a bucket
$ s3cmd -c ~/mytest.s3cfg mb s3://aistore

# put an object
$ touch test.txt
$ s3cmd -c ~/mytest.s3cfg put test.txt s3://aistore/

# list all
$ s3cmd -c ~/mytest.s3cfg la s3://
2023-10-20 08:58            0  s3://aistore/test.txt

# get a file
$ s3cmd -c ~/mytest.s3cfg get s3://aistore/test.txt test2.txt
```

## 检查状态

可通过查看服务状态及其 log：

```bash
$ sudo systemctl status minio

$ sudo journalctl -f -u minio

$ ps u -C minio
```

## 卸载 minio

停止 minio 服务（此时可以通过 systemctl disable --now minio 重启）：

```bash
$ sudo systemctl disable --now minio

# 确认服务已经停止
$ systemctl status minio
```

进一步卸载 minio 会造成不可逆的影响。在卸载 minio 之前，您需要妥善处理下面事项：

1. 备份 minio 中的数据（或确认其中只有测试数据）
1. 处理依赖 minio 的服务（比如 aistore、lakefs），卸载这些服务或者将它们配置为使用其他底层存储。

卸载 minio package：

```bash
$ sudo apt remove minio
```

[可选] 删除 minio 数据：

```bash
# 根据 /etc/default/minio 中的 MINIO_VOLUMES 配置确定路径

# 确认路径中的内容
$ sudo ls -alh /data/minio

# 删除 minio 数据
$ sudo rm -rf /data/minio
```

删除 minio 配置文件：

```bash
$ sudo rm -rf /etc/default/minio
```

删除 minio user （如果该 user 是 group minio-user 的唯一成员，group 也会被一起删除）：

```bash
$ sudo userdel minio-user
```
