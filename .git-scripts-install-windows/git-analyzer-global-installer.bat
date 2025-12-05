@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

REM ============================================
REM Git 代码分析器全局安装脚本 (Windows 版本 - 观察者模式)
REM GitAnalyzer 作为全局服务,项目通过注册/注销来订阅服务
REM ============================================

set "GIT_ANALYZER_HOME=%~dp0\.."
set "GLOBAL_INSTALL_DIR=%USERPROFILE%\.git-analyzer"

echo.
echo ============================================
echo    Git 代码分析器 - 全局安装 (观察者模式)
echo ============================================
echo.

call :check_dependencies
call :create_global_structure
call :install_scripts
call :add_to_path
call :create_readme

echo.
echo ============================================
echo    ✓ 全局安装完成！
echo ============================================
echo.
echo 下一步操作：
echo.
echo 1. 重新打开命令提示符或 PowerShell
echo.
echo 2. 查看服务状态:
echo    git-analyzer-status
echo.
echo 3. 在项目中注册:
echo    cd C:\path\to\your\project
echo    register
echo.
echo 4. 查看已注册项目:
echo    git-analyzer-list
echo.
echo 详细文档: %GLOBAL_INSTALL_DIR%\README.md
echo.
pause
exit /b 0

REM ============================================
REM 函数定义
REM ============================================

:check_dependencies
call :log_info "检查依赖..."

where curl >nul 2>&1
if errorlevel 1 (
    call :log_error "curl 未安装，请先安装 curl"
    echo.
    echo curl 通常随 Git for Windows 一起安装
    echo 如果未安装，请下载: https://curl.se/windows/
    echo.
    pause
    exit /b 1
)

where git >nul 2>&1
if errorlevel 1 (
    call :log_error "Git 未安装，请先安装 Git"
    echo.
    echo 下载地址: https://git-scm.com/download/win
    echo.
    pause
    exit /b 1
)

where powershell >nul 2>&1
if errorlevel 1 (
    call :log_error "PowerShell 未安装，请安装 PowerShell 5.0+"
    pause
    exit /b 1
)

call :log_success "依赖检查完成"
exit /b 0

:create_global_structure
call :log_info "创建全局目录结构..."

if not exist "%GLOBAL_INSTALL_DIR%" mkdir "%GLOBAL_INSTALL_DIR%"
if not exist "%GLOBAL_INSTALL_DIR%\bin" mkdir "%GLOBAL_INSTALL_DIR%\bin"
if not exist "%GLOBAL_INSTALL_DIR%\config" mkdir "%GLOBAL_INSTALL_DIR%\config"

echo %GIT_ANALYZER_HOME% > "%GLOBAL_INSTALL_DIR%\config\analyzer_home"
echo enabled > "%GLOBAL_INSTALL_DIR%\config\service_status"

call :log_success "全局目录结构创建完成: %GLOBAL_INSTALL_DIR%"
exit /b 0

:install_scripts
call :log_info "安装脚本到全局目录..."

copy /Y "%GIT_ANALYZER_HOME%\.git-scripts-install-windows\register.bat" "%GLOBAL_INSTALL_DIR%\bin\" >nul
copy /Y "%GIT_ANALYZER_HOME%\.git-scripts-install-windows\unregister.bat" "%GLOBAL_INSTALL_DIR%\bin\" >nul
copy /Y "%GIT_ANALYZER_HOME%\.git-scripts-install-windows\service-control.bat" "%GLOBAL_INSTALL_DIR%\bin\" >nul

call :log_success "脚本安装完成"
exit /b 0

:add_to_path
call :log_info "配置环境变量..."

REM 检查是否已添加到 PATH
echo %PATH% | findstr /i "%GLOBAL_INSTALL_DIR%\bin" >nul
if not errorlevel 1 (
    call :log_info "环境变量已配置"
    exit /b 0
)

REM 使用 PowerShell 添加到用户 PATH
powershell -Command "[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path', 'User') + ';%GLOBAL_INSTALL_DIR%\bin', 'User')" >nul 2>&1

