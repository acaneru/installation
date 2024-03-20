# PEP Proxy 配置

PEP Proxy 的配置由两部分组成：

* **基础配置**：PEP Proxy 作为反向代理、提供 Authentication 功能所需要的基础配置，一般通过命令行参数传入，也可以通过环境变量传入。例如，命令行参数 --foo-bar 对应的环境变量名为 PEP_PROXY_FOO_BAR。命令行参数的优先级高于环境变量。
* **PEP 配置**：PEP Proxy 作为 Policy Enforcement Point、提供 Authorization 功能所需要的配置，通过配置文件传入，并通过 --pep-config=/path/to/file.yaml 指定配置文件的路径。

当命令行参数、环境变量、PEP 配置文件发生改变时，PEP Proxy 需要重启才能使新的配置生效。

## 基础配置

PEP Proxy 基于 <a target="_blank" rel="noopener noreferrer" href="https://oauth2-proxy.github.io/oauth2-proxy/docs/">OAuth2 Proxy</a> v7.1.3 版本进行开发，支持 OAuth2 Proxy 的所有<a target="_blank" rel="noopener noreferrer" href="https://oauth2-proxy.github.io/oauth2-proxy/7.1.x/configuration/overview#command-line-options">命令行参数</a>。常用的命令行参数如下：

### --http-address

PEP Proxy 监听的地址，例如 http://0.0.0.0:4180。

### --upstream

受保护的资源服务器的地址，例如 http://127.0.0.1:8080。

### --client-id

Keycloak Client ID。

### --cookie-secret

用于加密 Cookie 的字符串，一般通过执行 `python -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(16)).decode())'` 产生。

### --oidc-issuer-url

OIDC 服务器地址，例如 Keycloak 地址 https://auth.example.t9kcloud.cn/auth/realms/t9k-realm。

### --redirect-url

用户登录成功后的跳转链接，例如 https://home.example.t9kcloud.cn/t9k/server/oauth2/callback。

### --redeem-url

在 OAuth2 授权流程中，向哪个链接发送 Authorization Code 以换取 Access Token。在平台中，为了不在容器的命令行参数中显示指定 Keycloak Client Secret、隐藏敏感信息，通过 Authorization Code 换取 Access Token 的 API 由 Security Server 代理。PEP Proxy 只需指定 Client ID，Security Server 负责添加对应的 Client Secret 并转发请求给 Keycloak。

### --security-server-address

平台 Security Server 的地址，例如 http://security-console-server.t9k-system:8080。

### --proxy-prefix

PEP Proxy 提供的服务（例如 /<prefix>/sign_in，/<prefix>/sign_out，/<prefix>/start，/<prefix>/callback）的路径前缀。默认为 "/oauth2"。

### --skip-auth-route

无需任何凭证（Cookie/Token/APIKey）即可访问的路径。

* 使用正则表达式匹配，例如 --skip-auth-route=^/apis/v1/public。
* 采用最长匹配原则，例如，如果访问 /apis/v1 需要凭证，我们可以设置 --skip-auth-route=^/apis/v1/public 使得 /apis/v1/public 无需凭证，而 /apis/v1 下的其他子路径仍然需要凭证。
* 可设置多个路径，例如，--skip-auth-route=^/apis/v1/public --skip-auth-route=^/apis/v2/public --skip-auth-route=^/apis/v3/public。

### --pass-authorization-header

如果此参数为 true，PEP Proxy 会将 Keycloak 返回的 id token 附加在请求的 Authorization Header（添加 Bearer 前缀）中转发给资源服务器。

### --pass-access-token

如果此参数为 true，PEP Proxy 会将 Keycloak 返回的 access token 附加在请求的 X-Forwarded-Access-Token Header 中转发给资源服务器。

## PEP 配置

PEP Proxy 在此基础上添加了一个命令行参数 --pep-config=/path/to/file.yaml，用于通过 YAML 文件详细配置安全访问控制策略。该 YAML 文件的示例如下：

```yaml
policyEnforcer:
  enableAPIKey: true
  securityServerAddress: http://security-console-server.t9k-system:8080
  forwardRPT: true
  enableListAuthorizationResources: true
  paths:
  - path: "/k8s-api-proxy/apis/{group}/{version}/namespaces/{namespace}"
    resourceName: "/project:{namespace}"
    methods:
    - method: "GET"
      scope: view
    - method: "POST"
      scope: edit
  - path: "/apis/v1/folders/{id}"
    resourceName: "Default Resource"
    methods:
    - method: "GET"
      scope: view
    - method: "POST"
      scope: edit
```

其中每个字段的含义如下：

### enableAPIKey

是否支持持有 API Key 作为凭证来访问资源服务器。默认为 false。

