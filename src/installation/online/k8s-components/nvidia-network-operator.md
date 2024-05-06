# 安装 Network Operator

## 前提条件

1. 节点包含 IB 网卡，且正确连接了 IB 网线

## 安装 MLNX_OFED 驱动

运行脚本安装驱动：

```bash
ansible-playbook ks-clusters/t9k-playbooks/4-install-ib-driver.yml \         
    -i ks-clusters/inventory/<new-cluster-name>-<version>/inventory.ini
    --become \
    -e "@~/ansible/<new-cluster-name>-<version>/vault.yml" \
    --vault-password-file=~/.vault-password.txt
```

本脚本暂不支持离线安装，您可以参考[附录：手动安装 MLNX_OFED 驱动](../../appendix/manually-install-mlnx-ofed-driver.md)来手动安装 MLNX_OFED 驱动。

## 安装 Network Operator

1. 按照[准备节点和安装 K8s](../prepare-nodes-and-install-k8s.md) 准备 Inventory，并完成 K8s 集群的部署。

2. 确认变量内容

在 t9k-playbooks/roles/network-operator/defaults/main.yml  中，设置了以下变量：

```bash
# Nvidia Network Operator
rdma_shared_device_name: rdma_shared_device_a
rdma_shared_device_vendor: 15b3
rdma_shared_device_id: 101b

network_operator_charts: oci://tsz.io/t9kcharts/network-operator
network_operator_version: "23.10.0"

network_operator_image_registry: t9kpublic
network_operator_test_image: ping-test
```

您需要确认这些变量是否符合您的实际需求。如果不符合，您需要在下一步“运行脚本”时使用命令行参数 -e 来指定您需要的参数。

3. 运行脚本：

```bash
# 使用 ansible vault 中保存的 become password
$ ansible-playbook ks-clusters/t9k-playbooks/4-install-network-operator.yml \         
    -i ks-clusters/inventory/<new-cluster-name>-<version>/inventory.ini
    --become \
    -e "@~/ansible/<new-cluster-name>-<version>/vault.yml" \
    --vault-password-file=~/.vault-password.txt


# 运行脚本时设置参数
$ ansible-playbook ks-clusters/t9k-playbooks/4-install-network-operator.yml \         
    -i ks-clusters/inventory/<new-cluster-name>-<version>/inventory.ini
    --become \
    -e "@~/ansible/<new-cluster-name>-<version>/vault.yml" \
    --vault-password-file=~/.vault-password.txt \
    -e rdma_shared_device_name=rdma_shared_device_a \
    -e rdma_shared_device_vendor=15b3 \
    -e rdma_shared_device_id=101b \
    -e network_operator_version="23.10.0" \
    -e network_operator_image_registry=t9kpublic

# 离线安装时，需要根据实际情况
# 设置 network_operator_charts 参数和 network_operator_image_registry 参数
$ ansible-playbook ks-clusters/t9k-playbooks/4-install-network-operator.yml \         
    -i ks-clusters/inventory/<new-cluster-name>-<version>/inventory.ini
    --become \
    -e "@~/ansible/<new-cluster-name>-<version>/vault.yml" \
    --vault-password-file=~/.vault-password.txt \
    -e network_operator_charts=\
../ks-clusters/tools/offline-additionals/charts/network-operator-23.10.0.tgz \
    -e network_operator_image_registry=192.168.101.159:5000/t9kpublic

# 交互式输入 become password
$ ansible-playbook ks-clusters/t9k-playbooks/4-install-network-operator.yml \
    -i ks-clusters/inventory/<new-cluster-name>-<version>/inventory.ini \
    --become --ask-become-pass
```

该脚本在 K8s 集群中创建 Network Operator。
