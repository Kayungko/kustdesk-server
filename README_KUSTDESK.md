# KustDesk Server

[![build](https://github.com/Kayungko/kustdesk-server/actions/workflows/build.yaml/badge.svg)](https://github.com/Kayungko/kustdesk-server/actions/workflows/build.yaml)

## 🚀 项目简介

KustDesk Server 是基于 RustDesk Server 的增强版本，专门为 KustDesk API 项目优化。

### ✨ 主要特性

- **API 集成优化** - 解决客户端登录API账号时的连接超时问题
- **S6 镜像支持** - 基于 S6-overlay 的稳定容器化部署
- **登录控制** - 支持 `MUST_LOGIN` 环境变量控制连接策略
- **JWT 认证** - 通过 `RUSTDESK_API_JWT_KEY` 进行 Token 合法性验证
- **WebSocket 支持** - 支持客户端 WebSocket 连接 (客户端 >= 1.4.1)

## 🐳 Docker 镜像

### S6 镜像 (推荐)
```bash
docker pull kayungko/kustdesk-server-s6:latest
```

### 普通镜像
```bash
docker pull kayungko/kustdesk-server:latest
```

## 🚀 快速部署

### Docker Compose 部署

```yaml
version: '3.8'

networks:
  rustdesk-net:
    external: false

services:
  kustdesk-server:
    image: kayungko/kustdesk-server-s6:latest
    container_name: kustdesk-server
    ports:
      - "21114:21114"  # API 服务
      - "21115:21115"  # TCP 穿透
      - "21116:21116"  # ID 服务器
      - "21116:21116/udp"  # ID 服务器 UDP
      - "21117:21117"  # 中继服务器
      - "21118:21118"  # Web 客户端
      - "21119:21119"  # Web 客户端 HTTPS
    environment:
      - RELAY=你的服务器IP:21117
      - ENCRYPTED_ONLY=1
      - MUST_LOGIN=Y  # 设置为 Y 则必须登录才能连接
      - TZ=Asia/Shanghai
      - RUSTDESK_API_RUSTDESK_ID_SERVER=你的服务器IP:21116
      - RUSTDESK_API_RUSTDESK_RELAY_SERVER=你的服务器IP:21117
      - RUSTDESK_API_RUSTDESK_API_SERVER=http://你的服务器IP:21114
      - RUSTDESK_API_KEY_FILE=/data/id_ed25519.pub
      - RUSTDESK_API_JWT_KEY=your_jwt_secret_here
    volumes:
      - ./data/rustdesk/server:/data
      - ./data/rustdesk/api:/app/data
    networks:
      - rustdesk-net
    restart: unless-stopped
```

## 🔧 环境变量配置

| 环境变量 | 说明 | 默认值 | 示例 |
|---------|------|--------|------|
| `RELAY` | 中继服务器地址 | - | `192.168.1.66:21117` |
| `ENCRYPTED_ONLY` | 仅允许加密连接 | `1` | `1` (仅加密), `0` (允许非加密) |
| `MUST_LOGIN` | 是否必须登录才能连接 | `N` | `Y` (必须登录), `N` (无需登录) |
| `TZ` | 时区设置 | - | `Asia/Shanghai` |
| `RUSTDESK_API_RUSTDESK_ID_SERVER` | ID服务器地址 | - | `192.168.1.66:21116` |
| `RUSTDESK_API_RUSTDESK_RELAY_SERVER` | 中继服务器地址 | - | `192.168.1.66:21117` |
| `RUSTDESK_API_RUSTDESK_API_SERVER` | API服务器地址 | - | `http://192.168.1.66:21114` |
| `RUSTDESK_API_KEY_FILE` | 公钥文件路径 | `/data/id_ed25519.pub` | `/data/id_ed25519.pub` |
| `RUSTDESK_API_JWT_KEY` | JWT密钥 | - | `your_jwt_secret_here` |

## 🌐 端口说明

- **21114**: API 服务端口
- **21115**: TCP 穿透端口
- **21116**: ID 服务器端口 (TCP + UDP)
- **21117**: 中继服务器端口
- **21118**: Web 客户端端口
- **21119**: Web 客户端 HTTPS 端口

## 🔑 密钥管理

### 自动生成密钥
容器启动时会自动检查密钥对，如果不存在会自动生成。

### 手动指定密钥
```bash
# 生成密钥对
docker run --rm --entrypoint /usr/bin/rustdesk-utils kayungko/kustdesk-server-s6:latest genkeypair

# 使用环境变量指定密钥
-e "KEY_PUB=your_public_key"
-e "KEY_PRIV=your_private_key"
```

## 📁 数据持久化

- **`./data/rustdesk/server`**: 服务器数据目录
- **`./data/rustdesk/api`**: API 数据目录

## 🔗 相关项目

- **KustDesk API**: [https://github.com/Kayungko/kustdesk-server](https://github.com/Kayungko/kustdesk-server)
- **KustDesk API Web**: [https://github.com/Kayungko/Kustdesk-api-web](https://github.com/Kayungko/Kustdesk-api-web)

## 📝 许可证

本项目基于 AGPL-3.0 许可证开源。

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📞 联系方式

- GitHub: [https://github.com/Kayungko](https://github.com/Kayungko)
- 项目地址: [https://github.com/Kayungko/kustdesk-server](https://github.com/Kayungko/kustdesk-server)

---

**KustDesk Server** - 为 KustDesk 生态提供强大的服务器支持 🚀
