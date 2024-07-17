# Helm Chart 修改

## Elastic Search

获取 elastic search 官方的 helm chart：

```bash
$ helm repo add elastic https://helm.elastic.co
$ helm pull elastic/elasticsearch --version 7.13.4
$ tar zxvf elasticsearch-7.13.4.tgz
```

进行以下修改：

```bash
$ git diff elasticsearch/templates/poddisruptionbudget.yaml
  diff --git a/skj/elasticsearch/templates/poddisruptionbudget.yaml 
b/skj/elasticsearch/templates/poddisruptionbudget.yaml
  index df6c74e..7f887da 100644
  --- a/skj/elasticsearch/templates/poddisruptionbudget.yaml
  +++ b/skj/elasticsearch/templates/poddisruptionbudget.yaml
  @@ -1,6 +1,6 @@
   ---
   {{- if .Values.maxUnavailable }}
  -apiVersion: policy/v1beta1
  +apiVersion: policy/v1
   kind: PodDisruptionBudget
   metadata:
     name: "{{ template "elasticsearch.uname" . }}-pdb"


$ git diff elasticsearch/values.yaml
  diff --git a/skj/elasticsearch/values.yaml b/skj/elasticsearch/values.yaml
  index 82b82b9..561a403 100644
  --- a/skj/elasticsearch/values.yaml
  +++ b/skj/elasticsearch/values.yaml
  @@ -58,7 +58,7 @@ hostAliases: []
   #  - "foo.local"
   #  - "bar.local"
   
  -image: "docker.elastic.co/elasticsearch/elasticsearch"
  +image: "docker.io/t9kpublic/elasticsearch"
   imageTag: "7.13.4"
   imagePullPolicy: "IfNotPresent"
```

打包上传：

```bash
$ rm elasticsearch-7.13.4.tgz
$ helm package elasticsearch
$ helm push ./elasticsearch-7.13.4.tgz oci://tsz.io/t9kcharts
```

## GPU Operator

下载并解压 Helm Chart:

```bash
# 添加 nvidia helm repo
helm repo add nvidia https://helm.ngc.nvidia.com/nvidia \
   && helm repo update
$ helm pull --untar nvidia/gpu-operator --version v22.9.2
$ ls gpu-operator
gpu-operator
```

将其中的几个 repository 地址全部换成 t9kpublic，具体操作如下：

```bash
sed -i "s|repository: nvcr.io/nvidia/cloud-native|repository: t9kpublic|g" \
    gpu-operator/values.yaml
sed -i "s|repository: nvcr.io/nvidia/k8s|repository: t9kpublic|g" \
    gpu-operator/values.yaml
sed -i "s|repository: nvcr.io/nvidia|repository: t9kpublic|g" \
    gpu-operator/values.yaml
```

完整的对比如下：

