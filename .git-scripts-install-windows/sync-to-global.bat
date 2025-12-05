@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

REM ============================================
REM 同步脚本到全局目录 (Windows 版本)
REM 用于开发时快速更新全局命令
REM ============================================

echo.
echo ==========================================
echo    同步脚本到全局目录
echo ==========================================
echo.

REM 获取 GitAnalyzer 主目录
for %%I in ("%~dp0..") do set "ANALYZER_HOME=%%~fI"
set "GLOBAL_BIN_DIR=%USERPROFILE%\.git-analyzer\bin"

call :log_info "GitAnalyzer 主目录: %ANALYZER_HOME%"
call :log_info "全局命令目录: %GLOBAL_BIN_DIR%"

REM 检查全局目录是否存在
if not exist "%GLOBAL_BIN_DIR%" (
    call :log_error "全局目录不存在，请先运行全局安装脚本"
    exit /b 1
)

echo.
call :log_info "开始同步脚本..."

set SYNCED=0
set FAILED=0

REM 同步 Windows 脚本
set "SCRIPTS=register.bat unregister.bat analyze_with_api.bat service-control.bat"

for %%s in (%SCRIPTS%) do (
    set "SOURCE=%ANALYZER_HOME%\.git-scripts-install-windows\%%s"
    set "TARGET=%GLOBAL_BIN_DIR%\%%s"
    
    if exist "!SOURCE!" (
        copy /Y "!SOURCE!" "!TARGET!" >nul 2>&1
        if !errorlevel! equ 0 (
            call :log_success "已同步: %%s"
            set /a SYNCED+=1
        ) else (
            call :log_error "同步失败: %%s"
            set /a FAILED+=1
        )
    ) else (
        call :log_warning "源文件不存在: %%s"
    )
)

echo.
call :log_info "=========================================="
call :log_success "同步完成: %SYNCED% 个文件"
if %FAILED% gtr 0 (
    call :log_error "失败: %FAILED% 个文件"
)
call :log_info "=========================================="
echo.

REM 显示版本信息
if exist "%GLOBAL_BIN_DIR%\register.bat" (
    for /f %%i in ('find /c /v "" ^< "%GLOBAL_BIN_DIR%\register.bat"') do set "LINES=%%i"
    call :log_info "register.bat: !LINES! 行"
)

echo.
call :log_success "✨ 全局命令已更新，可以直接使用最新版本"
echo.

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
