#!/bin/bash

# ============================================
# Git 代码分析器全局安装脚本
# ============================================

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 全局安装目录
GLOBAL_DIR="$HOME/.git-analyzer"
SCRIPTS_DIR="$GLOBAL_DIR/scripts"
TEMPLATES_DIR="$GLOBAL_DIR/templates"
PROJECTS_DIR="$GLOBAL_DIR/projects"

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

# 检查依赖
check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v gemini &> /dev/null; then
        log_error "Gemini CLI 未安装，请先安装: https://ai.google.dev/gemini-api/docs/cli"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_warning "jq 未安装，建议安装: brew install jq"
    fi
    
    log_success "依赖检查完成"
}

# 创建全局目录结构
create_global_structure() {
    log_info "创建全局目录结构..."
    
    mkdir -p "$GLOBAL_DIR"
    mkdir -p "$SCRIPTS_DIR"
    mkdir -p "$TEMPLATES_DIR"
    mkdir -p "$PROJECTS_DIR"
    
    log_success "全局目录结构创建完成"
}

# 复制脚本到全局目录
copy_scripts() {
    log_info "复制脚本文件..."
    
    # 复制主分析脚本
    cp .git-scripts/analyze_commit.sh "$SCRIPTS_DIR/"
    
    # 创建项目安装脚本
    cat > "$SCRIPTS_DIR/install.sh" << 'INSTALL_SCRIPT_EOF'
#!/bin/bash

# ============================================
# 为当前项目安装 Git 代码分析器
# ============================================

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 全局目录
GLOBAL_DIR="$HOME/.git-analyzer"
SCRIPTS_DIR="$GLOBAL_DIR/scripts"
PROJECTS_DIR="$GLOBAL_DIR/projects"

log_info() {
    echo -e "${BLUE}ℹ️  $@${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $@${NC}"
}

log_error() {
    echo -e "${RED}❌ $@${NC}"
}

# 检查是否在 Git 仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "当前目录不是 Git 仓库"
    exit 1
fi

# 获取项目信息
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"
PROJECT_DIR="$PROJECTS_DIR/$PROJECT_NAME"

log_info "为项目 '$PROJECT_NAME' 安装代码分析器..."

# 创建项目目录
mkdir -p "$PROJECT_DIR/logs"

# 创建项目配置文件
if [ ! -f "$PROJECT_DIR/config.json" ]; then
    cp "$GLOBAL_DIR/templates/config.json" "$PROJECT_DIR/config.json"
    log_info "已创建项目配置文件"
fi

# 创建 Git 钩子符号链接
HOOKS_DIR="$(git rev-parse --git-dir)/hooks"
POST_COMMIT_HOOK="$HOOKS_DIR/post-commit"

# 备份现有钩子（如果存在）
if [ -f "$POST_COMMIT_HOOK" ] && [ ! -L "$POST_COMMIT_HOOK" ]; then
    mv "$POST_COMMIT_HOOK" "$POST_COMMIT_HOOK.backup.$(date +%s)"
    log_warning "已备份现有 post-commit 钩子"
fi

# 创建符号链接到全局脚本
ln -sf "$SCRIPTS_DIR/analyze_commit.sh" "$POST_COMMIT_HOOK"
chmod +x "$POST_COMMIT_HOOK"

# 创建启用标记文件
touch "$PROJECT_ROOT/.git-analyzer-enabled"

log_success "Git 代码分析器安装完成！"
log_info "配置文件: $PROJECT_DIR/config.json"
log_info "日志文件: $PROJECT_DIR/logs/analyzer.log"
log_info "使用 'git-analyzer toggle' 来启用/禁用分析器"
INSTALL_SCRIPT_EOF

    # 创建项目卸载脚本
    cat > "$SCRIPTS_DIR/uninstall.sh" << 'UNINSTALL_SCRIPT_EOF'
#!/bin/bash

# ============================================
# 从当前项目卸载 Git 代码分析器
# ============================================

set -e

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${YELLOW}ℹ️  $@${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $@${NC}"
}

log_error() {
    echo -e "${RED}❌ $@${NC}"
}

# 检查是否在 Git 仓库中
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_error "当前目录不是 Git 仓库"
    exit 1
fi

# 获取项目信息
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
PROJECT_NAME="$(basename "$PROJECT_ROOT")"

log_info "从项目 '$PROJECT_NAME' 卸载代码分析器..."

# 移除 Git 钩子
HOOKS_DIR="$(git rev-parse --git-dir)/hooks"
POST_COMMIT_HOOK="$HOOKS_DIR/post-commit"

if [ -L "$POST_COMMIT_HOOK" ]; then
    rm "$POST_COMMIT_HOOK"
    log_info "已移除 Git 钩子"
fi

# 移除启用标记
rm -f "$PROJECT_ROOT/.git-analyzer-enabled"

log_success "Git 代码分析器已卸载"
log_info "项目数据保留在: ~/.git-analyzer/projects/$PROJECT_NAME/"
log_info "如需完全删除，请手动删除该目录"
UNINSTALL_SCRIPT_EOF

    chmod +x "$SCRIPTS_DIR/install.sh"
    chmod +x "$SCRIPTS_DIR/uninstall.sh"
    
    log_success "脚本文件复制完成"
}

