# Harbor

## 前提条件

Harbor 对于节点有以下要求，详见 <a target="_blank" rel="noopener noreferrer" href="https://goharbor.io/docs/2.0.0/install-config/installation-prereqs/">Harbor Installation Prerequisites</a>。

硬件要求：

| Resource | Minimum | Recommended |
| -------- | ------- | ----------- |
| CPU      | 2 cores | 4 cores     |
| Mem      | 4 GB    | 8 GB        |
| Disk     | 40 GB   | 160 GB      |

软件要求：

| Software       | Version                       |
| -------------- | ----------------------------- |
| Docker engine  | Version 17.06.0-ce+ or higher |
| Docker Compose | Version 1.18.0 or higher      |
| OpenSSL        | Latest is preferred           |

端口要求：

| 端口 | 协议  |
| ---- | ----- |
| 443  | HTTPS |
| 4443 | HTTPS |
| 80   | HTTP  |

## 快速安装

本节用于在一个 Ubuntu 系统中快速配置 Docker 运行环境并安装 Harbor。该 host 仅用于运行 Harbor，不应有其他系统。

获取 <a target="_blank" rel="noopener noreferrer" href="https://gitlab.dev.tensorstack.net/infra/experimental/blob/master/skj/deploy-tools/harbor.sh">harbor.sh</a>（内部链接）脚本，在安装路径中保存为 harbor.sh 并进行以下修改。

<aside class="note">
<div class="title">注意</div>

1. 该脚本来源于 <https://goharbor.io/docs/2.0.0/install-config/quick-install-script/>，在其基础上进行了修改。
1. 不要在计划或已经加入 K8s 的节点中运行该脚本。该安装脚本中安装的 docker 版本、docker 配置与 kubespray 不兼容，在同一个节点上运行这两个脚本（无论先后）会导致错误。
1. 该脚本安装的 Harbor 不使用 https，但可以在后续修改其设置。

</aside>

调整脚本，设置其中这两个参数：

```bash
COMPOSEVERSION="v2.23.0"
HARBORVERSION="v2.7.3"
```

运行以下命令，根据提示设置 IP 或者域名（FQDN）进行安装：

```bash
$ sudo chmod u+x harbor.sh
$ sudo ./harbor.sh
```

