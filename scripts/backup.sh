#!/bin/bash

# KustDesk Server 备份脚本
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
BACKUP_DIR="/data/kustdesk/backups"
DATA_DIR="/data/kustdesk"
RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

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

# 创建备份目录
create_backup_dir() {
    log_info "创建备份目录..."
    
    sudo mkdir -p "$BACKUP_DIR"
    sudo chown -R $USER:$USER "$BACKUP_DIR"
    
    log_success "备份目录创建完成: $BACKUP_DIR"
}

# 备份数据目录
backup_data() {
    log_info "备份数据目录..."
    
    local backup_file="$BACKUP_DIR/kustdesk-data-$TIMESTAMP.tar.gz"
    
    if [ -d "$DATA_DIR" ]; then
        tar -czf "$backup_file" -C "$DATA_DIR" .
        log_success "数据备份完成: $backup_file"
        
        # 显示备份文件大小
        local size=$(du -h "$backup_file" | cut -f1)
        log_info "备份文件大小: $size"
    else
        log_warning "数据目录不存在: $DATA_DIR"
    fi
}

# 备份Docker配置
backup_docker_config() {
    log_info "备份Docker配置..."
    
    local backup_file="$BACKUP_DIR/kustdesk-docker-config-$TIMESTAMP.tar.gz"
    
    # 备份docker-compose文件
    if [ -f "docker-compose-complete.yml" ]; then
        tar -czf "$backup_file" docker-compose-complete.yml
        log_success "Docker配置备份完成: $backup_file"
    else
        log_warning "docker-compose-complete.yml 文件不存在"
    fi
}

# 备份系统配置
backup_system_config() {
    log_info "备份系统配置..."
    
    local backup_file="$BACKUP_DIR/kustdesk-system-config-$TIMESTAMP.tar.gz"
    
    # 创建临时目录
    local temp_dir=$(mktemp -d)
    
    # 备份systemd服务文件
    if [ -f "/etc/systemd/system/kustdesk-server.service" ]; then
        cp /etc/systemd/system/kustdesk-server.service "$temp_dir/"
    fi
    
    # 备份环境变量文件
    if [ -f "/etc/environment" ]; then
        cp /etc/environment "$temp_dir/"
    fi
    
    # 备份网络配置
    if [ -f "/etc/docker/daemon.json" ]; then
        cp /etc/docker/daemon.json "$temp_dir/"
    fi
    
    # 创建备份文件
    if [ "$(ls -A "$temp_dir")" ]; then
        tar -czf "$backup_file" -C "$temp_dir" .
        log_success "系统配置备份完成: $backup_file"
    else
        log_warning "没有找到系统配置文件"
    fi
    
    # 清理临时目录
    rm -rf "$temp_dir"
}

# 清理旧备份
cleanup_old_backups() {
    log_info "清理 $RETENTION_DAYS 天前的旧备份..."
    
    local deleted_count=0
    
    # 删除旧的数据备份
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((deleted_count++))
    done < <(find "$BACKUP_DIR" -name "kustdesk-data-*.tar.gz" -mtime +$RETENTION_DAYS -print0)
    
    # 删除旧的Docker配置备份
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((deleted_count++))
    done < <(find "$BACKUP_DIR" -name "kustdesk-docker-config-*.tar.gz" -mtime +$RETENTION_DAYS -print0)
    
    # 删除旧的系统配置备份
    while IFS= read -r -d '' file; do
        rm -f "$file"
        ((deleted_count++))
    done < <(find "$BACKUP_DIR" -name "kustdesk-system-config-*.tar.gz" -mtime +$RETENTION_DAYS -print0)
    
    if [ $deleted_count -gt 0 ]; then
        log_success "已删除 $deleted_count 个旧备份文件"
    else
        log_info "没有找到需要删除的旧备份文件"
    fi
}

