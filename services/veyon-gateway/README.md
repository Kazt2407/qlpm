# QLPM Veyon Gateway

Gateway trung gian giữa Rails app và Veyon WebAPI.

Trong monorepo demo, service này chạy qua Docker Compose từ thư mục gốc:

```bash
ruby bin/demo
```

Kiểm tra health:

```bash
curl http://localhost:8088/v1/health
```

## Biến môi trường

- `GATEWAY_PORT` (default: `8088`)
- `GATEWAY_API_KEY` (bắt buộc, Rails gửi qua header `X-API-Key`)
- `VEYON_WEBAPI_BASE_URL` (default: `http://host.docker.internal:11080`): endpoint của Veyon WebAPI Proxy, không phải port Veyon Service trên từng Windows client.
- `VEYON_DEFAULT_AUTH_METHOD` (default: `auth_logon`)
- `VEYON_AUTH_USERNAME`, `VEYON_AUTH_PASSWORD` (cho `auth_logon`/`auth_ldap`)
- `VEYON_AUTH_SIMPLE_PASSWORD` (cho `auth_simple`)
- `VEYON_AUTH_KEYNAME`, `VEYON_AUTH_KEYDATA` hoặc `VEYON_AUTH_KEYDATA_FILE` (cho `auth_keys`)
- `VEYON_WEBAPI_INSECURE_SKIP_TLS_VERIFY` (`true/false`, default `false`)
- `GATEWAY_REQUEST_TIMEOUT_MS` (default: `15000`)
- `GATEWAY_CLEANUP_INTERVAL_MS` (default: `30000`)
- `GATEWAY_REUSE_SKEW_MS` (default: `5000`)

### `auth_keys` báº±ng file

Äáº·t file key á»Ÿ host, mount vÃ o container dÆ°á»›i dáº¡ng read-only, sau Ä‘Ã³ trá» `VEYON_AUTH_KEYDATA_FILE` tá»›i Ä‘Æ°á»ng dáº«n bÃªn trong container:

```yaml
veyon-gateway:
  volumes:
    - ./secrets/veyon-auth-key.pem:/run/secrets/veyon-auth-key.pem:ro
```

```env
VEYON_DEFAULT_AUTH_METHOD=auth_keys
VEYON_AUTH_KEYNAME=your-key-name
VEYON_AUTH_KEYDATA_FILE=/run/secrets/veyon-auth-key.pem
```

Náº¿u khÃ´ng dÃ¹ng file, cÃ³ thá»ƒ Ä‘áº·t ná»™i dung key trá»±c tiáº¿p trong `VEYON_AUTH_KEYDATA`.

## Endpoint

- `GET /v1/health`
- `POST /v1/connections/open`
- `DELETE /v1/connections/:connection_uid`
- `GET /v1/hosts/:host/framebuffer`
- `POST /v1/hosts/:host/features/:feature_key`
- `GET /v1/hosts/:host/user`
- `GET /v1/hosts/:host/session`

`GET /v1/health` không cần `X-API-Key`; các endpoint còn lại yêu cầu header này.

## Phân biệt port

- WebAPI Proxy: thường là `11080`, cấu hình bằng `VEYON_WEBAPI_BASE_URL`.
- Windows client Veyon Service: thường là `11100`, lưu trong QLPM host mapping dưới trường `service_port`.
