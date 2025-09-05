# 🛠️ KustDesk Server 脚本工具集

本目录包含了KustDesk Server的自动化部署、监控、备份和性能测试脚本。

## 📋 脚本列表

### 1. 部署脚本 (`deploy.sh`)
一键部署KustDesk Server和API服务。

**功能特性：**
- 自动检查系统依赖
- 拉取最新Docker镜像
- 创建必要的目录和网络
- 启动所有服务
- 健康检查验证
- 显示连接信息

**使用方法：**
```bash
# 一键部署
./scripts/deploy.sh

# 查看帮助
./scripts/deploy.sh --help
```

### 2. 监控脚本 (`monitor.sh`)
实时监控KustDesk Server的运行状态。

**功能特性：**
- 检查服务状态
- 监控端口监听
- 检查网络连接
- 监控资源使用
- 查看日志信息
- 健康状态检查
- 实时监控模式
- 生成监控报告

**使用方法：**
```bash
# 执行所有检查
./scripts/monitor.sh --all

# 实时监控
./scripts/monitor.sh --monitor

# 生成监控报告
./scripts/monitor.sh --report

# 查看帮助
./scripts/monitor.sh --help
```

### 3. 备份脚本 (`backup.sh`)
自动备份KustDesk Server的数据和配置。

**功能特性：**
- 备份数据目录
- 备份Docker配置
- 备份系统配置
- 自动清理旧备份
- 支持备份恢复
- 可配置保留天数

**使用方法：**
```bash
# 执行完整备份
./scripts/backup.sh --backup

# 仅备份数据
./scripts/backup.sh --data

# 列出备份文件
./scripts/backup.sh --list

# 恢复备份
./scripts/backup.sh --restore /path/to/backup.tar.gz

# 查看帮助
./scripts/backup.sh --help
```

### 4. 性能测试脚本 (`benchmark.sh`)
测试KustDesk Server的性能和稳定性。

**功能特性：**
- 端口连通性测试
- API响应时间测试
- 网络延迟测试
- 带宽测试
- 并发连接测试
- 压力测试
- 系统资源监控
- 生成性能报告

**使用方法：**
```bash
# 执行所有测试
./scripts/benchmark.sh --all

# 压力测试
./scripts/benchmark.sh --stress

# 测试指定服务器
./scripts/benchmark.sh --server 192.168.1.100

# 查看帮助
./scripts/benchmark.sh --help
```

## 🚀 快速开始

### 1. 部署服务
```bash
# 一键部署
./scripts/deploy.sh
```

### 2. 监控服务
```bash
# 检查服务状态
./scripts/monitor.sh --all

# 实时监控
./scripts/monitor.sh --monitor
```

### 3. 备份数据
```bash
# 执行备份
./scripts/backup.sh --backup
```

### 4. 性能测试
```bash
# 执行性能测试
./scripts/benchmark.sh --all
```

## ⚙️ 配置说明

### 环境变量
所有脚本都支持通过环境变量进行配置：

```bash
# 服务器配置
export KUSTDESK_SERVER="192.168.1.100"
export KUSTDESK_API_PORT="21114"
export KUSTDESK_SERVER_PORT="21116"

# 备份配置
export BACKUP_DIR="/data/kustdesk/backups"
export RETENTION_DAYS="7"

# 测试配置
export TEST_DURATION="60"
export CONCURRENT_CONNECTIONS="10"
```

### 配置文件
脚本会自动读取以下配置文件（如果存在）：
- `/etc/kustdesk/config.conf`
- `~/.kustdesk/config.conf`
- `./config.conf`

## 📊 监控指标

### 服务状态
- 容器运行状态
- 端口监听状态
- 网络连接状态
- 健康检查状态

### 资源使用
- CPU使用率
- 内存使用量
- 磁盘使用量
- 网络I/O

### 性能指标
- 响应时间
- 并发连接数
- 网络延迟
- 带宽使用

## 🔧 故障排除

### 常见问题

#### 1. 权限问题
```bash
# 设置脚本执行权限
chmod +x scripts/*.sh

# 检查文件权限
ls -la scripts/
```

#### 2. 依赖缺失
```bash
# 安装必要依赖
sudo apt update
sudo apt install -y curl netcat-openbsd bc

# 检查Docker
docker --version
docker-compose --version
```

#### 3. 网络问题
```bash
# 检查网络连接
ping 192.168.1.100

# 检查端口
netstat -tlnp | grep 2111
```

### 日志查看
```bash
# 查看脚本日志
tail -f /var/log/kustdesk-scripts.log

# 查看Docker日志
docker logs kustdesk-server
docker logs kustdesk-api
```

## 📚 高级用法

### 定时任务
```bash
# 添加到crontab
crontab -e

# 每天凌晨2点执行备份
0 2 * * * /path/to/scripts/backup.sh --backup

# 每5分钟检查服务状态
*/5 * * * * /path/to/scripts/monitor.sh --all
```

### 自动化部署
```bash
# 创建部署脚本
cat > auto-deploy.sh << 'EOF'
#!/bin/bash
set -e

# 拉取最新代码
git pull origin main

# 重新部署
./scripts/deploy.sh

# 执行健康检查
./scripts/monitor.sh --all
EOF

chmod +x auto-deploy.sh
```

### 监控告警
```bash
# 创建告警脚本
cat > alert.sh << 'EOF'
#!/bin/bash
# 检查服务状态
if ! ./scripts/monitor.sh --health; then
    # 发送告警邮件
    echo "KustDesk Server 服务异常" | mail -s "服务告警" admin@example.com
fi
EOF

chmod +x alert.sh
```

## 🤝 贡献指南

### 添加新脚本
1. 在 `scripts/` 目录下创建新脚本
2. 添加适当的错误处理和日志输出
3. 更新本README文档
4. 设置执行权限

### 脚本规范
- 使用bash shebang: `#!/bin/bash`
- 设置错误退出: `set -e`
- 添加颜色输出和日志函数
- 提供帮助信息
- 支持命令行参数

## 📄 许可证

本脚本工具集基于 [MIT License](../LICENSE) 许可证开源。

## 📞 支持

- **GitHub Issues**: [https://github.com/Kayungko/kustdesk-server/issues](https://github.com/Kayungko/kustdesk-server/issues)
- **文档**: [https://github.com/Kayungko/kustdesk-server](https://github.com/Kayungko/kustdesk-server)

---

**🛠️ KustDesk Server 脚本工具集** - 让部署和管理更简单！
