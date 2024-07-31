# 常见问题

## 大集群

如果集群节点数 > 100，请阅读： <https://github.com/kubernetes-sigs/kubespray/blob/master/docs/operations/large-deployments.md>

## 离线安装

请使用 [离线安装](../offline/index.md) 文档。

kubespray 的离线安装文档：<https://github.com/kubernetes-sigs/kubespray/blob/master/docs/operations/offline-environment.md>

## 调整 LVM 的逻辑卷大小

Logical Volume Manager（LVM）是 Linux 环境下对磁盘分区进行管理的一种机制。

LVM的主要概念有：

1. PV (Physical Volume)：物理卷，可以是整个物理硬盘或实际物理硬盘上的分区。
2. VG (Volume Group)：卷组，将数个PV进行整合，形成一个存储池。
3. LV (Logical Volume)：逻辑卷，由VG划分而来，LV的大小与PE的大小及PE的数量有关。
4. PE (Physical Extent)：物理区块，他是LVM中的最小存储单元。

在准备节点的过程中，有时需要调整逻辑卷的大小，下面介绍具体的操作方式。

参考：

1. <a target="_blank" rel="noopener noreferrer" href="https://linux.die.net/man/8/lvextend">lvextend(8) - Linux man page</a>
2. <a target="_blank" rel="noopener noreferrer" href="https://www.redhat.com/sysadmin/resize-lvm-simple">How to resize a logical volume with 5 simple LVM commands</a>


查看文件系统和磁盘信息：

```bash
lsblk
```

```bash
NAME                      MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0                       7:0    0  63.9M  1 loop /snap/core20/2318
loop1                       7:1    0  63.9M  1 loop /snap/core20/2105
loop3                       7:3    0    87M  1 loop /snap/lxd/28373
loop4                       7:4    0  38.7M  1 loop /snap/snapd/21465
loop5                       7:5    0  38.8M  1 loop /snap/snapd/21759
loop6                       7:6    0    87M  1 loop /snap/lxd/29351
sda                         8:0    0 447.1G  0 disk 
├─sda1                      8:1    0     1G  0 part /boot/efi
├─sda2                      8:2    0     2G  0 part /boot
└─sda3                      8:3    0 444.1G  0 part 
  └─ubuntu--vg-ubuntu--lv 252:0    0   440G  0 lvm  /var/lib/containers/storage/overlay
                                                    /
```

查看文件系统的信息：

```bash
df -hl
```

```bash
Filesystem                         Size  Used Avail Use% Mounted on
tmpfs                              1.6G   31M  1.5G   2% /run
efivarfs                           192K  108K   80K  58% /sys/firmware/efi/efivars
/dev/mapper/ubuntu--vg-ubuntu--lv  433G   18G  393G   5% /
tmpfs                              7.7G     0  7.7G   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
/dev/sda2                          2.0G  417M  1.4G  23% /boot
/dev/sda1                          1.1G  6.1M  1.1G   1% /boot/efi
tmpfs                              1.6G  4.0K  1.6G   1% /run/user/1000
```

查看卷组的信息：

```bash
vgs # 如需更详细的信息，可以运行 vgdisplay
```

```bash
  VG        #PV #LV #SN Attr   VSize    VFree 
  ubuntu-vg   1   1   0 wz--n- <444.08g <4.08g
```

查看逻辑卷的信息：

```bash
lvs # 如需更详细的信息，可以运行 lvdisplay
```

```bash
  LV        VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  ubuntu-lv ubuntu-vg -wi-ao---- 440.00g 
```

扩展逻辑卷，将它增加 2GB，并同时调整文件系统的大小：

```bash
lvextend --resizefs --size +2GB /dev/ubuntu-vg/ubuntu-lv
```

```bash
  Size of logical volume ubuntu-vg/ubuntu-lv changed from 440.00 GiB (112640 extents) to 442.00 GiB (113152 extents).
  Logical volume ubuntu-vg/ubuntu-lv successfully resized.
resize2fs 1.46.5 (30-Dec-2021)
Filesystem at /dev/mapper/ubuntu--vg-ubuntu--lv is mounted on /; on-line resizing required
old_desc_blocks = 55, new_desc_blocks = 56
The filesystem on /dev/mapper/ubuntu--vg-ubuntu--lv is now 115867648 (4k) blocks long.
```

<aside class="note">
<div class="title">注意</div>

1. `--resizefs` 参数仅适用于 ext2, ext3, ext4, ReiserFS, XFS 文件系统。
2. 除了使用 `--size +2GB` 指定具体的大小外，也可以使用 `-l +100%FREE` 指定百分比。

</aside>


验证文件系统已经扩大：

```bash
df -hl
```

