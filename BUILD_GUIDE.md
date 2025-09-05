# 🚀 KustDesk Server 完整构建教程

## 📋 目录

- [构建前准备](#构建前准备)
- [本地构建](#本地构建)
- [Docker构建](#docker构建)
- [部署方式](#部署方式)
- [配置管理](#配置管理)
- [监控维护](#监控维护)
- [故障排除](#故障排除)
- [性能优化](#性能优化)

---

## 📋 构建前准备

### 系统要求

| 组件 | 最低要求 | 推荐配置 |
|------|----------|----------|
| **操作系统** | Linux 3.10+, macOS 10.14+, Windows 10+ | Ubuntu 20.04+, CentOS 8+ |
| **CPU** | 双核 2.0GHz | 四核 3.0GHz+ |
| **内存** | 2GB | 4GB+ |
| **磁盘空间** | 1GB | 5GB+ |
| **网络** | 100Mbps | 1Gbps+ |

### 必需软件

#### 1. Rust工具链
```bash
# 安装Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# 重新加载环境变量
source ~/.cargo/env

# 验证安装
rustc --version    # 需要 1.76+
cargo --version    # 需要 1.76+
rustup --version   # 需要 1.76+
```

#### 2. 系统依赖
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install -y build-essential pkg-config libssl-dev libsqlite3-dev

# CentOS/RHEL
sudo yum groupinstall -y "Development Tools"
sudo yum install -y openssl-devel sqlite-devel

# macOS
brew install openssl sqlite3 pkg-config
```

#### 3. Git和子模块
```bash
# 安装Git
sudo apt install git  # Ubuntu/Debian
sudo yum install git  # CentOS/RHEL
brew install git      # macOS

# 配置Git
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

## 🔧 本地构建

### 1. 获取源码

```bash
# 克隆主项目
git clone https://github.com/Kayungko/kustdesk-server.git
cd kustdesk-server

# 初始化子模块
git submodule update --init --recursive

# 验证源码完整性
ls -la
ls -la libs/hbb_common/
```

### 2. 构建项目

#### 开发构建
```bash
# 清理之前的构建
cargo clean

# 开发构建（包含调试信息）
cargo build

# 验证构建产物
ls -la target/debug/
```

#### 发布构建
```bash
# 发布构建（优化后的生产版本）
cargo build --release

# 验证构建产物
ls -la target/release/
```

#### 构建特定组件
```bash
# 只构建ID服务器
cargo build --release --bin hbbs

# 只构建中继服务器
cargo build --release --bin hbbr

# 只构建工具集
cargo build --release --bin rustdesk-utils

# 构建所有组件
cargo build --release --bin hbbs --bin hbbr --bin rustdesk-utils
```

### 3. 构建产物说明

构建完成后，在 `target/release/` 目录下会生成：

```
target/release/
├── hbbs              # ID服务器 (约 15-20MB)
├── hbbr              # 中继服务器 (约 15-20MB)
└── rustdesk-utils    # 工具集 (约 5-10MB)
```

### 4. 构建优化选项

#### 使用特定目标
```bash
# 构建Linux版本
cargo build --release --target x86_64-unknown-linux-musl

# 构建Windows版本
cargo build --release --target x86_64-pc-windows-msvc

# 构建macOS版本
cargo build --release --target x86_64-apple-darwin
```

#### 启用特定功能
```bash
# 启用所有功能
cargo build --release --features "all"

# 启用特定功能
cargo build --release --features "sqlite,oauth"
```

---

## 🐳 Docker构建

### 1. 准备Docker环境

```bash
# 安装Docker
curl -fsSL https://get.docker.com | sh

# 启动Docker服务
sudo systemctl start docker
sudo systemctl enable docker

# 验证安装
docker --version
docker-compose --version
```

### 2. 使用Dockerfile.simple构建

#### 基础构建
```bash
# 构建镜像
docker build -f Dockerfile.simple -t kayung1012/kustdesk-server:latest .

# 查看构建的镜像
docker images | grep kustdesk-server

# 测试镜像
docker run --rm kayung1012/kustdesk-server:latest /usr/bin/rustdesk-utils genkeypair
```

#### 多阶段构建优化
```bash
# 启用BuildKit
export DOCKER_BUILDKIT=1

# 构建并优化
docker build --build-arg BUILDKIT_INLINE_CACHE=1 \
  -f Dockerfile.simple \
  -t kayung1012/kustdesk-server:latest .
```

### 3. 使用官方Dockerfile构建

#### S6-overlay镜像
```bash
# 构建S6-overlay镜像
docker build -f docker/Dockerfile -t kayung1012/kustdesk-server-s6:latest .

# 验证S6服务
docker run --rm kayung1012/kustdesk-server-s6:latest /usr/bin/rustdesk-utils genkeypair
```

#### 普通镜像
```bash
# 构建普通镜像
docker build -f docker/Dockerfile -t kayung1012/kustdesk-server:latest .

# 测试镜像功能
docker run --rm -p 21116:21116 kayung1012/kustdesk-server:latest
```

### 4. 多平台构建

#### 启用Buildx
```bash
# 创建新的构建器
docker buildx create --name kustdesk-builder --use

# 验证构建器
docker buildx inspect --bootstrap
```

#### 构建多平台镜像
```bash
# 构建AMD64和ARM64版本
docker buildx build --platform linux/amd64,linux/arm64 \
  -f Dockerfile.simple \
  -t kayung1012/kustdesk-server:latest \
  --push .

# 构建Windows版本
docker buildx build --platform windows/amd64 \
  -f Dockerfile.simple \
  -t kayung1012/kustdesk-server:windows \
  --push .
```

### 5. 构建优化技巧

#### 使用缓存
```bash
# 使用本地缓存
docker build --build-arg BUILDKIT_INLINE_CACHE=1 \
  --cache-from kayung1012/kustdesk-server:latest \
  -f Dockerfile.simple \
  -t kayung1012/kustdesk-server:latest .
```

#### 并行构建
```bash
# 启用并行构建
docker buildx build --platform linux/amd64,linux/arm64 \
  --parallel \
  -f Dockerfile.simple \
  -t kayung1012/kustdesk-server:latest .
```

---

## 🚀 部署方式

### 方式1: 直接运行

#### 准备环境
```bash
# 创建运行目录
sudo mkdir -p /opt/kustdesk/{bin,data,logs,conf}
sudo chown -R $USER:$USER /opt/kustdesk

# 复制二进制文件
cp target/release/{hbbs,hbbr,rustdesk-utils} /opt/kustdesk/bin/
chmod +x /opt/kustdesk/bin/*
```

#### 启动服务
```bash
# 启动ID服务器
nohup /opt/kustdesk/bin/hbbs \
  -k /opt/kustdesk/data/id_ed25519 \
  -r 192.168.1.66:21117 \
  -p 21116 \
  > /opt/kustdesk/logs/hbbs.log 2>&1 &

# 启动中继服务器
nohup /opt/kustdesk/bin/hbbr \
  -k /opt/kustdesk/data/id_ed25519 \
  -r 192.168.1.66:21117 \
  -p 21117 \
  > /opt/kustdesk/logs/hbbr.log 2>&1 &
```

#### 验证服务
```bash
# 检查进程
ps aux | grep -E "(hbbs|hbbr)"

# 检查端口
netstat -tlnp | grep -E "2111[6-7]"

# 检查日志
tail -f /opt/kustdesk/logs/hbbs.log
tail -f /opt/kustdesk/logs/hbbr.log
```

### 方式2: Docker Compose部署

#### 准备配置文件
```bash
# 创建部署目录
mkdir -p kustdesk-deploy/{data,conf,logs}
cd kustdesk-deploy

# 复制docker-compose文件
cp ../Kustdesk-server/docker-compose-complete.yml .
```

#### 启动服务
```bash
# 启动所有服务
docker-compose -f docker-compose-complete.yml up -d

# 查看服务状态
docker-compose -f docker-compose-complete.yml ps

# 查看日志
docker-compose -f docker-compose-complete.yml logs -f
```

#### 管理服务
```bash
# 停止服务
docker-compose -f docker-compose-complete.yml stop

# 重启服务
docker-compose -f docker-compose-compose.yml restart

# 停止并删除服务
docker-compose -f docker-compose-complete.yml down
```

### 方式3: 系统服务部署

#### 创建systemd服务文件
```bash
# 创建服务文件
sudo tee /etc/systemd/system/kustdesk-server.service > /dev/null <<EOF
[Unit]
Description=KustDesk Server
After=network.target

[Service]
Type=simple
User=kustdesk
Group=kustdesk
WorkingDirectory=/opt/kustdesk
ExecStart=/opt/kustdesk/bin/hbbs -k /opt/kustdesk/data/id_ed25519 -r 192.168.1.66:21117
ExecStartPost=/opt/kustdesk/bin/hbbr -k /opt/kustdesk/data/id_ed25519 -r 192.168.1.66:21117
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
```

#### 配置服务
```bash
# 创建用户
sudo useradd -r -s /bin/false kustdesk

# 设置权限
sudo chown -R kustdesk:kustdesk /opt/kustdesk

# 重新加载systemd
sudo systemctl daemon-reload

# 启用服务
sudo systemctl enable kustdesk-server

# 启动服务
sudo systemctl start kustdesk-server
```

---

## 🔑 配置管理

### 1. 密钥管理

#### 生成密钥对
```bash
# 使用rustdesk-utils生成
./target/release/rustdesk-utils genkeypair

# 输出示例：
# Public Key:  R4L0TAwThleT/B1LNbvyRkURfSegkiiaNW/qOlWsUHQ=
# Secret Key:  KRuReWqZP4X9YGxV0P8U7XwOxHa9Ao3V31CsKoIdtPZHgvRMDBOGV5P8HUs1u/JGRRF9J6CSKJo1b+o6VaxQdA==
```

#### 配置密钥
```bash
# 创建密钥文件
mkdir -p /opt/kustdesk/data
echo "R4L0TAwThleT/B1LNbvyRkURfSegkiiaNW/qOlWsUHQ=" > /opt/kustdesk/data/id_ed25519.pub
echo "KRuReWqZP4X9YGxV0P8U7XwOxHa9Ao3V31CsKoIdtPZHgvRMDBOGV5P8HUs1u/JGRRF9J6CSKJo1b+o6VaxQdA==" > /opt/kustdesk/data/id_ed25519

# 设置权限
chmod 600 /opt/kustdesk/data/id_ed25519
chmod 644 /opt/kustdesk/data/id_ed25519.pub
```

### 2. 环境变量配置

#### 核心配置
```bash
# 服务器配置
export RELAY="192.168.1.66:21117"
export ENCRYPTED_ONLY="1"
export MUST_LOGIN="Y"
export TZ="Asia/Shanghai"

# API集成配置
export RUSTDESK_API_RUSTDESK_ID_SERVER="192.168.1.66:21116"
export RUSTDESK_API_RUSTDESK_RELAY_SERVER="192.168.1.66:21117"
export RUSTDESK_API_RUSTDESK_API_SERVER="http://192.168.1.66:21114"
export RUSTDESK_API_JWT_KEY="your_jwt_secret_here"
```

#### 性能配置
```bash
# 带宽限制
export LIMIT_SPEED="4Mb/s"
export TOTAL_BANDWIDTH="1024Mb/s"
export SINGLE_BANDWIDTH="16Mb/s"

# 连接配置
export DOWNGRADE_THRESHOLD="0.66"
export DOWNGRADE_START_CHECK="1800s"
```

### 3. 配置文件

#### 创建配置文件
```bash
# 创建配置目录
mkdir -p /opt/kustdesk/conf

# 创建配置文件
cat > /opt/kustdesk/conf/config.toml <<EOF
[server]
relay = "192.168.1.66:21117"
encrypted_only = true
must_login = true
timezone = "Asia/Shanghai"

[api]
id_server = "192.168.1.66:21116"
relay_server = "192.168.1.66:21117"
api_server = "http://192.168.1.66:21114"
jwt_key = "your_jwt_secret_here"

[performance]
limit_speed = "4Mb/s"
total_bandwidth = "1024Mb/s"
single_bandwidth = "16Mb/s"
downgrade_threshold = 0.66
downgrade_start_check = 1800
EOF
```

---

## 📊 监控和维护

### 1. 服务状态监控

#### 进程监控
```bash
# 检查进程状态
ps aux | grep -E "(hbbs|hbbr)" | grep -v grep

# 检查进程资源使用
top -p $(pgrep -d',' hbbs),$(pgrep -d',' hbbr)
```

#### 端口监控
```bash
# 检查端口监听状态
netstat -tlnp | grep -E "2111[5-9]"

# 使用ss命令检查
ss -tlnp | grep -E "2111[5-9]"

# 检查端口连接数
ss -s | grep 2111
```

#### 网络连接监控
```bash
# 检查网络连接
netstat -an | grep 2111 | wc -l

# 检查TCP连接状态
ss -s | grep -A 10 "TCP:"
```

### 2. 日志管理

#### 日志配置
```bash
# 设置日志级别
export RUST_LOG="info"

# 启用详细日志
export RUST_LOG="debug"

# 设置日志文件
export RUST_LOG_FILE="/opt/kustdesk/logs/rustdesk.log"
```

#### 日志轮转
```bash
# 创建logrotate配置
sudo tee /etc/logrotate.d/kustdesk-server > /dev/null <<EOF
/opt/kustdesk/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 kustdesk kustdesk
    postrotate
        systemctl reload kustdesk-server
    endscript
}
EOF
```

### 3. 性能监控

#### 系统资源监控
```bash
# 监控CPU使用率
top -p $(pgrep -d',' hbbs),$(pgrep -d',' hbbr) -b -n 1

# 监控内存使用
free -h
ps -o pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -10

# 监控磁盘I/O
iostat -x 1 5
```

#### 网络性能监控
```bash
# 监控网络流量
iftop -i eth0

# 监控网络延迟
ping -c 10 192.168.1.66

# 监控网络连接
ss -s | grep 2111
```

---

## 🔧 故障排除

### 1. 常见问题

#### 端口被占用
```bash
# 检查端口占用
sudo lsof -i :21116
sudo netstat -tlnp | grep 21116

# 查找占用进程
sudo fuser -n tcp 21116

# 释放端口
sudo kill -9 $(sudo fuser -n tcp 21116)
```

#### 权限问题
```bash
# 检查文件权限
ls -la /opt/kustdesk/
ls -la /opt/kustdesk/data/

# 修复权限
sudo chown -R kustdesk:kustdesk /opt/kustdesk/
sudo chmod 755 /opt/kustdesk/
sudo chmod 600 /opt/kustdesk/data/id_ed25519
```

#### 网络连接问题
```bash
# 检查防火墙
sudo ufw status
sudo ufw allow 21115:21119/tcp
sudo ufw allow 21116/udp

# 检查SELinux
sudo setsebool -P httpd_can_network_connect 1

# 检查网络配置
ip addr show
ip route show
```

### 2. 错误诊断

#### 查看错误日志
```bash
# 查看系统日志
sudo journalctl -u kustdesk-server -f

# 查看应用日志
tail -f /opt/kustdesk/logs/*.log

# 查看Docker日志
docker logs kustdesk-server
```

#### 调试模式运行
```bash
# 启用调试日志
export RUST_LOG="debug"

# 前台运行服务
/opt/kustdesk/bin/hbbs -k /opt/kustdesk/data/id_ed25519 -r 192.168.1.66:21117 -v
```

### 3. 性能问题

#### 高CPU使用率
```bash
# 分析CPU使用
top -p $(pgrep -d',' hbbs),$(pgrep -d',' hbbr)

# 使用perf分析
sudo perf top -p $(pgrep hbbs)

# 检查系统负载
uptime
```

#### 高内存使用率
```bash
# 检查内存使用
free -h
ps -o pid,ppid,cmd,%mem --sort=-%mem | head -10

# 检查内存泄漏
valgrind --tool=memcheck --leak-check=full ./target/debug/hbbs
```

---

## ⚡ 性能优化

### 1. 系统级优化

#### 内核参数优化
```bash
# 优化网络参数
echo 'net.core.rmem_max = 134217728' >> /etc/sysctl.conf
echo 'net.core.wmem_max = 134217728' >> /etc/sysctl.conf
echo 'net.core.rmem_default = 262144' >> /etc/sysctl.conf
echo 'net.core.wmem_default = 262144' >> /etc/sysctl.conf

# 优化TCP参数
echo 'net.ipv4.tcp_rmem = 4096 262144 134217728' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_wmem = 4096 262144 134217728' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control = bbr' >> /etc/sysctl.conf

# 应用配置
sudo sysctl -p
```

#### 文件描述符限制
```bash
# 增加文件描述符限制
echo '* soft nofile 65536' >> /etc/security/limits.conf
echo '* hard nofile 65536' >> /etc/security/limits.conf

# 临时设置
ulimit -n 65536
```

### 2. Docker优化

#### Docker配置优化
```bash
# 优化Docker daemon配置
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "default-ulimits": {
    "nofile": {
      "name": "nofile",
      "hard": 65536,
      "soft": 65536
    }
  },
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

# 重启Docker服务
sudo systemctl restart docker
```

#### 容器资源限制
```bash
# 设置资源限制
docker run -d \
  --name kustdesk-server \
  --memory=2g \
  --cpus=2 \
  --ulimit nofile=65536:65536 \
  kayung1012/kustdesk-server:latest
```

### 3. 应用级优化

#### 编译优化
```bash
# 启用LTO优化
echo '[profile.release]' >> Cargo.toml
echo 'lto = true' >> Cargo.toml
echo 'codegen-units = 1' >> Cargo.toml

# 重新构建
cargo build --release
```

#### 运行时优化
```bash
# 设置环境变量
export RUSTFLAGS="-C target-cpu=native"
export CARGO_PROFILE_RELEASE_OPT_LEVEL="3"

# 构建优化版本
cargo build --release
```

---

## 📚 相关资源

### 官方文档
- [RustDesk官方文档](https://rustdesk.com/docs/)
- [自托管指南](https://rustdesk.com/docs/zh-cn/self-host/)
- [API文档](https://github.com/Kayungko/kustdesk-server)

### 社区资源
- [GitHub Issues](https://github.com/Kayungko/kustdesk-server/issues)
- [Discord社区](https://discord.gg/nDceKgxnkV)
- [Telegram群组](https://t.me/rustdesk)

### 工具和脚本
- [一键部署脚本](./scripts/deploy.sh)
- [监控脚本](./scripts/monitor.sh)
- [备份脚本](./scripts/backup.sh)
- [性能测试脚本](./scripts/benchmark.sh)

---

## 🤝 贡献指南

### 提交Issue
1. 使用Issue模板
2. 提供详细的错误信息
3. 包含系统环境信息
4. 附上相关日志和截图

### 提交PR
1. Fork项目到你的仓库
2. 创建功能分支 (`git checkout -b feature/amazing-feature`)
3. 提交代码更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建Pull Request

### 代码规范
- 遵循Rust编码规范
- 添加适当的注释和文档
- 编写单元测试和集成测试
- 更新相关文档和README

---

## 📄 许可证

本项目基于 [AGPL-3.0](LICENSE) 许可证开源。

---

## 📞 联系我们

- **GitHub**: [https://github.com/Kayungko](https://github.com/Kayungko)
- **项目地址**: [https://github.com/Kayungko/kustdesk-server](https://github.com/Kayungko/kustdesk-server)
- **Docker Hub**: [https://hub.docker.com/r/kayung1012/kustdesk-server](https://hub.docker.com/r/kayung1012/kustdesk-server)
- **问题反馈**: [https://github.com/Kayungko/kustdesk-server/issues](https://github.com/Kayungko/kustdesk-server/issues)

---

**KustDesk Server** - 为KustDesk生态提供强大的服务器支持 🚀

---

*最后更新: 2025-09-04*
*版本: v1.0.0*
