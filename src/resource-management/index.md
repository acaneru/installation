# 资源管理

TensorStack AI 平台通过多种机制联合工作来实现对集群资源和工作负载的的自动化管理，包括：

1. Admission Control：在准入阶段实施各种管理策略。
1. Scheduler：向各种工作负载分配资源。
1. Resource Keeper：自动化回收闲置资源。
1. Project Resource Quota: 自动化设置项目的资源配额。
1. [WIP] Elastic Control：负责自动调整一些工作负载的计算规模。

在本文档中，下列资源对象属于工作负载：

```yaml
- apiGroups: ["*"]
  kinds: ["Pod"]
- apiGroups: ["batch.tensorstack.dev"]
  kinds: ["BeamJob","ColossalAIJob","DeepSpeedJob","GenericJob","MPIJob","PyTorchTrainingJob","TensorFlowTrainingJob","XGBoostTrainingJob"]
- apiGroups: ["tensorstack.dev"]
  kinds: ["AutoTuneExperiment","MLService","Notebook","SimpleMLService"]
```
