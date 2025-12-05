#!/bin/bash

# ============================================
# 直接使用 Gemini API 进行分析
# 绕过 Gemini CLI，直接调用 REST API
# ============================================

set -e

# 参数
PROJECT_ROOT="${1:-$(git rev-parse --show-toplevel 2>/dev/null)}"
DIFF_CONTENT="${2:-$(git diff HEAD^ HEAD 2>/dev/null)}"

if [ -z "$PROJECT_ROOT" ]; then
    echo "错误: 无法确定项目根目录"
    exit 1
fi

# 获取 GitAnalyzer 主目录
ANALYZER_HOME="$(cat ~/.git-analyzer/config/analyzer_home 2>/dev/null)"
if [ -z "$ANALYZER_HOME" ]; then
    echo "错误: GitAnalyzer 未正确安装"
    exit 1
fi

# 项目信息
PROJECT_NAME="$(basename "$PROJECT_ROOT")"
PROJECT_LOGS_DIR="$ANALYZER_HOME/$PROJECT_NAME"
CONFIG_FILE="$PROJECT_ROOT/.git-scripts-logs/.git-analyzer-config.json"
LOG_FILE="$PROJECT_LOGS_DIR/analyzer.log"

# 创建项目日志目录
mkdir -p "$PROJECT_LOGS_DIR"
mkdir -p "$PROJECT_LOGS_DIR/logs"
mkdir -p "$PROJECT_LOGS_DIR/code_summaries"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

log_error() {
    log "ERROR" "$@"
    echo -e "${RED}❌ $@${NC}"
}

log_warning() {
    log "WARNING" "$@"
    echo -e "${YELLOW}⚠️  $@${NC}"
}

# 读取配置
if command -v jq &> /dev/null; then
    ENABLED=$(jq -r '.enabled' "$CONFIG_FILE")
    GEMINI_MODEL=$(jq -r '.gemini_model' "$CONFIG_FILE")
    MAX_DIFF_SIZE=$(jq -r '.max_diff_size' "$CONFIG_FILE")
    TIMEOUT=$(jq -r '.timeout_seconds' "$CONFIG_FILE")
    HTTP_PROXY=$(jq -r '.http_proxy // ""' "$CONFIG_FILE")
    HTTPS_PROXY=$(jq -r '.https_proxy // ""' "$CONFIG_FILE")
    GEMINI_API_KEY=$(jq -r '.gemini_api_key // ""' "$CONFIG_FILE")
else
    ENABLED="true"
    GEMINI_MODEL="gemini-1.5-flash"
    MAX_DIFF_SIZE=50000
    TIMEOUT=60
    HTTP_PROXY=""
    HTTPS_PROXY=""
    GEMINI_API_KEY=""
fi

# 设置代理（如果配置了）
if [ -n "$HTTP_PROXY" ]; then
    export http_proxy="$HTTP_PROXY"
    export HTTP_PROXY="$HTTP_PROXY"
    log_info "使用 HTTP 代理: $HTTP_PROXY"
fi

if [ -n "$HTTPS_PROXY" ]; then
    export https_proxy="$HTTPS_PROXY"
    export HTTPS_PROXY="$HTTPS_PROXY"
    log_info "使用 HTTPS 代理: $HTTPS_PROXY"
fi

# 检查是否启用
if [ "$ENABLED" != "true" ]; then
    log_info "代码分析功能已禁用，跳过分析"
    exit 0
fi

# 检查全局服务状态
SERVICE_STATUS=$(cat ~/.git-analyzer/config/service_status 2>/dev/null || echo "enabled")
if [ "$SERVICE_STATUS" != "enabled" ]; then
    log_info "全局服务已禁用，跳过分析"
    exit 0
fi

log_info "========== Git 代码分析开始 =========="
log_info "项目: $PROJECT_NAME"
log_info "项目路径: $PROJECT_ROOT"

# 检查 API Key
if [ -z "$GEMINI_API_KEY" ]; then
    log_error "未配置 Gemini API Key"
    log_error "请在配置文件中添加: gemini_api_key"
    exit 1
fi