### securityServerAddress

平台 Security Server 的地址，例如 http://security-console-server.t9k-system:8080。如果同时设置了此字段和命令行参数 --security-server-address，将采用命令行参数 --security-server-address 的值。

### forwardRPT

如果此参数为 true，PEP Proxy 会将 Keycloak 返回的 RPT 附加在请求的 Authorization Header（添加 Bearer 前缀）中转发给资源服务器。默认为 false。请勿将此字段与命令行参数 --pass-authorization-header 同时使用。

<aside class="note info">
<div class="title">什么是 RPT？</div>

在 <a target="_blank" rel="noopener noreferrer" href="https://www.keycloak.org/docs/latest/authorization_services/#token-endpoint">Keycloak Authorization Services</a> 中，带有权限信息的 access token 被称作 RPT（Requesting Party Token）。Keycloak 支持 <a target="_blank" rel="noopener noreferrer" href="https://docs.kantarainitiative.org/uma/wg/rec-oauth-uma-grant-2.0.html">UMA 2.0</a> 协议，当客户端向资源服务器请求资源时，需要首先从资源服务器获取 permission ticket，并持有 permission ticket 向 Keycloak Token Endpoint 换取 RPT，然后持有 RPT 向资源服务器请求资源。

</aside>

### enableListAuthorizationResources

是否提供一个 API /authorization-resources/project，用于列举当前用户能够访问的所有 Project，默认为 false。其返回结果格式为：

```json
{"resources":["proj1", "proj2", "proj3"]}
```

### paths

用于配置哪些 URL 路径需要被保护，为数组形式，采用最长匹配原则，数组元素的字段如下：

* **path**：受保护的 URL 路径，其中可以包含格式为 {name} 的变量，例如 /k8s-api-proxy/apis/{group}/{version}/namespaces/{namespace}。
* **resourceName**：该 URL 路径对应 Keycloak 中的哪个 resource，当客户端请求该 URL 路径时，PEP Proxy 将会向 Keycloak 询问客户端是否拥有此 resource 的相应权限。resourceName 可以是一个常量字符串，例如 "Default Resource"；也可以是一个带有变量的表达式，例如 "/project:{namespace}"，表达式中可以包含格式为 {name} 的变量，该变量必须在 path 中存在，并会被替换为 path 中对应变量的实际值。
* **methods**：客户端发送的 HTTP 请求的方法（例如 GET、POST、DELETE 等）与 Keycloak 中 的 scope 的对应关系。当客户端以此方法请求该 URL 路径时，PEP Proxy 将会向 Keycloak 询问客户端是否拥有此 resoure 的对应 scope 的权限。
    * **method**：客户端发送的 HTTP 请求的方法。
        * 可填写 "*" 表示匹配任意方法。
        * 没有填写的方法将不检查权限。
    * **scope**：对应的 Keycloak resource 的 scope。

在上面的示例中，如果客户端向 /k8s-api-proxy/apis/tensorstack.dev/v1beta1/namespaces/t9k-example/notebooks/test-notebook 发送了一个 GET 请求，PEP Proxy 会向 Keycloak 询问用户是否有 /project:t9k-example 这个 resource 的 view 这个 scope 的权限。

## 常见问题

### 如果请求中既有 Bearer Token 又有 Cookie，PEP Proxy 会采用哪一个作为身份凭证？

默认情况下，如果请求中已经带有 Bearer Token，那么将跳过 Cookie 解析，直接使用 Bearer Token 作为身份凭证。

PEP Proxy 提供了命令行参数 --skip-jwt-bearer-tokens 来控制这一行为，其默认值为 true，表示不会对已经携带 Bearer Token 的请求进行 Cookie 解析。

### 如果资源服务器需要获取客户端的身份凭证，应当如何配置 PEP Proxy？

根据资源服务器所需身份凭证的种类不同，有如下几种配置方式：

* 如果资源服务器需要客户端的 id token，可设置命令行参数 [--pass-authorization-header](#pass-authorization-header) 为 true，PEP Proxy 会将 id token 附加在请求的 Authorization Header（添加 Bearer 前缀）中转发给资源服务器。
* 如果资源服务器需要客户端的 access token，可设置命令行参数 [--pass-access-token](#pass-access-token) 为 true，PEP Proxy 会将 access token 附加在请求的 X-Forwarded-Access-Token Header 中转发给资源服务器。
* 如果资源服务器需要客户端的 RPT，可在 PEP 配置文件中设置 [forwardRPT](#forwardrpt) 为 true，PEP Proxy 会将 RPT 附加在请求的 Authorization Header（添加 Bearer 前缀）中转发给资源服务器。
