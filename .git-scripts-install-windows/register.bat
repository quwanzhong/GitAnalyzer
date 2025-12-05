@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

REM ============================================
REM 项目注册脚本 - 将当前项目注册到 GitAnalyzer (Windows 版本)
REM ============================================

REM 检查是否在 Git 仓库中
git rev-parse --git-dir >nul 2>&1
if errorlevel 1 (
    call :log_error "当前目录不是 Git 仓库"
    exit /b 1
)

REM 获取项目信息
for /f "delims=" %%i in ('git rev-parse --show-toplevel') do set "PROJECT_ROOT=%%i"
for %%F in ("%PROJECT_ROOT%") do set "PROJECT_NAME=%%~nxF"

REM 获取 GitAnalyzer 主目录
if not exist "%USERPROFILE%\.git-analyzer\config\analyzer_home" (
    call :log_error "GitAnalyzer 未安装，请先运行全局安装脚本"
    exit /b 1
)

set /p ANALYZER_HOME=<"%USERPROFILE%\.git-analyzer\config\analyzer_home"

call :log_info "为项目 '%PROJECT_NAME%' 注册 Git 代码分析器..."

REM 获取 hooks 目录
for /f "delims=" %%i in ('git rev-parse --git-dir') do set "GIT_DIR=%%i"
set "HOOKS_DIR=%GIT_DIR%\hooks"
set "POST_COMMIT_HOOK=%HOOKS_DIR%\post-commit"

REM 备份现有钩子
if exist "%POST_COMMIT_HOOK%" (
    if not exist "%POST_COMMIT_HOOK%.backup" (
        copy "%POST_COMMIT_HOOK%" "%POST_COMMIT_HOOK%.backup.%RANDOM%" >nul
        call :log_info "已备份现有 post-commit 钩子"
    )
)

REM 创建 post-commit 钩子
(
echo #!/bin/bash
echo.
echo PROJECT_ROOT="$(git rev-parse --show-toplevel)"
echo ANALYZER_HOME="$(cat ~/.git-analyzer/config/analyzer_home 2^>/dev/null)"
echo.
echo if [ -z "$ANALYZER_HOME" ]; then
echo     echo "⚠️  Git 代码分析器未正确安装"
echo     exit 0
echo fi
echo.
echo # 检测操作系统
echo if [[ "$OSTYPE" == "msys" ^|^| "$OSTYPE" == "win32" ^|^| "$OSTYPE" == "cygwin" ]]; then
echo     # Windows 系统
echo     ANALYZER_SCRIPT="$ANALYZER_HOME/.git-scripts-install-windows/analyze_with_api.bat"
echo     
echo     if [ ! -f "$ANALYZER_SCRIPT" ]; then
echo         echo "⚠️  分析脚本不存在: $ANALYZER_SCRIPT"
echo         exit 0
echo     fi
echo     
echo     DIFF_CONTENT="$(git diff HEAD^ HEAD)"
echo     
echo     # 使用 cmd 执行 bat 脚本
echo     cmd //c "\"$ANALYZER_SCRIPT\" \"$PROJECT_ROOT\" \"$DIFF_CONTENT\"" ^&
echo else
echo     # Mac/Linux 系统
echo     ANALYZER_SCRIPT="$ANALYZER_HOME/.git-scripts-install/analyze_with_api.sh"
echo     
echo     if [ ! -f "$ANALYZER_SCRIPT" ]; then
echo         echo "⚠️  分析脚本不存在: $ANALYZER_SCRIPT"
echo         exit 0
echo     fi
echo     
echo     DIFF_CONTENT="$(git diff HEAD^ HEAD)"
echo     
echo     nohup bash "$ANALYZER_SCRIPT" "$PROJECT_ROOT" "$DIFF_CONTENT" ^> /dev/null 2^>^&1 ^&
echo fi
echo.
echo echo "🚀 代码分析已在后台启动..."
echo exit 0
) > "%POST_COMMIT_HOOK%"

