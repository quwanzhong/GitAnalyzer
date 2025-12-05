@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

REM ============================================
REM 项目注销脚本 - 从 GitAnalyzer 注销当前项目 (Windows 版本)
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

call :log_info "从项目 '%PROJECT_NAME%' 注销代码分析器..."

REM 获取 hooks 目录
for /f "delims=" %%i in ('git rev-parse --git-dir') do set "GIT_DIR=%%i"
set "HOOKS_DIR=%GIT_DIR%\hooks"
set "POST_COMMIT_HOOK=%HOOKS_DIR%\post-commit"

REM 移除钩子
if exist "%POST_COMMIT_HOOK%" (
    del "%POST_COMMIT_HOOK%"
    call :log_info "已移除 Git 钩子"
    
    REM 恢复备份
    if exist "%POST_COMMIT_HOOK%.backup.*" (
        for /f "delims=" %%f in ('dir /b /o-d "%POST_COMMIT_HOOK%.backup.*" 2^>nul') do (
            copy "%HOOKS_DIR%\%%f" "%POST_COMMIT_HOOK%" >nul
            call :log_info "已恢复备份的钩子"
            goto :backup_restored
        )
        :backup_restored
    )
)

call :log_success "注销完成！"
call :log_info "项目配置和日志已保留，如需删除请手动清理："
call :log_info "  - 配置: %PROJECT_ROOT%\.git-scripts-logs\"

REM 获取 GitAnalyzer 主目录
if exist "%USERPROFILE%\.git-analyzer\config\analyzer_home" (
    set /p ANALYZER_HOME=<"%USERPROFILE%\.git-analyzer\config\analyzer_home"
    call :log_info "  - 日志: !ANALYZER_HOME!\%PROJECT_NAME%\"
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
