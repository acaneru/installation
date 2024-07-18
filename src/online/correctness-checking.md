# 正确性检查

## 准备工作

我们通过运行一个 <a target="_blank" rel="noopener noreferrer" href="https://docs.ansible.com/ansible/latest/index.html">ansible</a> playbook 来检查安装的正确性，需要完成以下准备工作。

### ansible 环境

参考[准备节点与安装 K8s](./prepare-nodes-and-install-k8s.md) 完成以下准备工作：

1. 安装 ansible
1. 将本机的 SSH 公钥复制到所有受控节点上

### inventory 准备

inventory 文件记录了所有目标节点的名称、分组等信息。

示例 inventory 见 <https://github.com/t9k/ks-clusters/blob/master/t9k-playbooks/inventory.yml>：

```yaml
all:
 hosts:
   nuc:
   nc11:
   nc13:
 vars:
   ansible_user: t9k

k8s_cluster:
 children:
   kube_control_plane:
   kube_node:

kube_control_plane:
 hosts:
   nuc:

kube_node:
 hosts:
   nc11:
   nc13:

gpu_nodes:
 hosts:
```

以下节点分组必填：

* `all`: 需要检查的所有节点
* `k8s_cluster`: k8s 集群的所有节点
* `kube_control_plane`: k8s 集群的控制平面节点
* `kube_node`: k8s 集群的工作节点
* `gpu_nodes`: k8s 集群中装有 GPU 的节点

### 变量准备

根据目标集群的实际情况，在默认配置的基础上修改变量。

变量默认值见 <https://github.com/t9k/ks-clusters/blob/master/t9k-playbooks/roles/check-installation/defaults/main.yml>：

```yaml
# default settings in the inventory
kube_config_dir: "/etc/kubernetes"
bin_dir: "/usr/local/bin"

ceph_enabled: false
nfs_enabled: true
ib_enabled: false
pvc_test_image: t9kpublic/busybox:2023
gpu_test_image: t9kpublic/nvidia-tensorflow:18.07-py3 # nvcr.io/nvidia/tensorflow:18.07-py3
gpu_test_tf_batch_size: 128 # (choose from 32, 64, 128, 256, 512)
gpu_test_tf_layers: 50 # (choose from 18, 34, 50, 101, 152)
system_namespaces:
- kube-system
- ingress-nginx
- istio-system
- t9k-system
- t9k-monitoring
- gpu-operator
- network-operator
s3:
 access_key: <access-key>
 secret_key: <secret-key>
 host: <host>
```

其中：

* `kube_config_dir`: YAML 配置文件的存放路径
* `bin_dir`: kubectl 可执行文件的存放路径
* `ceph_enabled`: 目标集群是否支持基于 ceph 的 pvc
* `nfs_enabled`: 目标集群是否支持基于 nfs 的 pvc
* `ib_enabled`: 目标集群是否支持 ib 网络
* `pvc_test_image`: 运行 pvc 测试所用的镜像
* `gpu_test_image`: 运行 gpu 测试所用的镜像
* `gpu_test_tf_batch_size`: 运行 gpu 测试时 resnet 训练的 batch 大小
* `gpu_test_tf_layers`: 运行 gpu 测试时 resnet 的层数
* `system_namespaces`: 目标集群中有哪些系统级 namesapce 需要检查
* `s3`: 用于检查 s3 服务的可访问性以及 StorageShim 功能

## 运行 playbook

通过以下命令运行 playbook 来检查安装正确性：

```bash
$ git clone https://github.com/t9k/ks-clusters.git
$ cd ks-clusters/t9k-playbooks
# check inventory
$ cat ./inventory.yml
# check variables
$ cat ./roles/check-installation/defaults/main.yml 
# run playbook
$ ansible-playbook -i inventory.yml 99-check-installation.yml --ask-become-pass
```

ansible 会对每个节点输出一行 task 运行结果统计，需要关注的是**标记为 failed 的数量**。

检查成功的运行结果如下：

```
...
...
...
TASK [check-installation : Check s3 | Verify pod log] ***********************************************************************************************
skipping: [nc11]
skipping: [nc13]
changed: [nuc]

TASK [check-installation : Check s3 | Delete pod and storageshim] ***********************************************************************************
skipping: [nc11]
skipping: [nc13]
ok: [nuc]

TASK [check-installation : Check s3 | Delete bucket] ************************************************************************************************
skipping: [nc11]
skipping: [nc13]
changed: [nuc]

PLAY RECAP ******************************************************************************************************************************************
nc11                       : ok=7    changed=4    unreachable=0    failed=0    skipped=22   rescued=0    ignored=0   
nc13                       : ok=7    changed=4    unreachable=0    failed=0    skipped=22   rescued=0    ignored=0   
nuc                        : ok=23   changed=15   unreachable=0    failed=0    skipped=6    rescued=0    ignored=0   
```

检查失败的运行结果如下：

```
...
...
...
TASK [check-installation : Check s3 | Verify pod log] ***********************************************************************************************
skipping: [nc11]
skipping: [nc13]

TASK [check-installation : Check s3 | Delete pod and storageshim] ***********************************************************************************
skipping: [nc11]
skipping: [nc13]

TASK [check-installation : Check s3 | Delete bucket] ************************************************************************************************
skipping: [nc11]
skipping: [nc13]

PLAY RECAP ******************************************************************************************************************************************
nc11                       : ok=7    changed=4    unreachable=0    failed=0    skipped=22   rescued=0    ignored=0   
nc13                       : ok=7    changed=4    unreachable=0    failed=0    skipped=22   rescued=0    ignored=0   
nuc                        : ok=7    changed=4    unreachable=0    failed=1    skipped=6    rescued=0    ignored=0  
```

如果 failed 数量不为 0，需要往前翻查看 ansible 报错确定具体原因。
