# 在线安装 Docker Compose

使用下列命令下载并安装 Docker Compose：

```bash
$ COMPOSEVERSION="v2.23.0"

$ curl -kL $(curl -s https://api.github.com/repos/docker/compose/releases/tags/$COMPOSEVERSION|grep browser_download_url|grep -i "$(uname -s)-$(uname -m)"|grep -v sha25|head -1|cut -d'"' -f4) -o /usr/local/bin/docker-compose

$ chmod +x /usr/local/bin/docker-compose
$ ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose || true
```
