# 集群管理安装配置

## 目的

记录集群管理(Cluster Admin)的安装配置方案。

## 依赖关系

集群管理模块 (Helm Chart cluster-admin) 包含下列子模块：
1. Cluster Admin Web：集群管理的前端服务。
2. Cluster Admin Server：集群管理的后端服务。
3. Admission Control：实现了 K8s 的准入控制器，包括验证控制器相关组件和变更控制器。包含下列组件：
    1. 验证控制器相关组件：T9k 提供的默认 ConstraintsTemplate&Constraints、T9k Admission Provider。
    2. 变更控制器
4. Duration Keeper：负责监听集群中使用 Queue 的工作负载的运行时长，并删除/暂停超过最大运行时长限制的工作负载
5. Resource Keeper：负责监听集群中 Notebook、Tensorborad、Explorer 工作负载，当工作负载满足回收条件时，修改工作负载的 spec，将其标记为暂停。

### 必需依赖

集群管理必需依赖的项目如下，不安装这些项目，无法部署集群管理：
1. T9k Security Console
2. T9k Monitoring
3. T9k Core

### 可选依赖

在集群管理中，有一部分组件会依赖于某些“可选依赖”。即使这些“可选依赖”对应的项目未被安装，我们仍然可以部署集群管理的。但是，在部署之前，我们需要正确地设置集群管理的安装配置，并关闭那些依赖于这些未安装项目的集群管理组件。这样，我们就可以确保集群管理的正常运行，而不会受到缺少“可选依赖”所带来的影响。

可选依赖以及依赖他们的组件：
1. 集群[预安装 Gatekeeper System](../online/k8s-components/gatekeeper.md)：依赖 gatekeeper system 的集群管理组件有
    1. Admission Control —— 验证控制器相关组件
    2. Cluster Admin Web
        1. 准入控制->验证规则
2. T9k Scheduler：依赖 T9k Scheduler 的集群管理组件有
    1. Admission Control —— Policy R001 Disallow unauthorized use of queue,R002 Prohibit queue overquota, R003 Verify ResourceShape
    2. Duration keeper
    3. Cluster Admin Web
        1. 所有页面->工作负载列表->队列/PodGroup 筛选按钮
        2. 资源管理->调度
        3. 资源管理->调度->队列
        4. 资源管理->调度->资源尺寸模版
        5. 工作负载->PodGroup
3. T9k Jobs：依赖 T9k Jobs 的集群管理组件有
    1. Cluster Admin Web
        1. 总览->工作负载章节->展示 Job 数量
        2. 工作负载->作业
4. Notebooks：依赖 Notebooks 的集群管理组件有
    1. Cluster Admin Web
        1. 工作负载->Notebooks
        2. 工作负载->资源状态->Notebook
5. MLServices：依赖 Notebooks 的集群管理组件有
    1. Cluster Admin Web
        1. 工作负载->资源状态->MLService
6. Tensorboard：依赖 Tensorboards 的集群管理组件有
    1. Cluster Admin Web
        1. 工作负载->资源状态->Tensorboard
7. AutotuneExperiment：依赖 AutotuneExperiment 的集群管理组件有
    1. Cluster Admin Web
        1. 工作负载->资源状态->AutotuneExperiment
8. 集群预先安装 elasticserach：依赖 elasticserach 的集群管理组件有
    1. Cluster Admin Web
        1. 监控与报警->其他工具->Kibana
9. T9k 审计日志：依赖 T9k 审计日志的集群管理组件有
    1. Cluster Admin Web
        1. 审计日志

## Values.yaml

在安装 Helm Chart cluster-admin 时，如果系统缺少部分[可选依赖](#可选依赖)，你需要按照下面说明来配置 values.yaml。

### 参数说明

Admission Control 组件相关的参数：
1. options.admissionControl：值类型 bool。设为 false 时，系统不会安装 Admission Control
2. global.t9k.admission.validation.enabled：值类型 bool。设为 false 时，系统不会安装验证控制器相关组件。
3. global.t9k.admission.validation.t9kSchedulerPolicy.enabled：值类型 bool。设为 false 时，系统不会安装 Policy R001，R002，R003。

Duration Keeper 组件相关的参数：
1. options.durationKeeper：值类型 bool。设为 false 时，系统不会安装 Duration Keeper

控制 Cluster Admin Web 是否显示 UI 组件的参数：
1. 参数的键是 `global.t9k.clusterAdminWeb.uiComponentDisplay.<ui-component-name>`
2. 值类型是 bool，表明是否显示这个 UI 组件
3. `<ui-component-name>` 及其对应的 ui 组件如下：
    1. auditing: 审计日志
    1. overviewWorkloadT9kJobs: 总览->工作负载章节->展示 Job 数量
    2. t9kSchedulerWorkloadListFilterButton: 所有页面->工作负载列表->队列/PodGroup 筛选按钮
    3. resourceManagementT9kScheduler: 资源管理->调度
    4. resourceManagementT9kSchedulerQueue: 资源管理->调度->队列
    5. resourceManagementT9kSchedulerResourceShape: 资源管理->调度->资源尺寸模版
    6. resourceManagementResourceReclaim: 资源管理->调度->资源回收
    7. admissionValidation: 准入控制->验证规则
    8. workloadPodgroup: 工作负载->PodGroup
    9. workloadT9kJobs: 工作负载->作业
    10. workloadNotebook: 工作负载->Notebooks
    11. workloadResourceStatus: 工作负载->资源状态
    12. workloadResourceStatusNotebook: 工作负载->资源状态->Notebook
    13. workloadResourceStatusMlservice: 工作负载->资源状态->MLService
    14. workloadResourceStatusTensorboard: 工作负载->资源状态->Tensorboard
    15. workloadResourceStatusAutotuneExperiment: 工作负载->资源状态->AutotuneExperiment
    16. monitoringToolsKibana: 监控与报警->其他工具->Kibana

### 示例

当集群中未安装 T9k Scheduler 时，如果你想要安装 Helm Chart cluster-admin，values.yaml 的下列字段必须设置为 false：
```yaml
global:
 t9k:
   admission:
     validation:
       # R001,R002,R003 is policy related to t9k-scheduler
       t9kSchedulerPolicy:
         enabled: false
   clusterAdminWeb:
     uiComponentDisplay:
       t9kSchedulerWorkloadListFilterButton: false
       resourceManagementT9kScheduler: false
       resourceManagementT9kSchedulerQueue: false
       resourceManagementT9kSchedulerResourceShape: false
       workloadPodgroup: false

options:
 durationKeeper:
   enabled: false
```
