# 沐曦


## 总览
本文是沐曦 GPU 云原生组件的安装文档，以支持在 Kubernetes 中使用沐曦 GPU。沐曦 GPU 云原生组件的产品版本：
1. GPU Operator
    1. Helm Chart 版本 0.9.2
    2. 安装包 metax-gpu-k8s-package.0.9.2.tar.gz
    3. 组件版本：
        1. Maca: 2.29.0.7-ubuntu22.04-amd64
        2. GPU 驱动: 2.29.0.13-amd64
        3. 其他组件: 0.9.2
2. MX Exporter：
    1. Helm Chart 版本 0.5.0
    2. 安装包 mx-exporter.0.9.2.tgz

安装步骤分为三步：
1. 安装 GPU Operator。
2. 安装 MX Exporter。
3. [安装后]监控配置：完成上述步骤后，后续安装 T9k 产品时，需要设置针对 Metax GPU 资源的监控配置。

注：安装包来源于[沐曦下载中心](#参考)。

## 环境

下面是经过验证的环境：
1. K8s 版本：v1.30.4
2. 集群 GPU 节点：
    1. OS：Ubuntu 22.04
    2. Kernel： 5.15.0-25-generic 
    3. 容器运行时：containerd://1.7.21
3. Harbor 本地镜像仓库：
    1. Harbor 版本：v2.7.3-252a0b7c
    2. 服务地址：https://harbor.example.cn
4. 准备镜像和 Helm Chart 的节点：
    1. OS：Ubuntu 22.04
    2. Kernel： 5.15.0-25-generic 
    3. Docker：20.10.20
    4. Helm：v3.17.2

## 安装 GPU Operator

### 准备工作

#### 下载安装包

从 <https://developer.metax-tech.com/softnova/index> 下载驱动、镜像、k8s 安装包：

```bash
root@mx-5500g6:~/tensorstack# tree .
.
├── driver
│   ├── k8s-driver-image.2.29.0.13-x86_64.run
│   └── metax-driver-mxc500-2.29.0.13-deb-x86_64.run
├── history.log
├── image
│   ├── mxc500-maca-2.29.0.7-ubuntu22.04-amd64.container.xz
│   ├── mxc500-torch2.1-py310-mc2.29.0.7-ubuntu22.04-amd64.container.xz
│   └── pulled_images
└── k8s
    └── 0.9.2
        ├── metax-gpu-extensions-0.9.2.tgz
        ├── metax-gpu-k8s-package.0.9.2.tar.gz
        ├── metax-k8s-images.0.9.2.run
        └── metax-operator-0.9.2.tgz

5 directories, 14 files
```

#### GPU Operator 镜像和 Helm Chart

在 Harbor 本地仓库中创建 Project mximages、mxcharts 来存储镜像和 helm charts。

解压 metax-gpu-k8s-package，并按照下列步骤将 image、helm chart 上传到 Harbor：

```bash
root@mx-5500g6:~/tensorstack/k8s/0.9.2# tar -xvzf metax-gpu-k8s-package.0.9.2.tar.gz
metax-k8s-images.0.9.2.run
metax-operator-0.9.2.tgz
metax-gpu-extensions-0.9.2.tgz
root@mx-5500g6:~/tensorstack/k8s/0.9.2# ls
metax-gpu-extensions-0.9.2.tgz  metax-gpu-k8s-package.0.9.2.tar.gz  metax-k8s-images.0.9.2.run  metax-operator-0.9.2.tgz
root@mx-5500g6:~/tensorstack/k8s/0.9.2# docker login harbor.example.cn
root@mx-5500g6:~/tensorstack/k8s/0.9.2# sudo ./metax-k8s-images.0.9.2.run push harbor.example.cn/mximages
Verifying archive integrity...  100%   MD5 checksums are OK. All good.
Uncompressing Metax Kubernetes Solution Images -- 0.9.2  100%
metax-topo-master-image.0.9.2-amd64.xz
metax-topo-master-image.0.9.2-arm64.xz
metax-operator-controller-image.0.9.2-amd64.xz
metax-operator-controller-image.0.9.2-arm64.xz
Loaded image: cr.metax-tech.com/cloud/gpu-label:0.9.2-amd64
Loaded image: cr.metax-tech.com/cloud/gpu-label:0.9.2-arm64
The push refers to repository [harbor.example.cn/mximages/gpu-label]
492d5ea47e39: Pushed
46a6cc483b01: Pushed
256d88da4185: Pushed
0.9.2-amd64: digest: sha256:b09b4cb6e8e00abf8c2a94cd0c0a36efbdf82f846e690585bfdbe2440929fd3a size: 953
The push refers to repository [harbor.example.cn/mximages/gpu-label]
9f77591b69ae: Pushed
a9cd3f1ed9f2: Pushed
d2d3127fc3d3: Pushed
0.9.2-arm64: digest: sha256:03c2f158f553bb60bca17641d995937fa9ac8608c0060137f96c0b9559cb96ef size: 953
Created manifest list harbor.example.cn/mximages/gpu-label:0.9.2
sha256:7c887b9343c3efcca8d39a71b3a1ef4f3c2080901c1333069e817722e1a14138
Loaded image: cr.metax-tech.com/cloud/gpu-device:0.9.2-amd64
Loaded image: cr.metax-tech.com/cloud/gpu-device:0.9.2-arm64
The push refers to repository [harbor.example.cn/mximages/gpu-device]
e97c45b0e05b: Pushed
888d617d1351: Pushed
bc0a9d4e16d0: Pushed
0.9.2-amd64: digest: sha256:b43d9065b7b357df8b3429e79bdbe63817f6dbfaa80d08ed8eb501bbd15c10e9 size: 950
The push refers to repository [harbor.example.cn/mximages/gpu-device]
6b99339aa709: Pushed
397e92eedb3b: Pushed
31551975770e: Pushed
0.9.2-arm64: digest: sha256:dc86926e11e9c5a3a3c3ab126e26655be4ed6bd0ece61458333eaf89e4938d87 size: 950
Created manifest list harbor.example.cn/mximages/gpu-device:0.9.2
sha256:52bb1acb6cfda75ed71a2b0c2a4962cb8df097e13753d8bee16470c4986f21c2
Loaded image: cr.metax-tech.com/cloud/gpu-aware:0.9.2-amd64
Loaded image: cr.metax-tech.com/cloud/gpu-aware:0.9.2-arm64
The push refers to repository [harbor.example.cn/mximages/gpu-aware]
32309a873245: Pushed
5d8a0b31f182: Pushed
3acfa1f41375: Pushed
21d4a257c8e9: Pushed
fb64dc64f869: Pushed
bc0a9d4e16d0: Mounted from mximages/gpu-device
0.9.2-amd64: digest: sha256:ccd00e9bb9742a5038499dc60ef182c76ee59972a8604c49de8e4713a2708322 size: 1576
The push refers to repository [harbor.example.cn/mximages/gpu-aware]
d30fd0f71d25: Pushed
8393540c163d: Pushed
ce1cff40131f: Pushed
1509646e108b: Pushed
f2df1485560f: Pushed
31551975770e: Mounted from mximages/gpu-device
0.9.2-arm64: digest: sha256:ebb3c747bac77c721d70d460d9ba1f92216c382a442613938c175f632d566469 size: 1575
Created manifest list harbor.example.cn/mximages/gpu-aware:0.9.2
sha256:3f004e5c83c6990923aa24031c7d4573b7823289b93a70a3a867de75e7bf0a1c
Loaded image: cr.metax-tech.com/cloud/topo-master:0.9.2-amd64
Loaded image: cr.metax-tech.com/cloud/topo-master:0.9.2-arm64
The push refers to repository [harbor.example.cn/mximages/topo-master]
cb0b32e2e00d: Pushed
b48c0c323027: Pushed
7d9e050d7143: Pushed
73e4afdeae23: Pushed
256d88da4185: Mounted from mximages/gpu-label
0.9.2-amd64: digest: sha256:18ff2be7bf1708560a21306035b1f5472d1a521201cd27fb8f3291051a52c959 size: 1367
The push refers to repository [harbor.example.cn/mximages/topo-master]
4c50f362ca1e: Pushed
8fa8d3328bce: Pushed
a16ea9098e7c: Pushed
e744b29d50a8: Pushed
d2d3127fc3d3: Mounted from mximages/gpu-label
0.9.2-arm64: digest: sha256:3849990a1c345c4a14dc2ced82d089d68ba8ee5f7f94891741abd7440e033dec size: 1367
Created manifest list harbor.example.cn/mximages/topo-master:0.9.2
sha256:70787c5c6c444deb7d0dc5102b891f414be42b3c942ea9d3a1c200c05e712433
Loaded image: cr.metax-tech.com/cloud/topo-worker:0.9.2-amd64
Loaded image: cr.metax-tech.com/cloud/topo-worker:0.9.2-arm64
The push refers to repository [harbor.example.cn/mximages/topo-worker]
00735b63658e: Pushed
02f5773ed5c6: Pushed
256d88da4185: Mounted from mximages/topo-master
0.9.2-amd64: digest: sha256:359aeb289f276ef23122855de394bef5e63f89418ef5580b84d30d407190ba0f size: 948
The push refers to repository [harbor.example.cn/mximages/topo-worker]
2bccb57b878e: Pushed
58dae86f2df5: Pushed
d2d3127fc3d3: Mounted from mximages/topo-master
0.9.2-arm64: digest: sha256:cd6f6c90ea1571e2d52024d7c07ea7e74ea8c7496cc190e43e0dc7a1ebfc31fc size: 948
Created manifest list harbor.example.cn/mximages/topo-worker:0.9.2
sha256:87d4b5e2f7192e6efb7b50f2e879703fdacebfed897843cac36f6f509a3ef212
Loaded image: cr.metax-tech.com/cloud/operator-controller:0.9.2-amd64
Loaded image: cr.metax-tech.com/cloud/operator-controller:0.9.2-arm64
The push refers to repository [harbor.example.cn/mximages/operator-controller]
4f0934cba5ea: Pushed
ec5aa7fec606: Pushed
c3284807f35f: Pushed
54304229b5bd: Pushed
3acfa1f41375: Mounted from mximages/gpu-aware
21d4a257c8e9: Mounted from mximages/gpu-aware
fb64dc64f869: Mounted from mximages/gpu-aware
bc0a9d4e16d0: Mounted from mximages/gpu-aware
0.9.2-amd64: digest: sha256:7f4c017ab5e070fb27d5de19a7d2065dedd901472b8409d947a30f567ec1f24d size: 1991
The push refers to repository [harbor.example.cn/mximages/operator-controller]
296b1014f52e: Pushed
35ba35ab39ec: Pushed
265a2f17c0de: Pushed
a43a98588d4b: Pushed
ce1cff40131f: Mounted from mximages/gpu-aware
1509646e108b: Mounted from mximages/gpu-aware
f2df1485560f: Mounted from mximages/gpu-aware
31551975770e: Mounted from mximages/gpu-aware
0.9.2-arm64: digest: sha256:fb5ea56376ff8268614c207bb0c6b2a36201c42ab5900625cf7693b12ea7d4dc size: 1991
Created manifest list harbor.example.cn/mximages/operator-controller:0.9.2
sha256:6216bd3ac6bd74694a7df2e9e61c343401de5ee8fcf26c55e7b5aaf712a508bc
Loaded image: cr.metax-tech.com/cloud/container-runtime:0.9.2-amd64
Loaded image: cr.metax-tech.com/cloud/container-runtime:0.9.2-arm64
The push refers to repository [harbor.example.cn/mximages/container-runtime]
3eb0b4c97cb4: Pushed
d37425073504: Pushed
52cdb0f94f4b: Pushed
dd6fd41e8771: Pushed
db0fa08f8efa: Pushed
5314a0bfa158: Pushed
fb64dc64f869: Mounted from mximages/operator-controller
bc0a9d4e16d0: Mounted from mximages/operator-controller
0.9.2-amd64: digest: sha256:008171ae23622255ac62f7bdaf844d4cdf1534a311a6aac5f45f7e1331fcac9e size: 1996
The push refers to repository [harbor.example.cn/mximages/container-runtime]
3eb0b4c97cb4: Layer already exists
6d3750a3af81: Pushed
8991a48747da: Pushed
bf3cbf1d7cda: Pushed
f9c79905bc38: Pushed
ee05d175e11b: Pushed
f2df1485560f: Mounted from mximages/operator-controller
31551975770e: Mounted from mximages/operator-controller
0.9.2-arm64: digest: sha256:195cf6196ebe024a3ed6fcd5c6ff70a39e12521eb30ba65283e3a690cc3c7a9a size: 1996
Created manifest list harbor.example.cn/mximages/container-runtime:0.9.2
sha256:378587b62419218b839a94b87b24d6ce1dc20d21319de43f5f95e440d1f92243
Loaded image: cr.metax-tech.com/cloud/driver-manager:0.9.2-amd64
Loaded image: cr.metax-tech.com/cloud/driver-manager:0.9.2-arm64
The push refers to repository [harbor.example.cn/mximages/driver-manager]
f1952629bb15: Pushed
da3fb242a023: Pushed
55d1ae7246f4: Pushed
3a60332c3b1e: Pushed
256d88da4185: Mounted from mximages/topo-worker
0.9.2-amd64: digest: sha256:6fc5d7a31ceeb67b637d54f7d5f18b3c4976bb758376a58962d0514c212eb3c1 size: 1368
The push refers to repository [harbor.example.cn/mximages/driver-manager]
3d378964d77a: Pushed
2ab7689a6e9f: Pushed
2e38ef8aa37c: Pushed
0f1ed02714f2: Pushed
d2d3127fc3d3: Mounted from mximages/topo-worker
0.9.2-arm64: digest: sha256:62eca88d73a32eef86e969d345671cf3b388800c16db33f595142602e9577fed size: 1368
Created manifest list harbor.example.cn/mximages/driver-manager:0.9.2
sha256:1ff19be10b7cc0bb944cf97ccc61d96bcba0f0b96a61339afeb47b96af6cb682
Loaded image: cr.metax-tech.com/cloud/vfio-manager:0.9.2-amd64
Loaded image: cr.metax-tech.com/cloud/vfio-manager:0.9.2-arm64
The push refers to repository [harbor.example.cn/mximages/vfio-manager]
ba6596c7cc2c: Pushed
256d88da4185: Mounted from mximages/driver-manager
0.9.2-amd64: digest: sha256:19d3689b5ab958306e1655be592e1a323d6d585de4777a0fead46ab8107e710b size: 741
The push refers to repository [harbor.example.cn/mximages/vfio-manager]
fefc9c701286: Pushed
d2d3127fc3d3: Mounted from mximages/driver-manager
0.9.2-arm64: digest: sha256:b0afea734229de2b791e0ebee799f7c7f0b26988bb6b4aaebe3cca27cf9628ad size: 740
Created manifest list harbor.example.cn/mximages/vfio-manager:0.9.2
sha256:082e945db4648aa0bea5d9367ef5dc202c40eb2bb83b54728dc995cf25e5170f

root@mx-5500g6:~/tensorstack/k8s/0.9.2# helm registry login harbor.example.cn
root@mx-5500g6:~/tensorstack/k8s/0.9.2# helm push ./metax-gpu-extensions-0.9.2.tgz oci://harbor.example.cn/mxcharts
Pushed: harbor.example.cn/mxcharts/metax-gpu-extensions:0.9.2
Digest: sha256:35aff8352564d9a5af435f70c7088ec05c3d7c6f26a41278a54001777c14ba56
root@mx-5500g6:~/tensorstack/k8s/0.9.2# helm push ./metax-operator-0.9.2.tgz oci://harbor.example.cn/mxcharts
Pushed: harbor.example.cn/mxcharts/metax-operator:0.9.2
Digest: sha256:3a469b0f125088422d2cc5bf8aa53b82561726ce374f00d4d7fbd8d497365e97
```

#### MXMACA 容器镜像

上传 MXMACA 容器镜像：

```bash
root@mx-5500g6:~/tensorstack/image# ls
mxc500-maca-2.29.0.7-ubuntu22.04-amd64.container.xz  mxc500-torch2.1-py310-mc2.29.0.7-ubuntu22.04-amd64.container.xz  pulled_images
root@mx-5500g6:~/tensorstack/image# docker load < mxc500-maca-2.29.0.7-ubuntu22.04-amd64.container.xz
Loaded image: mxc500-maca:2.29.0.7-ubuntu22.04-amd64
root@mx-5500g6:~/tensorstack/image# docker tag mxc500-maca:2.29.0.7-ubuntu22.04-amd64 harbor.example.cn/mximages/mxc500-maca:2.29.0.7-ubuntu22.04-amd64
root@mx-5500g6:~/tensorstack/image# docker push harbor.example.cn/mximages/mxc500-maca:2.29.0.7-ubuntu22.04-amd64
The push refers to repository [harbor.example.cn/mximages/mxc500-maca]
63a131e7b7d3: Pushed
9c13cbd5d65b: Pushed
f7edaed339f5: Pushed
00c7399cdccf: Pushed
bf28bea77f92: Pushed
256d88da4185: Mounted from mximages/vfio-manager
2.29.0.7-ubuntu22.04-amd64: digest: sha256:5ee1eaeaa8686d9a7b7d99ae658f6c6214302d1d36ba70b00673ed549725e348 size: 1583
```

#### 内核驱动容器镜像

上传GPU 内核驱动容器镜像：

```bash
root@mx-5500g6:~/tensorstack/driver# ls
k8s-driver-image.2.29.0.13-x86_64.run  metax-driver-mxc500-2.29.0.13-deb-x86_64.run
root@mx-5500g6:~/tensorstack/driver# ./k8s-driver-image.2.29.0.13-x86_64.run push harbor.example.cn/mximages
Verifying archive integrity...  100%   MD5 checksums are OK. All good.
Uncompressing Metax Docker installer 2.29.0.13  100%
d4fc045c9e3a: Loading layer [==================================================>]  7.667MB/7.667MB
a1e3173b0b8d: Loading layer [==================================================>]  445.6MB/445.6MB
27082316a453: Loading layer [==================================================>]   18.9MB/18.9MB
1322be161d1c: Loading layer [==================================================>]  57.03MB/57.03MB
8a11a9368729: Loading layer [==================================================>]  3.072kB/3.072kB
Loaded image: cr.metax-tech.com/cloud/driver-image:2.29.0.13-amd64
The push refers to repository [harbor.example.cn/mximages/driver-image]
8a11a9368729: Pushed
1322be161d1c: Pushed
27082316a453: Pushed
a1e3173b0b8d: Pushed
d4fc045c9e3a: Pushed
2.29.0.13-amd64: digest: sha256:767f18eb4259d775d92658f56d8421ac350de22f1a29c021fed4bb2314dce5e6 size: 1369
Created manifest list harbor.example.cn/mximages/driver-image:2.29.0.13
sha256:163f54838cae7e297dd9e6fa8d19147eca121b859be1f89b3d01c413479d9842
```

### 安装 Helm Chart

在可以访问 Kubernetes 集群的节点上，运行下列命令安装 helm chart：

```bash
(base) t9k@master01:~$ helm install oci://harbor.example.cn/mxcharts/metax-operator \
--create-namespace -n metax-operator \
--generate-name \
--wait \
--set registry=harbor.example.cn/mximages \
--set driver.payload.version=2.29.0.13 \
--set maca.payload.registry=harbor.example.cn/mximages \
--set maca.payload.images={mxc500-maca:2.29.0.7-ubuntu22.04-amd64}
Pulled: harbor.example.cn/mxcharts/metax-operator:0.9.2
Digest: sha256:3a469b0f125088422d2cc5bf8aa53b82561726ce374f00d4d7fbd8d497365e97
W0401 17:48:19.093624 4031913 warnings.go:70] metadata.finalizers: "gpu.metax-tech.com": prefer a domain-qualified finalizer name to avoid accidental conflicts with other finalizer writers
NAME: metax-operator-1743500897
LAST DEPLOYED: Tue Apr  1 17:48:17 2025
NAMESPACE: metax-operator
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

运行下列命令，修改 clusteroperator，不安装 vfioManager（需要虚拟化 GPU 时，再安装这个组件）：
```bash
(base) t9k@master01:~$ kubectl patch clusteroperator cluster-operator -n metax-operator --type=merge -p '{"spec":{"vfioManager":{"deploy":false}}}'
clusteroperator.gpu.metax-tech.com/cluster-operator patched

GPU Operator 使用 ClusterOperator cluster-operator 存储全局配置，运行下列命令查看全局配置：
(base) t9k@master01:~$ k get ClusterOperator cluster-operator  -o yaml
apiVersion: gpu.metax-tech.com/v1alpha1
kind: ClusterOperator
metadata:
  annotations:
    meta.helm.sh/release-name: metax-operator-1743500897
    meta.helm.sh/release-namespace: metax-operator
  creationTimestamp: "2025-04-01T09:48:19Z"
  finalizers:
  - gpu.metax-tech.com
  generation: 2
  labels:
    app.kubernetes.io/component: metax-operator
    app.kubernetes.io/instance: metax-operator-1743500897
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: metax-operator
    app.kubernetes.io/version: 0.9.2
    helm.sh/chart: metax-operator-0.9.2
  name: cluster-operator
  resourceVersion: "15711453"
  uid: 9f5bbddb-e114-4053-a330-79548d019f05
spec:
  dataExporter:
    deploy: false
    image:
      name: mx-exporter
      pullPolicy: IfNotPresent
      registry: harbor.example.cn/mximages
      version: 0.9.2
    service:
      port: 30445
      type: ClusterIP
  devicePlugin:
    healthyInterval: 5
    image:
      name: gpu-device
      pullPolicy: IfNotPresent
      registry: harbor.example.cn/mximages
      version: 0.9.2
    log:
      dir: /var/log/metax
      format: json
      level: info
      maxAge: 26w
      rotationTime: 1w
  driver:
    deployPolicy: PreferCloud
    fwEffectPolicy: NextReboot
    fwEnableVirt: false
    fwUpgradePolicy: Never
    image:
      name: driver-manager
      pullPolicy: IfNotPresent
      registry: harbor.example.cn/mximages
      version: 0.9.2
    log:
      dir: /var/log/metax
      format: json
      level: info
      maxAge: 26w
      rotationTime: 1w
    payload:
      name: driver-image
      pullPolicy: IfNotPresent
      registry: harbor.example.cn/mximages
      version: 2.29.0.13
    upgradePolicy:
      enableRollout: false
      fallback: pause
      maxFailureThreshold: 5
      maxParallel: 100%
      maxUnavailable: 0%
      pause: false
      upgradeSteps:
      - pauseDuration: 30000
        replicas: 1
      - pauseDuration: 0
        replicas: 100%
  labelgen:
    image:
      name: gpu-label
      pullPolicy: IfNotPresent
      registry: harbor.example.cn/mximages
      version: 0.9.2
    log:
      dir: /var/log/metax
      format: json
      level: info
      maxAge: 26w
      rotationTime: 1w
  maca:
    image:
      name: driver-manager
      pullPolicy: IfNotPresent
      registry: harbor.example.cn/mximages
      version: 0.9.2
    log:
      dir: /var/log/metax
      format: json
      level: info
      maxAge: 26w
      rotationTime: 1w
    payload:
      images:
      - mxc500-maca:2.29.0.7-ubuntu22.04-amd64
      pullPolicy: IfNotPresent
      registry: harbor.example.cn/mximages
    resources:
      limits:
        memory: 10Gi
      requests:
        memory: 1Gi
  runtime:
    image:
      name: container-runtime
      pullPolicy: IfNotPresent
      registry: harbor.example.cn/mximages
      version: 0.9.2
    log:
      dir: /var/log/metax
      format: json
      level: info
      maxAge: 26w
      rotationTime: 1w
  vfioManager:
    deploy: false
    image:
      name: vfio-manager
      pullPolicy: IfNotPresent
      registry: harbor.example.cn/mximages
      version: 0.9.2
    log:
      dir: /var/log/metax
      format: json
      level: info
      maxAge: 26w
      rotationTime: 1w
```

等待一段时间后，查看 GPU Operator 组件 Pods 状态：

```bash
(base) t9k@master01:~$ k -n metax-operator get pod
NAME                                         READY   STATUS             RESTARTS      AGE
metax-container-runtime-vzgww                1/1     Running            0             106s
metax-driver-5p6pv                           1/1     Running            0             98s
metax-gpu-device-shdr5                       1/1     Running            0             22s
metax-gpu-label-64sk2                        1/1     Running            0             108s
metax-gpu-label-rcp9x                        1/1     Running            0             108s
metax-maca-d4r9f                             1/1     Running            0             98s
metax-operator-1743500897-7bd9f64956-5t7v7   1/1     Running            0             2m15s
metax-vfio-manager-27nqj                     0/1     CrashLoopBackOff   4 (18s ago)   106s
(base) t9k@master01:~$ k -n metax-operator describe pod metax-vfio-manager-fhr28
Name:             metax-vfio-manager-fhr28
Namespace:        metax-operator
...
Events:
  Type     Reason         Age                   From               Message
  ----     ------         ----                  ----               -------
  Normal   Scheduled      5m29s                 default-scheduler  Successfully assigned metax-operator/metax-vfio-manager-fhr28 to mx-5500g6
  Warning  IOMMUDisabled  5m28s                 vfio-manager       IOMMU support is missing on node mx-5500g6. Please ensure that IOMMU is enabled on the node
  Warning  IOMMUDisabled  5m27s                 vfio-manager       IOMMU support is missing on node mx-5500g6. Please ensure that IOMMU is enabled on the node
  Warning  IOMMUDisabled  5m11s                 vfio-manager       IOMMU support is missing on node mx-5500g6. Please ensure that IOMMU is enabled on the node
  Warning  IOMMUDisabled  4m43s                 vfio-manager       IOMMU support is missing on node mx-5500g6. Please ensure that IOMMU is enabled on the node
  Normal   Pulled         4m2s (x5 over 5m28s)  kubelet            Container image "harbor.example.cn/mximages/vfio-manager:0.9.2" already present on machine
  Warning  IOMMUDisabled  4m1s                  vfio-manager       IOMMU support is missing on node mx-5500g6. Please ensure that IOMMU is enabled on the node
  Normal   Created        4m1s (x5 over 5m28s)  kubelet            Created container vfio-manager-container
  Normal   Started        4m1s (x5 over 5m28s)  kubelet            Started container vfio-manager-container
  Warning  IOMMUDisabled  2m39s                 vfio-manager       IOMMU support is missing on node mx-5500g6. Please ensure that IOMMU is enabled on the node
  Warning  BackOff        19s (x22 over 5m26s)  kubelet            Back-off restarting failed container vfio-manager-container in pod metax-vfio-manager-fhr28_metax-operator(3c9da45a-796d-42f9-b888-4b9bccd51e5f)
(base) t9k@master01:~$ k -n metax-operator logs metax-vfio-manager-fhr28
{"level":"fatal","msg":"iommu is not enabled, progress quit now","time":"2025-04-01T08:46:41Z"}
```

删除 DaemonSet metax-vfio-manager：

```bash
(base) t9k@master01:~$ k -n metax-operator get ds
NAME                      DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                                                                                        AGE
metax-container-runtime   1         1         1       1            1           metax-tech.com/gpu.installed=true                                                                    3m14s
metax-driver              1         1         1       1            1           metax-tech.com/gpu.installed=true,metax-tech.com/runtime.ready=true                                  3m14s
metax-gpu-device          1         1         1       1            1           metax-tech.com/gpu.installed=true,metax-tech.com/maca.ready=true,metax-tech.com/runtime.ready=true   3m14s
metax-gpu-label           2         2         2       2            2           <none>                                                                                               3m14s
metax-maca                1         1         1       1            1           metax-tech.com/gpu.installed=true,metax-tech.com/runtime.ready=true                                  3m14s
metax-vfio-manager        1         1         0       1            0           metax-tech.com/gpu.installed=true                                                                    3m13s
(base) t9k@master01:~$ k -n metax-operator delete ds metax-vfio-manager
daemonset.apps "metax-vfio-manager" deleted
```

### 验证

#### GPU 扩展资源

查看 GPU 节点上是否有 GPU 扩展资源：
1. 有扩展资源 `metax-tech.com/gpu`。
2. 扩展资源数量与节点上 GPU 硬件数量一致。

```bash
(base) t9k@master01:~$ k get node mx-5500g6 -o json | jq .status.allocatable
{
  "cpu": "191900m",
  "ephemeral-storage": "379445965811",
  "hugepages-1Gi": "0",
  "hugepages-2Mi": "0",
  "memory": "1056124912Ki",
  "metax-tech.com/gpu": "8",
  "metax-tech.com/vfio-gpu": "0",
  "pods": "110"
}
```

#### GPU 节点标签

查看 GPU 节点标签，节点标签包含 metax GPU 信息：

```bash
(base) t9k@master01:~$ k get node mx-5500g6 -o yaml
apiVersion: v1
kind: Node
metadata:
  creationTimestamp: "2025-03-31T08:40:44Z"
  labels:
    beta.kubernetes.io/arch: amd64
    beta.kubernetes.io/fluentd-ds-ready: "true"
    beta.kubernetes.io/os: linux
    kubernetes.io/arch: amd64
    kubernetes.io/hostname: mx-5500g6
    kubernetes.io/os: linux
    metax-tech.com/driver.ready: "true"
    metax-tech.com/gpu.driver.major: "2"
    metax-tech.com/gpu.driver.minor: "12"
    metax-tech.com/gpu.driver.mode: cloud
    metax-tech.com/gpu.driver.patch: "13"
    metax-tech.com/gpu.family: MXC
    metax-tech.com/gpu.installed: "true"
    metax-tech.com/gpu.memory: 64GB
    metax-tech.com/gpu.product: MXC550
    metax-tech.com/gpu.sriov: forbidden
    metax-tech.com/maca.ready: "true"
    metax-tech.com/runtime.ready: "true"
    node-role.kubernetes.io/compute: ""
  name: mx-5500g6
```

#### Containerd 配置

查看 GPU 节点的 containerd 配置：
1. 已被注入 [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.metax]
2. default runtime 被设置为 metax

```bash
root@mx-5500g6:~# cat /etc/containerd/config.toml
oom_score = 0
root = "/var/lib/containerd"
state = "/run/containerd"
version = 2

[debug]
  address = ""
  format = ""
  gid = 0
  level = "info"
  uid = 0

[grpc]
  max_recv_message_size = 16777216
  max_send_message_size = 16777216

[metrics]
  address = ""
  grpc_histogram = false

[plugins]

  [plugins."io.containerd.grpc.v1.cri"]
    disable_apparmor = false
    disable_hugetlb_controller = true
    enable_selinux = false
    enable_unprivileged_icmp = false
    enable_unprivileged_ports = false
    image_pull_progress_timeout = "5m"
    max_container_log_line_size = -1
    sandbox_image = "registry.cn-hangzhou.aliyuncs.com/t9k/pause:3.9"
    tolerate_missing_hugetlb_controller = true

    [plugins."io.containerd.grpc.v1.cri".containerd]
      default_runtime_name = "metax"
      discard_unpacked_layers = true
      snapshotter = "overlayfs"

      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]

        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.metax]
          base_runtime_spec = "/etc/containerd/cri-base.json"
          runtime_engine = ""
          runtime_root = ""
          runtime_type = "io.containerd.runc.v2"

          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.metax.options]
            BinaryName = "/var/lib/metax/tools/usr/bin/mx-container-runtime"
            binaryName = "/usr/local/bin/runc"
            systemdCgroup = true

        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
          base_runtime_spec = "/etc/containerd/cri-base.json"
          runtime_engine = ""
          runtime_root = ""
          runtime_type = "io.containerd.runc.v2"

          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            binaryName = "/usr/local/bin/runc"
            systemdCgroup = true

    [plugins."io.containerd.grpc.v1.cri".registry]

      [plugins."io.containerd.grpc.v1.cri".registry.mirrors]

        [plugins."io.containerd.grpc.v1.cri".registry.mirrors."docker.io"]
          endpoint = ["https://registry.dockermirror.com"]