运行结束后，根据提示信息运行 docker login 验证 Harbor 是否安装成功。后续请参考[配置 Harbor](#配置-harbor)，比如修改[管理员密码](#管理员初始密码)。

## 安装 Harbor

如果无法进行“快速安装”（例如已经配置了 Docker），可参照本节，设置更多选项后进行高级安装。

首先确认节点安装了 Docker 和 Docker Compose。如未安装，可参考[附录：安装 Docker](../../appendix/install-docker.md) 和[附录：安装 Docker Compose](../../appendix/install-docker-compose.md) 进行安装。

参考：<a target="_blank" rel="noopener noreferrer" href="https://goharbor.io/docs/2.7.0/install-config/">Harbor Installation and Configuration</a>

### 步骤

1. 从 <https://github.com/goharbor/harbor/releases> 获取 online-installer 或者 offline-installer。online-installer 会在安装过程中在线拉取镜像，而 offline-installer 中已经包含了需要的所有镜像，适用于离线安装。

```bash
# get offline installer; use proxy if needed: export https_proxy=<your-proxy>
$ wget https://github.com/goharbor/harbor/releases/download\
/v2.7.3/harbor-offline-installer-v2.7.3.tgz
```

2. 解压安装包：

```bash
$ tar xzvf harbor-online-installer-v2.7.3.tgz
```

3. 进入 harbor 目录，创建 harbor.yml：

```bash
$ cd harbor
$ cp harbor.yml.tmpl harbor.yml
```

然后根据[配置 Harbor 部分](#配置-harbor)的说明，修改 harbor.yml。

4. 启动 Harbor：

```bash
$ sudo ./install.sh

# 确认服务正常运行
$ sudo docker-compose ps
```

### harbor 客户端

如果未配置 Harbor 通过 HTTPS 提供服务 ，则所有需要访问该 Registry 的节点应当允许 insecure 访问。

假设客户端使用 Docker，可进行如下设置：

```bash
$ IPorFQDN="<ip-or-domain>"

# 运行前请确认 /etc/docker/daemon.json 文件不存在或为空
# 否则只需要把 "insecure-registries" 设置增加到 /etc/docker/daemon.json 文件中
$ sudo cat > /etc/docker/daemon.json <<EOF
{
  "insecure-registries" : ["$IPorFQDN:80","0.0.0.0/0"]
}
EOF

$ sudo systemctl daemon-reload
$ sudo systemctl restart docker
```

## 配置 Harbor

Harbor 安装包（例如：harbor-online-installer-v2.7.3.tgz）解压后，会在当前路径生成 harbor 目录：

```bash
harbor
├── common
│   └── config/ # 其中包含的文件略
├── common.sh
├── docker-compose.yml
├── harbor.yml
├── harbor.yml.tmpl
├── install.sh
├── LICENSE
└── prepare
```

执行 install.sh 将根据 harbor.yml 文件中的配置生成 docker-compose.yml 文件，并运行 docker-compose up -d 以启动/重启服务。因此，我们建议按照以下步骤修改 Harbor 的配置：

1. 修改 harbor.yml 文件
1. 运行 install.sh 以重新启动服务

关于 harbor.yml 文件的详细说明，请参阅相应版本的 Harbor 官方文档 <a target="_blank" rel="noopener noreferrer" href="https://goharbor.io/docs/2.7.0/install-config/configure-yml-file/">Configure the Harbor YML File</a>。本章节仅对 TensorStack 常用的配置进行说明。

### 管理员初始密码

Harbor 的管理员用户为 admin，初始密码在 `harbor_admin_password` 字段中设置，默认值是 Harbor12345。

您应当使用该用户登录 Harbor 网页，修改 admin 的密码。

<aside class="note">
<div class="title">注意</div>

修改 harbor.yml 并再次运行 install.sh 不会重置管理员的密码。

</aside>

### 使用 HTTPS 访问 Harbor

harbor.yml 中的以下字段用于配置 HTTPS 服务：

```yaml
hostname: registry.sample.t9kcloud.cn
https:
  port: 443
  certificate: </your/certificate/path>
  private_key: </your/private/key/path>
```

### 设置存储路径

Harbor 具有以下存储需求：

1. 关系型数据库： Harbor 需要关系型数据库来存储元数据，如项目、用户、项目成员、镜像元数据、策略等
1. 数据存储：用于持久化存储镜像和 Helm Chart
1. Redis：提供数据缓存功能

使用以下字段设置存储路径：

```yaml
data_volume: /data/harbor
```

该路径下会被创建以下目录：

1. database：关系型数据库
1. job_logs：保存 job 日志
1. redis：保存数据缓存
1. registry：存储数据，即镜像和 Helm Chart

### 使用 S3 作为数据存储

在 harbor.yml 中，storage_service 字段用于设置保存镜像和 Helm Chart 的外部存储服务。当 storage_service 未被设置时，数据存储路径为 data_volume 中的 registry 目录；设置 storage_service 并重启服务后，使用该存储服务进行存储。

Harbor 支持多种存储后端，例如 azure, gcs, s3, swift 等，详情请参考：<https://goharbor.io/docs/1.10/install-config/configure-yml-file/#backend>

根据 S3 服务的信息设置以下字段：

```yaml
storage_service:
  s3:
    accesskey: <access Key>
    secretkey: <secret Key>
    region: <region>
    regionendpoint: http://<s3-url>
    bucket: <bucket-name>
```

其中 bucket 的 region 可以通过下面命令获取：

```bash
$ s3cmd info s3://my-bucket | grep Location
```

## 常用操作

Harbor 服务通过 docker-compose 运行，本章节说明 docker-compose 的常用操作。

<aside class="note">
<div class="title">注意</div>

下列命令需要在 harbor 目录（即 docker-compose.yml 所在路径）下运行。

</aside>

查看运行中的容器及其状态：

```bash
$ sudo docker-compose ps

# 注意第四列的 SERVICE
# docker-compose 使用 SERVICE 而不是第一列的 NAME 来指代具体的容器

# 查看 service core 的容器状态
$ sudo docker-compose ps core
```

启动 docker-compose.yml 指定的容器：

```bash
# 启动所有容器
$ sudo docker-compose up -d

# 使用 SERVICE 名指定的容器
$ sudo docker-compose up -d core
```

关闭并删除 docker-compse.yml 指定的容器：

```bash
# 关闭所有容器
$ sudo docker-compose down

# 关闭 SERVICE 名指定的容器
$ sudo docker-compose down core
```

重启 docker-compose.yml 指定的容器：

```bash
# 重启所有容器
$ sudo docker-compose restart

# 重启 SERVICE 名指定的容器
$ sudo docker-compose restart core
```

<aside class="note">
<div class="title">注意</div>

如果修改了 harbor.yml 配置或更新了证书，应当通过 install.sh 来重启使得修改生效：

</aside>

```bash
$ sudo ./install.sh
```

查看容器的运行日志：

```bash
# 查看当前所有日志
$ sudo docker-compose logs

# 仅查看指定 SERVICE 的日志
$ sudo docker-compose logs core

# 查看指定时间段内的日志
$ sudo docker-compose logs \
    --since 2023-10-20T00:00:00Z \
    --until 2023-10-20T12:00:00Z

# 查看最新的 20 条日志
$ sudo docker-compose logs --tail 20

# 持续跟踪日志输出
$ sudo docker-compose log -f
```

在容器中运行命令：

```bash
# 运行 SERVICE core 的 bash 以进行调试
$ sudo docker-compose exec core bash
```

## 其他

* 配置 Harbor 组件之间使用 TLS 通信：<a target="_blank" rel="noopener noreferrer" href="https://goharbor.io/docs/2.0.0/install-config/configure-internal-tls/">Configure Internal TLS communication between Harbor Component</a>