# 获取提交信息
cd "$PROJECT_ROOT"
COMMIT_HASH=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
COMMIT_MESSAGE=$(git log -1 --pretty=%B 2>/dev/null || echo "unknown")
COMMIT_AUTHOR=$(git log -1 --pretty=%an 2>/dev/null || echo "unknown")
COMMIT_DATE=$(git log -1 --pretty=%ad --date=format:'%Y-%m-%d %H:%M:%S' 2>/dev/null || date '+%Y-%m-%d %H:%M:%S')

log_info "提交哈希: $COMMIT_HASH"
log_info "提交信息: $COMMIT_MESSAGE"

# 检查差异大小
if [ -z "$DIFF_CONTENT" ]; then
    log_warning "没有检测到代码变更"
    exit 0
fi

DIFF_SIZE=${#DIFF_CONTENT}
log_info "代码差异大小: $DIFF_SIZE 字符"

if [ $DIFF_SIZE -gt $MAX_DIFF_SIZE ]; then
    log_warning "代码差异过大，可能导致分析超时"
fi

# 创建 API 请求
log_info "正在调用 Gemini API 进行分析..."
log_info "使用模型: $GEMINI_MODEL"

# 构建 prompt
PROMPT="请分析以下 Git 提交的代码差异，并严格按照要求的 Markdown 格式输出。

**提交信息:**
- 项目名称: $PROJECT_NAME
- 提交哈希: $COMMIT_HASH
- 提交信息: $COMMIT_MESSAGE
- 提交作者: $COMMIT_AUTHOR
- 提交时间: $COMMIT_DATE

**输出格式要求 (严格遵守):**

# [简短功能标题，用于文件名，不超过50字符]

---

## ✨ 功能总结

[简明扰要地总结本次提交实现的功能，3-5句话]

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
$DIFF_CONTENT
\`\`\`"

# 调用 Gemini API（使用 v1beta API）
API_URL="https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent?key=${GEMINI_API_KEY}"

# 创建临时文件
TEMP_REQUEST=$(mktemp)
TEMP_RESPONSE=$(mktemp)

# 构建 JSON 请求
cat > "$TEMP_REQUEST" << EOF
{
  "contents": [{
    "parts": [{
      "text": $(echo "$PROMPT" | jq -Rs .)
    }]
  }]
}
EOF

# 发送请求
if curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d @"$TEMP_REQUEST" \
    --connect-timeout 30 \
    --max-time $TIMEOUT \
    -o "$TEMP_RESPONSE"; then
    
    # 解析响应
    AI_RESULT=$(jq -r '.candidates[0].content.parts[0].text' "$TEMP_RESPONSE" 2>/dev/null)
    
    if [ -n "$AI_RESULT" ] && [ "$AI_RESULT" != "null" ]; then
        log_success "AI 分析完成"
        
        # 提取标题
        TITLE=$(echo "$AI_RESULT" | grep -m 1 "^#" | sed 's/^# //' | sed 's/[^a-zA-Z0-9\u4e00-\u9fa5_-]/_/g' | cut -c1-50)
        
        if [ -z "$TITLE" ]; then
            TITLE="Commit_Summary_$(date +%H%M%S)"
        fi
        
        # 创建目录结构
        YEAR_MONTH=$(date +%Y%m)
        DAY=$(date +%d)
        SAVE_DIR="$PROJECT_LOGS_DIR/code_summaries/$YEAR_MONTH/$DAY"
        mkdir -p "$SAVE_DIR"
        
        # 保存文件
        FILE_PATH="$SAVE_DIR/${TITLE}.md"
        
        if [ -f "$FILE_PATH" ]; then
            FILE_PATH="$SAVE_DIR/${TITLE}_$(date +%H%M%S).md"
        fi
        
        echo "$AI_RESULT" > "$FILE_PATH"
        
        log_success "分析结果已保存到: $FILE_PATH"
        log_success "========== Git 代码分析完成 =========="
        
        # Mac 通知
        if command -v osascript &> /dev/null; then
            osascript -e "display notification \"项目: $PROJECT_NAME\" with title \"Git Analyzer\" subtitle \"$TITLE\"" 2>/dev/null || true
        fi
    else
        log_error "API 返回空结果或格式错误"
        log_error "响应内容: $(cat "$TEMP_RESPONSE")"
    fi
else
    log_error "API 调用失败"
fi

# 清理临时文件
rm -f "$TEMP_REQUEST" "$TEMP_RESPONSE"