```bash
$ diff -u ./gpu-operator-22/values.yaml ./gpu-operator/values.yaml
--- ./gpu-operator-22/values.yaml	2024-01-30 14:24:59.000000000 +0800
+++ ./gpu-operator/values.yaml	2024-01-30 14:25:43.000000000 +0800
@@ -33,7 +33,7 @@
     maxUnavailable: "1"
 
 validator:
-  repository: nvcr.io/nvidia/cloud-native
+  repository: t9kpublic
   image: gpu-operator-validator
   # If version is not specified, then default is to use chart.AppVersion
   #version: ""
@@ -48,7 +48,7 @@
         value: "true"
 
 operator:
-  repository: nvcr.io/nvidia
+  repository: t9kpublic
   image: gpu-operator
   # If version is not specified, then default is to use chart.AppVersion
   #version: ""
@@ -65,7 +65,7 @@
   upgradeCRD: false
   initContainer:
     image: cuda
-    repository: nvcr.io/nvidia
+    repository: t9kpublic
     version: 11.8.0-base-ubi8
     imagePullPolicy: IfNotPresent
   tolerations:
@@ -105,7 +105,7 @@
 
 driver:
   enabled: true
-  repository: nvcr.io/nvidia
+  repository: t9kpublic
   image: driver
   version: "525.60.13"
   imagePullPolicy: IfNotPresent
@@ -141,7 +141,7 @@
       deleteEmptyDir: false
   manager:
     image: k8s-driver-manager
-    repository: nvcr.io/nvidia/cloud-native
+    repository: t9kpublic
     version: v0.6.0
     imagePullPolicy: IfNotPresent
     env:
@@ -178,7 +178,7 @@
 
 toolkit:
   enabled: true
-  repository: nvcr.io/nvidia/k8s
+  repository: t9kpublic
   image: container-toolkit
   version: v1.11.0-ubuntu20.04
   imagePullPolicy: IfNotPresent
@@ -189,7 +189,7 @@
 
 devicePlugin:
   enabled: true
-  repository: nvcr.io/nvidia
+  repository: t9kpublic
   image: k8s-device-plugin
   version: v0.13.0-ubi8
   imagePullPolicy: IfNotPresent
@@ -243,7 +243,7 @@
 dcgm:
   # disabled by default to use embedded nv-hostengine by exporter
   enabled: false
-  repository: nvcr.io/nvidia/cloud-native
+  repository: t9kpublic
   image: dcgm
   version: 3.1.3-1-ubuntu20.04
   imagePullPolicy: IfNotPresent
@@ -254,7 +254,7 @@
 
 dcgmExporter:
   enabled: true
-  repository: nvcr.io/nvidia/k8s
+  repository: t9kpublic
   image: dcgm-exporter
   version: 3.1.3-3.1.2-ubuntu20.04
   imagePullPolicy: IfNotPresent
@@ -274,7 +274,7 @@
 
 gfd:
   enabled: true
-  repository: nvcr.io/nvidia
+  repository: t9kpublic
   image: gpu-feature-discovery
   version: v0.7.0-ubi8
   imagePullPolicy: IfNotPresent
@@ -288,7 +288,7 @@
 
 migManager:
   enabled: true
-  repository: nvcr.io/nvidia/cloud-native
+  repository: t9kpublic
   image: k8s-mig-manager
   version: v0.5.0-ubuntu20.04
   imagePullPolicy: IfNotPresent
@@ -304,7 +304,7 @@
 
 nodeStatusExporter:
   enabled: false
-  repository: nvcr.io/nvidia/cloud-native
+  repository: t9kpublic
   image: gpu-operator-validator
   # If version is not specified, then default is to use chart.AppVersion
   #version: ""
@@ -314,7 +314,7 @@
 
 gds:
   enabled: false
-  repository: nvcr.io/nvidia/cloud-native
+  repository: t9kpublic
   image: nvidia-fs
   version: "2.14.13"
   imagePullPolicy: IfNotPresent
@@ -333,7 +333,7 @@
   resources: {}
   driverManager:
     image: k8s-driver-manager
-    repository: nvcr.io/nvidia/cloud-native
+    repository: t9kpublic
     version: v0.6.0
     imagePullPolicy: IfNotPresent
     env:
@@ -344,7 +344,7 @@
 
 vgpuDeviceManager:
   enabled: true
-  repository: nvcr.io/nvidia/cloud-native
+  repository: t9kpublic
   image: vgpu-device-manager
   version: "v0.2.0"
   imagePullPolicy: IfNotPresent
@@ -356,7 +356,7 @@
 
 vfioManager:
   enabled: true
-  repository: nvcr.io/nvidia
+  repository: t9kpublic
   image: cuda
   version: 11.7.1-base-ubi8
   imagePullPolicy: IfNotPresent
@@ -365,7 +365,7 @@
   resources: {}
   driverManager:
     image: k8s-driver-manager
-    repository: nvcr.io/nvidia/cloud-native
+    repository: t9kpublic
     version: v0.6.0
     imagePullPolicy: IfNotPresent
     env:
@@ -376,7 +376,7 @@
 
 sandboxDevicePlugin:
   enabled: true
-  repository: nvcr.io/nvidia
+  repository: t9kpublic
   image: kubevirt-gpu-device-plugin
   version: v1.2.1
   imagePullPolicy: IfNotPresent
```

重新打包，然后上传：

```bash
$ rm -f gpu-operator-v22.9.2.tgz
$ helm package gpu-operator
$ helm push gpu-operator-v22.9.2.tgz oci://tsz.io/t9kcharts
```

验证：

```bash
$ helm show chart oci://tsz.io/t9kcharts/gpu-operator --version v22.9.2
```
