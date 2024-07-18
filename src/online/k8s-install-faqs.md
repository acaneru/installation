# 常见问题

## 大集群

如果集群节点数 > 100，请阅读： <https://github.com/kubernetes-sigs/kubespray/blob/master/docs/operations/large-deployments.md>

## 离线安装

请使用 [离线安装](../offline/index.md) 文档。

kubespray 的离线安装文档：<https://github.com/kubernetes-sigs/kubespray/blob/master/docs/operations/offline-environment.md>

## 修改 LVM size

在准备节点的过程中，有时需要调整 LVM size。

参考：<https://www.redhat.com/sysadmin/resize-lvm-simple>

```bash
root@nc06:/home/t9k# lsblk
NAME                      MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
loop0                       7:0    0  63.5M  1 loop /snap/core20/1950
loop1                       7:1    0  91.9M  1 loop /snap/lxd/24061
loop2                       7:2    0  49.9M  1 loop 
loop3                       7:3    0  67.8M  1 loop /snap/lxd/22753
loop4                       7:4    0  63.3M  1 loop 
loop5                       7:5    0  53.3M  1 loop /snap/snapd/19457
loop6                       7:6    0  53.3M  1 loop /snap/snapd/19361
loop7                       7:7    0  63.5M  1 loop /snap/core20/1974
nvme0n1                   259:0    0 465.8G  0 disk 
├─nvme0n1p1               259:1    0   1.1G  0 part /boot/efi
├─nvme0n1p2               259:2    0     2G  0 part /boot
└─nvme0n1p3               259:3    0 462.7G  0 part 
  └─ubuntu--vg-ubuntu--lv 253:0    0 462.7G  0 lvm  /
```

```bash
root@nc06:/home/t9k# df -hl
Filesystem                         Size  Used Avail Use% Mounted on
udev                                16G     0   16G   0% /dev
tmpfs                              3.2G   16M  3.1G   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv   98G   63G   30G  68% /
tmpfs                               16G     0   16G   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
tmpfs                               16G     0   16G   0% /sys/fs/cgroup
/dev/nvme0n1p2                     2.0G  109M  1.7G   6% /boot
/dev/nvme0n1p1                     1.1G  6.1M  1.1G   1% /boot/efi
/dev/loop1                          92M   92M     0 100% /snap/lxd/24061
/dev/loop3                          68M   68M     0 100% /snap/lxd/22753
```

Identify the Logical Volume：

```bash
root@nc06:/home/t9k# lvs
  LV        VG        Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
  ubuntu-lv ubuntu-vg -wi-ao---- 100.00g 
```

Extend the Logical Volume，这里除了使用 `-l +100%FREE` 指定百分比以外，也可以使用 `-L +50G` 的方式指定具体的大小：

```bash
root@nc06:/home/t9k# lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv 
  Size of logical volume ubuntu-vg/ubuntu-lv changed from 100.00 GiB (25600 extents) to <462.71 GiB (118453 extents).
  Logical volume ubuntu-vg/ubuntu-lv successfully resized.
```

验证：

```bash
root@nc06:/home/t9k# lsblk
NAME                      MAJ:MIN RM   SIZE RO TYPE MOUNTPOINT
loop0                       7:0    0  63.5M  1 loop /snap/core20/1950
loop1                       7:1    0  91.9M  1 loop /snap/lxd/24061
loop2                       7:2    0  49.9M  1 loop 
loop3                       7:3    0  67.8M  1 loop /snap/lxd/22753
loop4                       7:4    0  63.3M  1 loop 
loop5                       7:5    0  53.3M  1 loop /snap/snapd/19457
loop6                       7:6    0  53.3M  1 loop /snap/snapd/19361
loop7                       7:7    0  63.5M  1 loop /snap/core20/1974
nvme0n1                   259:0    0 465.8G  0 disk 
├─nvme0n1p1               259:1    0   1.1G  0 part /boot/efi
├─nvme0n1p2               259:2    0     2G  0 part /boot
└─nvme0n1p3               259:3    0 462.7G  0 part 
  └─ubuntu--vg-ubuntu--lv 253:0    0 462.7G  0 lvm  /
```

但是文件系统不会自动扩大：

```bash
root@nc06:/home/t9k# df -hl
Filesystem                         Size  Used Avail Use% Mounted on
udev                                16G     0   16G   0% /dev
tmpfs                              3.2G   16M  3.1G   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv   98G   63G   30G  68% /
tmpfs                               16G     0   16G   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
tmpfs                               16G     0   16G   0% /sys/fs/cgroup
/dev/nvme0n1p2                     2.0G  109M  1.7G   6% /boot
/dev/nvme0n1p1                     1.1G  6.1M  1.1G   1% /boot/efi
/dev/loop1                          92M   92M     0 100% /snap/lxd/24061
/dev/loop3                          68M   68M     0 100% /snap/lxd/22753
```

<aside class="note">
<div class="title">注意</div>

`resize2fs` 是针对 ext2, ext3, ext4 文件系统调整大小的命令，如果使用其他文件系统，请查找对应的命令。

</aside>

Extend the filesystem，在调整文件系统大小之前，应确保文件系统已备份，并且没有错误：

```bash
root@nc06:/home/t9k# resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv
resize2fs 1.45.5 (07-Jan-2020)
Filesystem at /dev/mapper/ubuntu--vg-ubuntu--lv is mounted on /; on-line resizing required
old_desc_blocks = 13, new_desc_blocks = 58
The filesystem on /dev/mapper/ubuntu--vg-ubuntu--lv is now 121295872 (4k) blocks long.
```

验证：

```bash
root@nc06:/home/t9k# df -hl
Filesystem                         Size  Used Avail Use% Mounted on
udev                                16G     0   16G   0% /dev
tmpfs                              3.2G   16M  3.1G   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv  455G   63G  373G  15% /
tmpfs                               16G     0   16G   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
tmpfs                               16G     0   16G   0% /sys/fs/cgroup
/dev/nvme0n1p2                     2.0G  109M  1.7G   6% /boot
/dev/nvme0n1p1                     1.1G  6.1M  1.1G   1% /boot/efi
/dev/loop1                          92M   92M     0 100% /snap/lxd/24061
/dev/loop3                          68M   68M     0 100% /snap/lxd/22753
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