# 创建配置模板
create_config_template() {
    log_info "创建配置模板..."
    
    cat > "$TEMPLATES_DIR/config.json" << 'CONFIG_EOF'
{
  "enabled": true,
  "output_base_dir": "code_summaries",
  "gemini_model": "gemini-2.0-flash-exp",
  "max_diff_size": 50000,
  "timeout_seconds": 60,
  "notification": {
    "show_success": true,
    "show_errors": true
  }
}
CONFIG_EOF
    
    log_success "配置模板创建完成"
}

# 更新主分析脚本
update_main_script() {
    log_info "更新主分析脚本以支持跨项目..."
    
    # 更新脚本中的路径逻辑
    sed -i.tmp 's|LOGS_DIR="$PROJECT_ROOT/.git-scripts-logs"|PROJECT_DIR="$HOME/.git-analyzer/projects/$(basename \"$PROJECT_ROOT\")"\nLOGS_DIR="$PROJECT_DIR/logs"|g' "$SCRIPTS_DIR/analyze_commit.sh"
    sed -i.tmp 's|CONFIG_FILE="$LOGS_DIR/.git-analyzer-config.json"|CONFIG_FILE="$PROJECT_DIR/config.json"|g' "$SCRIPTS_DIR/analyze_commit.sh"
    sed -i.tmp 's|LOG_FILE="$LOGS_DIR/.git-analyzer.log"|LOG_FILE="$LOGS_DIR/analyzer.log"|g' "$SCRIPTS_DIR/analyze_commit.sh"
    
    rm "$SCRIPTS_DIR/analyze_commit.sh.tmp"
    
    log_success "主分析脚本更新完成"
}

# 创建全局命令脚本
create_global_command() {
    log_info "创建全局命令..."
    
    cat > "$GLOBAL_DIR/git-analyzer" << 'GLOBAL_CMD_EOF'
#!/bin/bash

# ============================================
# Git 代码分析器全局命令
# ============================================

SCRIPTS_DIR="$HOME/.git-analyzer/scripts"
PROJECTS_DIR="$HOME/.git-analyzer/projects"

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

# 显示帮助
show_help() {
    echo "Git 代码分析器全局命令"
    echo ""
    echo "用法: git-analyzer [命令]"
    echo ""
    echo "命令:"
    echo "  install     - 为当前项目安装代码分析器"
    echo "  uninstall   - 从当前项目卸载代码分析器"
    echo "  toggle      - 切换当前项目的分析器开关"
    echo "  status      - 查看当前项目的状态"
    echo "  list        - 列出所有已安装的项目"
    echo "  help        - 显示此帮助信息"
    echo ""
}

# 安装到当前项目
install_project() {
    if [ ! -f "$SCRIPTS_DIR/install.sh" ]; then
        log_error "安装脚本不存在，请先运行全局安装"
        exit 1
    fi
    bash "$SCRIPTS_DIR/install.sh"
}

# 从当前项目卸载
uninstall_project() {
    if [ ! -f "$SCRIPTS_DIR/uninstall.sh" ]; then
        log_error "卸载脚本不存在，请先运行全局安装"
        exit 1
    fi
    bash "$SCRIPTS_DIR/uninstall.sh"
}

# 切换开关
toggle_project() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "当前目录不是 Git 仓库"
        exit 1
    fi
    
    PROJECT_ROOT="$(git rev-parse --show-toplevel)"
    PROJECT_NAME="$(basename "$PROJECT_ROOT")"
    CONFIG_FILE="$PROJECTS_DIR/$PROJECT_NAME/config.json"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "项目尚未安装代码分析器"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_error "jq 未安装，无法切换开关"
        exit 1
    fi
    
    CURRENT_STATUS=$(jq -r '.enabled' "$CONFIG_FILE")
    
    if [ "$CURRENT_STATUS" == "true" ]; then
        jq '.enabled = false' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        log_success "代码分析器已禁用"
    else
        jq '.enabled = true' "$CONFIG_FILE" > "$CONFIG_FILE.tmp" && mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
        log_success "代码分析器已启用"
    fi
}

