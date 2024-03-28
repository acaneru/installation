# 数据备份

管理员可以通过以下几种方式对 TensorStack AI 平台进行备份：

1. 使用 <a target="_blank" rel="noopener noreferrer" href="https://velero.io/docs/v1.12/">velero</a> 对集群中的所有资源 yaml 和 pvc 数据进行备份
1. 使用 etcd 提供的命令行工具对 k8s apiserver 的 etcd 数据库进行备份
1. 使用 PostgreSQL 提供的命令行工具对 T9k 平台中几个重要的 PostgreSQL 数据库进行备份

<aside class="note">
<div class="title">注意</div>

* 在对 T9k 平台进行重大更新时，第 1 种方式总是应当采用
* 在对 security console、AIStore、cost server 进行更新时，应当在第 1 种方式的基础上，进一步采用第 3 种方式

</aside>
