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

# 同步配置文件到所有注册项目
echo ""
log_info "开始同步配置文件到已注册项目..."

REGISTRY_FILE="$HOME/.git-analyzer/config/registered_projects.txt"
CONFIG_SOURCE="$ANALYZER_HOME/.git-scripts-logs/.git-analyzer-config.json"

if [ -f "$REGISTRY_FILE" ] && [ -f "$CONFIG_SOURCE" ]; then
    CONFIG_SYNCED=0
    CONFIG_FAILED=0
    
    while IFS= read -r project_path; do
        if [ -d "$project_path" ]; then
            CONFIG_TARGET="$project_path/.git-scripts-logs/.git-analyzer-config.json"
            
            # 创建目标目录
            mkdir -p "$(dirname "$CONFIG_TARGET")"
            
            # 如果目标配置存在，保留其 API 密钥
            if [ -f "$CONFIG_TARGET" ]; then
                # 读取目标配置的 API 密钥
                EXISTING_API_KEY=$(jq -r '.gemini_api_key' "$CONFIG_TARGET" 2>/dev/null || echo "")
                
                # 复制源配置
                if cp "$CONFIG_SOURCE" "$CONFIG_TARGET"; then
                    # 恢复原有的 API 密钥（如果存在且不为空）
                    if [ -n "$EXISTING_API_KEY" ] && [ "$EXISTING_API_KEY" != "null" ] && [ "$EXISTING_API_KEY" != "YOUR_API_KEY_HERE" ]; then
                        jq --arg api_key "$EXISTING_API_KEY" '.gemini_api_key = $api_key' "$CONFIG_TARGET" > "$CONFIG_TARGET.tmp" && mv "$CONFIG_TARGET.tmp" "$CONFIG_TARGET"
                    fi
                    log_success "已同步配置到: $(basename "$project_path")"
                    ((CONFIG_SYNCED++))
                else
                    log_error "配置同步失败: $(basename "$project_path")"
                    ((CONFIG_FAILED++))
                fi
            else
                # 目标配置不存在，直接复制
                if cp "$CONFIG_SOURCE" "$CONFIG_TARGET" ]; then
                    log_success "已同步配置到: $(basename "$project_path")"
                    ((CONFIG_SYNCED++))
                else
                    log_error "配置同步失败: $(basename "$project_path")"
                    ((CONFIG_FAILED++))
                fi
            fi
        fi
    done < "$REGISTRY_FILE"
    
    echo ""
    log_info "配置同步结果:"
    log_success "成功: $CONFIG_SYNCED 个项目"
    if [ $CONFIG_FAILED -gt 0 ]; then
        log_error "失败: $CONFIG_FAILED 个项目"
    fi
else
    if [ ! -f "$REGISTRY_FILE" ]; then
        log_warning "注册列表文件不存在，跳过配置同步"
    fi
    if [ ! -f "$CONFIG_SOURCE" ]; then
        log_warning "源配置文件不存在，跳过配置同步"
    fi
fi

echo ""
log_info "=========================================="

# 显示版本信息
if [ -f "$GLOBAL_BIN_DIR/register.sh" ]; then
    LINES=$(wc -l < "$GLOBAL_BIN_DIR/register.sh")
    log_info "register.sh: $LINES 行"
fi

echo ""
log_success "✨ 全局命令和配置已更新"
echo ""

# 自动重新加载 shell 配置
if [ -f "$HOME/.zshrc" ]; then
    log_info "正在重新加载 shell 配置..."
    source "$HOME/.zshrc"
    log_success "✅ shell 配置已重新加载，所有更改立即生效"
fi
echo ""
