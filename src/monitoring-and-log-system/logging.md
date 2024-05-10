# 日志系统

```
TODO:
    1. 使用非 tsz.io OCI registry;
    2. 把 "查看集群中的分片情况" 的截图改成文本；
```


日志系统负责收集集群中的各种日志，包括 T9k 系统服务、集群服务及工作负载的输出、集群事件等，并提供查询服务。

系统由以下四个组件构成：

* [ElasticSearch](./es.md)：负责存储数据，并提供查询服务；
* [Fluentd](./fluentd.md)：数据收集器，负责收集日志并发送给 ElasticSearch；
* [Event Router](./event-router.md)：收集集群事件，并将事件以日志形式打印出来，方便日志系统收集；
* [Event Controller](../user-and-security-management/event-controller.md)：负责监控各 Project 中的资源，生成相应事件 [1]。

> [1] Event Controller 的配置/管理在 [项目管理 > 事件控制器](../user-and-security-management/event-controller.md) 中提供。
