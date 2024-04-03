# 生成 K8s 文件和镜像列表

这里需要一个节点来准备 offline 安装包，该节点满足以下要求：

1. 可以连接到互联网
1. 与计划离线安装 K8s 集群的“目标节点”操作系统相同

## 准备 ansible 运行环境和 inventory

1. 需要在节点设置 ansible 运行环境，参见基本场景。
1. 准备 inventory 并设置变量。变量会影响需要下载的 files、images 版本。

变量使用在线安装的配置设置即可，建议检查下面的镜像、文件源配置（download.yaml）：

```yaml
files_repo: "https://mirror.ghproxy.com"
gcr_image_repo: "docker.io/t9kpublic"
kube_image_repo: "docker.io/t9kpublic"
docker_image_repo: "docker.io/t9kpublic"
quay_image_repo: "docker.io/t9kpublic"
```

## 生成列表

1）生成 files 和 images 列表的 template（保存在 ks-clusters/tools/offline-k8s/temp 路径下）： 

```yaml
# 进入 kubespray 专用的目录
$ cd ~/ansible

# 将 kubespray 切换到合适分支（推荐使用 offline 分支）
$ cd kubespray
$ git checkout kubernetes-<version>
$ cd ..

# 读取 kubespray 的 download role 的设置，生成一个 template
ks-clusters/tools/offline-k8s/generate_list_template.sh \
    -d ~/ansible/kubespray
```

2）运行 ansible 来渲染 template，生成实际使用的 files.list 和 images.list。

这里需要一个可访问的、与“目标节点”操作系统相同的节点（可以是当前节点自身）。修改 inventory.ini，将该节点设置为 kube_control_plane[0]，下面以 nuc 节点为例：

```yaml
# 进入 inventory 目录
$ export T9K_CLUSTER=<cluster>
# 该目录在准备 inventory 时创建
$ cd ~/ansible/$T9K_CLUSTER/inventory
```

修改 inventory.ini：

```yaml
$ diff -u ./inventory-old.ini ./inventory-new.ini 
--- ./inventory.ini	2023-12-05 13:23:30.000000000 +0800
+++ new-inventory.ini	2023-12-12 14:23:19.000000000 +0800
@@ -1,12 +1,13 @@
 [all]
 nc15 ansible_host=x.x.x.x
+nuc ansible_host=100.64.4.159
 
 ; ## configure a bastion host if your nodes are not directly reachable
 ; [bastion]
 ; bastion ansible_host=x.x.x.x ansible_user=some_user
 
 [kube_control_plane]
-nc15
+nuc
 
 [etcd]
 nc15
@@ -31,7 +32,7 @@
 calico_rr
 
 [all:vars]
-ansible_user=<user>
+ansible_user=t9k
 
 [kube_control_plane:vars]
 node_labels={"beta.kubernetes.io/fluentd-ds-ready": "true"}
```

3）运行命令生成 files.list 和 images.list（这个 playbook 不会对节点做任何修改）：

```yaml
# 进入 inventory 所在的目录
$ cd ~/ansible/$T9K_CLUSTER


# 运行之前是需要生成 SSH Key 并运行 ssh-copy-id t9k@nuc 的，这里省略
$ ansible-playbook ../ks-clusters/tools/offline-k8s/generate_list.yml \
    -i inventory/inventory.ini 
```

生成的 list 被保存在 `../ks-clusters/tools/offline-k8s/temp/` 路径中。

## 修改文件、镜像列表

上面生成了文件和镜像的列表，但这个列表需要修改。

列表需要修改的原因如下：

1. 由于生成 template 和生成列表这两个步骤的局限性，这里生成的文件/镜像列表是 kubespray 的 download role 中所列举的所有文件/镜像。没有考虑 inventory 设置中是否用到了这些文件/镜像，也没有考虑 inventory 的部分特殊设置会覆盖 download role 中的设置。

1）删除以下未被使用的镜像：

```bash
sed -i '/t9kpublic/!d' ../ks-clusters/tools/offline-k8s/temp/images.list
sed -i '/t9kpublic.*\/.*\//d' ../ks-clusters/tools/offline-k8s/temp/images.list
```

说明：

* 第一条删除了名称中不包含 t9kpublic 的镜像
* 第二条删除了在 t9kpublic 后有多于一个斜线 “/” 符号的镜像

这里是利用了我们仅使用 docker.io/t9kpublic 作为镜像源的设置。所有我们需要使用的镜像都必然满足上述两个条件，而我们没用到的镜像因为没有进行相应设置，所以不会同时满足上述两点。

2）调整命令行工具下载源

调整 K8s 命令行工具的下载源，通常国内使用该下载源会更快（详细说明见：[K8s 命令行工具下载路径错误]()）：

```bash
sed -i 's|dl.k8s.io|storage.googleapis.com/kubernetes-release|g' \
    ../ks-clusters/tools/offline-k8s/temp/files.list
```

3）[推荐] 设置 github 代理

根据实际情况进行设置，如果列表输出中使用了 ghproxy.com 作为代理，则替换为最新的：

```bash
sed -i 's|https://ghproxy.com/https://github.com|https://mirror.ghproxy.com/https://github.com|g' \
    ../ks-clusters/tools/offline-k8s/temp/files.list
```

如果未使用，则增加代理：

```bash
sed -i 's|https://github.com|https://mirror.ghproxy.com/https://github.com|g' 
    ../ks-clusters/tools/offline-k8s/temp/files.list
```

4）检查文件列表

检查 `../ks-clusters/tools/offline-k8s/temp/files.list` 中的文件下载地址，确认符合预期。

[可选] 如果对 kubespray 的设置很熟悉，您可以：

* 编辑文件列表，去除不需要的文件。

