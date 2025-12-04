#!/bin/bash

# ============================================
# GitAnalyzer 快速测试脚本
# 测试整个系统是否正常工作
# ============================================

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   GitAnalyzer 系统测试                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# 1. 检查全局安装
echo -e "${YELLOW}1. 检查全局安装...${NC}"
if [ -d ~/.git-analyzer ]; then
    echo -e "${GREEN}✅ 全局目录存在${NC}"
else
    echo -e "${RED}❌ 全局目录不存在${NC}"
    exit 1
fi

# 2. 检查全局命令
echo ""
echo -e "${YELLOW}2. 检查全局命令...${NC}"
for cmd in git-analyzer-start git-analyzer-stop git-analyzer-status git-analyzer-list; do
    if command -v $cmd &> /dev/null; then
        echo -e "${GREEN}✅ $cmd${NC}"
    else
        echo -e "${RED}❌ $cmd 不可用${NC}"
    fi
done

# 3. 检查服务状态
echo ""
echo -e "${YELLOW}3. 检查服务状态...${NC}"
git-analyzer-status

# 4. 检查项目配置
echo ""
echo -e "${YELLOW}4. 检查项目配置...${NC}"
CONFIG_FILE="/Users/qwz/yzkj/APP/clinicalbloodpda/.git-scripts-logs/.git-analyzer-config.json"
if [ -f "$CONFIG_FILE" ]; then
    echo -e "${GREEN}✅ 配置文件存在${NC}"
    echo ""
    echo "配置内容："
    cat "$CONFIG_FILE" | jq .
    
    # 检查 API Key
    API_KEY=$(jq -r '.gemini_api_key' "$CONFIG_FILE")
    if [ -n "$API_KEY" ] && [ "$API_KEY" != "YOUR_API_KEY_HERE" ]; then
        echo -e "${GREEN}✅ API Key 已配置${NC}"
    else
        echo -e "${RED}❌ API Key 未配置${NC}"
    fi
else
    echo -e "${RED}❌ 配置文件不存在${NC}"
fi

# 5. 测试代理
echo ""
echo -e "${YELLOW}5. 测试代理连接...${NC}"
export http_proxy="http://127.0.0.1:7897"
export https_proxy="http://127.0.0.1:7897"

if curl -s --connect-timeout 5 https://www.google.com > /dev/null 2>&1; then
    echo -e "${GREEN}✅ 代理连接正常${NC}"
else
    echo -e "${RED}❌ 代理连接失败${NC}"
fi

# 6. 测试 API
echo ""
echo -e "${YELLOW}6. 测试 Gemini API...${NC}"
if [ -n "$API_KEY" ] && [ "$API_KEY" != "YOUR_API_KEY_HERE" ]; then
    TEST_URL="https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=${API_KEY}"
    
    TEMP_REQUEST=$(mktemp)
    cat > "$TEMP_REQUEST" << 'EOF'
{
  "contents": [{
    "parts": [{
      "text": "测试"
    }]
  }]
}
EOF
    
    if curl -s -X POST "$TEST_URL" \
        -H "Content-Type: application/json" \
        -d @"$TEMP_REQUEST" \
        --connect-timeout 10 \
        --max-time 30 | jq -e '.candidates[0].content.parts[0].text' > /dev/null 2>&1; then
        echo -e "${GREEN}✅ API 连接正常${NC}"
    else
        echo -e "${RED}❌ API 连接失败${NC}"
    fi
    
    rm -f "$TEMP_REQUEST"
else
    echo -e "${YELLOW}⚠️  跳过（API Key 未配置）${NC}"
fi

# 7. 总结
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}测试完成！${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo "下一步："
echo "1. 如果 API Key 未配置，运行: ./setup_gemini_api.sh"
echo "2. 在项目中测试提交: cd /Users/qwz/yzkj/APP/clinicalbloodpda && git commit --allow-empty -m '测试'"
echo "3. 查看日志: tail -f ~/GitAnalyzer/clinicalbloodpda/analyzer.log"
echo ""
