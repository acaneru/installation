# Summary

[概述](./overview.md)

---

* [在线安装](online/index.md)
    * [设置 ansible inventory](online/inventory/index.md)
        * [基本设置](online/inventory/basic-settings.md)
        * [高级设置](online/inventory/advanced-settings.md)
    * [准备节点](online/prepare-nodes.md)
    * [安装 K8s](online/k8s-index.md)
        * [基本安装](online/k8s-install.md) 
        * [CRI 配置](online/cri.md)
        * [CNI 配置](online/cni.md)
        * [设置 User Namespace](online/k8s-userns.md)
        * [设置集群存储](online/k8s-storage.md)
        * [集群维护](online/k8s-ops.md)
        * [常见问题](online/k8s-install-faqs.md)
        * [安装后配置](online/k8s-post-install.md)
    * [安装 K8s 组件](online/k8s-components/index.md)
        * [Istio](online/k8s-components/istio.md)
        * [Knative](online/k8s-components/knative.md)
        * [Metrics Server](online/k8s-components/metrics-server.md)
        * [Elastic Search](online/k8s-components/elastic-search.md)
        * [Loki](online/k8s-components/loki.md)
        * [监控相关](online/k8s-components/monitoring.md)
        * [Gatekeeper](online/k8s-components/gatekeeper.md)
    * [安装硬件支持](hardware/index.md)
        * [NVIDIA](hardware/nvidia/index.md)
            * [GPU Operator](hardware/nvidia/gpu-operator.md)
            * [Network Operator](hardware/nvidia/network-operator.md)
        * [AMD](hardware/amd/index.md)
        * [燧原 Enflame](hardware/enflame/index.md)
        * [海光 Hygon](hardware/hygon/index.md)
        * [华为](hardware/huawei/index.md)
        * [天数智芯 iluvatar](hardware/iluvatar/index.md)
        * [沐曦 MetaX](hardware/metax/index.md)
    * [安装 TensorStack AI 计算平台](online/products/index.md)
        * [安装前准备](online/products/pre-install.md)
            * [审计日志](online/products/pre-install/t9k-auditing.md)
        * [安装产品-User Console 模式](online/products/install-uc-mode.md)
            * [安装产品](online/products/install-uc.md)
            * [注册 APP](online/products/register-app.md)
        * [安装产品-传统模式](online/products/install-traditional-mode.md)
        * [安装后配置](online/products/post-install.md)
        * [安装后可选配置](online/products/post-install-optional.md)
    * [正确性检查](online/correctness-checking.md)
    * [安装 Harbor Registry](online/registry/harbor.md)
    * [安装存储服务](online/storage-service/index.md)
        * [MinIO](online/storage-service/minio.md)
        * [NFS 和 StorageClass](online/storage-service/nfs.md)
        * [Ceph](online/storage-service/ceph.md)
        * [Lustre](online/storage-service/lustre.md)
        * [GPFS](online/storage-service/gpfs.md)
* [离线安装](offline/index.md)
    * [准备离线安装包](offline/prepare-offline-packages/index.md)
        * [Kubespray](offline/prepare-offline-packages/kubespray.md)
        * [K8s 组件](offline/prepare-offline-packages/k8s-components.md)
        * [产品](offline/prepare-offline-packages/products.md)
    * [安装](offline/install/index.md)
        * [K8s](offline/install/k8s.md)
        * [K8s 组件](offline/install/k8s-components.md)
        * [产品](offline/install/products.md)
* [产品升级](update/index.md)
* [附录](appendix/index.md)
    * [在线安装 Docker](appendix/install-docker.md)
    * [在线安装 Docker Compose](appendix/install-docker-compose.md)
    * [配置 Docker Insecure Registry](appendix/configure-docker-insecure-registry.md)
    * [在线安装 s3cmd](appendix/install-s3cmd.md)
    * [安装 K8s 注释](appendix/k8s-install-notes.md)
    * [生成 K8s 文件和镜像列表](appendix/generate-k8s-file-and-image-list.md)
    * [生成 T9k 产品镜像列表](appendix/generate-t9k-product-image-list.md)
    * [Helm Chart 修改](appendix/modify-helm-chart.md)
    * [手动安装 MLNX_OFED 驱动](appendix/manually-install-mlnx-ofed-driver.md)
    * [ansible vars](appendix/ansible-vars.md)
    * [ansible debugging](appendix/ansible-debugging.md)
    * [管理域名证书](appendix/manage-domain-certificate.md)
    * [CRI 命令行工具](appendix/container-runtime-cli.md)
    * [集群管理安装配置](appendix/cluster-admin-installation-configuration.md)
