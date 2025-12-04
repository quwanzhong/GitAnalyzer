#!/bin/bash

# ============================================
# Git 提交代码自动分析脚本 (Mac版本)
# 使用 Gemini CLI 进行代码分析
# ============================================

set -e  # 遇到错误立即退出

# 获取脚本所在目录的父目录（项目根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOGS_DIR="$PROJECT_ROOT/.git-scripts-logs"
CONFIG_FILE="$LOGS_DIR/.git-analyzer-config.json"
LOG_FILE="$LOGS_DIR/.git-analyzer.log"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================
# 日志函数
# ============================================
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

log_info() {
    log "INFO" "$@"
    echo -e "${BLUE}ℹ️  $@${NC}"
}

log_success() {
    log "SUCCESS" "$@"
    echo -e "${GREEN}✅ $@${NC}"
}

log_warning() {
    log "WARNING" "$@"
    echo -e "${YELLOW}⚠️  $@${NC}"
}

log_error() {
    log "ERROR" "$@"
    echo -e "${RED}❌ $@${NC}" >&2
}

# ============================================
# 检查配置文件是否存在
# ============================================
check_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "配置文件不存在: $CONFIG_FILE"
        log_error "请先创建配置文件"
        exit 1
    fi
}

# ============================================
# 读取配置
# ============================================
read_config() {
    if ! command -v jq &> /dev/null; then
        log_warning "jq 未安装，使用默认配置"
        ENABLED="true"
        OUTPUT_DIR="$PROJECT_ROOT/code_summaries"
        GEMINI_MODEL="gemini-2.0-flash-exp"
        return
    fi
    
    ENABLED=$(jq -r '.enabled' "$CONFIG_FILE")
    OUTPUT_DIR="$PROJECT_ROOT/$(jq -r '.output_base_dir' "$CONFIG_FILE")"
    GEMINI_MODEL=$(jq -r '.gemini_model' "$CONFIG_FILE")
    MAX_DIFF_SIZE=$(jq -r '.max_diff_size' "$CONFIG_FILE")
    TIMEOUT=$(jq -r '.timeout_seconds' "$CONFIG_FILE")
}

# ============================================
# 检查是否启用
# ============================================
check_enabled() {
    if [ "$ENABLED" != "true" ]; then
        log_info "代码分析功能已禁用，跳过分析"
        exit 0
    fi
}

# ============================================
# 检查 Gemini CLI 是否安装
# ============================================
check_gemini_cli() {
    if ! command -v gemini &> /dev/null; then
        log_error "Gemini CLI 未安装或不在 PATH 中"
        log_error "请先安装 Gemini CLI: https://ai.google.dev/gemini-api/docs/cli"
        exit 1
    fi
    log_info "Gemini CLI 检查通过"
}

# ============================================
# 检查网络连接
# ============================================
check_network() {
    if ! ping -c 1 8.8.8.8 &> /dev/null; then
        log_error "网络连接失败，请检查网络或代理设置"
        log_error "可能原因: 1) 网络断开 2) 代理未启动 3) 防火墙阻止"
        exit 1
    fi
    log_info "网络连接正常"
}

