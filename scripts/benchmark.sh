#!/bin/bash

# KustDesk Server 性能测试脚本
# 作者: Kayungko
# 版本: v1.0.0

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
TEST_DURATION=60
CONCURRENT_CONNECTIONS=10
TEST_SERVER="localhost"
TEST_PORTS=(21116 21117)

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

# 检查依赖
check_dependencies() {
    log_info "检查测试依赖..."
    
    local missing_deps=()
    
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    if ! command -v netstat &> /dev/null; then
        missing_deps+=("netstat")
    fi
    
    if ! command -v ss &> /dev/null; then
        missing_deps+=("ss")
    fi
    
    if ! command -v iostat &> /dev/null; then
        missing_deps+=("iostat")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_error "缺少依赖: ${missing_deps[*]}"
        log_info "请安装缺少的依赖后重试"
        exit 1
    fi
    
    log_success "依赖检查通过"
}

# 测试端口连通性
test_port_connectivity() {
    log_info "测试端口连通性..."
    
    for port in "${TEST_PORTS[@]}"; do
        if nc -z "$TEST_SERVER" "$port" 2>/dev/null; then
            log_success "端口 $port 连通正常"
        else
            log_error "端口 $port 连通失败"
        fi
    done
}

# 测试API响应时间
test_api_response() {
    log_info "测试API响应时间..."
    
    local api_url="http://$TEST_SERVER:21114"
    
    if curl -f -s "$api_url" &> /dev/null; then
        log_success "API服务可访问"
        
        # 测试响应时间
        local response_time=$(curl -o /dev/null -s -w '%{time_total}' "$api_url")
        log_info "API响应时间: ${response_time}s"
    else
        log_error "API服务不可访问"
    fi
}

# 测试并发连接
test_concurrent_connections() {
    log_info "测试并发连接..."
    
    local success_count=0
    local total_count=$CONCURRENT_CONNECTIONS
    
    for ((i=1; i<=total_count; i++)); do
        if nc -z "$TEST_SERVER" 21116 2>/dev/null; then
            ((success_count++))
        fi
    done
    
    local success_rate=$((success_count * 100 / total_count))
    log_info "并发连接测试: $success_count/$total_count 成功 (${success_rate}%)"
}

# 测试网络延迟
test_network_latency() {
    log_info "测试网络延迟..."
    
    local total_latency=0
    local test_count=10
    
    for ((i=1; i<=test_count; i++)); do
        local latency=$(ping -c 1 "$TEST_SERVER" 2>/dev/null | grep "time=" | awk '{print $7}' | cut -d'=' -f2)
        if [ -n "$latency" ]; then
            total_latency=$(echo "$total_latency + $latency" | bc -l)
        fi
    done
    
    local avg_latency=$(echo "scale=2; $total_latency / $test_count" | bc -l)
    log_info "平均网络延迟: ${avg_latency}ms"
}

# 测试带宽
test_bandwidth() {
    log_info "测试带宽..."
    
    # 创建测试文件
    local test_file="/tmp/kustdesk-bandwidth-test"
    dd if=/dev/zero of="$test_file" bs=1M count=10 2>/dev/null
    
    # 测试上传速度
    local start_time=$(date +%s.%N)
    if curl -s -T "$test_file" "http://$TEST_SERVER:21114/upload" &> /dev/null; then
        local end_time=$(date +%s.%N)
        local duration=$(echo "$end_time - $start_time" | bc -l)
        local speed=$(echo "scale=2; 10 / $duration" | bc -l)
        log_info "上传速度: ${speed}MB/s"
    else
        log_warning "上传测试失败"
    fi
    
    # 清理测试文件
    rm -f "$test_file"
}

# 监控系统资源
monitor_system_resources() {
    log_info "监控系统资源..."
    
    echo ""
    echo "📊 系统资源使用情况："
    echo "=========================================="
    
    # CPU使用率
    echo "CPU使用率:"
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 | xargs echo "  总CPU: %"
    
    # 内存使用
    echo "内存使用:"
    free -h | grep "Mem:" | awk '{print "  总内存: " $2 ", 已用: " $3 ", 可用: " $7}'
    
    # 磁盘使用
    echo "磁盘使用:"
    df -h / | tail -1 | awk '{print "  根分区: " $3 "/" $2 " (" $5 " 已使用)"}'
    
    # 网络连接数
    echo "网络连接:"
    ss -s | grep "TCP:" | awk '{print "  TCP连接: " $2}'
    
    echo "=========================================="
}

# 监控Docker容器资源
monitor_docker_resources() {
    log_info "监控Docker容器资源..."
    
    echo ""
    echo "🐳 Docker容器资源使用："
    echo "=========================================="
    
    if docker ps | grep -q kustdesk; then
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}\t{{.NetIO}}\t{{.BlockIO}}" | grep kustdesk
    else
        log_warning "没有找到KustDesk容器"
    fi
    
    echo "=========================================="
}

