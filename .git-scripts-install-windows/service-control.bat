@echo off
setlocal enabledelayedexpansion

REM ============================================
REM GitAnalyzer 全局服务控制脚本 (Windows 版本)
REM 用于启动/停止全局分析服务(可选功能)
REM ============================================

REM 从配置文件读取 GitAnalyzer 主目录
if exist "%USERPROFILE%\.git-analyzer\config\analyzer_home" (
    set /p GIT_ANALYZER_HOME=<"%USERPROFILE%\.git-analyzer\config\analyzer_home"
) else (
    set "GIT_ANALYZER_HOME=%~dp0\.."
)

set "SERVICE_STATUS_FILE=%USERPROFILE%\.git-analyzer\config\service_status"

if "%~1"=="" goto show_status
if /i "%~1"=="start" goto start_service
if /i "%~1"=="stop" goto stop_service
if /i "%~1"=="status" goto show_status
if /i "%~1"=="list" goto list_projects
if /i "%~1"=="help" goto show_help
if /i "%~1"=="--help" goto show_help
if /i "%~1"=="-h" goto show_help

call :log_error "未知命令: %~1"
goto show_help

:show_help
echo GitAnalyzer 全局服务控制
echo.
echo 用法: %~nx0 [命令]
echo.
echo 命令:
echo   start   - 启动全局服务(标记为启用)
echo   stop    - 停止全局服务(标记为禁用)
echo   status  - 查看服务状态
echo   list    - 列出所有已注册的项目
echo.
echo 注意: 本服务采用观察者模式，无需常驻进程
echo       启动/停止仅影响全局配置状态
exit /b 0

:check_api_config
call :log_info "检查 Gemini API 配置..."

REM 检查是否有项目注册
set HAS_PROJECTS=0
if exist "%GIT_ANALYZER_HOME%" (
    for /d %%D in ("%GIT_ANALYZER_HOME%\*") do (
        set "PROJECT_NAME=%%~nxD"
        
        REM 排除系统目录
        if /i "!PROJECT_NAME!"==".git" goto :skip_check
        if /i "!PROJECT_NAME!"==".git-scripts" goto :skip_check
        if /i "!PROJECT_NAME!"==".git-scripts-logs" goto :skip_check
        if /i "!PROJECT_NAME!"==".git-scripts-install" goto :skip_check
        if /i "!PROJECT_NAME!"==".git-scripts-install-windows" goto :skip_check
        if /i "!PROJECT_NAME!"=="bin" goto :skip_check
        if /i "!PROJECT_NAME!"=="config" goto :skip_check
        
        if exist "%%D\code_summaries" set HAS_PROJECTS=1
        if exist "%%D\analyzer.log" set HAS_PROJECTS=1
        
        :skip_check
    )
)

if %HAS_PROJECTS%==0 (
    call :log_warning "尚未注册任何项目"
    echo.
    echo 请在项目目录中运行:
    echo    register
    echo.
)

REM 检查配置模板中是否有 API Key
set CONFIG_TEMPLATE=%GIT_ANALYZER_HOME%\.git-scripts-logs\.git-analyzer-config.json
if exist "%CONFIG_TEMPLATE%" (
    REM 使用 PowerShell 检查 API Key
    for /f "delims=" %%i in ('powershell -Command "(Get-Content '%CONFIG_TEMPLATE%' | ConvertFrom-Json).gemini_api_key"') do set API_KEY=%%i
    
    if "!API_KEY!"=="" (
        call :log_warning "未检测到 Gemini API Key 配置"
        echo.
        set /p CONFIGURE_NOW="是否现在配置 API Key? (Y/n): "
        
        if "!CONFIGURE_NOW!"=="" set CONFIGURE_NOW=Y
        if /i "!CONFIGURE_NOW!"=="Y" (
            REM 调用配置向导
            set SETUP_SCRIPT=%GIT_ANALYZER_HOME%\setup_gemini_api.sh
            if exist "!SETUP_SCRIPT!" (
                bash "!SETUP_SCRIPT!"
            ) else (
                call :log_error "配置脚本不存在: !SETUP_SCRIPT!"
                call :log_info "请手动配置: %CONFIG_TEMPLATE%"
                call :log_info "API Key 获取: https://aistudio.google.com/app/apikey"
            )
        ) else (
            call :log_info "请手动配置 API Key"
            call :log_info "配置文件: %CONFIG_TEMPLATE%"
            call :log_info "API Key 获取: https://aistudio.google.com/app/apikey"
        )
        echo.
    ) else (
        call :log_success "已检测到 API Key 配置"
    )
) else (
    call :log_warning "配置模板不存在: %CONFIG_TEMPLATE%"
    call :log_info "请确保在项目配置文件中设置了 Gemini API Key"
    call :log_info "配置文件: 项目根目录\.git-scripts-logs\.git-analyzer-config.json"
    call :log_info "API Key 获取: https://aistudio.google.com/app/apikey"
)
echo.

exit /b 0

