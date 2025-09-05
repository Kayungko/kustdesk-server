# 🚀 KustDesk Server 快速开始指南

## 📋 5分钟快速部署

### 方式1: Docker Compose 一键部署 (推荐)

#### 1. 下载配置文件
```bash
# 克隆项目
git clone https://github.com/Kayungko/kustdesk-server.git
cd kustdesk-server

# 或直接下载docker-compose文件
curl -O https://raw.githubusercontent.com/Kayungko/kustdesk-server/main/docker-compose-complete.yml
```

#### 2. 启动服务
```bash
# 一键启动所有服务
docker-compose -f docker-compose-complete.yml up -d

# 查看服务状态
docker-compose -f docker-compose-complete.yml ps
```

#### 3. 获取连接信息
```bash
# 查看服务器公钥
docker exec kustdesk-server cat /data/id_ed25519.pub

# 查看服务日志
docker-compose -f docker-compose-complete.yml logs -f
```

### 方式2: 使用预构建镜像

#### 1. 拉取镜像
```bash
# 拉取最新镜像
docker pull kayung1012/kustdesk-server:latest
docker pull kayung1012/kustdesk-api:latest
```

#### 2. 运行服务
```bash
# 创建网络
docker network create kustdesk-net

# 启动API服务
docker run -d \
  --name kustdesk-api \
  --network kustdesk-net \
  -p 21114:21114 \
  -v /data/kustdesk/api:/app/data \
  kayung1012/kustdesk-api:latest

# 启动Server服务
docker run -d \
  --name kustdesk-server \
  --network kustdesk-net \
  -p 21115:21115 \
  -p 21116:21116 \
  -p 21116:21116/udp \
  -p 21117:21117 \
  -p 21118:21118 \
  -p 21119:21119 \
  -v /data/kustdesk/server:/data \
  -e RUSTDESK_API_RUSTDESK_API_SERVER=http://kustdesk-api:21114 \
  kayung1012/kustdesk-server:latest
```

---

## 🔧 本地构建快速指南

### 1. 环境准备
```bash
# 安装Rust (如果未安装)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# 安装系统依赖
sudo apt update && sudo apt install -y build-essential pkg-config libssl-dev
```

### 2. 构建项目
```bash
# 克隆项目
git clone https://github.com/Kayungko/kustdesk-server.git
cd kustdesk-server

# 初始化子模块
git submodule update --init --recursive

# 构建项目
cargo build --release
```

### 3. 运行服务
```bash
# 生成密钥
./target/release/rustdesk-utils genkeypair

# 启动ID服务器
./target/release/hbbs -k ./id_ed25519 -r 192.168.1.66:21117 &

# 启动中继服务器
./target/release/hbbr -k ./id_ed25519 -r 192.168.1.66:21117 &
```

---

## ⚙️ 基础配置

### 环境变量配置
```bash
# 创建环境配置文件
cat > .env <<EOF
# 服务器配置
RELAY=192.168.1.66:21117
ENCRYPTED_ONLY=1
MUST_LOGIN=N
TZ=Asia/Shanghai

# API集成配置
RUSTDESK_API_RUSTDESK_ID_SERVER=192.168.1.66:21116
RUSTDESK_API_RUSTDESK_RELAY_SERVER=192.168.1.66:21117
RUSTDESK_API_RUSTDESK_API_SERVER=http://192.168.1.66:21114
RUSTDESK_API_JWT_KEY=your_jwt_secret_here
EOF
```

### 端口说明
| 端口 | 服务 | 说明 |
|------|------|------|
| 21114 | API服务 | Web管理界面 |
| 21115 | 中继服务 | 中继服务器 |
| 21116 | ID服务 | ID服务器 (TCP/UDP) |
| 21117 | 中继服务 | 中继服务器 |
| 21118 | 中继服务 | 中继服务器 |
| 21119 | 中继服务 | 中继服务器 |

---

## 🔍 验证部署

### 1. 检查服务状态
```bash
# 检查Docker容器
docker ps | grep kustdesk

# 检查端口监听
netstat -tlnp | grep -E "2111[4-9]"

# 检查进程
ps aux | grep -E "(hbbs|hbbr)"
```

### 2. 测试连接
```bash
# 测试ID服务器
telnet 192.168.1.66 21116

# 测试API服务
curl http://192.168.1.66:21114/api/health

# 测试Web界面
curl http://192.168.1.66:21114
```

### 3. 查看日志
```bash
# Docker日志
docker logs kustdesk-server
docker logs kustdesk-api

# 系统日志
sudo journalctl -u kustdesk-server -f
```

---

## 🎯 客户端配置

### 1. 获取服务器信息
```bash
# 获取公钥
cat /data/kustdesk/server/id_ed25519.pub

# 获取服务器地址
echo "ID服务器: 192.168.1.66:21116"
echo "中继服务器: 192.168.1.66:21117"
```

### 2. 客户端设置
1. 打开RustDesk客户端
2. 点击"设置" → "网络"
3. 输入ID服务器地址: `192.168.1.66:21116`
4. 输入中继服务器地址: `192.168.1.66:21117`
5. 输入公钥: `R4L0TAwThleT/B1LNbvyRkURfSegkiiaNW/qOlWsUHQ=`
6. 点击"应用"

---

## 🚨 常见问题

### 问题1: 端口被占用
```bash
# 检查端口占用
sudo lsof -i :21116

# 释放端口
sudo kill -9 <PID>
```

### 问题2: 权限问题
```bash
# 修复权限
sudo chown -R 1000:1000 /data/kustdesk/
sudo chmod 755 /data/kustdesk/
```

### 问题3: 网络连接问题
```bash
# 检查防火墙
sudo ufw allow 21115:21119/tcp
sudo ufw allow 21116/udp

# 检查网络
ping 192.168.1.66
```

---

## 📚 下一步

### 完整配置
- 查看 [完整构建教程](BUILD_GUIDE.md)
- 阅读 [详细文档](README.md)

### 高级功能
- 配置SSL证书
- 设置用户认证
- 配置API集成
- 性能优化

### 监控维护
- 设置日志轮转
- 配置监控告警
- 定期备份数据

---

## 🆘 获取帮助

- **GitHub Issues**: [https://github.com/Kayungko/kustdesk-server/issues](https://github.com/Kayungko/kustdesk-server/issues)
- **文档**: [https://github.com/Kayungko/kustdesk-server](https://github.com/Kayungko/kustdesk-server)
- **Docker Hub**: [https://hub.docker.com/r/kayung1012/kustdesk-server](https://hub.docker.com/r/kayung1012/kustdesk-server)

---

**🎉 恭喜！你已经成功部署了KustDesk Server！**

现在你可以使用RustDesk客户端连接到你的私有服务器了。
