# 产品升级

## 升级

首先参考[数据备份](../../data-backup/index.md)进行必要的数据备份。

准备 values.yaml，如果已经准备则可以跳过：

```bash
# 从 ks-clusters 项目获取 value.yaml
$ cd ~/ansible/ks-clusters

# 这里的 <cluster> 可以是任意名称，只是用于区分不同集群的配置文件
$ mkdir ../<cluster>
$ cp values-sample-1.79.0.yaml ../<cluster>/values.yaml
$ cd ../<cluster>

# 根据 values.yaml 中的注释，修改文件内容以设置合适的值
# 注释了 MUST 的内容必须进行修改
$ vim values.yaml
```

从 [T9k Releases]() 文档获取最新的产品列表及版本。

使用 Helm upgrade 命令逐个升级产品（以产品 “t9k-csi-s3” 的 1.79.0 版本为例）：

```yaml
$ helm upgrade -n t9k-system t9k-csi-s3 \
    oci://tsz.io/t9kcharts/t9k-csi-s3 \
    --version 1.79.0 \
    -f values.yaml
```