# 显示备份信息
show_backup_info() {
    log_info "显示备份信息..."
    
    echo ""
    echo "=========================================="
    echo "📋 备份信息"
    echo "=========================================="
    echo "备份目录: $BACKUP_DIR"
    echo "备份时间: $(date)"
    echo "保留天数: $RETENTION_DAYS"
    echo ""
    
    echo "📊 备份文件列表："
    if [ -d "$BACKUP_DIR" ]; then
        ls -lh "$BACKUP_DIR" | grep kustdesk
    else
        echo "备份目录不存在"
    fi
    
    echo ""
    echo "💾 磁盘使用情况："
    if [ -d "$BACKUP_DIR" ]; then
        du -sh "$BACKUP_DIR"
    fi
    
    echo "=========================================="
}

# 恢复备份
restore_backup() {
    local backup_file="$1"
    
    if [ -z "$backup_file" ]; then
        log_error "请指定备份文件路径"
        exit 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        log_error "备份文件不存在: $backup_file"
        exit 1
    fi
    
    log_warning "即将恢复备份: $backup_file"
    read -p "确认继续? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "取消恢复操作"
        exit 0
    fi
    
    # 停止服务
    log_info "停止服务..."
    docker stop kustdesk-server kustdesk-api 2>/dev/null || true
    
    # 备份当前数据
    log_info "备份当前数据..."
    local current_backup="$BACKUP_DIR/current-data-backup-$(date +%Y%m%d_%H%M%S).tar.gz"
    if [ -d "$DATA_DIR" ]; then
        tar -czf "$current_backup" -C "$DATA_DIR" .
    fi
    
    # 恢复数据
    log_info "恢复数据..."
    sudo mkdir -p "$DATA_DIR"
    tar -xzf "$backup_file" -C "$DATA_DIR"
    sudo chown -R $USER:$USER "$DATA_DIR"
    
    # 启动服务
    log_info "启动服务..."
    docker start kustdesk-api kustdesk-server
    
    log_success "恢复完成"
}

# 显示帮助信息
show_help() {
    echo "KustDesk Server 备份脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示帮助信息"
    echo "  -b, --backup        执行完整备份"
    echo "  -d, --data          仅备份数据"
    echo "  -c, --config        仅备份配置"
    echo "  -s, --system        仅备份系统配置"
    echo "  -l, --list          列出备份文件"
    echo "  -r, --restore FILE  恢复指定备份"
    echo "  -clean, --cleanup   清理旧备份"
    echo "  -i, --info          显示备份信息"
    echo ""
    echo "示例:"
    echo "  $0 --backup          # 执行完整备份"
    echo "  $0 --list            # 列出备份文件"
    echo "  $0 --restore /path/to/backup.tar.gz  # 恢复备份"
    echo "  $0 --cleanup         # 清理旧备份"
}

# 列出备份文件
list_backups() {
    log_info "列出备份文件..."
    
    if [ -d "$BACKUP_DIR" ]; then
        echo ""
        echo "📋 备份文件列表："
        echo "=========================================="
        ls -lh "$BACKUP_DIR" | grep kustdesk
        echo "=========================================="
    else
        log_warning "备份目录不存在: $BACKUP_DIR"
    fi
}

# 主函数
main() {
    case "${1:-}" in
        -h|--help)
            show_help
            ;;
        -b|--backup)
            create_backup_dir
            backup_data
            backup_docker_config
            backup_system_config
            cleanup_old_backups
            show_backup_info
            ;;
        -d|--data)
            create_backup_dir
            backup_data
            show_backup_info
            ;;
        -c|--config)
            create_backup_dir
            backup_docker_config
            show_backup_info
            ;;
        -s|--system)
            create_backup_dir
            backup_system_config
            show_backup_info
            ;;
        -l|--list)
            list_backups
            ;;
        -r|--restore)
            restore_backup "$2"
            ;;
        -clean|--cleanup)
            cleanup_old_backups
            ;;
        -i|--info)
            show_backup_info
            ;;
        "")
            # 默认执行完整备份
            create_backup_dir
            backup_data
            backup_docker_config
            backup_system_config
            cleanup_old_backups
            show_backup_info
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
