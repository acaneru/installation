# 准入控制

T9k Admission 根据准入规则（验证规则+变更规则）对用户创建的特定资源对象进行验证、修改，以保证集群的正确性和稳定性。

T9k Admission 包含两部分：

* Validation：根据验证规则来检验用户的资源对象，拒绝非法的资源对象的创建/修改。
* Mutation：根据变更规则来对资源对象进行修改，以强制实施一些配置等。

Validation 和 Mutation 通过两种不同的方式实现：

* Validation 通过 <a target="_blank" rel="noopener noreferrer" href="https://open-policy-agent.github.io/gatekeeper/website/docs">Gatekeeper</a> 实现，验证规则配置灵活，T9k 提供了一些默认的验证规则，管理员可以按需修改 T9k 验证规则，也可以定义新的验证规则。
* Mutation 通过专门的 T9k Server 实现，提供固定的变更规则，管理员可以控制变更规则的开启/关闭、调整某些变更规则的参数。

<figure class="architecture">
  <img alt="architecture" src="../../assets/resource-management/validation-mutation.png" />
  <figcaption>图 1：TensorStack AI 平台的 admission 机制概览。1）Validation 采用 [GateKeeper](https://open-policy-agent.github.io/gatekeeper/website/)；通过 ConstraintTemplate 和 Constraint 来定义验证规则，其中 Constraint 是 ConstraintTemplate 的实例；二者通过 CRD 的机制实现；2）Mutation 通过 T9k 的独立 server 实现，其配置信息存放在 2 个 configmap 中：admission-feature, admission-arguments</figcaption>
</figure>

## Validation

Validation 的组件主要分为两部分：

* Gatekeeper system：gatekeeper 系统服务，主要包含下列组件：
    * `audit`：Audit performs periodic evaluations of existing resources against constraints, detecting pre-existing misconfigurations.
    * `controller manager`：serves the valdating webhook that Kubernetes' API server calls as part of the admission process.
* T9k Admission Provider：https server，用于向 gatekeeper 提供 <a target="_blank" rel="noopener noreferrer" href="https://open-policy-agent.github.io/gatekeeper/website/docs/externaldata">external data</a>。详情见[参考]()。

配置文件：

* CRD Provider：通知 Gatekeeper system 如何访问 T9k Provider 服务。如何配置 provider 可以参考 <a target="_blank" rel="noopener noreferrer" href="https://open-policy-agent.github.io/gatekeeper/website/docs/externaldata/#providers">Gatekeeper 文档</a>。

验证规则：通过 ConstraintTemplate 和 Constraint 来定义验证规则，详情见[验证规则](./validation.md#验证规则)。

## Mutation

在集群中运行 Mutation 的主要资源对象有：

1. Deployment admission-control：运行一个 https server，提供 mutating webhook 以响应 Kubernetes‘ API server 的调用。
1. Service admission-webhook：将 deploy admission-control 的 Pod 提供的服务暴露出来。
1. MutatingWebhookConfiguration admission.tensorstack.dev：向 Kubernetes API Server 注册 mutating webhook 服务。

配置文件：

* ConfigMap admission-features：控制 Mutation Policies 的开启/关闭。
* ConfigMap admission-arguments：设置 Mutation Policies 的详细参数。