```

#### 创建 Pod 测试用例

创建使用 GPU 的 Pod，并在 Pod 容器中查看 metax 相关配置：

```bash
(base) t9k@master01:~$ k create -f - << EOF
> apiVersion: v1
kind: Pod
metadata:
  name: ubuntu
spec:
  containers:
  - image: registry.cn-hangzhou.aliyuncs.com/t9k/ubuntu:22.04
    name: hey
    tty: true
    resources:
      limits:
        metax-tech.com/gpu: 1
        cpu: 100m
        memory: 100Mi
EOF
pod/ubuntu created
(base) t9k@master01:~$ k get pod
NAME     READY   STATUS    RESTARTS   AGE
ubuntu   1/1     Running   0          23s
(base) t9k@master01:~$ k exec -ti ubuntu -- bash
root@ubuntu:/# mx-smi
mx-smi  version: 2.1.12

=================== MetaX System Management Interface Log ===================
Timestamp                                         : Tue Apr  1 10:10:23 2025

Attached GPUs                                     : 1
+---------------------------------------------------------------------------------+
| MX-SMI 2.1.12                       Kernel Mode Driver Version: 2.12.13         |
| MACA Version: unknown               BIOS Version: 1.13.4.0                      |
|------------------------------------+---------------------+----------------------+
| GPU         NAME                   | Bus-id              | GPU-Util             |
| Temp        Pwr:Usage/Cap          | Memory-Usage        |                      |
|====================================+=====================+======================|
| 0           MetaX C550             | 0000:2a:00.0        | 0%                   |
| 34C         97W / NA               | 858/65536 MiB       |                      |
+------------------------------------+---------------------+----------------------+

