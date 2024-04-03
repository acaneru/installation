# 在线安装 Docker

安装 apt packages：

```bash
$ sudo apt update -y
$ sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
```

设置 apt 源：

```bash
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
     | sudo apt-key add -

$ sudo add-apt-repository -y \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

$ sudo apt-get update -y
```

安装 Docker（可以参考 安装 Kubespray 指定版本的 Docker）：

```bash
$ apt-get install -y docker-ce docker-ce-cli containerd.io
```

配置 Docker：

```bash
$ IPorFQDN="ip-or-domain"

# 以下配置可能与 kubespray 不一致导致冲突
$ sudo tee /etc/docker/daemon.json >/dev/null <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "insecure-registries" : ["$IPorFQDN:443","$IPorFQDN:80","0.0.0.0/0"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
```

进行用户的配置：

```bash
$ mkdir -p /etc/systemd/system/docker.service.d
$ groupadd -f docker
$ MAINUSER=$(logname)
$ usermod -aG docker $MAINUSER
$ sudo systemctl daemon-reload
$ sudo systemctl restart docker
```

确认 docker 正常运行：

```bash
$ sudo systemctl status docker
```
