#!/bin/bash

# ============================================
# Git 代码分析器 - 跨项目分析包装脚本
# 接收项目路径和差异内容作为参数
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

log_warning() {
    log "WARNING" "$@"
    echo -e "${YELLOW}⚠️  $@${NC}"
}

log_error() {
    log "ERROR" "$@"
    echo -e "${RED}❌ $@${NC}" >&2
}

# 检查配置文件
if [ ! -f "$CONFIG_FILE" ]; then
    log_error "配置文件不存在: $CONFIG_FILE"
    exit 1
fi

# 读取配置
if command -v jq &> /dev/null; then
    ENABLED=$(jq -r '.enabled' "$CONFIG_FILE")
    GEMINI_MODEL=$(jq -r '.gemini_model' "$CONFIG_FILE")
    MAX_DIFF_SIZE=$(jq -r '.max_diff_size' "$CONFIG_FILE")
    TIMEOUT=$(jq -r '.timeout_seconds' "$CONFIG_FILE")
else
    ENABLED="true"
    GEMINI_MODEL="gemini-2.0-flash-exp"
    MAX_DIFF_SIZE=50000
    TIMEOUT=60
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

# 跨平台超时函数
run_with_timeout() {
    local timeout_duration=$1
    shift
    local cmd="$@"
    
    # 检查是否有timeout命令（Linux）
    if command -v timeout &> /dev/null; then
        timeout "$timeout_duration" bash -c "$cmd"
        return $?
    # 检查是否有gtimeout命令（macOS with GNU coreutils）
    elif command -v gtimeout &> /dev/null; then
        gtimeout "$timeout_duration" bash -c "$cmd"
        return $?
    else
        # macOS原生方案：使用后台进程+sleep
        bash -c "$cmd" &
        local pid=$!
        local count=0
        
        while kill -0 $pid 2>/dev/null; do
            if [ $count -ge $timeout_duration ]; then
                kill -9 $pid 2>/dev/null
                wait $pid 2>/dev/null
                return 124  # timeout的标准退出码
            fi
            sleep 1
            ((count++))
        done
        
        wait $pid
        return $?
    fi
}

log_info "========== Git 代码分析开始 =========="
log_info "项目: $PROJECT_NAME"
log_info "项目路径: $PROJECT_ROOT"

# 检查 Gemini CLI
if ! command -v gemini &> /dev/null; then
    log_error "Gemini CLI 未安装"
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

# 如果没有传入差异内容，则获取
if [ -z "$DIFF_CONTENT" ]; then
    DIFF_CONTENT=$(git diff HEAD^ HEAD 2>/dev/null)
fi

if [ -z "$DIFF_CONTENT" ]; then
    log_warning "没有检测到代码变更"
    exit 0
fi