# ============================================
# 获取 Git 提交差异
# ============================================
get_commit_diff() {
    cd "$PROJECT_ROOT"
    
    # 检查是否在 Git 仓库中
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "当前目录不是 Git 仓库"
        exit 1
    fi
    
    # 获取提交信息
    COMMIT_HASH=$(git rev-parse HEAD)
    COMMIT_MESSAGE=$(git log -1 --pretty=%B)
    COMMIT_AUTHOR=$(git log -1 --pretty=%an)
    COMMIT_DATE=$(git log -1 --pretty=%ad --date=format:'%Y-%m-%d %H:%M:%S')
    
    log_info "提交哈希: $COMMIT_HASH"
    log_info "提交信息: $COMMIT_MESSAGE"
    
    # 获取差异
    DIFF_OUTPUT=$(git diff HEAD^ HEAD 2>&1)
    
    if [ -z "$DIFF_OUTPUT" ]; then
        log_warning "没有检测到代码变更，可能是首次提交或空提交"
        exit 0
    fi
    
    # 检查差异大小
    DIFF_SIZE=${#DIFF_OUTPUT}
    if [ $DIFF_SIZE -gt $MAX_DIFF_SIZE ]; then
        log_warning "代码差异过大 ($DIFF_SIZE 字符)，可能导致分析超时"
    fi
    
    log_info "成功获取代码差异 ($DIFF_SIZE 字符)"
}

# ============================================
# 使用 Gemini CLI 分析代码
# ============================================
analyze_with_gemini() {
    log_info "正在调用 Gemini API 进行分析..."
    
    # 创建临时文件存储 prompt
    TEMP_PROMPT=$(mktemp)
    
    cat > "$TEMP_PROMPT" << EOF
请分析以下 Git 提交的代码差异，并严格按照要求的 Markdown 格式输出。

**提交信息:**
- 提交哈希: $COMMIT_HASH
- 提交信息: $COMMIT_MESSAGE
- 提交作者: $COMMIT_AUTHOR
- 提交时间: $COMMIT_DATE

**输出格式要求 (严格遵守):**

# [简短功能标题，用于文件名，不超过50字符]

---

## ✨ 功能总结

[简明扼要地总结本次提交实现的功能，3-5句话]

## 🧠 AI 代码分析

### 代码质量
[评估代码质量、可读性、可维护性]

### 潜在问题
[指出可能存在的问题或风险]

### 最佳实践
[评估是否遵循最佳实践]

## 🚀 优化建议

[提供3-5条具体的、可操作的优化建议]

## 📝 变更文件列表

[列出本次提交涉及的主要文件]

---

**代码差异:**

\`\`\`diff
$DIFF_OUTPUT
\`\`\`
EOF
    
    # 调用 Gemini CLI (添加超时控制)
    if timeout $TIMEOUT gemini chat -m "$GEMINI_MODEL" < "$TEMP_PROMPT" > "$TEMP_PROMPT.result" 2>&1; then
        AI_RESULT=$(cat "$TEMP_PROMPT.result")
        rm -f "$TEMP_PROMPT" "$TEMP_PROMPT.result"
        
        if [ -z "$AI_RESULT" ]; then
            log_error "Gemini API 返回空结果"
            return 1
        fi
        
        log_success "AI 分析完成"
        return 0
    else
        local exit_code=$?
        rm -f "$TEMP_PROMPT" "$TEMP_PROMPT.result"
        
        if [ $exit_code -eq 124 ]; then
            log_error "Gemini API 调用超时 (>${TIMEOUT}秒)"
        else
            log_error "Gemini API 调用失败 (退出码: $exit_code)"
            log_error "可能原因: 1) API 密钥无效 2) 网络问题 3) 配额用尽"
        fi
        return 1
    fi
}

# ============================================
# 保存分析结果
# ============================================
save_result() {
    # 提取标题（第一行）
    TITLE=$(echo "$AI_RESULT" | grep -m 1 "^#" | sed 's/^# //' | sed 's/[^a-zA-Z0-9\u4e00-\u9fa5_-]/_/g' | cut -c1-50)
    
    if [ -z "$TITLE" ]; then
        TITLE="Commit_Summary_$(date +%H%M%S)"
        log_warning "无法提取标题，使用默认文件名: $TITLE"
    fi
    
    # 创建目录结构: 项目名/年月/日/
    PROJECT_NAME=$(basename "$PROJECT_ROOT")
    YEAR_MONTH=$(date +%Y%m)
    DAY=$(date +%d)
    
    SAVE_DIR="$OUTPUT_DIR/$PROJECT_NAME/$YEAR_MONTH/$DAY"
    mkdir -p "$SAVE_DIR"
    
    # 保存文件
    FILE_PATH="$SAVE_DIR/${TITLE}.md"
    
    # 如果文件已存在，添加时间戳
    if [ -f "$FILE_PATH" ]; then
        FILE_PATH="$SAVE_DIR/${TITLE}_$(date +%H%M%S).md"
    fi
    
    echo "$AI_RESULT" > "$FILE_PATH"
    
    log_success "分析结果已保存到: $FILE_PATH"
    
    # 显示通知（Mac 系统）
    if command -v osascript &> /dev/null; then
        osascript -e "display notification \"代码分析完成\" with title \"Git Analyzer\" subtitle \"$TITLE\""
    fi
}

# ============================================
# 主函数
# ============================================
main() {
    log_info "========== Git 代码分析开始 =========="
    
    # 1. 检查配置
    check_config
    read_config
    check_enabled
    
    # 2. 环境检查
    check_gemini_cli
    check_network
    
    # 3. 获取代码差异
    get_commit_diff
    
    # 4. AI 分析
    if ! analyze_with_gemini; then
        log_error "代码分析失败"
        exit 1
    fi
    
    # 5. 保存结果
    save_result
    
    log_success "========== Git 代码分析完成 =========="
}

# ============================================
# 错误处理
# ============================================
trap 'log_error "脚本执行过程中发生错误"; exit 1' ERR

# 执行主函数
main "$@"
