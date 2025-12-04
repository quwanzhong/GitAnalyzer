#!/bin/bash

# ============================================
# Git 代码分析器全局安装脚本 (观察者模式)
# GitAnalyzer 作为全局服务，项目通过注册/注销来订阅服务
# ============================================

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

GIT_ANALYZER_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && cd .. && pwd)"
GLOBAL_INSTALL_DIR="$HOME/.git-analyzer"

log_info() { echo -e "${BLUE}ℹ️  $@${NC}"; }
log_success() { echo -e "${GREEN}✅ $@${NC}"; }
log_error() { echo -e "${RED}❌ $@${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $@${NC}"; }

check_dependencies() {
    log_info "检查依赖..."
    
    if ! command -v gemini &> /dev/null; then
        log_error "Gemini CLI 未安装，请先安装: https://ai.google.dev/gemini-api/docs/cli"
        exit 1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_warning "jq 未安装，建议安装: brew install jq (用于配置管理)"
    fi
    
    log_success "依赖检查完成"
}

create_global_structure() {
    log_info "创建全局目录结构..."
    
    mkdir -p "$GLOBAL_INSTALL_DIR"
    mkdir -p "$GLOBAL_INSTALL_DIR/bin"
    mkdir -p "$GLOBAL_INSTALL_DIR/config"
    
    echo "$GIT_ANALYZER_HOME" > "$GLOBAL_INSTALL_DIR/config/analyzer_home"
    echo "enabled" > "$GLOBAL_INSTALL_DIR/config/service_status"
    
    log_success "全局目录结构创建完成: $GLOBAL_INSTALL_DIR"
}

install_scripts() {
    log_info "安装脚本到全局目录..."
    
    cp "$GIT_ANALYZER_HOME/.git-scripts-install/register.sh" "$GLOBAL_INSTALL_DIR/bin/"
    cp "$GIT_ANALYZER_HOME/.git-scripts-install/unregister.sh" "$GLOBAL_INSTALL_DIR/bin/"
    cp "$GIT_ANALYZER_HOME/.git-scripts-install/service-control.sh" "$GLOBAL_INSTALL_DIR/bin/"
    
    chmod +x "$GLOBAL_INSTALL_DIR/bin/"*.sh
    
    log_success "脚本安装完成"
}

add_to_path() {
    log_info "配置环境变量..."
    
    local shell_rc=""
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bash_profile"
    else
        shell_rc="$HOME/.profile"
    fi
    
    if ! grep -q "git-analyzer" "$shell_rc" 2>/dev/null; then
        echo "" >> "$shell_rc"
        echo "# Git 代码分析器" >> "$shell_rc"
        echo "export PATH=\"\$PATH:$GLOBAL_INSTALL_DIR/bin\"" >> "$shell_rc"
        echo "alias git-analyzer-start='bash $GLOBAL_INSTALL_DIR/bin/service-control.sh start'" >> "$shell_rc"
        echo "alias git-analyzer-stop='bash $GLOBAL_INSTALL_DIR/bin/service-control.sh stop'" >> "$shell_rc"
        echo "alias git-analyzer-status='bash $GLOBAL_INSTALL_DIR/bin/service-control.sh status'" >> "$shell_rc"
        echo "alias git-analyzer-list='bash $GLOBAL_INSTALL_DIR/bin/service-control.sh list'" >> "$shell_rc"
        log_success "已添加到 $shell_rc"
    else
        log_info "环境变量已配置"
    fi
}

