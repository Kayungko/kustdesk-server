#!/bin/bash

# KustDesk Server 监控脚本
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

# 检查服务状态
check_services() {
    log_info "检查服务状态..."
    
    # 检查Docker容器
    if docker ps | grep -q kustdesk-server; then
        log_success "KustDesk Server 容器运行正常"
    else
        log_error "KustDesk Server 容器未运行"
    fi
    
    if docker ps | grep -q kustdesk-api; then
        log_success "KustDesk API 容器运行正常"
    else
        log_error "KustDesk API 容器未运行"
    fi
}

# 检查端口监听
check_ports() {
    log_info "检查端口监听状态..."
    
    local ports=(21114 21115 21116 21117 21118 21119)
    
    for port in "${ports[@]}"; do
        if netstat -tlnp | grep -q ":$port "; then
            log_success "端口 $port 监听正常"
        else
            log_warning "端口 $port 未监听"
        fi
    done
}

# 检查网络连接
check_network() {
    log_info "检查网络连接..."
    
    # 检查Docker网络
    if docker network ls | grep -q kustdesk-net; then
        log_success "Docker 网络 kustdesk-net 存在"
    else
        log_error "Docker 网络 kustdesk-net 不存在"
    fi
    
    # 检查容器间网络连通性
    if docker exec kustdesk-server ping -c 1 kustdesk-api &> /dev/null; then
        log_success "容器间网络连通性正常"
    else
        log_warning "容器间网络连通性异常"
    fi
}

# 检查资源使用
check_resources() {
    log_info "检查资源使用情况..."
    
    # 检查CPU和内存使用
    echo "容器资源使用情况："
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | grep kustdesk
    
    # 检查磁盘使用
    echo ""
    echo "磁盘使用情况："
    df -h /data/kustdesk 2>/dev/null || echo "数据目录不存在"
}

# 检查日志
check_logs() {
    log_info "检查最近日志..."
    
    echo "KustDesk Server 最近日志："
    docker logs --tail 10 kustdesk-server 2>/dev/null || echo "无法获取日志"
    
    echo ""
    echo "KustDesk API 最近日志："
    docker logs --tail 10 kustdesk-api 2>/dev/null || echo "无法获取日志"
}

# 检查健康状态
check_health() {
    log_info "检查服务健康状态..."
    
    # 检查API健康状态
    if curl -f http://localhost:21114/api/health &> /dev/null; then
        log_success "API 服务健康检查通过"
    else
        log_warning "API 服务健康检查失败"
    fi
    
    # 检查Server服务
    if docker exec kustdesk-server /usr/bin/rustdesk-utils genkeypair &> /dev/null; then
        log_success "Server 服务健康检查通过"
    else
        log_warning "Server 服务健康检查失败"
    fi
}

# 显示连接信息
show_connection_info() {
    log_info "显示连接信息..."
    
    # 获取公钥
    PUBLIC_KEY=$(docker exec kustdesk-server cat /data/id_ed25519.pub 2>/dev/null || echo "未找到公钥")
    
    # 获取服务器IP
    SERVER_IP=$(hostname -I | awk '{print $1}')
    
    echo ""
    echo "=========================================="
    echo "📋 连接信息"
    echo "=========================================="
    echo "ID服务器: ${SERVER_IP}:21116"
    echo "中继服务器: ${SERVER_IP}:21117"
    echo "Web管理界面: http://${SERVER_IP}:21114"
    echo ""
    echo "🔑 公钥:"
    echo "${PUBLIC_KEY}"
    echo "=========================================="
}

# 实时监控
real_time_monitor() {
    log_info "启动实时监控 (按 Ctrl+C 退出)..."
    
    while true; do
        clear
        echo "🚀 KustDesk Server 实时监控"
        echo "=================================="
        echo "时间: $(date)"
        echo ""
        
        # 显示容器状态
        echo "📊 容器状态："
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep kustdesk
        echo ""
        
        # 显示资源使用
        echo "💻 资源使用："
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep kustdesk
        echo ""
        
        # 显示网络连接
        echo "🌐 网络连接："
        netstat -an | grep 2111 | wc -l | xargs echo "活跃连接数:"
        echo ""
        
        sleep 5
    done
}

# 生成监控报告
generate_report() {
    log_info "生成监控报告..."
    
    local report_file="/tmp/kustdesk-monitor-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "KustDesk Server 监控报告"
        echo "生成时间: $(date)"
        echo "=================================="
        echo ""
        
        echo "1. 服务状态："
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep kustdesk
        echo ""
        
        echo "2. 端口监听："
        netstat -tlnp | grep -E "2111[4-9]"
        echo ""
        
        echo "3. 资源使用："
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}" | grep kustdesk
        echo ""
        
        echo "4. 磁盘使用："
        df -h /data/kustdesk 2>/dev/null || echo "数据目录不存在"
        echo ""
        
        echo "5. 最近日志："
        echo "Server 日志："
        docker logs --tail 20 kustdesk-server 2>/dev/null || echo "无法获取日志"
        echo ""
        echo "API 日志："
        docker logs --tail 20 kustdesk-api 2>/dev/null || echo "无法获取日志"
        
    } > "$report_file"
    
    log_success "监控报告已生成: $report_file"
}

# 显示帮助信息
show_help() {
    echo "KustDesk Server 监控脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示帮助信息"
    echo "  -s, --status        检查服务状态"
    echo "  -p, --ports         检查端口监听"
    echo "  -n, --network       检查网络连接"
    echo "  -r, --resources     检查资源使用"
    echo "  -l, --logs          检查日志"
    echo "  -c, --health        检查健康状态"
    echo "  -i, --info          显示连接信息"
    echo "  -m, --monitor       实时监控"
    echo "  -g, --report        生成监控报告"
    echo "  -a, --all           执行所有检查"
    echo ""
    echo "示例:"
    echo "  $0 --all            # 执行所有检查"
    echo "  $0 --monitor        # 启动实时监控"
    echo "  $0 --report         # 生成监控报告"
}

# 主函数
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            ;;
        -s|--status)
            check_services
            ;;
        -p|--ports)
            check_ports
            ;;
        -n|--network)
            check_network
            ;;
        -r|--resources)
            check_resources
            ;;
        -l|--logs)
            check_logs
            ;;
        -c|--health)
            check_health
            ;;
        -i|--info)
            show_connection_info
            ;;
        -m|--monitor)
            real_time_monitor
            ;;
        -g|--report)
            generate_report
            ;;
        -a|--all)
            check_services
            check_ports
            check_network
            check_resources
            check_logs
            check_health
            show_connection_info
            ;;
        "")
            # 默认执行所有检查
            check_services
            check_ports
            check_network
            check_resources
            check_logs
            check_health
            show_connection_info
            ;;
        *)
            log_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
