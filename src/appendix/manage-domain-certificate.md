# 管理域名证书

本文档介绍如何使用 acme.sh 生产和更新 TLS 证书。

## 安装 acme.sh

使用以下命令安装 acme.sh：
``` bash
git clone https://github.com/acmesh-official/acme.sh.git
cd ./acme.sh
./acme.sh --install -m my@example.com
```

其中 `-m my@example.com` 指定了一个电子邮箱地址，如果证书即将到期或者已经到期，该邮箱会收到相应的电子邮件提醒。

## 生成域名证书

生成域名证书的更多用法和细节请参考[官方文档](https://github.com/acmesh-official/acme.sh)。

### 使用 acme.sh

使用 acme.sh 自动创建域名证书需要依赖域名供应商的 API，详细信息请参考文档 [How to use DNS API](https://github.com/acmesh-official/acme.sh/wiki/dnsapi)。

这里以华为云的[云解析服务](https://www.huaweicloud.com/product/dns.html)为例，说明如何创建域名证书。设置以下环境变量：

```bash
# acme.sh 需要的华为云环境变量
export HUAWEICLOUD_DomainName="<your-account-name>"
export HUAWEICLOUD_ACCESS_KEY="<your-access-key>"
export HUAWEICLOUD_SECRET_KEY="<your-secret-key>"
```

环境变量 `HUAWEICLOUD_DomainName` 对应华为云控制台的“账号名”或者“Account name”。

然后，运行下面的命令来创建证书：

```bash
acme.sh --issue --dns dns_huaweicloud -d "*.sample.t9kcloud.cn"
```

如果需要同时指定多个域名：

```bash
acme.sh --issue --dns dns_huaweicloud \
    -d "home.sample.t9kcloud.cn" \
    -d "auth.sample.t9kcloud.cn"
```

如果需要更多的日志输出以方便调试：

```bash
acme.sh --issue --dns dns_huaweicloud \
    -d "*.sample.t9kcloud.cn" \
    --debug 2
```

创建成功的输出：

```
[Wed Oct 25 14:50:05 CST 2023] Your cert is in: /Users/<user>/.acme.sh/*.sample.t9kcloud.cn_ecc/*.sample.t9kcloud.cn.cer
[Wed Oct 25 14:50:05 CST 2023] Your cert key is in: /Users/<user>/.acme.sh/*.sample.t9kcloud.cn_ecc/*.sample.t9kcloud.cn.key
[Wed Oct 25 14:50:05 CST 2023] The intermediate CA cert is in: /Users/<user>/.acme.sh/*.sample.t9kcloud.cn_ecc/ca.cer
[Wed Oct 25 14:50:05 CST 2023] And the full chain certs is there: /Users/<user>/.acme.sh/*.sample.t9kcloud.cn_ecc/fullchain.cer
```

证书会被保存在 `~/.acme.sh` 路径下，有效期是 90 天。acme.sh 会每 60 天自动更新证书，细节在[更新证书](#更新证书)章节中进行说明。

## 更新证书

acme.sh 在安装时会添加 cronjob 来自动更新证书，您可以通过 crontab -e 命令看到该任务：

```bash
crontab -e
```

```bash
54 15 * * * "/Users/<user>/.acme.sh"/acme.sh --cron --home "/Users/<user>/.acme.sh" > /dev/null
```

该任务会在每天 15:54 自动运行，`--cron` 参数会让 acme.sh 检查所有的证书，并更新其中超过更新间隔的证书。默认的更新间隔为 60 天。

如果您没有找到上述 cronjob，可以通过下面命令进行安装：

```bash
acme.sh --install-cronjob
```

如果您想要立即更新证书，可以手动运行：

```bash
acme.sh --renew --dns dns_huaweicloud -d "*.sample.t9kcloud.cn" --force
```

如果你想要停止一个证书的自动更新，可以运行：

```bash
acme.sh --remove -d "*.sample.t9kcloud.cn"
```

## 查看证书信息

查看证书有效期：

```bash
openssl x509 -noout -enddate -in <cert-file>
```

查看证书颁发者信息：

```bash
openssl x509 -noout -issuer -in <cert-file>
```

查看证书详细信息：

```bash
openssl x509 -txt -in <cert-file>
```

检查私钥：

```bash
# 命令要根据加密算法变化，ec 代表 ECDSA 算法
openssl ec -txt -in <private-key-file>
```

## 参考

<https://github.com/acmesh-official/acme.sh>
