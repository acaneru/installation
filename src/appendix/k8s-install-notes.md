# 安装 K8s 注释

## 过程解释

### 脚本内容

集群安装脚本 `cluster.yml` 需要执行 ~1300 个 ansible Tasks，可以通过下面的命令输出完整的 Task 列表：

```bash
ansible-playbook ../kubespray/playbooks/cluster.yml \
    -i inventory/inventory.ini \
    --list-tasks
```

### 安装时长

安装 K8s 集群所需要的时间受网络下载速度（主要因素）、节点性能、节点当前状态影响。

初次运行该脚本的用时通常在 30 分钟到 1 小时范围内。其中，命令行工具、镜像等内容的下载约 25 分钟，下载之外的运行时间约 20 分钟。但在网络环境较差的情况下，下载时间可能会延长到数个小时。

### 安装进度

Ansible 在执行过程中会输出当前运行的 Task 名称（方括号中的内容），及对每个节点的运行结果。格式如下：

```
TASK [reset : reset | Restart network]********************************
changed: [nc12]
changed: [nc13]
changed: [nc11]
changed: [nuc]
changed: [nc14]
```


### 查看结果

Ansible playbook 在运行结束后会输出一个运行回顾，示例如下：

```
PLAY RECAP *****************************************************************************************************
localhost                  : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
nc11                       : ok=609  changed=35   unreachable=0    failed=0    skipped=1108 rescued=0    ignored=1   
nc12                       : ok=452  changed=22   unreachable=0    failed=0    skipped=758  rescued=0    ignored=1   
nc13                       : ok=610  changed=34   unreachable=0    failed=0    skipped=1107 rescued=0    ignored=1  
nc14                       : ok=452  changed=22   unreachable=0    failed=0    skipped=758  rescued=0    ignored=1   
nuc                        : ok=728  changed=45   unreachable=0    failed=0    skipped=1237 rescued=0    ignored=7
```

如果出现异常，需进一步检查：

1. unreachable: 如果有节点显示为不可达，那么您应该检查该节点状态和网络连接。
2. failed: 如果有任务失败，那么您应该检查错误原因，并尝试解决问题。
3. ignored: 如果有错误被忽略，那么您应该检查错误信息和忽略原因，并确定是否需要采取进一步的措施。

Kubespray 运行过程中一些错误可被忽略 （ignored） 。这些被忽略的错误并不会影响 Kubespray 正常运行和安装 K8s 集群（但是会显示在 PLAY RECAP 的 `ignored` 项中）。

如果部分节点的 unreachable 或 failed 异常数量不为 0，则该节点的 K8s 安装失败，需要处理错误。


## 常见失败原因

安装过程中，有以下常见失败原因：

1. 镜像、命令行工具下载失败
    1. 设置的镜像名称错误
    1. Registry 不可访问，或者网络不通、不稳定
1. 验证未通过
    1. 重启 cri-dockerd 等系统服务时，等待时间超过预设值
    1. 用户配置不符合要求，如 etcd 节点数量为偶数
1. 节点遗留设置与现有设置冲突，导致命令运行出错
    1. 节点中设置了额外的 apt 源，导致冲突
    1. 节点中已经安装了新版本 docker，导致试图安装指定版本时失败
