# Git 代码分析器 - Windows 安装指南

## 🎯 系统要求

- ✅ Windows 10/11
- ✅ Git for Windows
- ✅ PowerShell 5.0+ 或 Git Bash
- ✅ 代理软件（如果在中国大陆）

## 📦 安装步骤

### 步骤 1: 安装依赖

#### 1.1 安装 Git for Windows

如果尚未安装 Git:

```batch
# 下载并安装
https://git-scm.com/download/win
```

#### 1.2 准备 API Key

访问 [Google AI Studio](https://aistudio.google.com/app/apikey) 获取 Gemini API Key。

### 步骤 2: 配置 Gemini API

在开始使用前，需要配置 Gemini API Key：

```batch
# 运行配置向导（在 Git Bash 中）
cd C:\path\to\GitAnalyzer
./setup_gemini_api.sh
```

**配置向导会：**
1. 提示你输入 API Key（从 https://aistudio.google.com/app/apikey 获取）
2. 自动测试 API Key 是否有效
3. 更新项目配置文件
4. 部署新的分析脚本

**手动配置方式：**
如果配置向导不可用，你可以手动创建项目配置文件：
```batch
REM 在项目根目录创建配置文件
mkdir .git-scripts-logs
echo { > .git-scripts-logs\.git-analyzer-config.json
echo   "enabled": true, >> .git-scripts-logs\.git-analyzer-config.json
echo   "output_base_dir": "code_summaries", >> .git-scripts-logs\.git-analyzer-config.json
echo   "gemini_model": "gemini-2.0-flash", >> .git-scripts-logs\.git-analyzer-config.json
echo   "gemini_api_key": "YOUR_API_KEY_HERE", >> .git-scripts-logs\.git-analyzer-config.json
echo   "max_diff_size": 50000, >> .git-scripts-logs\.git-analyzer-config.json
echo   "timeout_seconds": 120, >> .git-scripts-logs\.git-analyzer-config.json
echo   "http_proxy": "http://127.0.0.1:7897", >> .git-scripts-logs\.git-analyzer-config.json
echo   "https_proxy": "http://127.0.0.1:7897" >> .git-scripts-logs\.git-analyzer-config.json
echo } >> .git-scripts-logs\.git-analyzer-config.json
```

### 步骤 3: 全局安装 GitAnalyzer

```batch
# 在 GitAnalyzer 目录中运行
cd C:\path\to\GitAnalyzer
.git-scripts-install-windows\git-analyzer-global-installer.bat

# 重新打开命令提示符或 PowerShell
```

### 步骤 4: 在项目中注册

```batch
# 进入你的项目目录
cd C:\path\to\your\project

# 注册到 GitAnalyzer
register
```

### 步骤 5: 启动服务

```batch
git-analyzer-start
```

## 🎮 常用命令

### 服务管理

```batch
git-analyzer-start    # 启动服务
git-analyzer-stop     # 停止服务
git-analyzer-status   # 查看状态
git-analyzer-list     # 列出已注册项目
```

### 项目管理

```batch
# 注册项目
cd C:\path\to\project
register

# 注销项目
cd C:\path\to\project
unregister
```

## 📁 目录结构

```
GitAnalyzer\                    # 全局服务主目录
├── .git-scripts\               # Mac 核心分析脚本
├── .git-scripts-install\       # Mac 安装脚本
├── .git-scripts-install-windows\  # Windows 安装脚本
│   ├── analyze_commit_wrapper.bat
│   ├── service-control.bat
│   ├── git-analyzer-global-installer.bat
│   ├── register.bat
│   └── unregister.bat
├── 项目A\                      # 项目A的分析日志
│   ├── logs\
│   └── code_summaries\
└── ...

%USERPROFILE%\.git-analyzer\    # 全局安装目录
├── bin\                        # 可执行脚本
│   ├── register.bat
│   ├── unregister.bat
│   ├── service-control.bat
│   ├── git-analyzer-start.bat
│   ├── git-analyzer-stop.bat
│   ├── git-analyzer-status.bat
│   └── git-analyzer-list.bat
└── config\                     # 全局配置
    ├── analyzer_home           # GitAnalyzer 主目录路径
    └── service_status          # 服务状态

项目A\                          # 你的实际项目
├── .git\
│   └── hooks\
│       └── post-commit         # Git 钩子 (跨平台)
└── .git-scripts-logs\          # 项目本地配置
    └── .git-analyzer-config.json
```

## ⚙️ 配置文件

配置文件位置：`项目根目录\.git-scripts-logs\.git-analyzer-config.json`

```json
{
  "enabled": true,
  "output_base_dir": "code_summaries",
  "gemini_model": "gemini-2.0-flash-exp",
  "max_diff_size": 50000,
  "timeout_seconds": 60
}
```

## 🔧 跨平台支持

Git 钩子会自动检测操作系统:

- **Windows**: 调用 `.git-scripts-install-windows\` 下的 `.bat` 脚本
- **Mac/Linux**: 调用 `.git-scripts-install\` 下的 `.sh` 脚本

这意味着:
- ✅ 同一个项目可以在 Windows 和 Mac 之间切换使用
- ✅ 团队成员可以使用不同的操作系统
- ✅ 所有命令保持一致

## 📊 查看分析结果

### 查看日志

```batch
# 实时查看日志
type %USERPROFILE%\GitAnalyzer\项目名\analyzer.log

# 或使用 PowerShell
Get-Content %USERPROFILE%\GitAnalyzer\项目名\analyzer.log -Tail 50
```

### 查看分析报告

```batch
# 查看报告目录
dir %USERPROFILE%\GitAnalyzer\项目名\code_summaries

# 查看最新报告
dir %USERPROFILE%\GitAnalyzer\项目名\code_summaries /s /o-d
```

## ⚠️ 常见问题

### 问题 1: 命令找不到

**症状**: 运行 `git-analyzer-start` 提示命令不存在

**解决方案**:
1. 重新打开命令提示符或 PowerShell
2. 检查环境变量是否包含 `%USERPROFILE%\.git-analyzer\bin`
3. 手动添加到 PATH:
   - 右键 "此电脑" > "属性"
   - "高级系统设置" > "环境变量"
   - 在用户变量的 Path 中添加: `%USERPROFILE%\.git-analyzer\bin`

### 问题 2: Git 钩子不执行

**症状**: 提交代码后没有触发分析

**解决方案**:
1. 确认使用 Git Bash 或支持 bash 的终端
2. 检查钩子文件是否存在: `.git\hooks\post-commit`
3. 在 Git Bash 中测试钩子:
   ```bash
   bash .git/hooks/post-commit
   ```

### 问题 3: PowerShell 执行策略限制

**症状**: PowerShell 提示无法执行脚本

**解决方案**:
```powershell
# 以管理员身份运行 PowerShell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 问题 4: Gemini CLI 认证失败

**症状**: 提示认证错误

**解决方案**:
```batch
# 重新认证
gemini auth

# 测试连接
echo 你好 | gemini chat --no-stream
```

### 问题 5: 中文路径问题

**症状**: 路径包含中文时出错

**解决方案**:
- 建议使用英文路径
- 或确保使用 UTF-8 编码:
  ```batch
  chcp 65001
  ```

## 💡 使用建议

### 推荐终端

1. **Git Bash** (推荐) - 完全兼容 bash 脚本
2. **PowerShell** - 支持所有功能
3. **Windows Terminal** - 现代化终端体验
4. **CMD** - 基本功能支持

### 性能优化

1. **排除杀毒软件扫描**:
   - 将 `%USERPROFILE%\.git-analyzer` 添加到杀毒软件白名单
   - 将项目目录添加到白名单

2. **使用 SSD**:
   - 将 GitAnalyzer 和项目放在 SSD 上以提高性能

3. **代理设置**:
   - 如果在中国大陆,需要配置代理访问 Gemini API
   - 在配置文件中添加代理设置

## 🔄 从 Mac 迁移

如果你之前在 Mac 上使用 GitAnalyzer:

1. **同步 GitAnalyzer 目录**:
   ```batch
   # 使用 Git 或云同步工具同步整个 GitAnalyzer 目录
   ```

2. **重新安装**:
   ```batch
   cd GitAnalyzer
   .git-scripts-install-windows\git-analyzer-global-installer.bat
   ```

3. **项目自动兼容**:
   - 已注册的项目会自动检测 Windows 系统
   - 无需重新注册

## 📚 更多资源

- [主文档](./如何使用.md)
- [实现细节](./IMPLEMENTATION.md)
- [快速开始](./QUICKSTART.md)
- [Gemini CLI 文档](https://ai.google.dev/gemini-api/docs/cli)

## 🆘 获取帮助

如果遇到问题:

1. 查看日志文件: `%USERPROFILE%\GitAnalyzer\项目名\analyzer.log`
2. 检查配置文件: `项目\.git-scripts-logs\.git-analyzer-config.json`
3. 运行诊断: `git-analyzer-status`
4. 查看已注册项目: `git-analyzer-list`