if errorlevel 1 (
    call :log_warning "自动添加环境变量失败，请手动添加："
    echo.
    echo 1. 右键 "此电脑" ^> "属性"
    echo 2. 点击 "高级系统设置"
    echo 3. 点击 "环境变量"
    echo 4. 在 "用户变量" 中找到 "Path"
    echo 5. 添加: %GLOBAL_INSTALL_DIR%\bin
    echo.
) else (
    call :log_success "已添加到环境变量"
)

REM 创建命令别名脚本
call :create_aliases

exit /b 0

:create_aliases
REM 创建 CMD 批处理别名
echo @echo off > "%GLOBAL_INSTALL_DIR%\bin\git-analyzer-start.bat"
echo call "%GLOBAL_INSTALL_DIR%\bin\service-control.bat" start >> "%GLOBAL_INSTALL_DIR%\bin\git-analyzer-start.bat"

echo @echo off > "%GLOBAL_INSTALL_DIR%\bin\git-analyzer-stop.bat"
echo call "%GLOBAL_INSTALL_DIR%\bin\service-control.bat" stop >> "%GLOBAL_INSTALL_DIR%\bin\git-analyzer-stop.bat"

echo @echo off > "%GLOBAL_INSTALL_DIR%\bin\git-analyzer-status.bat"
echo call "%GLOBAL_INSTALL_DIR%\bin\service-control.bat" status >> "%GLOBAL_INSTALL_DIR%\bin\git-analyzer-status.bat"

echo @echo off > "%GLOBAL_INSTALL_DIR%\bin\git-analyzer-list.bat"
echo call "%GLOBAL_INSTALL_DIR%\bin\service-control.bat" list >> "%GLOBAL_INSTALL_DIR%\bin\git-analyzer-list.bat"

REM 创建 PowerShell 别名配置
set "PS_PROFILE=%USERPROFILE%\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
if not exist "%USERPROFILE%\Documents\WindowsPowerShell" mkdir "%USERPROFILE%\Documents\WindowsPowerShell"

findstr /i "git-analyzer" "%PS_PROFILE%" >nul 2>&1
if errorlevel 1 (
    echo. >> "%PS_PROFILE%"
    echo # Git Analyzer Aliases >> "%PS_PROFILE%"
    echo function git-analyzer-start { ^& "%GLOBAL_INSTALL_DIR%\bin\service-control.bat" start } >> "%PS_PROFILE%"
    echo function git-analyzer-stop { ^& "%GLOBAL_INSTALL_DIR%\bin\service-control.bat" stop } >> "%PS_PROFILE%"
    echo function git-analyzer-status { ^& "%GLOBAL_INSTALL_DIR%\bin\service-control.bat" status } >> "%PS_PROFILE%"
    echo function git-analyzer-list { ^& "%GLOBAL_INSTALL_DIR%\bin\service-control.bat" list } >> "%PS_PROFILE%"
)

exit /b 0

:create_readme
call :log_info "创建说明文档..."

