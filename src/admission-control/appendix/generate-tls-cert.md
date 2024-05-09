# 手动生成 TLS 证书

使用 openssl 生成 tls 证书 tls.key 和 tls.crt：

```bash
# Generate a private key for your CA:
openssl genrsa -out ca.key 2048
# Generate a self-signed certificate for your CA:
openssl req -new -x509 -days 3650 -key ca.key \
  -subj "/O=My Org/CN=External Data Provider CA" -out ca.crt

# Generate a private key for your external data provider:
openssl genrsa -out tls.key 2048

# Generate a certificate signing request (CSR) for your external data provider:
openssl req -newkey rsa:2048 -nodes -keyout tls.key \
  -subj "/CN=t9k-admission-provider.t9k-system " -out server.csr

# Generate a certificate for your external data provider:
openssl x509 -req \
  -extfile <(printf "subjectAltName=DNS:t9k-admission-provider.t9k-system ") \
  -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out tls.crt
```
