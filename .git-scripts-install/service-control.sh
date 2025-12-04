#!/bin/bash

# ============================================
# GitAnalyzer 全局服务控制脚本
# 用于启动/停止全局分析服务(可选功能)
# ============================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $@${NC}"; }
log_success() { echo -e "${GREEN}✅ $@${NC}"; }
log_error() { echo -e "${RED}❌ $@${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $@${NC}"; }

GIT_ANALYZER_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
SERVICE_STATUS_FILE="$HOME/.git-analyzer/config/service_status"

show_help() {
    echo "GitAnalyzer 全局服务控制"
    echo ""
    echo "用法: $0 [命令]"
    echo ""
    echo "命令:"
    echo "  start   - 启动全局服务(标记为启用)"
    echo "  stop    - 停止全局服务(标记为禁用)"
    echo "  status  - 查看服务状态"
    echo "  list    - 列出所有已注册的项目"
    echo ""
    echo "注意: 本服务采用观察者模式，无需常驻进程"
    echo "      启动/停止仅影响全局配置状态"
}

start_service() {
    mkdir -p "$(dirname "$SERVICE_STATUS_FILE")"
    echo "enabled" > "$SERVICE_STATUS_FILE"
    log_success "GitAnalyzer 全局服务已启用"
    log_info "所有已注册项目的提交都将被分析"
}

stop_service() {
    mkdir -p "$(dirname "$SERVICE_STATUS_FILE")"
    echo "disabled" > "$SERVICE_STATUS_FILE"
    log_warning "GitAnalyzer 全局服务已禁用"
    log_info "已注册项目的提交将不会被分析"
}

show_status() {
    if [ ! -f "$SERVICE_STATUS_FILE" ]; then
        log_info "服务状态: 未初始化 (默认启用)"
        return
    fi
    
    STATUS=$(cat "$SERVICE_STATUS_FILE")
    if [ "$STATUS" == "enabled" ]; then
        log_success "服务状态: 已启用 ✓"
    else
        log_warning "服务状态: 已禁用 ✗"
    fi
    
    echo ""
    echo "GitAnalyzer 主目录: $GIT_ANALYZER_HOME"
    echo "配置目录: $HOME/.git-analyzer/config"
}

list_projects() {
    log_info "已注册的项目:"
    echo ""
    
    if [ ! -d "$GIT_ANALYZER_HOME" ]; then
        log_warning "未找到项目目录"
        return
    fi
    
    COUNT=0
    for project_dir in "$GIT_ANALYZER_HOME"/*; do
        if [ -d "$project_dir" ] && [ "$(basename "$project_dir")" != ".git" ] && [ "$(basename "$project_dir")" != ".git-scripts" ] && [ "$(basename "$project_dir")" != ".git-scripts-logs" ] && [ "$(basename "$project_dir")" != ".git-scripts-install" ]; then
            project_name=$(basename "$project_dir")
            if [ "$project_name" != "项目实现思路观察者.md" ] && [ "$project_name" != ".DS_Store" ] && [ "$project_name" != ".gitignore" ]; then
                echo "  📁 $project_name"
                if [ -d "$project_dir/logs" ] || [ -d "$project_dir/code_summaries" ]; then
                    echo "     └─ 日志目录: $project_dir/"
                fi
                COUNT=$((COUNT + 1))
            fi
        fi
    done
    
    if [ $COUNT -eq 0 ]; then
        log_info "暂无已注册的项目"
        echo "使用 'register.sh' 在项目目录中注册"
    else
        echo ""
        log_success "共 $COUNT 个已注册项目"
    fi
}

case "${1:-status}" in
    start)
        start_service
        ;;
    stop)
        stop_service
        ;;
    status)
        show_status
        ;;
    list)
        list_projects
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        log_error "未知命令: $1"
        show_help
        exit 1
        ;;
esac
