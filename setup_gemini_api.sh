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
echo -e "${BLUE}║   直接使用 Gemini API - 配置向导         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}📝 这个方案的优势：${NC}"
echo "  ✅ 绕过 Gemini CLI 的代理问题"
echo "  ✅ 直接调用 REST API"
echo "  ✅ 完全支持代理"
echo "  ✅ 更稳定可靠"
echo ""

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# 获取 API Key
echo -e "${YELLOW}步骤 1: 获取 API Key${NC}"
echo ""
echo "1. 访问: https://aistudio.google.com/app/apikey"
echo "2. 点击 'Create API Key' 创建密钥"
echo "3. 复制 API Key"
echo ""

read -p "请输入你的 API Key: " API_KEY

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
    exit 1
fi

echo ""
echo -e "${YELLOW}步骤 3: 更新项目配置${NC}"

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
echo -e "${YELLOW}步骤 4: 更新分析脚本${NC}"

# 复制新的分析脚本
cp /Users/qwz/GitAnalyzer/.git-scripts-install/analyze_with_api.sh ~/.git-analyzer/bin/analyze_commit_wrapper.sh
chmod +x ~/.git-analyzer/bin/analyze_commit_wrapper.sh

echo -e "${GREEN}✅ 已更新分析脚本${NC}"

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ 配置完成！${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "现在可以测试了："
echo ""
echo "1. 在项目中做一次提交："
echo -e "   ${BLUE}cd /Users/qwz/yzkj/APP/clinicalbloodpda${NC}"
echo -e "   ${BLUE}echo '# 测试' >> README.md${NC}"
echo -e "   ${BLUE}git add . && git commit -m '测试直接API'${NC}"
echo ""
echo "2. 查看日志："
echo -e "   ${BLUE}tail -f ~/GitAnalyzer/clinicalbloodpda/analyzer.log${NC}"
echo ""
