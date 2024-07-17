# 产品升级

```
TODO:
    1. 提供 charts 列表
```

## 升级

首先参考[数据备份](../../data-backup/index.md)进行必要的数据备份。

更新 ks-clusters：

```bash
cd ~/ansible/ks-clusters
git pull
```

进入 inventory 所在的目录，并获取新版本产品对应的 `values.yaml`：

```bash
cd ~/ansible/$T9K_CLUSTER
cp ../ks-clusters/values/values-sample-1.79.2.yaml ./new-values.yaml
```

获取安装产品时使用的 `values.yaml`：
```bash
helm get values t9k-core -n t9k-system > old-values.yaml
```

进行对比：

```bash
# 要求 yq 4.x.x 版本
yq eval 'sortKeys(..)' old-values.yaml > old-values-sort.yaml
yq eval 'sortKeys(..)' new-values.yaml > new-values-sort.yaml
diff -u old-values-sort.yaml new-values-sort.yaml
```

结合这两个文件得到最终的 values.yaml。然后使用 Helm upgrade 命令逐个升级产品。这里以产品 "t9k-core" 的 1.79.0 版本为例：

```bash
$ helm upgrade -n t9k-system t9k-core \
    oci://tsz.io/t9kcharts/t9k-core \
    --version 1.79.0 \
    -f values.yaml
```