+---------------------------------------------------------------------------------+
| Process:                                                                        |
|  GPU                    PID         Process Name                 GPU Memory     |
|                                                                  Usage(MiB)     |
|=================================================================================|
|  no process found                                                               |
+---------------------------------------------------------------------------------+

End of Log
# 输入 mx，然后按 tab 键，可以查看到下列 binary
root@ubuntu:/# mx
mx-diagease            mx-report              mx-smi                 mxcc                   mxcc-ocl               mxfortran              mxfortran.py           mxmaca-sdk-install.sh
root@ubuntu:/# ls /opt/
maca  maca-2.29.0.19  mxdriver
```

作为对比，创建一个不使用 GPU 的 Pod ubuntu-nogpu：

```bash
(base) t9k@master01:~$ k create -f - << EOF
> apiVersion: v1
kind: Pod
metadata:
  name: ubuntu-nogpu
spec:
  containers:
  - image: registry.cn-hangzhou.aliyuncs.com/t9k/ubuntu:22.04
    name: hey
    tty: true
    resources:
      limits:
        cpu: 100m
        memory: 100Mi
EOF
pod/ubuntu-nogpu created
(base) t9k@master01:~$ k get pod
NAME           READY   STATUS    RESTARTS   AGE
ubuntu         1/1     Running   0          3m39s
ubuntu-nogpu   1/1     Running   0          6s
(base) t9k@master01:~$ k exec -ti ubuntu-nogpu -- bash
root@ubuntu-nogpu:/# mx-smi
bash: mx-smi: command not found
root@ubuntu-nogpu:/# ls /opt/
```

删除测试 pods：

```bash
(base) t9k@master01:~$ k delete pod ubuntu ubuntu-nogpu
pod "ubuntu" deleted
pod "ubuntu-nogpu" deleted
```

## 安装 MX Exporter

### 准备工作

#### 下载安装包

从 <https://developer.metax-tech.com/softnova/index> 找到安装包下载命令，运行下列命令下载 mx-exporter 安装包：

```bash
root@mx-5500g6:~$ wget -O mx-exporter.0.9.2.tgz "https://metax-pub.oss-cn-shanghai.aliyuncs.com/mxmaca2.0/2.28.0.x/binary/x86_64/cloud/mx-exporter.0.9.2.tgz?OSSAccessKeyId=LTAI5t8HeoJo71RpDsrCMZbQ&Expires=1743530864&Signature=Nm949ZAzFqOqF7fJ9bl2ZU4TaKQ%3D"
--2025-04-01 18:07:47--  https://metax-pub.oss-cn-shanghai.aliyuncs.com/mxmaca2.0/2.28.0.x/binary/x86_64/cloud/mx-exporter.0.9.2.tgz?OSSAccessKeyId=LTAI5t8HeoJo71RpDsrCMZbQ&Expires=1743530864&Signature=Nm949ZAzFqOqF7fJ9bl2ZU4TaKQ%3D
Resolving metax-pub.oss-cn-shanghai.aliyuncs.com (metax-pub.oss-cn-shanghai.aliyuncs.com)... 222.73.156.23
Connecting to metax-pub.oss-cn-shanghai.aliyuncs.com (metax-pub.oss-cn-shanghai.aliyuncs.com)|222.73.156.23|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 184856654 (176M) [application/octet-stream]
Saving to: ‘mx-exporter.0.9.2.tgz’