# 检查差异大小
DIFF_SIZE=${#DIFF_CONTENT}
log_info "代码差异大小: $DIFF_SIZE 字符"

if [ $DIFF_SIZE -gt $MAX_DIFF_SIZE ]; then
    log_warning "代码差异过大，可能导致分析超时"
fi

# 创建临时文件
TEMP_PROMPT=$(mktemp)

cat > "$TEMP_PROMPT" << EOF
请分析以下 Git 提交的代码差异，并严格按照要求的 Markdown 格式输出。

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
$DIFF_CONTENT
\`\`\`
EOF

log_info "正在调用 Gemini API 进行分析..."
log_info "使用模型: $GEMINI_MODEL"
log_info "超时设置: ${TIMEOUT}秒"
log_info "当前目录: $(pwd)"

# 切换到项目目录（Gemini CLI 建议在项目目录中运行）
cd "$PROJECT_ROOT"

# 重试机制
MAX_RETRIES=3
RETRY_COUNT=0
SUCCESS=false
AI_RESULT=""

while [ $RETRY_COUNT -lt $MAX_RETRIES ] && [ "$SUCCESS" = false ]; do
    if [ $RETRY_COUNT -gt 0 ]; then
        log_info "第 $((RETRY_COUNT + 1)) 次重试..."
        sleep 5  # 重试前等待5秒
    fi
    
    # 清理之前的临时文件
    rm -f "$TEMP_PROMPT.result" "$TEMP_PROMPT.error"
    
    # 直接调用 Gemini CLI，使用后台进程+超时控制
    gemini chat -m "$GEMINI_MODEL" < "$TEMP_PROMPT" > "$TEMP_PROMPT.result" 2> "$TEMP_PROMPT.error" &
    GEMINI_PID=$!
    
    # 超时控制
    COUNT=0
    TIMED_OUT=false
    
    while kill -0 $GEMINI_PID 2>/dev/null; do
        if [ $COUNT -ge $TIMEOUT ]; then
            log_warning "Gemini API 调用超时 (${TIMEOUT}秒) - 尝试 $((RETRY_COUNT + 1))/$MAX_RETRIES"
            kill -9 $GEMINI_PID 2>/dev/null
            wait $GEMINI_PID 2>/dev/null
            TIMED_OUT=true
            
            # 记录错误信息
            if [ -f "$TEMP_PROMPT.error" ] && [ -s "$TEMP_PROMPT.error" ]; then
                log_warning "错误详情:"
                head -n 5 "$TEMP_PROMPT.error" | while IFS= read -r line; do
                    log_warning "  $line"
                done
            fi
            break
        fi
        sleep 1
        ((COUNT++))
        
        # 每10秒显示一次进度
        if [ $((COUNT % 10)) -eq 0 ]; then
            log_info "已等待 ${COUNT} 秒..."
        fi
        
        # 早期错误检测：如果在前5秒内有错误输出，立即记录
        if [ $COUNT -le 5 ] && [ -f "$TEMP_PROMPT.error" ] && [ -s "$TEMP_PROMPT.error" ]; then
            log_warning "检测到早期错误输出:"
            head -n 10 "$TEMP_PROMPT.error" | while IFS= read -r line; do
                log_warning "  $line"
            done
        fi
    done
    
    # 如果没有超时，等待进程结束并获取退出码
    if [ "$TIMED_OUT" = false ]; then
        wait $GEMINI_PID
        EXIT_CODE=$?
        
        if [ $EXIT_CODE -eq 0 ]; then
            AI_RESULT=$(cat "$TEMP_PROMPT.result" 2>/dev/null)
            
            # 记录任何stderr输出（即使成功）
            if [ -f "$TEMP_PROMPT.error" ] && [ -s "$TEMP_PROMPT.error" ]; then
                log_warning "Gemini API 警告信息:"
                while IFS= read -r line; do
                    log_warning "  $line"
                done < "$TEMP_PROMPT.error"
            fi
            
            if [ -n "$AI_RESULT" ]; then
                SUCCESS=true
                log_success "AI 分析完成"
                break
            else
                log_warning "Gemini API 返回空结果 - 尝试 $((RETRY_COUNT + 1))/$MAX_RETRIES"
            fi
        else
            log_warning "Gemini API 调用失败 (退出码: $EXIT_CODE) - 尝试 $((RETRY_COUNT + 1))/$MAX_RETRIES"
            
            # 记录stderr内容
            if [ -f "$TEMP_PROMPT.error" ] && [ -s "$TEMP_PROMPT.error" ]; then
                log_warning "错误详情:"
                head -n 5 "$TEMP_PROMPT.error" | while IFS= read -r line; do
                    log_warning "  $line"
                done
            fi
        fi
    fi
    
    RETRY_COUNT=$((RETRY_COUNT + 1))
done

# 最终检查结果
if [ "$SUCCESS" = true ] && [ -n "$AI_RESULT" ]; then
    rm -f "$TEMP_PROMPT" "$TEMP_PROMPT.result" "$TEMP_PROMPT.error"
else
    log_error "Gemini API 调用最终失败，已重试 $MAX_RETRIES 次"
    
    # 最后一次记录完整错误
    if [ -f "$TEMP_PROMPT.error" ] && [ -s "$TEMP_PROMPT.error" ]; then
        log_error "最终错误详情:"
        while IFS= read -r line; do
            log_error "  $line"
        done < "$TEMP_PROMPT.error"
    fi
    
    # 记录stdout内容（可能包含部分响应）
    if [ -f "$TEMP_PROMPT.result" ] && [ -s "$TEMP_PROMPT.result" ]; then
        log_error "部分响应:"
        head -n 10 "$TEMP_PROMPT.result" | while IFS= read -r line; do
            log_error "  $line"
        done
    fi
    
    rm -f "$TEMP_PROMPT" "$TEMP_PROMPT.result" "$TEMP_PROMPT.error"
    exit 1
fi

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

exit 0
