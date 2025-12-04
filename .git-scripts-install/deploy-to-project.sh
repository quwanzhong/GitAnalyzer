#!/bin/bash

# ============================================
# Git 代码分析器 - 项目部署脚本
# 将当前项目的分析器复制到其他项目
# ============================================

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $@${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $@${NC}"
}

log_error() {
    echo -e "${RED}❌ $@${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $@${NC}"
}

# 显示帮助
show_help() {
    echo "Git 代码分析器部署脚本"
    echo ""
    echo "用法: $0 <目标项目路径>"
    echo ""
    echo "示例:"
    echo "  $0 ~/projects/my-new-project"
    echo "  $0 /path/to/another/project"
    echo ""
}

# 检查参数
if [ $# -ne 1 ]; then
    log_error "请提供目标项目路径"
    show_help
    exit 1
fi

TARGET_PROJECT="$1"

# 检查目标项目是否存在
if [ ! -d "$TARGET_PROJECT" ]; then
    log_error "目标项目不存在: $TARGET_PROJECT"
    exit 1
fi

# 检查目标项目是否是 Git 仓库
if [ ! -d "$TARGET_PROJECT/.git" ]; then
    log_error "目标项目不是 Git 仓库: $TARGET_PROJECT"
    exit 1
fi

# 获取当前项目路径
CURRENT_PROJECT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log_info "部署 Git 代码分析器..."
log_info "源项目: $CURRENT_PROJECT"
log_info "目标项目: $TARGET_PROJECT"

# 创建目标目录
mkdir -p "$TARGET_PROJECT/.git-scripts"
mkdir -p "$TARGET_PROJECT/.git-scripts-logs"

# 复制脚本文件
log_info "复制脚本文件..."
cp -r "$CURRENT_PROJECT/.git-scripts/"* "$TARGET_PROJECT/.git-scripts/"

# 复制配置文件（如果不存在）
if [ ! -f "$TARGET_PROJECT/.git-scripts-logs/.git-analyzer-config.json" ]; then
    cp "$CURRENT_PROJECT/.git-scripts-logs/.git-analyzer-config.json" "$TARGET_PROJECT/.git-scripts-logs/"
    log_info "已复制配置文件"
else
    log_info "配置文件已存在，跳过复制"
fi

# 设置执行权限
chmod +x "$TARGET_PROJECT/.git-scripts/"*.sh

# 创建 Git 钩子
log_info "创建 Git 钩子..."
HOOKS_DIR="$TARGET_PROJECT/.git/hooks"
POST_COMMIT_HOOK="$HOOKS_DIR/post-commit"

# 备份现有钩子（如果存在）
if [ -f "$POST_COMMIT_HOOK" ] && [ ! -L "$POST_COMMIT_HOOK" ]; then
    mv "$POST_COMMIT_HOOK" "$POST_COMMIT_HOOK.backup.$(date +%s)"
    log_warning "已备份现有 post-commit 钩子"
fi

# 创建新的钩子
cat > "$POST_COMMIT_HOOK" << 'HOOK_EOF'
#!/bin/bash

# ============================================
# Git Post-Commit Hook
# 自动触发代码分析脚本
# ============================================

# 获取项目根目录
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
ANALYZER_SCRIPT="$PROJECT_ROOT/.git-scripts/analyze_commit.sh"

# 检查分析脚本是否存在
if [ ! -f "$ANALYZER_SCRIPT" ]; then
    echo "⚠️  代码分析脚本不存在: $ANALYZER_SCRIPT"
    exit 0
fi

# 在后台执行分析脚本，避免阻塞 git commit
# 使用 nohup 确保即使终端关闭也能继续运行
nohup bash "$ANALYZER_SCRIPT" > /dev/null 2>&1 &

echo "🚀 代码分析已在后台启动..."

exit 0
HOOK_EOF

chmod +x "$POST_COMMIT_HOOK"

# 更新目标项目的 .gitignore
log_info "更新 .gitignore..."
GITIGNORE_FILE="$TARGET_PROJECT/.gitignore"

# 检查是否已包含分析器忽略规则
if ! grep -q "Git 代码分析器" "$GITIGNORE_FILE" 2>/dev/null; then
    echo "" >> "$GITIGNORE_FILE"
    echo "# Git 代码分析器" >> "$GITIGNORE_FILE"
    echo ".git-scripts-logs/" >> "$GITIGNORE_FILE"
    echo "code_summaries/" >> "$GITIGNORE_FILE"
    log_info "已更新 .gitignore"
else
    log_info ".gitignore 已包含忽略规则"
fi

log_success "部署完成！"
echo ""
echo -e "${YELLOW}下一步操作：${NC}"
echo "1. 进入目标项目: cd $TARGET_PROJECT"
echo "2. 检查状态: .git-scripts/toggle_analyzer.sh status"
echo "3. 测试提交: git add . && git commit -m 'test analyzer'"
echo ""
echo -e "${BLUE}项目结构：${NC}"
echo "$TARGET_PROJECT/"
echo "├── .git-scripts/           # 脚本目录"
echo "├── .git-scripts-logs/      # 数据目录（被忽略）"
echo "└── .git/hooks/post-commit  # Git 钩子"
echo ""