# 查看状态
show_status() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "当前目录不是 Git 仓库"
        exit 1
    fi
    
    PROJECT_ROOT="$(git rev-parse --show-toplevel)"
    PROJECT_NAME="$(basename "$PROJECT_ROOT")"
    CONFIG_FILE="$PROJECTS_DIR/$PROJECT_NAME/config.json"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        log_info "项目尚未安装代码分析器"
        return
    fi
    
    if ! command -v jq &> /dev/null; then
        log_warning "jq 未安装，无法读取状态"
        return
    fi
    
    CURRENT_STATUS=$(jq -r '.enabled' "$CONFIG_FILE")
    
    if [ "$CURRENT_STATUS" == "true" ]; then
        log_success "代码分析器状态: 已启用"
    else
        log_error "代码分析器状态: 已禁用"
    fi
    
    echo "配置文件: $CONFIG_FILE"
    echo "日志文件: $PROJECTS_DIR/$PROJECT_NAME/logs/analyzer.log"
}

# 列出所有项目
list_projects() {
    log_info "已安装的项目:"
    
    if [ ! -d "$PROJECTS_DIR" ]; then
        log_info "无已安装的项目"
        return
    fi
    
    for project_dir in "$PROJECTS_DIR"/*; do
        if [ -d "$project_dir" ]; then
            project_name=$(basename "$project_dir")
            config_file="$project_dir/config.json"
            
            if [ -f "$config_file" ] && command -v jq &> /dev/null; then
                status=$(jq -r '.enabled' "$config_file" 2>/dev/null || echo "unknown")
                if [ "$status" == "true" ]; then
                    echo "  ✅ $project_name (已启用)"
                else
                    echo "  ❌ $project_name (已禁用)"
                fi
            else
                echo "  📁 $project_name (配置异常)"
            fi
        fi
    done
}

# 主逻辑
case "${1:-help}" in
    install)
        install_project
        ;;
    uninstall)
        uninstall_project
        ;;
    toggle)
        toggle_project
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
GLOBAL_CMD_EOF

    chmod +x "$GLOBAL_DIR/git-analyzer"
    
    log_success "全局命令创建完成"
}

# 创建 README
create_readme() {
    log_info "创建说明文档..."
    
    cat > "$GLOBAL_DIR/README.md" << 'README_EOF'
# Git 代码分析器 - 全局版本

## 🚀 快速开始

### 1. 安装到全局
```bash
# 在任意项目中运行
./git-analyzer-global-installer.sh
```

### 2. 为项目安装分析器
```bash
cd your-project
git-analyzer install
```

### 3. 使用
```bash
git add .
git commit -m "your commit message"
# 分析会在后台自动运行
```

## 🎮 命令

```bash
# 为当前项目安装
git-analyzer install

# 从当前项目卸载
git-analyzer uninstall

# 切换启用/禁用
git-analyzer toggle

# 查看状态
git-analyzer status

# 列出所有项目
git-analyzer list
```

## 📁 目录结构

```
~/.git-analyzer/
├── scripts/           # 通用脚本
├── templates/         # 配置模板
├── projects/          # 各项目数据
│   └── project-name/
│       ├── config.json
│       └── logs/
└── git-analyzer       # 全局命令
```

## ⚙️ 配置

每个项目的配置文件位于：`~/.git-analyzer/projects/项目名/config.json`

## 📊 日志

每个项目的日志文件位于：`~/.git-analyzer/projects/项目名/logs/analyzer.log`
README_EOF
    
    log_success "说明文档创建完成"
}

# 添加到 PATH
add_to_path() {
    log_info "添加到 PATH..."
    
    local shell_rc=""
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bash_profile"
    else
        shell_rc="$HOME/.profile"
    fi
    
    if ! grep -q "$GLOBAL_DIR" "$shell_rc" 2>/dev/null; then
        echo "" >> "$shell_rc"
        echo "# Git 代码分析器" >> "$shell_rc"
        echo "export PATH=\"\$PATH:$GLOBAL_DIR\"" >> "$shell_rc"
        log_success "已添加到 $shell_rc"
    else
        log_info "PATH 已配置"
    fi
}

# 主函数
main() {
    echo -e "${BLUE}🚀 Git 代码分析器 - 全局安装${NC}"
    echo ""
    
    check_dependencies
    create_global_structure
    copy_scripts
    create_config_template
    update_main_script
    create_global_command
    create_readme
    add_to_path
    
    echo ""
    log_success "全局安装完成！"
    echo ""
    echo -e "${YELLOW}下一步操作：${NC}"
    echo "1. 重新加载 shell 配置: source ~/.zshrc"
    echo "2. 为项目安装: git-analyzer install"
    echo "3. 查看帮助: git-analyzer help"
    echo ""
}

# 执行主函数
main "$@"
