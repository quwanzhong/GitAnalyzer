#!/bin/bash

# ============================================
# 项目注册脚本 - 将当前项目注册到 GitAnalyzer
# ============================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $@${NC}"; }
log_success() { echo -e "${GREEN}✅ $@${NC}"; }
log_error() { echo -e "${RED}❌ $@${NC}"; }

if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "当前目录不是 Git 仓库"
    exit 1
fi

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"
ANALYZER_HOME="$(cat ~/.git-analyzer/config/analyzer_home 2>/dev/null)"

if [ -z "$ANALYZER_HOME" ]; then
    log_error "GitAnalyzer 未安装，请先运行全局安装脚本"
    exit 1
fi

log_info "为项目 '$PROJECT_NAME' 注册 Git 代码分析器..."

HOOKS_DIR="$(git rev-parse --git-dir)/hooks"
POST_COMMIT_HOOK="$HOOKS_DIR/post-commit"

if [ -f "$POST_COMMIT_HOOK" ] && [ ! -L "$POST_COMMIT_HOOK" ]; then
    mv "$POST_COMMIT_HOOK" "$POST_COMMIT_HOOK.backup.$(date +%s)"
    log_info "已备份现有 post-commit 钩子"
fi

cat > "$POST_COMMIT_HOOK" << 'HOOK_EOF'
#!/bin/bash

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
ANALYZER_HOME="$(cat ~/.git-analyzer/config/analyzer_home 2>/dev/null)"

if [ -z "$ANALYZER_HOME" ]; then
    echo "⚠️  Git 代码分析器未正确安装"
    exit 0
fi

# 检测操作系统
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || "$OSTYPE" == "cygwin" ]]; then
    # Windows 系统
    ANALYZER_SCRIPT="$ANALYZER_HOME/.git-scripts-install-windows/analyze_with_api.bat"
    
    if [ ! -f "$ANALYZER_SCRIPT" ]; then
        echo "⚠️  分析脚本不存在: $ANALYZER_SCRIPT"
        exit 0
    fi
    
    DIFF_CONTENT="$(git diff HEAD^ HEAD)"
    
    # 使用 cmd 执行 bat 脚本
    cmd //c "\"$ANALYZER_SCRIPT\" \"$PROJECT_ROOT\" \"$DIFF_CONTENT\"" &
else
    # Mac/Linux 系统
    ANALYZER_SCRIPT="$ANALYZER_HOME/.git-scripts-install/analyze_with_api.sh"
    
    if [ ! -f "$ANALYZER_SCRIPT" ]; then
        echo "⚠️  分析脚本不存在: $ANALYZER_SCRIPT"
        exit 0
    fi
    
    DIFF_CONTENT="$(git diff HEAD^ HEAD)"
    
    nohup bash "$ANALYZER_SCRIPT" "$PROJECT_ROOT" "$DIFF_CONTENT" > /dev/null 2>&1 &
fi

echo "🚀 代码分析已在后台启动..."
exit 0
HOOK_EOF

chmod +x "$POST_COMMIT_HOOK"

mkdir -p "$PROJECT_ROOT/.git-scripts-logs"

if [ ! -f "$PROJECT_ROOT/.git-scripts-logs/.git-analyzer-config.json" ]; then
    if [ -f "$ANALYZER_HOME/.git-scripts-logs/.git-analyzer-config.json" ]; then
        cp "$ANALYZER_HOME/.git-scripts-logs/.git-analyzer-config.json" "$PROJECT_ROOT/.git-scripts-logs/"
    else
        cat > "$PROJECT_ROOT/.git-scripts-logs/.git-analyzer-config.json" << 'CONFIG_EOF'
{
  "enabled": true,
  "output_base_dir": "code_summaries",
  "gemini_model": "gemini-1.5-flash",
  "gemini_api_key": "YOUR_API_KEY_HERE",
  "max_diff_size": 50000,
  "timeout_seconds": 120,
  "http_proxy": "",
  "https_proxy": ""
}
CONFIG_EOF
    fi
    log_info "已创建项目配置文件"
fi

mkdir -p "$ANALYZER_HOME/$PROJECT_NAME"

log_success "注册完成！"
log_info "配置文件: $PROJECT_ROOT/.git-scripts-logs/.git-analyzer-config.json"
log_info "日志目录: $ANALYZER_HOME/$PROJECT_NAME/"
log_info "使用 'unregister.sh' 可以注销分析器"
