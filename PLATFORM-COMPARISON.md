# 跨平台实现对比

## 📊 功能对比

| 功能 | macOS | Windows | Linux |
|------|-------|---------|-------|
| 全局安装 | ✅ | ✅ | ✅ |
| 项目注册 | ✅ | ✅ | ✅ |
| 自动分析 | ✅ | ✅ | ✅ |
| 服务控制 | ✅ | ✅ | ✅ |
| 系统通知 | ✅ osascript | ✅ PowerShell | ⚠️ 需要配置 |
| JSON 解析 | jq (可选) | PowerShell | jq (可选) |
| 超时控制 | timeout/gtimeout | PowerShell Job | timeout |

## 🔧 技术实现差异

### 1. 脚本语言

**macOS/Linux**:
- Bash Shell (`.sh`)
- 原生 Unix 命令

**Windows**:
- Batch Script (`.bat`)
- PowerShell 辅助

### 2. 路径处理

**macOS/Linux**:
```bash
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
ANALYZER_HOME="$(cat ~/.git-analyzer/config/analyzer_home)"
```

**Windows**:
```batch
for /f "delims=" %%i in ('git rev-parse --show-toplevel') do set "PROJECT_ROOT=%%i"
set /p ANALYZER_HOME=<"%USERPROFILE%\.git-analyzer\config\analyzer_home"
```

### 3. JSON 解析

**macOS/Linux**:
```bash
# 使用 jq (如果可用)
ENABLED=$(jq -r '.enabled' "$CONFIG_FILE")

# 或使用 grep/sed 作为后备
```

**Windows**:
```batch
# 使用 PowerShell
for /f "delims=" %%i in ('powershell -Command "(Get-Content '%CONFIG_FILE%' | ConvertFrom-Json).enabled"') do set "ENABLED=%%i"
```

### 4. 超时控制

**macOS**:
```bash
# 使用 gtimeout (GNU coreutils) 或自定义实现
gtimeout 60 gemini chat < prompt.txt

# 或使用后台进程 + kill
gemini chat < prompt.txt &
pid=$!
# ... 超时检测逻辑
```

**Windows**:
```batch
# 使用 PowerShell Job
powershell -Command "$job = Start-Job -ScriptBlock { ... }; Wait-Job $job -Timeout 60"
```

### 5. 系统通知

**macOS**:
```bash
osascript -e "display notification \"$MESSAGE\" with title \"Git Analyzer\""
```

**Windows**:
```batch
powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $notification = New-Object System.Windows.Forms.NotifyIcon; ..."
```

### 6. 环境变量配置

**macOS/Linux**:
```bash
# 添加到 ~/.zshrc 或 ~/.bash_profile
echo "export PATH=\"\$PATH:$GLOBAL_INSTALL_DIR/bin\"" >> ~/.zshrc
```

**Windows**:
```batch
# 使用 PowerShell 修改用户 PATH
powershell -Command "[Environment]::SetEnvironmentVariable('Path', ...)"
```

## 🔄 跨平台钩子

Git post-commit 钩子自动检测操作系统:

```bash
#!/bin/bash

PROJECT_ROOT="$(git rev-parse --show-toplevel)"
ANALYZER_HOME="$(cat ~/.git-analyzer/config/analyzer_home 2>/dev/null)"

# 检测操作系统
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" || "$OSTYPE" == "cygwin" ]]; then
    # Windows 系统
    WRAPPER_SCRIPT="$ANALYZER_HOME/.git-scripts-install-windows/analyze_commit_wrapper.bat"
    cmd //c "\"$WRAPPER_SCRIPT\" \"$PROJECT_ROOT\" \"$DIFF_CONTENT\"" &
else
    # Mac/Linux 系统
    WRAPPER_SCRIPT="$ANALYZER_HOME/.git-scripts-install/analyze_commit_wrapper.sh"
    nohup bash "$WRAPPER_SCRIPT" "$PROJECT_ROOT" "$DIFF_CONTENT" > /dev/null 2>&1 &
fi

echo "🚀 代码分析已在后台启动..."
exit 0
```

## 📂 文件结构对比

### macOS/Linux 脚本目录
```
.git-scripts-install/
├── git-analyzer-global-installer.sh
├── register.sh
├── unregister.sh
├── service-control.sh
└── analyze_commit_wrapper.sh
```

### Windows 脚本目录
```
.git-scripts-install-windows/
├── git-analyzer-global-installer.bat
├── register.bat
├── unregister.bat
├── service-control.bat
└── analyze_commit_wrapper.bat
```

## 🎯 设计原则

1. **命令统一**: 所有平台使用相同的命令名称
   - `git-analyzer-start`
   - `git-analyzer-stop`
   - `git-analyzer-status`
   - `git-analyzer-list`
   - `register`
   - `unregister`

2. **配置兼容**: 所有平台使用相同的 JSON 配置格式

3. **日志统一**: 所有平台的日志格式和存储位置一致

4. **自动检测**: Git 钩子自动检测系统类型,无需用户干预

5. **独立维护**: Mac 和 Windows 版本完全独立,互不影响

## 🚀 优势

- ✅ **用户体验一致**: 所有平台使用相同的命令
- ✅ **团队协作友好**: 团队成员可以使用不同的操作系统
- ✅ **维护简单**: 各平台代码独立,修改不会相互影响
- ✅ **扩展性好**: 可以轻松添加新平台支持
- ✅ **无需重新注册**: 项目在不同平台间切换无需重新配置

## 📝 注意事项

### Windows 特殊说明

1. **Git Bash 推荐**: Windows 用户推荐使用 Git Bash 以获得最佳体验
2. **路径格式**: Windows 路径会自动转换 (如 `C:\path` 在 Git Bash 中为 `/c/path`)
3. **PowerShell 依赖**: 部分功能需要 PowerShell 5.0+
4. **执行策略**: 可能需要调整 PowerShell 执行策略

### macOS 特殊说明

1. **GNU Coreutils**: 可选安装 `brew install coreutils` 以获得 `gtimeout`
2. **系统通知**: 使用 `osascript` 实现原生通知
3. **Shell 配置**: 支持 zsh 和 bash

### Linux 特殊说明

1. **使用 Mac 脚本**: Linux 用户直接使用 `.git-scripts-install/` 下的脚本
2. **通知系统**: 可能需要安装 `notify-send` 或其他通知工具
3. **依赖安装**: 确保安装了 `timeout` 命令 (通常预装)

## 🔮 未来计划

- [ ] 添加 Linux 特定优化
- [ ] 支持更多 Shell (fish, nushell)
- [ ] 提供 Docker 容器版本
- [ ] 添加 CI/CD 集成支持