mx-exporter.0.9.2.tgz                               100%[=================================================================================================================>] 176.29M  75.6MB/s    in 2.3s

2025-04-01 18:07:50 (75.6 MB/s) - ‘mx-exporter.0.9.2.tgz’ saved [184856654/184856654]
root@mx-5500g6:~$ ls mx-exporter.0.9.2.tgz
mx-exporter.0.9.2.tgz
root@mx-5500g6:~$ tar -xzf mx-exporter.0.9.2.tgz
root@mx-5500g6:~$ cd mx-exporter/
root@mx-5500g6:~/mx-exporter$ ls
config  deployment  DOCKER.md  mx-exporter-0.9.2-amd64.xz  mx-exporter-0.9.2-arm64.xz
root@mx-5500g6:~/mx-exporter$ tree .
.
├── config
│   └── default-counters.csv
├── deployment
│   ├── grafana
│   │   ├── deployment.yaml
│   │   ├── grafana-datasource-config.yaml
│   │   └── service.yaml
│   ├── grafana-dashboard
│   │   ├── Metax-Alerts.json
│   │   ├── MetaX-Data-Center-GPU-Usage-Overview.json
│   │   └── MetaX-GPU-C500.json
│   ├── mx-exporter
│   │   ├── helm
│   │   │   └── mx-exporter
│   │   │       ├── Chart.yaml
│   │   │       ├── templates
│   │   │       │   ├── daemonset.yaml
│   │   │       │   ├── _helpers.tpl
│   │   │       │   ├── hpa.yaml
│   │   │       │   ├── ingress.yaml
│   │   │       │   ├── metrics-configmap.yaml
│   │   │       │   ├── NOTES.txt
│   │   │       │   ├── serviceaccount.yaml
│   │   │       │   └── service.yaml
│   │   │       └── values.yaml
│   │   └── mx-exporter-daemonset.yaml
│   ├── namespace.yaml
│   └── prometheus
│       ├── clusterRole.yaml
│       ├── config-map.yaml
│       ├── prometheus-deployment.yaml
│       └── prometheus-service.yaml
├── DOCKER.md
├── mx-exporter-0.9.2-amd64.xz
└── mx-exporter-0.9.2-arm64.xz