create_readme() {
    log_info "创建说明文档..."
    
    cat > "$GLOBAL_INSTALL_DIR/README.md" << 'README_EOF'
# Git 代码分析器 - 全局版本 (观察者模式)

## 🎯 设计思想

采用**观察者模式**：
- **GitAnalyzer** 作为全局服务（观察者）
- **项目A/B/C** 通过注册/注销来订阅服务
- 所有分析日志集中存储在 GitAnalyzer 目录下

## 🚀 快速开始

### 1. 全局安装（仅需一次）

```bash
cd GitAnalyzer
bash .git-scripts-install/git-analyzer-global-installer-new.sh
source ~/.zshrc  # 重新加载配置
```

### 2. 在项目中注册

```bash
cd /path/to/your/project
register.sh  # 注册到 GitAnalyzer
```

### 3. 正常使用 Git

```bash
git add .
git commit -m "your message"
# 代码分析会自动在后台运行
```

### 4. 注销项目（可选）

```bash
cd /path/to/your/project
unregister.sh  # 从 GitAnalyzer 注销
```

## 🎮 全局服务控制

```bash
# 启动全局服务
git-analyzer-start

# 停止全局服务
git-analyzer-stop

# 查看服务状态
git-analyzer-status

# 列出所有已注册项目
git-analyzer-list
```

或直接使用脚本：

```bash
bash ~/.git-analyzer/bin/service-control.sh start
bash ~/.git-analyzer/bin/service-control.sh status
bash ~/.git-analyzer/bin/service-control.sh list
```

## 📁 目录结构

```
GitAnalyzer/                    # 全局服务主目录
├── .git-scripts/               # 核心分析脚本
├── .git-scripts-logs/          # 默认配置模板
├── 项目A/                      # 项目A的分析日志
│   ├── logs/
│   └── code_summaries/
├── 项目B/                      # 项目B的分析日志
│   ├── logs/
│   └── code_summaries/
└── ...

~/.git-analyzer/                # 全局安装目录
├── bin/                        # 可执行脚本
│   ├── register.sh
│   ├── unregister.sh
│   └── service-control.sh
└── config/                     # 全局配置
    ├── analyzer_home           # GitAnalyzer 主目录路径
    └── service_status          # 服务状态

项目A/                          # 你的实际项目
├── .git/
│   └── hooks/
│       └── post-commit         # Git 钩子
└── .git-scripts-logs/          # 项目本地配置
    └── .git-analyzer-config.json
```

## ⚙️ 工作原理

1. **全局安装**: 在 `~/.git-analyzer` 创建全局配置，记录 GitAnalyzer 主目录位置
2. **项目注册**: 在项目的 `.git/hooks/post-commit` 创建钩子，指向 GitAnalyzer 的分析脚本
3. **代码提交**: Git 钩子触发，调用 GitAnalyzer 的分析脚本
4. **日志存储**: 分析结果保存到 `GitAnalyzer/项目名/` 目录下

## 💡 优势

- ✅ **一次安装，全局共享**: 所有项目共用一套分析脚本
- ✅ **集中管理**: 所有项目的分析日志集中在 GitAnalyzer 目录
- ✅ **简单注册**: 项目中只需运行 `register.sh` 即可
- ✅ **易于维护**: 更新 GitAnalyzer 即可影响所有项目
- ✅ **干净隔离**: 项目目录保持干净，只有配置文件

## 🔧 配置

每个项目的配置文件位于: `项目根目录/.git-scripts-logs/.git-analyzer-config.json`

```json
{
  "enabled": true,
  "output_base_dir": "code_summaries",
  "gemini_model": "gemini-2.0-flash-exp",
  "max_diff_size": 50000,
  "timeout_seconds": 60
}
```

## 📊 查看日志

```bash
# 查看某个项目的分析日志
cd GitAnalyzer/项目A
ls -la code_summaries/
```
README_EOF
    
    log_success "说明文档创建完成: $GLOBAL_INSTALL_DIR/README.md"
}

main() {
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}   🚀 Git 代码分析器 - 全局安装 (观察者模式)${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    check_dependencies
    create_global_structure
    install_scripts
    add_to_path
    create_readme
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}   ✅ 全局安装完成！${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}📋 下一步操作：${NC}"
    echo ""
    echo "1️⃣  重新加载 shell 配置:"
    echo "   ${BLUE}source ~/.zshrc${NC}"
    echo ""
    echo "2️⃣  查看服务状态:"
    echo "   ${BLUE}git-analyzer-status${NC}"
    echo ""
    echo "3️⃣  在项目中注册:"
    echo "   ${BLUE}cd /path/to/your/project${NC}"
    echo "   ${BLUE}register.sh${NC}"
    echo ""
    echo "4️⃣  查看已注册项目:"
    echo "   ${BLUE}git-analyzer-list${NC}"
    echo ""
    echo -e "${BLUE}📖 详细文档: $GLOBAL_INSTALL_DIR/README.md${NC}"
    echo ""
}

main "$@"