# 压力测试
stress_test() {
    log_info "执行压力测试 (持续 ${TEST_DURATION} 秒)..."
    
    local start_time=$(date +%s)
    local end_time=$((start_time + TEST_DURATION))
    local connection_count=0
    
    while [ $(date +%s) -lt $end_time ]; do
        for port in "${TEST_PORTS[@]}"; do
            if nc -z "$TEST_SERVER" "$port" 2>/dev/null; then
                ((connection_count++))
            fi
        done
        sleep 1
    done
    
    log_info "压力测试完成，总连接数: $connection_count"
}

# 生成性能报告
generate_performance_report() {
    log_info "生成性能报告..."
    
    local report_file="/tmp/kustdesk-performance-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "KustDesk Server 性能测试报告"
        echo "测试时间: $(date)"
        echo "测试服务器: $TEST_SERVER"
        echo "测试端口: ${TEST_PORTS[*]}"
        echo "并发连接数: $CONCURRENT_CONNECTIONS"
        echo "测试持续时间: ${TEST_DURATION}秒"
        echo "=================================="
        echo ""
        
        echo "1. 端口连通性测试："
        for port in "${TEST_PORTS[@]}"; do
            if nc -z "$TEST_SERVER" "$port" 2>/dev/null; then
                echo "  端口 $port: 连通正常"
            else
                echo "  端口 $port: 连通失败"
            fi
        done
        echo ""
        
        echo "2. API响应测试："
        local api_url="http://$TEST_SERVER:21114"
        if curl -f -s "$api_url" &> /dev/null; then
            local response_time=$(curl -o /dev/null -s -w '%{time_total}' "$api_url")
            echo "  API响应时间: ${response_time}s"
        else
            echo "  API服务不可访问"
        fi
        echo ""
        
        echo "3. 系统资源使用："
        echo "  CPU使用率:"
        top -bn1 | grep "Cpu(s)" | awk '{print "    " $2}'
        echo "  内存使用:"
        free -h | grep "Mem:" | awk '{print "    总内存: " $2 ", 已用: " $3 ", 可用: " $7}'
        echo "  磁盘使用:"
        df -h / | tail -1 | awk '{print "    根分区: " $3 "/" $2 " (" $5 " 已使用)"}'
        echo ""
        
        echo "4. 网络连接统计："
        ss -s | grep "TCP:" | awk '{print "  TCP连接: " $2}'
        echo ""
        
        echo "5. Docker容器状态："
        if docker ps | grep -q kustdesk; then
            docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep kustdesk
        else
            echo "  没有找到KustDesk容器"
        fi
        
    } > "$report_file"
    
    log_success "性能报告已生成: $report_file"
}

# 显示帮助信息
show_help() {
    echo "KustDesk Server 性能测试脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示帮助信息"
    echo "  -c, --connectivity  测试端口连通性"
    echo "  -a, --api           测试API响应"
    echo "  -n, --network       测试网络延迟"
    echo "  -b, --bandwidth     测试带宽"
    echo "  -s, --stress        执行压力测试"
    echo "  -r, --resources     监控系统资源"
    echo "  -d, --docker        监控Docker资源"
    echo "  -p, --report        生成性能报告"
    echo "  -a, --all           执行所有测试"
    echo ""
    echo "配置选项:"
    echo "  --server HOST       测试服务器地址 (默认: localhost)"
    echo "  --duration SECONDS  测试持续时间 (默认: 60)"
    echo "  --connections NUM   并发连接数 (默认: 10)"
    echo ""
    echo "示例:"
    echo "  $0 --all                    # 执行所有测试"
    echo "  $0 --stress --duration 120  # 执行120秒压力测试"
    echo "  $0 --server 192.168.1.100   # 测试指定服务器"
}

# 主函数
main() {
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --server)
                TEST_SERVER="$2"
                shift 2
                ;;
            --duration)
                TEST_DURATION="$2"
                shift 2
                ;;
            --connections)
                CONCURRENT_CONNECTIONS="$2"
                shift 2
                ;;
            -c|--connectivity)
                check_dependencies
                test_port_connectivity
                ;;
            -a|--api)
                check_dependencies
                test_api_response
                ;;
            -n|--network)
                check_dependencies
                test_network_latency
                ;;
            -b|--bandwidth)
                check_dependencies
                test_bandwidth
                ;;
            -s|--stress)
                check_dependencies
                stress_test
                ;;
            -r|--resources)
                monitor_system_resources
                ;;
            -d|--docker)
                monitor_docker_resources
                ;;
            -p|--report)
                generate_performance_report
                ;;
            --all)
                check_dependencies
                test_port_connectivity
                test_api_response
                test_concurrent_connections
                test_network_latency
                test_bandwidth
                monitor_system_resources
                monitor_docker_resources
                stress_test
                generate_performance_report
                ;;
            *)
                log_error "未知选项: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 如果没有指定任何选项，执行默认测试
    if [ $# -eq 0 ]; then
        check_dependencies
        test_port_connectivity
        test_api_response
        test_concurrent_connections
        test_network_latency
        monitor_system_resources
        monitor_docker_resources
    fi
}

# 脚本入口
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