```bash
Filesystem                         Size  Used Avail Use% Mounted on
tmpfs                              1.6G   31M  1.5G   2% /run
efivarfs                           192K  108K   80K  58% /sys/firmware/efi/efivars
/dev/mapper/ubuntu--vg-ubuntu--lv  434G   18G  394G   5% /
tmpfs                              7.7G     0  7.7G   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
/dev/sda2                          2.0G  417M  1.4G  23% /boot
/dev/sda1                          1.1G  6.1M  1.1G   1% /boot/efi
tmpfs                              1.6G  4.0K  1.6G   1% /run/user/1000
```

## 日志收集不完整

问题表现为 kubelet cadvisor 收集的 `container_network_receive_bytes_total` 等 metrics 缺失 container 信息。

该问题在 issue 中有非常清晰的描述：

* <https://github.com/rancher/rancher/issues/38934#issuecomment-1294585708>
* <https://github.com/kubernetes/website/issues/30681#issuecomment-1205677145>


上述的两个 issue 中，前一个 issue 中的回答解释了问题的原因，并提供了一个 workaround。后一个 issue 简单介绍了这个问题的原因和现状，并附上了相关 KEP 的[链接](https://github.com/kubernetes/enhancements/blob/master/keps/sig-node/2371-cri-pod-container-stats/README.md)。

## 无法拉取 Docker Hub 镜像

使用下面的命令验证 docker 可以从 Docker Hub 拉取镜像：

```bash
docker pull t9kpublic/hello-world
docker pull hello-world
```

如果节点无法顺利拉取 docker.io 的镜像，可以通过设置 registry-mirrors 来解决。

Docker Hub 镜像源参考：<https://juejin.cn/post/7165806699461378085>。

具体设置可分为如下 2 种情况。

<aside class="note">
<div class="title">注意</div>

如果使用了其他 container runtime，请参考其对应文档进行设置。

</aside>

### 已加入 K8s 集群

修改 docker 的配置文件：

```bash
sudo vim /etc/systemd/system/docker.service.d/docker-options.conf
```

进行以下修改：

```diff
diff -u docker-options.old.conf docker-options.new.conf 
--- ./docker-options.old.conf	2023-08-15 10:23:44.388444563 +0000
+++ ./docker-options.new.conf	2023-08-15 10:23:22.120168571 +0000
@@ -2,7 +2,7 @@
 Environment="DOCKER_OPTS= --iptables=false \
 --exec-opt native.cgroupdriver=systemd \
  \
- \
+--registry-mirror=https://dockerproxy.com/ --registry-mirror=https://hub-mirror.c.163.com/ --registry-mirror=https://mirror.baidubce.com/ --registry-mirror=https://ccr.ccs.tencentyun.com/  \
 --data-root=/var/lib/docker \
 --log-opt max-size=50m --log-opt max-file=5"
```

加载配置，并重启 docker：

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
```

验证生效：

```bash
sudo docker info
```

输出：

```
…
Server:
…
 Registry Mirrors:
  https://dockerproxy.com/
  https://hub-mirror.c.163.com/
  https://mirror.baidubce.com/
  https://ccr.ccs.tencentyun.com/
…
```

### 未加入 K8s 集群

Kubespray 添加节点的过程会安装 Docker，而移除节点的过程会卸载 Docker。我们可以修改 kubespray inventory 的配置来直接完成配置，具体见 [ansible vars](../appendix/ansible-vars.md#group_varsalldockeryml)。


## 升级 linux kernel 后无法找到网卡

通过以下命令可以升级 ubuntu 系统的 linux kernel：

```bash
sudo apt --fix-broken install linux-{image,headers}-5.15.0-107-generic
sudo reboot
```

如果升级 kernel 后，节点无法 ssh 连接，物理连接后显示没有可用的网卡，根据[讨论](https://askubuntu.com/questions/1307447/network-not-working-updating-to-kernel-5-8-ubuntu-20-04)，原因是升级 kernel 时 `linux-modules-extra-*` 包缺失，安装对应版本的包并重启即可：

```bash
dpkg -l | grep linux- | grep 5.15.0
```

```
ii  linux-headers-5.15.0-107-generic      5.15.0-107.117~20.04.1            amd64        Linux kernel headers for version 5.15.0 on 64 bit x86 SMP
ii  linux-hwe-5.15-headers-5.15.0-107     5.15.0-107.117~20.04.1            all          Header files related to Linux kernel version 5.15.0
ii  linux-image-5.15.0-107-generic        5.15.0-107.117~20.04.1            amd64        Signed kernel image generic
ii  linux-modules-5.15.0-107-generic      5.15.0-107.117~20.04.1            amd64        Linux kernel extra modules for version 5.15.0 on 64 bit x86 SMP
```

```bash
sudo apt install linux-modules-extra-5.15.0-107-generic

sudo reboot
```

## 参考

<https://github.com/kubernetes-sigs/kubespray/blob/master/docs/operations/large-deployments.md>
