#!/bin/bash

# ============================================
# 配置直接使用 Gemini API
# 绕过 Gemini CLI
# ============================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   直接使用 Gemini API - 配置向导       ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}📝 优势：${NC}"
# echo "  ✅ 绕过 Gemini CLI 的代理问题"
echo "  ✅ 直接调用 REST API"
echo "  ✅ 完全支持代理"
echo "  ✅ 更稳定可靠"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 检查是否已有配置
CONFIG_TEMPLATE="/Users/qwz/GitAnalyzer/.git-scripts-logs/.git-analyzer-config.json"
EXISTING_API_KEY=""

if [ -f "$CONFIG_TEMPLATE" ]; then
    EXISTING_API_KEY=$(jq -r '.gemini_api_key // ""' "$CONFIG_TEMPLATE" 2>/dev/null)
fi

# 获取 API Key
echo -e "${YELLOW}步骤 1: 配置 API Key${NC}"
echo ""

if [ -n "$EXISTING_API_KEY" ] && [ "$EXISTING_API_KEY" != "null" ]; then
    echo -e "${GREEN}✅ 检测到已配置的 API Key: ${EXISTING_API_KEY:0:20}...${NC}"
    API_KEY="$EXISTING_API_KEY"
    SKIP_INPUT=true
else
    echo "1. 访问: https://aistudio.google.com/app/apikey"
    echo "2. 点击 'Create API Key' 创建密钥"
    echo "3. 复制 API Key"
    echo ""
    read -p "请输入你的 API Key: " API_KEY
    SKIP_INPUT=false
fi

if [ -z "$API_KEY" ]; then
    echo -e "${RED}❌ API Key 不能为空${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}步骤 2: 测试 API Key${NC}"

# 设置代理
export http_proxy="http://127.0.0.1:7897"
export https_proxy="http://127.0.0.1:7897"

# 测试 API（使用 v1 API 和 gemini-2.0-flash 模型）
TEST_URL="https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=${API_KEY}"

TEMP_REQUEST=$(mktemp)
cat > "$TEMP_REQUEST" << 'EOF'
{
  "contents": [{
    "parts": [{ 
      "text": "你好，请简单回复"
    }]
  }]
}
EOF

echo "测试 API 连接..."
RESPONSE=$(curl -s -X POST "$TEST_URL" \
    -H "Content-Type: application/json" \
    -d @"$TEMP_REQUEST" \
    --connect-timeout 10 \
    --max-time 30)

rm -f "$TEMP_REQUEST"

if echo "$RESPONSE" | jq -e '.candidates[0].content.parts[0].text' > /dev/null 2>&1; then
    echo -e "${GREEN}✅ API Key 有效！${NC}"
    echo ""
    echo "API 响应:"
    echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text'
else
    echo -e "${RED}❌ API Key 无效或网络问题${NC}"
    echo ""
    echo "错误响应:"
    echo "$RESPONSE" | jq . 2>/dev/null || echo "$RESPONSE"
    
    # 如果是使用已有配置且失败，提示重新输入
    if [ "$SKIP_INPUT" = true ]; then
        echo ""
        echo -e "${YELLOW}⚠️  已保存的 API Key 无效，请重新输入${NC}"
        echo ""
        echo "1. 访问: https://aistudio.google.com/app/apikey"
        echo "2. 点击 'Create API Key' 创建密钥"
        echo "3. 复制 API Key"
        echo ""
        read -p "请输入新的 API Key: " API_KEY
        
        if [ -z "$API_KEY" ]; then
            echo -e "${RED}❌ API Key 不能为空${NC}"
            exit 1
        fi
        
        # 重新测试新的 API Key
        echo ""
        echo "重新测试 API 连接..."
        TEST_URL="https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=${API_KEY}"
        TEMP_REQUEST=$(mktemp)
        cat > "$TEMP_REQUEST" << 'EOF'
{
  "contents": [{
    "parts": [{ 
      "text": "你好，请简单回复"
    }]
  }]
}
EOF
        
        RESPONSE=$(curl -s -X POST "$TEST_URL" \
            -H "Content-Type: application/json" \
            -d @"$TEMP_REQUEST" \
            --connect-timeout 10 \
            --max-time 30)
        
        rm -f "$TEMP_REQUEST"
        
        if echo "$RESPONSE" | jq -e '.candidates[0].content.parts[0].text' > /dev/null 2>&1; then
            echo -e "${GREEN}✅ 新 API Key 有效！${NC}"
        else
            echo -e "${RED}❌ 新 API Key 仍然无效${NC}"
            exit 1
        fi
    else
        exit 1
    fi
fi

echo ""
echo -e "${YELLOW}步骤 3: 保存配置到模板${NC}"

# 更新配置模板
if [ -f "$CONFIG_TEMPLATE" ]; then
    # 备份原配置
    cp "$CONFIG_TEMPLATE" "${CONFIG_TEMPLATE}.backup"
    
    # 更新 API Key
    jq ".gemini_api_key = \"$API_KEY\"" "$CONFIG_TEMPLATE" > "${CONFIG_TEMPLATE}.tmp" && mv "${CONFIG_TEMPLATE}.tmp" "$CONFIG_TEMPLATE"
    
    echo -e "${GREEN}✅ 已保存 API Key 到配置模板${NC}"
else
    echo -e "${YELLOW}⚠️  配置模板不存在: $CONFIG_TEMPLATE${NC}"
fi

echo ""
echo -e "${YELLOW}步骤 4: 更新项目配置${NC}"

# 查找所有项目配置文件
ANALYZER_HOME="$(cat ~/.git-analyzer/config/analyzer_home 2>/dev/null)"

if [ -z "$ANALYZER_HOME" ]; then
    echo -e "${RED}❌ GitAnalyzer 未正确安装${NC}"
    exit 1
fi

# 更新 clinicalbloodpda 项目配置
CONFIG_FILE="/Users/qwz/yzkj/APP/clinicalbloodpda/.git-scripts-logs/.git-analyzer-config.json"

if [ -f "$CONFIG_FILE" ]; then
    # 备份原配置
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup"
    
    # 更新 API Key
    jq ".gemini_api_key = \"$API_KEY\"" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp" && mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    
    echo -e "${GREEN}✅ 已更新配置文件: $CONFIG_FILE${NC}"
else
    echo -e "${YELLOW}⚠️  配置文件不存在: $CONFIG_FILE${NC}"
fi

echo ""
echo -e "${YELLOW}步骤 5: 更新分析脚本${NC}"

# 复制新的分析脚本
cp /Users/qwz/GitAnalyzer/.git-scripts-install/analyze_with_api.sh ~/.git-analyzer/bin/analyze_commit_wrapper.sh
chmod +x ~/.git-analyzer/bin/analyze_commit_wrapper.sh
COMMENT

echo -e "${GREEN}✅ 已更新分析脚本${NC}"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 配置完成！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "配置已完成！现在可以在任何已注册的项目中提交代码，系统会自动分析。"