:start_service
echo.
call :log_info "========== 启动 GitAnalyzer 全局服务 =========="
echo.

REM 检查 API 配置
call :check_api_config

echo.
if not exist "%USERPROFILE%\.git-analyzer\config" mkdir "%USERPROFILE%\.git-analyzer\config"
echo enabled > "%SERVICE_STATUS_FILE%"
call :log_success "GitAnalyzer 全局服务已启用"
call :log_info "所有已注册项目的提交都将被分析"

REM 显示当前配置的 API Key 信息
set CONFIG_TEMPLATE=%GIT_ANALYZER_HOME%\.git-scripts-logs\.git-analyzer-config.json
if exist "%CONFIG_TEMPLATE%" (
    for /f "delims=" %%i in ('powershell -Command "(Get-Content '%CONFIG_TEMPLATE%' | ConvertFrom-Json).gemini_api_key"') do set API_KEY=%%i
    if not "!API_KEY!"=="" (
        set KEY_START=!API_KEY:~0,20!
        set KEY_END=!API_KEY:~-4!
        call :log_success "当前 API Key: !KEY_START!...!KEY_END!"
    ) else (
        call :log_warning "未配置 API Key，请运行: setup_gemini_api.sh"
    )
)
echo.
exit /b 0

:stop_service
if not exist "%USERPROFILE%\.git-analyzer\config" mkdir "%USERPROFILE%\.git-analyzer\config"
echo disabled > "%SERVICE_STATUS_FILE%"
call :log_warning "GitAnalyzer 全局服务已禁用"
call :log_info "已注册项目的提交将不会被分析"
exit /b 0

:show_status
if not exist "%SERVICE_STATUS_FILE%" (
    call :log_info "服务状态: 未初始化 (默认启用)"
    goto show_status_info
)

set /p STATUS=<"%SERVICE_STATUS_FILE%"
if /i "%STATUS%"=="enabled" (
    call :log_success "服务状态: 已启用 ✓"
) else (
    call :log_warning "服务状态: 已禁用 ✗"
)

:show_status_info
echo.
echo GitAnalyzer 主目录: %GIT_ANALYZER_HOME%
echo 配置目录: %USERPROFILE%\.git-analyzer\config
exit /b 0

:list_projects
call :log_info "已注册的项目:"
echo.

if not exist "%GIT_ANALYZER_HOME%" (
    call :log_warning "未找到项目目录"
    exit /b 0
)

set COUNT=0
for /d %%D in ("%GIT_ANALYZER_HOME%\*") do (
    set "PROJECT_NAME=%%~nxD"
    
    REM 排除系统目录
    if /i "!PROJECT_NAME!"==".git" goto :skip_project
    if /i "!PROJECT_NAME!"==".git-scripts" goto :skip_project
    if /i "!PROJECT_NAME!"==".git-scripts-logs" goto :skip_project
    if /i "!PROJECT_NAME!"==".git-scripts-install" goto :skip_project
    if /i "!PROJECT_NAME!"==".git-scripts-install-windows" goto :skip_project
    if /i "!PROJECT_NAME!"=="bin" goto :skip_project
    if /i "!PROJECT_NAME!"=="config" goto :skip_project
    if /i "!PROJECT_NAME!"==".DS_Store" goto :skip_project
    
    REM 只显示包含 code_summaries 或 analyzer.log 的项目
    if exist "%%D\code_summaries" (
        echo   [项目] !PROJECT_NAME!
        
        REM 显示项目信息
        if exist "%%D\analyzer.log" (
            for /f "tokens=1-2 delims=[]" %%A in ('findstr /r "\[.*\]" "%%D\analyzer.log" 2^>nul ^| find /v "" ^| more +1') do (
                echo      ^|-- 最后分析: %%A
                goto :next_info
            )
            :next_info
        )
        
        REM 统计报告数量
        set "REPORT_COUNT=0"
        for /r "%%D\code_summaries" %%F in (*.md) do set /a REPORT_COUNT+=1
        if !REPORT_COUNT! gtr 0 echo      ^|-- 分析报告: !REPORT_COUNT! 个
        
        set /a COUNT+=1
    ) else if exist "%%D\analyzer.log" (
        echo   [项目] !PROJECT_NAME!
        
        if exist "%%D\analyzer.log" (
            for /f "tokens=1-2 delims=[]" %%A in ('findstr /r "\[.*\]" "%%D\analyzer.log" 2^>nul ^| find /v "" ^| more +1') do (
                echo      ^|-- 最后分析: %%A
                goto :next_info2
            )
            :next_info2
        )
        
        set /a COUNT+=1
    )
    
    :skip_project
)

if %COUNT%==0 (
    call :log_info "暂无已注册的项目"
    echo 使用 'register.bat' 在项目目录中注册
) else (
    echo.
    call :log_success "共 %COUNT% 个已注册项目"
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

:log_warning
echo [!] %~1
exit /b

:log_error
echo [X] %~1
exit /b
