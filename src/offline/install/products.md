# 产品

## 检查安装包

`ks-clusters/offline/t9k` 中提前准备的离线文件一览：

| 内容             | 存放路径              |
| -------------- | ----------------- |
| 1. Helm Chart | charts/           |
| 2. 镜像（images） | container-images/ |
| 3. 域名证书       | certs/            |
| 4. 其他         | misc/             |

> 说明：“其他” 中包含 Serving 使用的镜像，kubectl 和 helm 命令行工具，用于保障单独部署 T9k 产品时这些功能可以正常使用。

## 上传镜像

1）进入 offline/t9k 目录：

```bash
cd ~/ansible/ks-clusters/offline/t9k
```

2）确认本地 Registry 服务正在运行。此服务在[离线安装 K8s](./k8s.md#运行-nginx-和上传镜像)过程中启动。

3）上传 K8s 安装需要的镜像到 registry 的 t9kpublic 项目中，其中 `<registry>` 为 Registry 的域名：

```bash
$ ./manage-offline-container-images.sh \
    --option register --registry <registry>
```

## 验证镜像下载

在“控制节点”查看镜像版本：

```bash
ls container-images | grep landing-page-web
```

下载镜像：

```bash
docker pull <registry>/t9kpublic/landing-page-web:1.78.4
```

## 安装 T9k 产品

### 安装前准备

参考 [安装前准备](../../online/products/pre-install.md)。

#### TLS 证书

域名证书位于 `certs/`，可以供测试使用。

#### 设置 DNS

##### 独立 DNS server

如果部署环境有 DNS server，则在此 DNS server 中增加相应记录即可。

例如，增加如下记录：

```
home.sample.t9kcloud.cn
auth.sample.t9kcloud.cn
```

<aside class="note">
<div class="title">注意</div>

需使用和 TLS 证书对应的 DNS。

</aside>

##### 使用 K8s 的 coredns

如果没有 DNS server，可直接修改 K8s 中的 coredns。

这种情况下所有需要访问集群服务的节点都需要修改 `/etc/hosts`，且无法支持 mlservice 的使用。只适用于测试场景。

集群内，通过编辑 kube-system 的 configmap `coredns` 来设置 DNS：

```bash
kubectl -n kube-system edit cm coredns
```

```diff
diff -u ./old-corefile.yaml ./new-corefile.yaml 
--- ./old-corefile.yaml	2023-09-26 12:09:48.000000000 +0800
+++ ./new-corefile.yaml	2023-09-26 12:09:41.000000000 +0800
@@ -5,6 +5,10 @@
             lameduck 5s
         }
         ready
+        hosts {
+            192.168.101.75 home.sample.t9kcloud.cn auth.sample.t9kcloud.cn
+            fallthrough
+        }
         kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
```

重启 coredns 使上述修改生效：

```bash
kubectl -n kube-system rollout restart deploy/coredns
```

在其他需要解析域名的节点设置静态解析。修改 /etc/hosts：

```bash
sudo cat >> /etc/hosts < EOF
192.168.101.75 home.sample.t9kcloud.cn auth.sample.t9kcloud.cn
EOF
```

### 安装产品

参考 [安装产品](../../online/products/install-uc-mode.md)。

<aside class="note">
<div class="title">注意</div>

需要将 values.yaml 中的 docker.io/t9kpublic 替换为 <control-node-ip>:5000/t9kpublic。其中 <control-node-ip> 为控制节点的 IP 地址。

</aside>

可以使用的修改命令：

```bash
cd ~/ansible/$T9K_CLUSTER
sed -i "s|docker.io/t9kpublic|<control-node-ip>:5000/t9kpublic|g" \
    values.yaml 
```

产品列表见：

```bash
ls ~/ansible/ks-clusters/offline/t9k/productlist

cat ~/ansible/ks-clusters/offline/t9k/productlist/t9k-2023-12-20.list
```

安装产品：

```bash
# 安装命令
helm install <product> \
  ../ks-clusters/offline/t9k/charts/<product>-<version.tgz> \
  -f values.yaml \
  -n t9k-system

# 以安装 t9k-core 为例
helm install t9k-core \
  ../ks-clusters/offline/t9k/charts/t9k-core-1.78.4.tgz \
  -f values.yaml \
  -n t9k-system

# t9k-monitoring 的 namespace 与其他产品不同
helm install t9k-monitoring \
  ../ks-clusters/offline/t9k/charts/t9k-monitoring \
  -f values.yaml \
  -n t9k-monitoring
```

### 安装后配置

参考 [安装后配置](../../online/products/post-install.md)。

<aside class="note">
<div class="title">注意</div>

需要执行标注了 [离线安装场景] 的修改。

</aside>
