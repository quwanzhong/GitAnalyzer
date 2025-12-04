#!/bin/bash

# ============================================
# Git 代码分析器开关控制脚本
# ============================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOGS_DIR="$PROJECT_ROOT/.git-scripts-logs"
CONFIG_FILE="$LOGS_DIR/.git-analyzer-config.json"

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 检查配置文件
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}❌ 配置文件不存在: $CONFIG_FILE${NC}"
    exit 1
fi

# 检查 jq 是否安装
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}⚠️  jq 未安装，请先安装: brew install jq${NC}"
    exit 1
fi

# 读取当前状态
CURRENT_STATUS=$(jq -r '.enabled' "$CONFIG_FILE")

# 显示当前状态
show_status() {
    if [ "$CURRENT_STATUS" == "true" ]; then
        echo -e "${GREEN}✅ 代码分析器当前状态: 已启用${NC}"
    else
        echo -e "${RED}❌ 代码分析器当前状态: 已禁用${NC}"
    fi
}

# 切换状态
toggle() {
    if [ "$CURRENT_STATUS" == "true" ]; then
        jq '.enabled = false' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        echo -e "${RED}❌ 代码分析器已禁用${NC}"
    else
        jq '.enabled = true' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        echo -e "${GREEN}✅ 代码分析器已启用${NC}"
    fi
}

# 启用
enable() {
    jq '.enabled = true' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    echo -e "${GREEN}✅ 代码分析器已启用${NC}"
}

# 禁用
disable() {
    jq '.enabled = false' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
    echo -e "${RED}❌ 代码分析器已禁用${NC}"
}

# 显示帮助
show_help() {
    echo "Git 代码分析器控制脚本"
    echo ""
    echo "用法:"
    echo "  $0 [命令]"
    echo ""
    echo "命令:"
    echo "  status    - 显示当前状态"
    echo "  toggle    - 切换启用/禁用状态"
    echo "  enable    - 启用分析器"
    echo "  disable   - 禁用分析器"
    echo "  help      - 显示此帮助信息"
    echo ""
}

# 主逻辑
case "${1:-status}" in
    status)
        show_status
        ;;
    toggle)
        toggle
        ;;
    enable)
        enable
        ;;
    disable)
        disable
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}❌ 未知命令: $1${NC}"
        show_help
        exit 1
        ;;
esac
