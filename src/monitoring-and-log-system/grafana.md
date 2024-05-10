# Grafana

Grafana 对监控数据进行可视化展示，方便用户了解集群状态。

## 部署设置

运行下列命令可以查看部署的 Grafana 详情：

```bash
kubectl -n t9k-monitoring get deploy grafana -o yaml
```

## Dashboard

### 查看 Dashboard

Dashboard 列表：`https://<host>/t9k-monitoring/grafana/dashboards`

选择一个 Dashboard 点击，就可以查看这个 Dashboard 的详情。

### 增加 Dashboard

在 Grafana 中增加 Dashboard 有两种方法。

#### 通过 UI 

通过 UI 创建新的 Dashboard。在 Grafana 的 Web UI 可以找到创建 Dashboard 的按钮，点击就可以创建新的 Dashboard，详细内容请参考 <a target="_blank" rel="noopener noreferrer" href="https://grafana.com/docs/grafana/latest/dashboards/">Grafana 文档</a>。

需要注意，按照上述方式创建的 Dashboard 无法被持久性存储，Grafana Pod 重启后，这些 Dashboard 会消失。

#### 通过 ConfigMap

使用 ConfigMap 存储 dashboard，然后修改 Deployment grafana 的配置，可以在 Grafana 中增加持久性存储的 dashboard。

下面是操作示例：

1) 首先运行下列命令创建 ConfigMap grafana-dashboard-demo，data[custom.json] 字段下存储着 dashboard json 文件：

    ```bash
    kubectl create -f - << EOF
    apiVersion: v1
    data:
    demo.json: |-
        {
            ...
            <Dashboard-Json>
            ... 
        }
    kind: ConfigMap
    metadata:
    name: grafana-dashboard-demo
    namespace: t9k-monitoring
    EOF
    ```

2) 修改 Grafana dashboards 目录配置：

    ```bash
    kubectl -n t9k-monitoring edit cm grafana-dashboards
    ```

    增加下列绿底内容，表明在 dashboards 目录中新增自定义文件夹 custom：

    <details><summary><code class="hljs">grafana-dashboards.yaml</code></summary>

    <pre><code class="language-bash hljs">apiVersion: v1
    data:
    dashboards.yaml: |-
        {
            <span class="hljs-string">"apiVersion"</span>: 1,
            <span class="hljs-string">"providers"</span>: [
    <span style="background-color: #D6E8D3">            {
                    <span class="hljs-string">"folder"</span>: <span class="hljs-string">"Default"</span>,
                    <span class="hljs-string">"folderUid"</span>: <span class="hljs-string">""</span>,
                    <span class="hljs-string">"name"</span>: <span class="hljs-string">"0"</span>,
                    <span class="hljs-string">"options"</span>: {
                        <span class="hljs-string">"path"</span>: <span class="hljs-string">"/grafana-dashboard-definitions/0"</span>
                    },
                    <span class="hljs-string">"orgId"</span>: 1,
                    <span class="hljs-string">"type"</span>: <span class="hljs-string">"file"</span>
                },</span>
                {
                    <span class="hljs-string">"folder"</span>: <span class="hljs-string">"T9k"</span>,
                    <span class="hljs-string">"folderUid"</span>: <span class="hljs-string">""</span>,
                    <span class="hljs-string">"name"</span>: <span class="hljs-string">"T9k"</span>,
                    <span class="hljs-string">"options"</span>: {
                        <span class="hljs-string">"path"</span>: <span class="hljs-string">"/grafana-dashboard-definitions/T9k"</span>
                    },
                    <span class="hljs-string">"orgId"</span>: 1,
                    <span class="hljs-string">"type"</span>: <span class="hljs-string">"file"</span>
                },
                {
                    <span class="hljs-string">"folder"</span>: <span class="hljs-string">"Custom"</span>,
                    <span class="hljs-string">"folderUid"</span>: <span class="hljs-string">""</span>,
                    <span class="hljs-string">"name"</span>: <span class="hljs-string">"custom"</span>,
                    <span class="hljs-string">"options"</span>: {
                        <span class="hljs-string">"path"</span>: <span class="hljs-string">"/grafana-dashboard-definitions/custom"</span>
                    },
                    <span class="hljs-string">"orgId"</span>: 1,
                    <span class="hljs-string">"type"</span>: <span class="hljs-string">"file"</span>
                }
            ]
        }
    kind: ConfigMap
    metadata:
    name: grafana-dashboards
    namespace: t9k-monitoring
    </code></pre>

    </details>

3) 修改 deployment grafana：

    ```bash
    kubectl -n t9k-monitoring edit deploy grafana
    ```

    在 volumes 中增加下列字段：

    ```yaml
        - configMap:
            defaultMode: 420
            name: grafana-dashboard-demo
            name: grafana-dashboard-demo
    ```

    在 container grafana 的 volumeMounts 中增加下列字段：

    ```yaml
            - mountPath: /grafana-dashboard-definitions/custom/demo
            name: grafana-dashboard-demo
    ```

完成后，Grafana Pod 会被重新运行，然后可以在 Grafana Dashboard 列表看见一个新增的文件夹 Custom。这个文件夹下有 ConfigMap grafana-dashboard-demo 中定义的 Dashboards。

## 参考

<https://grafana.com/>

