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

# 从配置文件读取 GitAnalyzer 主目录
if [ -f "$HOME/.git-analyzer/config/analyzer_home" ]; then
    GIT_ANALYZER_HOME="$(cat "$HOME/.git-analyzer/config/analyzer_home")"
else
    # 如果配置文件不存在，尝试计算路径
    GIT_ANALYZER_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
fi
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

check_api_config() {
    log_info "检查 Gemini API 配置..."
    
    # 检查是否有项目注册
    local has_projects=false
    if [ -d "$GIT_ANALYZER_HOME" ]; then
        for project_dir in "$GIT_ANALYZER_HOME"/*; do
            [ ! -d "$project_dir" ] && continue
            
            local project_name=$(basename "$project_dir")
            
            # 排除系统目录
            case "$project_name" in
                .git|.git-scripts|.git-scripts-logs|.git-scripts-install|.git-scripts-install-windows|bin|config|.DS_Store|.gitignore|*.md)
                    continue
                    ;;
            esac
            
            if [ -d "$project_dir/code_summaries" ] || [ -f "$project_dir/analyzer.log" ]; then
                has_projects=true
                break
            fi
        done
    fi
    
    if [ "$has_projects" = false ]; then
        log_warning "尚未注册任何项目"
        echo ""
        echo "请在项目目录中运行:"
        echo "   ${GREEN}register.sh${NC}"
        echo ""
    fi
    
    # 检查配置模板中是否有 API Key
    CONFIG_TEMPLATE="$GIT_ANALYZER_HOME/.git-scripts-logs/.git-analyzer-config.json"
    if [ -f "$CONFIG_TEMPLATE" ]; then
        API_KEY=$(jq -r '.gemini_api_key // ""' "$CONFIG_TEMPLATE" 2>/dev/null)
        if [ -z "$API_KEY" ] || [ "$API_KEY" = "null" ]; then
            log_warning "未检测到 Gemini API Key 配置"
            echo ""
            read -p "是否现在配置 API Key? (Y/n): " CONFIGURE_NOW
            
            if [ -z "$CONFIGURE_NOW" ] || [ "$CONFIGURE_NOW" = "Y" ] || [ "$CONFIGURE_NOW" = "y" ]; then
                # 调用配置向导
                SETUP_SCRIPT="$GIT_ANALYZER_HOME/setup_gemini_api.sh"
                if [ -f "$SETUP_SCRIPT" ]; then
                    bash "$SETUP_SCRIPT"
                else
                    log_error "配置脚本不存在: $SETUP_SCRIPT"
                    log_info "请手动配置: $CONFIG_TEMPLATE"
                    log_info "API Key 获取: https://aistudio.google.com/app/apikey"
                fi
            else
                log_info "请手动配置 API Key"
                log_info "配置文件: $CONFIG_TEMPLATE"
                log_info "API Key 获取: https://aistudio.google.com/app/apikey"
            fi
            echo ""
        else
            log_success "已检测到 API Key 配置"
        fi
    else
        log_warning "配置模板不存在: $CONFIG_TEMPLATE"
        log_info "请确保在项目配置文件中设置了 Gemini API Key"
        log_info "配置文件: 项目根目录/.git-scripts-logs/.git-analyzer-config.json"
        log_info "API Key 获取: https://aistudio.google.com/app/apikey"
    fi
    echo ""
    
    return 0
}

start_service() {
    echo ""
    log_info "========== 启动 GitAnalyzer 全局服务 =========="
    echo ""
    
    # 检查 API 配置
    check_api_config
    
    echo ""
    mkdir -p "$(dirname "$SERVICE_STATUS_FILE")"
    echo "enabled" > "$SERVICE_STATUS_FILE"
    log_success "GitAnalyzer 全局服务已启用"
    log_info "所有已注册项目的提交都将被分析"
    
    # 显示当前配置的 API Key 信息
    CONFIG_TEMPLATE="$GIT_ANALYZER_HOME/.git-scripts-logs/.git-analyzer-config.json"
    if [ -f "$CONFIG_TEMPLATE" ]; then
        API_KEY=$(jq -r '.gemini_api_key // ""' "$CONFIG_TEMPLATE" 2>/dev/null)
        if [ -n "$API_KEY" ] && [ "$API_KEY" != "null" ]; then
            log_success "当前 API Key: ${API_KEY:0:20}...${API_KEY: -4}"
        else
            log_warning "未配置 API Key，请运行: setup_gemini_api.sh"
        fi
    fi
    echo ""
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
        [ ! -d "$project_dir" ] && continue
        
        project_name=$(basename "$project_dir")
        
        # 排除系统目录
        case "$project_name" in
            .git|.git-scripts|.git-scripts-logs|.git-scripts-install|bin|config|.DS_Store|.gitignore|*.md)
                continue
                ;;
        esac
        
        # 只显示包含 code_summaries 或 analyzer.log 的项目
        if [ -d "$project_dir/code_summaries" ] || [ -f "$project_dir/analyzer.log" ]; then
            echo "  📁 $project_name"
            
            # 显示项目信息
            if [ -f "$project_dir/analyzer.log" ]; then
                LAST_ANALYSIS=$(tail -1 "$project_dir/analyzer.log" 2>/dev/null | grep -oE '\[[0-9-]+ [0-9:]+\]' | head -1)
                [ -n "$LAST_ANALYSIS" ] && echo "     ├─ 最后分析: $LAST_ANALYSIS"
            fi
            
            if [ -d "$project_dir/code_summaries" ]; then
                REPORT_COUNT=$(find "$project_dir/code_summaries" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
                [ "$REPORT_COUNT" -gt 0 ] && echo "     └─ 分析报告: $REPORT_COUNT 个"
            fi
            
            COUNT=$((COUNT + 1))
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
