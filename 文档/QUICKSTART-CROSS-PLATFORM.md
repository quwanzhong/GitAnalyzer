# 🚀 跨平台快速开始指南

## 选择你的平台

- [macOS / Linux](#macos--linux)
- [Windows](#windows)

---

## macOS / Linux

### 1️⃣ 安装

```bash
cd /path/to/GitAnalyzer
bash .git-scripts-install/git-analyzer-global-installer.sh
source ~/.zshrc  # 或 ~/.bash_profile
```

### 2️⃣ 启动服务

```bash
git-analyzer-start
```

### 3️⃣ 注册项目

```bash
cd /path/to/your/project
register.sh
```

### 4️⃣ 提交代码

```bash
git add .
git commit -m "your message"
# 🚀 代码分析已在后台启动...
```

### 5️⃣ 查看结果

```bash
# 查看日志
tail -f ~/GitAnalyzer/项目名/analyzer.log

# 查看报告
ls ~/GitAnalyzer/项目名/code_summaries/
```

---

## Windows

### 1️⃣ 安装

```batch
cd C:\path\to\GitAnalyzer
.git-scripts-install-windows\git-analyzer-global-installer.bat
```

重新打开命令提示符或 PowerShell

### 2️⃣ 启动服务

```batch
git-analyzer-start
```

### 3️⃣ 注册项目

```batch
cd C:\path\to\your\project
register
```

### 4️⃣ 提交代码

```batch
git add .
git commit -m "your message"
REM 🚀 代码分析已在后台启动...
```

### 5️⃣ 查看结果

```batch
REM 查看日志
type %USERPROFILE%\GitAnalyzer\项目名\analyzer.log

REM 查看报告
dir %USERPROFILE%\GitAnalyzer\项目名\code_summaries
```

---

## 🎮 通用命令 (所有平台)

### 服务管理

```bash
git-analyzer-start    # 启动服务
git-analyzer-stop     # 停止服务
git-analyzer-status   # 查看状态
git-analyzer-list     # 列出项目
```

### 项目管理

```bash
# 在项目目录中
register              # 注册项目
unregister            # 注销项目
```

---

## ⚙️ 配置文件

所有平台使用相同的配置格式:

**位置**: `项目根目录/.git-scripts-logs/.git-analyzer-config.json`

```json
{
  "enabled": true,
  "output_base_dir": "code_summaries",
  "gemini_model": "gemini-2.0-flash-exp",
  "max_diff_size": 50000,
  "timeout_seconds": 60
}
```

---

## 🔧 前置要求

### macOS / Linux

- ✅ Git
- ✅ Bash
- ✅ Gemini CLI: `brew install gemini-cli` 或 `npm install -g @google/generative-ai-cli`
- ✅ 认证: `gemini auth`

### Windows

- ✅ Git for Windows
- ✅ Gemini CLI: `npm install -g @google/generative-ai-cli`
- ✅ 认证: `gemini auth`
- ✅ PowerShell 5.0+

---

## 🌟 跨平台特性

### 自动系统检测

Git 钩子会自动检测你的操作系统:

- 在 **Windows** 上自动调用 `.bat` 脚本
- 在 **macOS/Linux** 上自动调用 `.sh` 脚本

### 团队协作

团队成员可以使用不同的操作系统:

```
团队成员 A (macOS)  ──┐
                      ├──> 同一个 Git 仓库
团队成员 B (Windows) ─┘

✅ 无需额外配置
✅ 自动适配各自的系统
✅ 分析结果格式统一
```

### 系统切换

在不同系统间切换项目:

```bash
# 在 macOS 上开发
git commit -m "feature A"  # ✅ 使用 .sh 脚本

# 切换到 Windows
git pull
git commit -m "feature B"  # ✅ 自动使用 .bat 脚本
```

---

## 📊 查看分析结果

### 日志位置

**macOS/Linux**:
```
~/GitAnalyzer/项目名/analyzer.log
~/GitAnalyzer/项目名/code_summaries/
```

**Windows**:
```
%USERPROFILE%\GitAnalyzer\项目名\analyzer.log
%USERPROFILE%\GitAnalyzer\项目名\code_summaries\
```

### 报告结构

```
code_summaries/
└── YYYYMM/          # 年月
    └── DD/          # 日
        └── 功能标题.md
```

---

## ⚠️ 常见问题

### 命令找不到

**macOS/Linux**:
```bash
source ~/.zshrc
# 或使用完整路径
bash ~/.git-analyzer/bin/service-control.sh status
```

**Windows**:
```batch
REM 重新打开终端
REM 或使用完整路径
%USERPROFILE%\.git-analyzer\bin\service-control.bat status
```

### Git 钩子不执行

**检查步骤**:
1. 确认已注册: `git-analyzer-list`
2. 检查钩子: `cat .git/hooks/post-commit` (Mac/Linux) 或 `type .git\hooks\post-commit` (Windows)
3. 查看日志: 检查 analyzer.log

### Gemini API 失败

**解决方案**:
```bash
# 重新认证
gemini auth

# 测试连接
echo "Hello" | gemini chat --no-stream
```

---

## 📚 更多文档

- [完整文档](./README.md)
- [Windows 详细指南](./README-WINDOWS.md)
- [平台对比](./PLATFORM-COMPARISON.md)
- [实现细节](./IMPLEMENTATION.md)

---

## 🎉 开始使用

选择你的平台,按照上面的步骤操作,几分钟内即可开始使用 GitAnalyzer！

**祝你编码愉快！** 🚀
