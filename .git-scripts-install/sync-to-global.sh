#!/bin/bash

# ============================================
# 同步脚本到全局目录
# 用于开发时快速更新全局命令
# ============================================

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $@${NC}"; }
log_success() { echo -e "${GREEN}✅ $@${NC}"; }
log_error() { echo -e "${RED}❌ $@${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $@${NC}"; }

echo ""
echo "=========================================="
echo "  同步脚本到全局目录"
echo "=========================================="
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANALYZER_HOME="$(dirname "$SCRIPT_DIR")"
GLOBAL_BIN_DIR="$HOME/.git-analyzer/bin"

log_info "GitAnalyzer 主目录: $ANALYZER_HOME"
log_info "全局命令目录: $GLOBAL_BIN_DIR"

# 检查全局目录是否存在
if [ ! -d "$GLOBAL_BIN_DIR" ]; then
    log_error "全局目录不存在，请先运行全局安装脚本"
    exit 1
fi

echo ""
log_info "开始同步脚本..."

# 同步 Mac/Linux 脚本
SCRIPTS=(
    "register.sh"
    "unregister.sh"
    "analyze_with_api.sh"
    "test-api.sh"
)

SYNCED=0
FAILED=0

for script in "${SCRIPTS[@]}"; do
    SOURCE="$SCRIPT_DIR/$script"
    TARGET="$GLOBAL_BIN_DIR/$script"
    
    if [ -f "$SOURCE" ]; then
        if cp "$SOURCE" "$TARGET" && chmod +x "$TARGET"; then
            log_success "已同步: $script"
            ((SYNCED++))
        else
            log_error "同步失败: $script"
            ((FAILED++))
        fi
    else
        log_warning "源文件不存在: $script"
    fi
done

echo ""
log_info "=========================================="
log_success "同步完成: $SYNCED 个文件"
if [ $FAILED -gt 0 ]; then
    log_error "失败: $FAILED 个文件"
fi
log_info "=========================================="
echo ""

# 显示版本信息
if [ -f "$GLOBAL_BIN_DIR/register.sh" ]; then
    LINES=$(wc -l < "$GLOBAL_BIN_DIR/register.sh")
    log_info "register.sh: $LINES 行"
fi

echo ""
log_success "✨ 全局命令已更新，可以直接使用最新版本"
echo ""