root@mx-5500g6:~/mx-exporter$ cat deployment/mx-exporter/helm/mx-exporter/Chart.yaml
apiVersion: v2
name: mx-exporter
description: A Helm chart for MetaX GPU metrics exporter

# A chart can be either an 'application' or a 'library' chart.
#
# Application charts are a collection of templates that can be packaged into versioned archives
# to be deployed.
#
# Library charts provide useful utilities or functions for the chart developer. They're included as
# a dependency of application charts to inject those utilities and functions into the rendering
# pipeline. Library charts do not define any templates and therefore cannot be deployed.
type: application

# This is the chart version. This version number should be incremented each time you make changes
# to the chart and its templates, including the app version.
# Versions are expected to follow Semantic Versioning (https://semver.org/)
version: 0.5.0

# This is the version number of the application being deployed. This version number should be
# incremented each time you make changes to the application. Versions are not expected to
# follow Semantic Versioning. They should reflect the version the application is using.
# It is recommended to use it with quotes.
appVersion: "2.1.10"

keywords:
  - gpu
  - compute
  - monitoring
  - telemetry
```

#### MX Exporter 镜像和 Helm Chart

从安装包加载镜像，并上传到 harbor.example.cn

```bash
root@mx-5500g6:~/mx-exporter$ docker load -i mx-exporter-0.9.2-amd64.xz
548a79621a42: Loading layer [==================================================>]  65.53MB/65.53MB
a6f5a4db20b6: Loading layer [==================================================>]  235.9MB/235.9MB
1dd18676a0da: Loading layer [==================================================>]   14.8MB/14.8MB
e89ea7416e05: Loading layer [==================================================>]  14.41MB/14.41MB
b87ee5e66685: Loading layer [==================================================>]  2.048kB/2.048kB
e56417dbe59d: Loading layer [==================================================>]  2.129MB/2.129MB
Loaded image: cr.metax-tech.com/cloud/mx-exporter:0.9.2
root@mx-5500g6:~/mx-exporter$ docker tag  cr.metax-tech.com/cloud/mx-exporter:0.9.2 harbor.example.cn/mximages/mx-exporter:0.9.2
root@mx-5500g6:~/mx-exporter$ docker push harbor.example.cn/mximages/mx-exporter:0.9.2
The push refers to repository [harbor.example.cn/mximages/mx-exporter]
e56417dbe59d: Pushed
b87ee5e66685: Pushed
e89ea7416e05: Pushed
1dd18676a0da: Pushed
a6f5a4db20b6: Pushed
548a79621a42: Pushed
0.9.2: digest: sha256:a64c6f193b0892e71a91ac6f72d3b206b91f83063fb21404ba63d1fe37675124 size: 1580
```

将 Helm Chart 上传到 harbor.example.cn

```bash
root@mx-5500g6:~/mx-exporter$ ls deployment/mx-exporter/helm/mx-exporter/
Chart.yaml  templates  values.yaml
root@mx-5500g6:~/mx-exporter$ helm package deployment/mx-exporter/helm/mx-exporter
Successfully packaged chart and saved it to: /home/t9k/mx-exporter/mx-exporter-0.5.0.tgz
root@mx-5500g6:~/mx-exporter$ helm push mx-exporter-0.5.0.tgz  oci://harbor.example.cn/mxcharts
Pushed: harbor.example.cn/mxcharts/mx-exporter:0.5.0
Digest: sha256:366ab5faf6f9e047617ef6b17a622fe9e961b4972f02666b1e67dba2abbe7337
```

### 安装 Helm Chart

在可以访问 Kubernetes 集群的节点上，运行下列命令安装 helm chart

```bash
(base) t9k@master01:~/mx-exporter$ helm install mx-exporter oci://harbor.example.cn/mxcharts/mx-exporter --create-namespace -n metax-monitor --wait --set image.repository=harbor.example.cn/mximages/mx-exporter --set image.tag=0.9.2 --set-string nodeSelector."metax-tech\.com/gpu\.installed"=true
Pulled: harbor.example.cn/mxcharts/mx-exporter:0.5.0
Digest: sha256:366ab5faf6f9e047617ef6b17a622fe9e961b4972f02666b1e67dba2abbe7337
NAME: mx-exporter
LAST DEPLOYED: Wed Apr  2 10:59:35 2025
NAMESPACE: metax-monitor
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace metax-monitor -l "app.kubernetes.io/name=mx-exporter,app.kubernetes.io/instance=mx-exporter" -o jsonpath="{.items[0].metadata.name}")
  export CONTAINER_PORT=$(kubectl get pod --namespace metax-monitor $POD_NAME -o jsonpath="{.spec.containers[0].ports[0].containerPort}")
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl --namespace metax-monitor port-forward $POD_NAME 8080:$CONTAINER_PORT
```


### 验证&问题

查看 Pod 状态:
1. mx-exporter pod 正常运行在 GPU 节点上
2. mx-exporter pod 日志输出错误 `GpuMonitor mxSmlGetCurrentClocksThrottleReason failed: Sysfs error` （目前认为是 metax 产品 bug）。

```bash
(base) t9k@master01:~/mx-exporter$ k -n metax-monitor  get pod -o wide
NAME                READY   STATUS    RESTARTS   AGE   IP              NODE        NOMINATED NODE   READINESS GATES
mx-exporter-lrh44   1/1     Running   0          34s   10.233.65.227   mx-5500g6   <none>           <none>
(base) t9k@master01:~/mx-exporter$ k -n metax-monitor  logs mx-exporter-lrh44
Using lib from /opt/mxexporter/mx_exporter/libmxsml.so
Namespace(config_file='/etc/config/metrics', ib_monitor=0, interval=10000, log_monitor=0, mode=1, mount_point='/', port=8000)
Config file: /etc/config/metrics
2025-04-02 02:59:37.092945 GpuMonitor first mxSmlInit success
2025-04-02 02:59:37.092984 GpuMonitor Device number1: 8
2025-04-02 03:00:07.149238 GpuMonitor second mxSmlInit success
2025-04-02 03:00:07.149345 GpuMonitor Device number2: 8
2025-04-02 03:00:07.149363 GpuMonitor initialize success
2025-04-02 03:00:07.149384 GpuMonitor mxSmlGetDeviceCount number: 8
2025-04-02 03:00:07.149448 GpuMonitor mxSmlGetDeviceInfo for GPU#0 device name: MXC550
2025-04-02 03:00:07.149777 GpuMonitor mxSmlGetDeviceInfo for GPU#1 device name: MXC550
2025-04-02 03:00:07.150025 GpuMonitor mxSmlGetDeviceInfo for GPU#2 device name: MXC550
2025-04-02 03:00:07.150246 GpuMonitor mxSmlGetDeviceInfo for GPU#3 device name: MXC550
2025-04-02 03:00:07.150457 GpuMonitor mxSmlGetDeviceInfo for GPU#4 device name: MXC550
2025-04-02 03:00:07.150666 GpuMonitor mxSmlGetDeviceInfo for GPU#5 device name: MXC550
2025-04-02 03:00:07.150985 GpuMonitor mxSmlGetDeviceInfo for GPU#6 device name: MXC550
2025-04-02 03:00:07.151192 GpuMonitor mxSmlGetDeviceInfo for GPU#7 device name: MXC550
2025-04-02 03:00:07.151428 GpuMonitor mxSmlGetPfDeviceCount number: 0
2025-04-02 03:00:07.152206 MxCollector ["# The line begins with '#' is a comment line."]
2025-04-02 03:00:07.152251 MxCollector Skip comment line
2025-04-02 03:00:07.152274 MxCollector ['# Format: metric id', 'metric type', 'metric name', 'metric description', 'label1', 'label2', '...']
2025-04-02 03:00:07.152300 MxCollector Skip comment line
2025-04-02 03:00:07.152316 MxCollector ['# metric name', ' metric description and labels name can be modified as your need']
...
2025-04-02 03:00:07.155851 MxCollector Skip comment line
2025-04-02 03:00:07.155871 MxCollector ['gpu_state', 'Gauge', 'mx_gpu_state', 'GPU state: 0(not available) 1(available)', 'deviceId', 'uuid', 'exported_pod', 'exported_namespace', 'exported_container', 'Hostname', 'driver_version', 'bios_version', 'modelName']
2025-04-02 03:00:07.155935 MxCollector []
2025-04-02 03:00:07.155951 MxCollector Skip empty line
2025-04-02 03:00:07.155965 MxCollector ['# MXC specific current gpu clock throttle reason']
2025-04-02 03:00:07.155981 MxCollector Skip comment line
2025-04-02 03:00:07.156001 MxCollector ['clk_thr', 'Gauge', 'mx_clk_thr', 'Current gpu clock throttling reason', 'deviceId', 'uuid', 'exported_pod', 'exported_namespace', 'exported_container', 'Hostname', 'driver_version', 'bios_version', 'modelName']
2025-04-02 03:00:07.156646 GpuMonitor Get data GPU#0
2025-04-02 03:00:07.166124 GpuMonitor mxSmlGetOpticalModuleStatus failed: Operation not support in target device
2025-04-02 03:00:07.166167 GpuMonitor Remove not supported metric optical_module_temp
2025-04-02 03:00:07.256227 GpuMonitor mxSmlGetCurrentClocksThrottleReason failed: Sysfs error
2025-04-02 03:00:07.256280 GpuMonitor Get data GPU#1
2025-04-02 03:00:07.351904 GpuMonitor mxSmlGetCurrentClocksThrottleReason failed: Sysfs error
2025-04-02 03:00:07.351967 GpuMonitor Get data GPU#2
2025-04-02 03:00:07.447818 GpuMonitor mxSmlGetCurrentClocksThrottleReason failed: Sysfs error
2025-04-02 03:00:07.447888 GpuMonitor Get data GPU#3
2025-04-02 03:00:07.543754 GpuMonitor mxSmlGetCurrentClocksThrottleReason failed: Sysfs error
2025-04-02 03:00:07.543825 GpuMonitor Get data GPU#4
2025-04-02 03:00:07.639940 GpuMonitor mxSmlGetCurrentClocksThrottleReason failed: Sysfs error
2025-04-02 03:00:07.639995 GpuMonitor Get data GPU#5
2025-04-02 03:00:07.736289 GpuMonitor mxSmlGetCurrentClocksThrottleReason failed: Sysfs error
2025-04-02 03:00:07.736356 GpuMonitor Get data GPU#6
2025-04-02 03:00:07.831746 GpuMonitor mxSmlGetCurrentClocksThrottleReason failed: Sysfs error
2025-04-02 03:00:07.831816 GpuMonitor Get data GPU#7
2025-04-02 03:00:07.927858 GpuMonitor mxSmlGetCurrentClocksThrottleReason failed: Sysfs error
2025-04-02 03:00:17.937977 GpuMonitor Get data GPU#0
2025-04-02 03:00:18.035451 GpuMonitor mxSmlGetCurrentClocksThrottleReason failed: Sysfs error
2025-04-02 03:00:18.035524 GpuMonitor Get data GPU#1
2025-04-02 03:00:18.131583 GpuMonitor mxSmlGetCurrentClocksThrottleReason failed: Sysfs error
```

查看 mx-exporter 提供的 metrics：无 metric mx_clk_thr 数据，与 Pod 日志输出的错误信息（mxSmlGetCurrentClocksThrottleReason failed）一致。

```bash
(base) t9k@master01:~$ k -n metax-monitor port-forward mx-exporter-lrh44 8000
Forwarding from 127.0.0.1:8000 -> 8000
Forwarding from [::1]:8000 -> 8000
Handling connection for 8000
(base) t9k@master01:~/mx-exporter$ curl localhost:8000/metrics
# HELP mx_device_type Device type
# TYPE mx_device_type gauge
mx_device_type{deviceId="0",deviceType="MXC550",uuid="GPU-87ba9f62-d02e-0528-f19e-1936f082e738"} 1.0
mx_device_type{deviceId="1",deviceType="MXC550",uuid="GPU-9cea8405-18ff-28ff-44ee-ace7e8b938b9"} 1.0
mx_device_type{deviceId="2",deviceType="MXC550",uuid="GPU-c56e8f62-3a2c-3d23-a742-a9361e146f3d"} 1.0
mx_device_type{deviceId="3",deviceType="MXC550",uuid="GPU-bb19f045-15b4-532c-5523-9027577c2d14"} 1.0
mx_device_type{deviceId="4",deviceType="MXC550",uuid="GPU-43387c13-822c-0e21-9d88-64ed1614e2ab"} 1.0
mx_device_type{deviceId="5",deviceType="MXC550",uuid="GPU-5168627d-2d56-447d-bbf8-36afdfcaecaf"} 1.0
mx_device_type{deviceId="6",deviceType="MXC550",uuid="GPU-6887400c-2ddd-fc03-f8f1-c074df4fe45d"} 1.0
mx_device_type{deviceId="7",deviceType="MXC550",uuid="GPU-76b9c484-c749-d7b4-aac3-6cac3153817c"} 1.0
...
# HELP mx_clk_thr Current gpu clock throttling reason
# TYPE mx_clk_thr gauge
```

## 监控配置

### T9k Monitoring

在安装 T9k Monitoring 时，可通过 Helm values.yaml 中的 `global.t9k.monitoring.gpu.metax` 字段配置针对 MetaX GPU 的监控设置。启用 Metax GPU 监控后：
1. T9k Monitoring 部署的 Prometheus 服务将自动收集 MX Exporter 生成的监控数据。
2. 在 T9k Monitoring 部署的 Grafana 中，可以通过 Dashboard 查看 MetaX GPU 的监控图表。

下面是一个配置示例：
```yaml
global:
  t9k:
    monitoring:
      gpu:
        metax:
          enabled: false
          serviceMonitor:
            # namespace where service mx-exporter is located
            namespaceMatchName: metax-monitor
            # port in service mx-exporter to expose metrics
            port: metrics
            # labels to match service mx-exporter
            selector:      
              matchLabels:
                app.kubernetes.io/name: mx-exporter
