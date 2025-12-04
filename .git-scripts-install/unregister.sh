#!/bin/bash

# ============================================
# 项目注销脚本 - 从 GitAnalyzer 注销当前项目
# ============================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${YELLOW}ℹ️  $@${NC}"; }
log_success() { echo -e "${GREEN}✅ $@${NC}"; }
log_error() { echo -e "${RED}❌ $@${NC}"; }

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "当前目录不是 Git 仓库"
    exit 1
fi

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"

log_info "从项目 '$PROJECT_NAME' 注销代码分析器..."

HOOKS_DIR="$(git rev-parse --git-dir)/hooks"
POST_COMMIT_HOOK="$HOOKS_DIR/post-commit"

if [ -f "$POST_COMMIT_HOOK" ]; then
    rm "$POST_COMMIT_HOOK"
    log_info "已移除 Git 钩子"
    
    BACKUP_HOOK="${POST_COMMIT_HOOK}.backup."*
    if ls $BACKUP_HOOK 2>/dev/null; then
        LATEST_BACKUP=$(ls -t $BACKUP_HOOK | head -1)
        mv "$LATEST_BACKUP" "$POST_COMMIT_HOOK"
        log_info "已恢复备份的钩子"
    fi
fi

log_success "注销完成！"
log_info "项目配置和日志已保留，如需删除请手动清理："
log_info "  - 配置: $PROJECT_ROOT/.git-scripts-logs/"
log_info "  - 日志: ~/.git-analyzer/../$PROJECT_NAME/"