REM 在 Windows 上，Git Bash 会处理权限
call :log_info "已创建 Git 钩子"

REM 创建项目配置目录
if not exist "%PROJECT_ROOT%\.git-scripts-logs" mkdir "%PROJECT_ROOT%\.git-scripts-logs"

REM 复制或创建配置文件
if not exist "%PROJECT_ROOT%\.git-scripts-logs\.git-analyzer-config.json" (
    if exist "%ANALYZER_HOME%\.git-scripts-logs\.git-analyzer-config.json" (
        copy "%ANALYZER_HOME%\.git-scripts-logs\.git-analyzer-config.json" "%PROJECT_ROOT%\.git-scripts-logs\" >nul
    ) else (
        (
        echo {
        echo   "enabled": true,
        echo   "output_base_dir": "code_summaries",
        echo   "gemini_model": "gemini-1.5-flash",
        echo   "gemini_api_key": "YOUR_API_KEY_HERE",
        echo   "max_diff_size": 50000,
        echo   "timeout_seconds": 120,
        echo   "http_proxy": "",
        echo   "https_proxy": ""
        echo }
        ) > "%PROJECT_ROOT%\.git-scripts-logs\.git-analyzer-config.json"
    )
    call :log_info "已创建项目配置文件"
)

REM 创建项目日志目录
if not exist "%ANALYZER_HOME%\%PROJECT_NAME%" mkdir "%ANALYZER_HOME%\%PROJECT_NAME%"

call :log_success "注册完成！"
call :log_info "配置文件: %PROJECT_ROOT%\.git-scripts-logs\.git-analyzer-config.json"
call :log_info "日志目录: %ANALYZER_HOME%\%PROJECT_NAME%\"
call :log_info "使用 'unregister' 可以注销分析器"

REM 自动分析最后一次提交
call :log_info "正在分析最后一次提交..."
set "ANALYZER_SCRIPT=%ANALYZER_HOME%\.git-scripts-install-windows\analyze_with_api.bat"

if exist "%ANALYZER_SCRIPT%" (
    cd /d "%PROJECT_ROOT%"
    for /f "delims=" %%i in ('git rev-parse HEAD 2^>nul') do set "LAST_COMMIT=%%i"
    
    if not "!LAST_COMMIT!"=="" (
        set "TEMP_DIFF=%TEMP%\git_diff_check_%RANDOM%.txt"
        git diff HEAD^ HEAD > "!TEMP_DIFF!" 2>nul
        
        for %%A in ("!TEMP_DIFF!") do set "DIFF_SIZE=%%~zA"
        
        if not "!DIFF_SIZE!"=="0" (
            REM 创建临时日志文件用于捕获错误
            set "TEMP_LOG=%TEMP%\git_analyzer_log_%RANDOM%.txt"
            start /B cmd /c ""%ANALYZER_SCRIPT%" "%PROJECT_ROOT%" > "!TEMP_LOG!" 2>&1"
            
            REM 等待2秒检查是否有立即错误
            timeout /t 2 /nobreak >nul
            
            REM 检查日志文件是否包含错误
            findstr /C:"错误" /C:"失败" /C:"error" /C:"Error" "!TEMP_LOG!" >nul 2>&1
            if !errorlevel! equ 0 (
                call :log_error "分析启动失败，错误信息:"
                type "!TEMP_LOG!"
                del "!TEMP_LOG!" 2>nul
            ) else (
                call :log_success "最后一次提交分析已在后台启动"
                call :log_info "分析日志: !TEMP_LOG!"
            )
        ) else (
            call :log_info "最后一次提交没有代码变更，跳过分析"
        )
        
        del "!TEMP_DIFF!" 2>nul
    ) else (
        call :log_info "仓库中没有提交记录，跳过分析"
    )
) else (
    call :log_error "分析脚本不存在: %ANALYZER_SCRIPT%"
)

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

:log_error
echo [X] %~1
exit /b