(
echo # Git 代码分析器 - 全局版本 ^(观察者模式^) - Windows
echo.
echo ## 🎯 设计思想
echo.
echo 采用**观察者模式**：
echo - **GitAnalyzer** 作为全局服务（观察者）
echo - **项目A/B/C** 通过注册/注销来订阅服务
echo - 所有分析日志集中存储在 GitAnalyzer 目录下
echo.
echo ## 🚀 快速开始
echo.
echo ### 1. 全局安装（仅需一次）
echo.
echo ```batch
echo cd GitAnalyzer
echo .git-scripts-install-windows\git-analyzer-global-installer.bat
echo ```
echo.
echo ### 2. 在项目中注册
echo.
echo ```batch
echo cd C:\path\to\your\project
echo register
echo ```
echo.
echo ### 3. 正常使用 Git
echo.
echo ```batch
echo git add .
echo git commit -m "your message"
echo # 代码分析会自动在后台运行
echo ```
echo.
echo ### 4. 注销项目（可选）
echo.
echo ```batch
echo cd C:\path\to\your\project
echo unregister
echo ```
echo.
echo ## 🎮 全局服务控制
echo.
echo ```batch
echo # 启动全局服务
echo git-analyzer-start
echo.
echo # 停止全局服务
echo git-analyzer-stop
echo.
echo # 查看服务状态
echo git-analyzer-status
echo.
echo # 列出所有已注册项目
echo git-analyzer-list
echo ```
echo.
echo ## 📁 目录结构
echo.
echo ```
echo GitAnalyzer\                    # 全局服务主目录
echo ├── .git-scripts\               # 核心分析脚本
echo ├── .git-scripts-logs\          # 默认配置模板
echo ├── .git-scripts-install-windows\  # Windows 安装脚本
echo ├── 项目A\                      # 项目A的分析日志
echo │   ├── logs\
echo │   └── code_summaries\
echo ├── 项目B\                      # 项目B的分析日志
echo │   ├── logs\
echo │   └── code_summaries\
echo └── ...
echo.
echo %USERPROFILE%\.git-analyzer\   # 全局安装目录
echo ├── bin\                        # 可执行脚本
echo │   ├── register.bat
echo │   ├── unregister.bat
echo │   └── service-control.bat
echo └── config\                     # 全局配置
echo     ├── analyzer_home           # GitAnalyzer 主目录路径
echo     └── service_status          # 服务状态
echo.
echo 项目A\                          # 你的实际项目
echo ├── .git\
echo │   └── hooks\
echo │       └── post-commit         # Git 钩子
echo └── .git-scripts-logs\          # 项目本地配置
echo     └── .git-analyzer-config.json
echo ```
echo.
echo ## ⚙️ 工作原理
echo.
echo 1. **全局安装**: 在 `%USERPROFILE%\.git-analyzer` 创建全局配置
echo 2. **项目注册**: 在项目的 `.git\hooks\post-commit` 创建钩子
echo 3. **代码提交**: Git 钩子触发，调用 GitAnalyzer 的分析脚本
echo 4. **日志存储**: 分析结果保存到 `GitAnalyzer\项目名\` 目录下
echo.
echo ## 💡 优势
echo.
echo - ✅ **一次安装，全局共享**: 所有项目共用一套分析脚本
echo - ✅ **集中管理**: 所有项目的分析日志集中在 GitAnalyzer 目录
echo - ✅ **简单注册**: 项目中只需运行 `register` 即可
echo - ✅ **易于维护**: 更新 GitAnalyzer 即可影响所有项目
echo - ✅ **干净隔离**: 项目目录保持干净，只有配置文件
echo.
echo ## 🔧 配置
echo.
echo 每个项目的配置文件位于: `项目根目录\.git-scripts-logs\.git-analyzer-config.json`
echo.
echo ```json
echo {
echo   "enabled": true,
echo   "output_base_dir": "code_summaries",
echo   "gemini_model": "gemini-2.0-flash-exp",
echo   "max_diff_size": 50000,
echo   "timeout_seconds": 60
echo }
echo ```
echo.
echo ## 📊 查看日志
echo.
echo ```batch
echo # 查看某个项目的分析日志
echo cd GitAnalyzer\项目A
echo dir code_summaries
echo ```
echo.
echo ## ⚠️ 注意事项
echo.
echo 1. 需要安装 Git for Windows
echo 2. 需要安装 Gemini CLI
echo 3. 需要配置 Gemini 认证: `gemini auth`
echo 4. 建议使用 PowerShell 或 Git Bash
) > "%GLOBAL_INSTALL_DIR%\README.md"

call :log_success "说明文档创建完成: %GLOBAL_INSTALL_DIR%\README.md"
exit /b 0

REM ============================================
REM 日志函数
REM ============================================

:log_info
echo [i] %~1
exit /b

:log_success
echo [✓] %~1
exit /b

:log_warning
echo [!] %~1
exit /b

:log_error
echo [X] %~1
exit /b
