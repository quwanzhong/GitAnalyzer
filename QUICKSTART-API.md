# 🚀 GitAnalyzer 快速开始指南 (API Key 版本)

## 📋 前置要求

### macOS / Linux
- ✅ Git
- ✅ curl (通常已预装)
- ✅ jq - JSON 处理工具
  ```bash
  brew install jq
  ```

### Windows
- ✅ Git for Windows
- ✅ curl (随 Git for Windows 安装)
- ✅ PowerShell 5.0+

### 获取 Gemini API Key
1. 访问: https://aistudio.google.com/app/apikey
2. 登录 Google 账号
3. 点击 "Create API Key"
4. 复制生成的 API Key

---

## 🎯 安装步骤

### macOS / Linux

#### 1️⃣ 全局安装
```bash
cd /path/to/GitAnalyzer
bash .git-scripts-install/git-analyzer-global-installer.sh
source ~/.zshrc  # 或 ~/.bash_profile
```

#### 2️⃣ 启动服务
```bash
git-analyzer-start
```

#### 3️⃣ 注册项目
```bash
cd /path/to/your/project
register.sh
```

#### 4️⃣ 配置 API Key
编辑项目配置文件: `.git-scripts-logs/.git-analyzer-config.json`

```json
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
```

**如果在中国大陆,需要配置代理**:
```json
{
  "http_proxy": "http://127.0.0.1:7897",
  "https_proxy": "http://127.0.0.1:7897"
}
```

#### 5️⃣ 测试
```bash
git add .
git commit -m "test analyzer"
# 🚀 代码分析已在后台启动...
```

查看日志:
```bash
tail -f ~/GitAnalyzer/项目名/analyzer.log
```

---

### Windows

#### 1️⃣ 全局安装
```batch
cd C:\path\to\GitAnalyzer
.git-scripts-install-windows\git-analyzer-global-installer.bat
```
重新打开命令提示符或 PowerShell

#### 2️⃣ 启动服务
```batch
git-analyzer-start
```

#### 3️⃣ 注册项目
```batch
cd C:\path\to\your\project
register
```

#### 4️⃣ 配置 API Key
编辑项目配置文件: `.git-scripts-logs\.git-analyzer-config.json`

```json
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
```

#### 5️⃣ 测试
```batch
git add .
git commit -m "test analyzer"
REM 🚀 代码分析已在后台启动...
```

查看日志:
```batch
type %USERPROFILE%\GitAnalyzer\项目名\analyzer.log
```

---

## ⚙️ 配置说明

### 必填字段

| 字段 | 说明 | 示例 |
|------|------|------|
| `gemini_api_key` | Gemini API Key | `AIza...` |

### 可选字段

| 字段 | 说明 | 默认值 |
|------|------|--------|
| `enabled` | 是否启用分析 | `true` |
| `gemini_model` | 使用的模型 | `gemini-1.5-flash` |
| `max_diff_size` | 最大差异大小(字符) | `50000` |
| `timeout_seconds` | API 超时时间(秒) | `120` |
| `http_proxy` | HTTP 代理 | `""` |
| `https_proxy` | HTTPS 代理 | `""` |

### 可用模型

- `gemini-1.5-flash` - 推荐,速度快,免费额度高
- `gemini-1.5-pro` - 更强大,但较慢
- `gemini-2.0-flash-exp` - 实验性最新模型

---

## 🎮 常用命令

### 服务管理
```bash
git-analyzer-start    # 启动服务
git-analyzer-stop     # 停止服务
git-analyzer-status   # 查看状态
git-analyzer-list     # 列出已注册项目
```

### 项目管理
```bash
# 在项目目录中
register              # 注册项目
unregister            # 注销项目
```

---

## 📊 查看分析结果

### 日志位置

**macOS/Linux**:
```
~/GitAnalyzer/项目名/analyzer.log
~/GitAnalyzer/项目名/code_summaries/YYYYMM/DD/
```

**Windows**:
```
%USERPROFILE%\GitAnalyzer\项目名\analyzer.log
%USERPROFILE%\GitAnalyzer\项目名\code_summaries\YYYYMM\DD\
```

### 查看日志

**macOS/Linux**:
```bash
# 实时查看
tail -f ~/GitAnalyzer/项目名/analyzer.log

# 查看最近50行
tail -50 ~/GitAnalyzer/项目名/analyzer.log
```

**Windows**:
```batch
REM 查看全部
type %USERPROFILE%\GitAnalyzer\项目名\analyzer.log

REM 实时查看 (PowerShell)
Get-Content %USERPROFILE%\GitAnalyzer\项目名\analyzer.log -Wait -Tail 50
```

---

## ⚠️ 常见问题

### 1. API Key 无效

**症状**: 日志显示 "未配置 Gemini API Key" 或 API 调用失败

**解决方案**:
1. 检查配置文件中的 API Key 是否正确
2. 确认 API Key 没有多余的空格或引号
3. 访问 https://aistudio.google.com/app/apikey 重新生成

### 2. 代理不工作

**症状**: 日志显示连接超时或网络错误

**解决方案**:
1. 确认代理软件正在运行
2. 检查代理端口是否正确
3. 测试代理:
   ```bash
   # macOS/Linux
   curl -x http://127.0.0.1:7897 https://www.google.com
   
   # Windows
   curl -x http://127.0.0.1:7897 https://www.google.com
   ```

### 3. 分析报告未生成

**可能原因**:
- 服务未启动
- 项目配置中 `enabled` 为 false
- API Key 无效
- 网络连接问题

**解决方案**:
```bash
# 1. 检查服务状态
git-analyzer-status

# 2. 检查项目配置
cat .git-scripts-logs/.git-analyzer-config.json

# 3. 查看日志
tail -50 ~/GitAnalyzer/项目名/analyzer.log
```

### 4. 模型不可用 (404 错误)

**症状**: API 返回 404,提示模型不存在

**解决方案**:
1. 更换为稳定模型: `gemini-1.5-flash`
2. 查询可用模型:
   ```bash
   curl "https://generativelanguage.googleapis.com/v1/models?key=YOUR_API_KEY"
   ```

---

## 💡 最佳实践

### 1. API Key 安全

- ❌ 不要将 API Key 提交到 Git 仓库
- ✅ 将 `.git-scripts-logs/` 添加到 `.gitignore`
- ✅ 定期轮换 API Key

### 2. 代理配置

- 如果在中国大陆,强烈建议配置代理
- 使用稳定的代理服务,避免分析中断

### 3. 模型选择

- 日常使用: `gemini-1.5-flash` (快速,免费额度高)
- 重要分析: `gemini-1.5-pro` (更详细,但较慢)

### 4. 差异大小

- 建议保持单次提交差异在 50000 字符以内
- 大型重构建议分批提交

---

## 🔄 从旧版本迁移

如果你之前使用 Gemini CLI 版本:

1. **获取 API Key**: https://aistudio.google.com/app/apikey

2. **更新配置文件**:
   ```json
   {
     "gemini_api_key": "YOUR_API_KEY_HERE"
   }
   ```

3. **重新注册项目** (会自动使用新脚本):
   ```bash
   cd /path/to/project
   register.sh
   ```

4. **测试**:
   ```bash
   git commit --allow-empty -m "test new api"
   ```

---

## 📚 更多资源

- [完整文档](./README.md)
- [Windows 详细指南](./README-WINDOWS.md)
- [配置模板](./config-template.json)
- [Gemini API 文档](https://ai.google.dev/gemini-api/docs)

---

**开始使用 GitAnalyzer,让 AI 帮你分析每一次代码提交！** 🎉
