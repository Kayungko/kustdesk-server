#!/bin/bash

# KustDesk Server 一键部署脚本
# 作者: Kayungko
# 版本: v1.0.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        log_error "$1 命令未找到，请先安装 $1"
        exit 1
    fi
}

# 检查Docker是否运行
check_docker() {
    if ! docker info &> /dev/null; then
        log_error "Docker 未运行，请先启动 Docker"
        exit 1
    fi
}

# 创建目录结构
create_directories() {
    log_info "创建目录结构..."
    
    sudo mkdir -p /data/kustdesk/{server,api,logs}
    sudo chown -R $USER:$USER /data/kustdesk
    
    log_success "目录创建完成"
}

# 拉取镜像
pull_images() {
    log_info "拉取 Docker 镜像..."
    
    docker pull kayung1012/kustdesk-server:latest
    docker pull kayung1012/kustdesk-api:latest
    
    log_success "镜像拉取完成"
}

# 创建网络
create_network() {
    log_info "创建 Docker 网络..."
    
    if ! docker network ls | grep -q kustdesk-net; then
        docker network create kustdesk-net
        log_success "网络创建完成"
    else
        log_warning "网络已存在"
    fi
}

# 启动API服务
start_api() {
    log_info "启动 API 服务..."
    
    if docker ps -a | grep -q kustdesk-api; then
        log_warning "API 服务已存在，正在停止..."
        docker stop kustdesk-api
        docker rm kustdesk-api
    fi
    
    docker run -d \
        --name kustdesk-api \
        --network kustdesk-net \
        -p 21114:21114 \
        -v /data/kustdesk/api:/app/data \
        -e TZ=Asia/Shanghai \
        --restart unless-stopped \
        kayung1012/kustdesk-api:latest
    
    log_success "API 服务启动完成"
}

# 启动Server服务
start_server() {
    log_info "启动 Server 服务..."
    
    if docker ps -a | grep -q kustdesk-server; then
        log_warning "Server 服务已存在，正在停止..."
        docker stop kustdesk-server
        docker rm kustdesk-server
    fi
    
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
        -e TZ=Asia/Shanghai \
        -e RUSTDESK_API_RUSTDESK_API_SERVER=http://kustdesk-api:21114 \
        --restart unless-stopped \
        kayung1012/kustdesk-server:latest
    
    log_success "Server 服务启动完成"
}

# 等待服务启动
wait_for_services() {
    log_info "等待服务启动..."
    
    sleep 10
    
    # 检查API服务
    if docker exec kustdesk-api curl -f http://localhost:21114/api/health &> /dev/null; then
        log_success "API 服务健康检查通过"
    else
        log_warning "API 服务健康检查失败，请检查日志"
    fi
    
    # 检查Server服务
    if docker exec kustdesk-server /usr/bin/rustdesk-utils genkeypair &> /dev/null; then
        log_success "Server 服务健康检查通过"
    else
        log_warning "Server 服务健康检查失败，请检查日志"
    fi
}

# 显示部署信息
show_info() {
    log_info "获取部署信息..."
    
    # 获取公钥
    PUBLIC_KEY=$(docker exec kustdesk-server cat /data/id_ed25519.pub 2>/dev/null || echo "未找到公钥")
    
    # 获取服务器IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo ""
    echo "=========================================="
    echo "🎉 KustDesk Server 部署完成！"
    echo "=========================================="
    echo ""
    echo "📋 连接信息："
    echo "  ID服务器: ${SERVER_IP}:21116"
    echo "  中继服务器: ${SERVER_IP}:21117"
    echo "  Web管理界面: http://${SERVER_IP}:21114"
    echo ""
    echo "🔑 公钥:"
    echo "  ${PUBLIC_KEY}"
    echo ""
    echo "📊 服务状态："
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep kustdesk
    echo ""
    echo "📝 常用命令："
    echo "  查看日志: docker logs kustdesk-server"
    echo "  重启服务: docker restart kustdesk-server"
    echo "  停止服务: docker stop kustdesk-server"
    echo ""
    echo "=========================================="
}

# 主函数
main() {
    echo "🚀 KustDesk Server 一键部署脚本"
    echo "=================================="
    echo ""
    
    # 检查依赖
    log_info "检查系统依赖..."
    check_command docker
    check_command docker-compose
    check_docker
    
    # 执行部署步骤
    create_directories
    pull_images
    create_network
    start_api
    start_server
    wait_for_services
    show_info
    
    log_success "部署完成！"
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
