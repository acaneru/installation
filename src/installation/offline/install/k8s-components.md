# K8s 组件

## 检查离线安装包

`ks-clusters/tools/offline-additionals` 中提前准备的离线文件一览：

| 内容              | 存放路径          |
| ----------------- | ----------------- |
| 1. 镜像（images） | container-images/ |
| 2. Helm Chart     | charts/           |
| 3. 其他           | misc/             |

## 上传镜像

1）确认已经运行了 Registry 服务，详见 [运行 NGINX 和上传镜像](./k8s.md#运行-nginx-和上传镜像)。

2）将保存的镜像上传到 Registry 中：

```bash
cd ~/ansible/ks-clusters/tools/offline-additionals
./manage-offline-container-images.sh --option register
```

## 安装组件

首先将 minio 复制到计划安装 minio 的存储节点上：

```bash
rsync -aP misc/minio.deb <user>@<minio-node-ip>:~/
```

参考以下文档进行安装：

* [minio](../../online/storage-service/minio.md)
* [NFS](../../online/storage-service/nfs.md)
* [K8s 组件](../../online/k8s-components/index.md)

<aside class="note">
<div class="title">注意</div>

1. 需要执行标注了 [离线安装场景] 的修改。
2. 部分离线安装命令与在线安装命令不同，注意 `“# offline install”` 的注释。

</aside>