```

### Cluster Admin

在安装 Cluster Admin 时，可通过 Helm values.yaml 中的 `global.t9k.clusterAdminWeb.gpuMonitoring.metax` 字段配置针对 MetaX GPU 的监控设置。启用 MetaX GPU 监控后：
1. 管理员可以在 Cluster Admin Web 的工作负载详情页面查看 MetaX GPU 的资源监控图表。
2. 管理员可以在节点详情页面查看节点上的 MetaX GPU 信息。

下面是一个配置示例，配置的字段说明请参考<a target="_blank" rel="noopener noreferrer" href="https://github.com/t9k/admin-manuals/blob/master/src/cluster-admin-ui/config.md#gpu-%E7%9B%91%E6%8E%A7%E9%85%8D%E7%BD%AE">管理员文档</a>：
```yaml
global:
  t9k:
    clusterAdminWeb:
      gpuMonitoring:
        metax:
          charts:
          - legend: '{{uuid}}'
            promQLFormat: avg(label_replace(label_replace(mx_memory_used{job="metax-exporter",type="vram",exported_namespace="${namespace}",exported_pod=~"${pods}",exported_pod!=""},"pod","$1","exported_pod","(.+)"),"namespace","$1","exported_namespace","(.+)")    *
              on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
            title:
              en: GPU Memory Used
              zh: GPU 已用显存
            unit: KB
          - legend: '{{uuid}}'
            promQLFormat: avg(label_replace(label_replace(mx_memory_usage{job="metax-exporter",type="vram",exported_namespace="${namespace}",exported_pod=~"${pods}",exported_pod!=""},"pod","$1","exported_pod","(.+)"),"namespace","$1","exported_namespace","(.+)")    *
              on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
            title:
              en: GPU Memory Usage
              zh: GPU 显存使用率
            unit: '%'
          - legend: '{{uuid}}'
            promQLFormat: avg(label_replace(label_replace(mx_board_power{job="metax-exporter",exported_namespace="${namespace}",exported_pod=~"${pods}",exported_pod!=""},"pod","$1","exported_pod","(.+)"),"namespace","$1","exported_namespace","(.+)")    *
              on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
            title:
              en: GPU Power
              zh: GPU 功率
            unit: mW
          - legend: '{{uuid}}'
            promQLFormat: avg(label_replace(label_replace(mx_chip_hotspot_temp{job="metax-exporter",exported_namespace="${namespace}",exported_pod=~"${pods}",exported_pod!=""},"pod","$1","exported_pod","(.+)"),"namespace","$1","exported_namespace","(.+)")    *
              on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
            title:
              en: Chip Hotspot Temperature
              zh: 芯片热点温度
            unit: '°C'
          - legend: '{{uuid}}'
            promQLFormat: avg(label_replace(label_replace(mx_board_core_temp{job="metax-exporter",exported_namespace="${namespace}",exported_pod=~"${pods}",exported_pod!=""},"pod","$1","exported_pod","(.+)"),"namespace","$1","exported_namespace","(.+)")    *
              on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
            title:
              en: Board CORE Temperature
              zh: 主板核心温度
            unit: '°C'
          - legend: '{{uuid}}'
            promQLFormat: avg(label_replace(label_replace(mx_gpu_usage{job="metax-exporter",exported_namespace="${namespace}",exported_pod=~"${pods}",exported_pod!=""},"pod","$1","exported_pod","(.+)"),"namespace","$1","exported_namespace","(.+)")    *
              on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
            title:
              en: GPU Usage
              zh: GPU 使用率
            unit: '%'
          info:
            attributes:
              count: .status.allocatable.'metax-tech.com/gpu'
              memory:
                key: .metadata.labels.'metax-tech.com/gpu.memory'
              product: .metadata.labels.'metax-tech.com/gpu.product'
            source: node_yaml
          resource:
            names:
            - metax-tech.com/gpu
```

### Core

在安装 Core 时，可通过 Helm values.yaml 中的 `global.t9k.k8sResourceServer.gpuCharts.config.metax` 字段设置针对  MetaX GPU 的监控配置。启用 MetaX GPU 监控后，普通用户可以在 Job Manager 和 Service Manager 中查看到 MetaX GPU 的资源监控图表。

下面是一个配置示例，配置的字段说明请参考<a target="_blank" rel="noopener noreferrer" href="https://github.com/t9k/admin-manuals/blob/0455c009ae0d91fa7c3aced89ad4c329b2eeb308/src/others/k8s-resource-server.md#%E9%85%8D%E7%BD%AE%E6%A0%BC%E5%BC%8F">管理员文档</a>：

```yaml
global:
  t9k:
    k8sResourceServer:
      gpuCharts:
        config:
          metax:
            charts:
              memory_used:
                legend: '{{uuid}}'
                promQLFormat: avg(label_replace(label_replace(mx_memory_used{job="metax-exporter",type="vram",exported_namespace="%s",exported_pod=~"%s",exported_pod!=""},"pod","$1","exported_pod","(.+)"),"namespace","$1","exported_namespace","(.+)")    *
                  on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
                title:
                  en: GPU Memory Used
                  zh: GPU 已用显存
                unit: KB
              memory_usage:
                legend: '{{uuid}}'
                promQLFormat: avg(label_replace(label_replace(mx_memory_usage{job="metax-exporter",type="vram",exported_namespace="%s",exported_pod=~"%s",exported_pod!=""},"pod","$1","exported_pod","(.+)"),"namespace","$1","exported_namespace","(.+)")    *
                  on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
                title:
                  en: GPU Memory Usage
                  zh: GPU 显存使用率
                unit: '%'
              power:
                legend: '{{uuid}}'
                promQLFormat: avg(label_replace(label_replace(mx_board_power{job="metax-exporter",exported_namespace="%s",exported_pod=~"%s",exported_pod!=""},"pod","$1","exported_pod","(.+)"),"namespace","$1","exported_namespace","(.+)")    *
                  on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
                title:
                  en: GPU Power
                  zh: GPU 功率
                unit: mW
              chip_temperature:
                legend: '{{uuid}}'
                promQLFormat: avg(label_replace(label_replace(mx_chip_hotspot_temp{job="metax-exporter",exported_namespace="%s",exported_pod=~"%s",exported_pod!=""},"pod","$1","exported_pod","(.+)"),"namespace","$1","exported_namespace","(.+)")    *
                  on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
                title:
                  en: Chip Hotspot Temperature
                  zh: 芯片热点温度
                unit: °C
              board_temperature:
                legend: '{{uuid}}'
                promQLFormat: avg(label_replace(label_replace(mx_board_core_temp{job="metax-exporter",exported_namespace="%s",exported_pod=~"%s",exported_pod!=""},"pod","$1","exported_pod","(.+)"),"namespace","$1","exported_namespace","(.+)")    *
                  on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
                title:
                  en: Board CORE Temperature
                  zh: 主板核心温度
                unit: °C
              usage:
                legend: '{{uuid}}'
                promQLFormat: avg(label_replace(label_replace(mx_gpu_usage{job="metax-exporter",exported_namespace="%s",exported_pod=~"%s",exported_pod!=""},"pod","$1","exported_pod","(.+)"),"namespace","$1","exported_namespace","(.+)")    *
                  on(namespace,pod) group_left t9k_pod_resources_allocated) by(uuid)
                title:
                  en: GPU Usage
                  zh: GPU 使用率
                unit: '%'
            resource:
              names:
              - metax-tech.com/gpu
```

## 参考

[1] <a target="_blank" rel="noopener noreferrer" href="https://developer.metax-tech.com/doc/128">曦云系列_通用计算GPU_云原生参考手册_CN_V10</a>

[2] <a target="_blank" rel="noopener noreferrer" href="https://developer.metax-tech.com/doc/126">曦云系列_通用计算GPU_mx-exporterKubernetes集群监控部署手册_CN_V03</a> 

[3] <a target="_blank" rel="noopener noreferrer" href="https://developer.metax-tech.com/softnova/index">沐曦下载中心</a> 

[4] <a target="_blank" rel="noopener noreferrer" href="https://developer.metax-tech.com/doc/index">沐曦文档</a> 
