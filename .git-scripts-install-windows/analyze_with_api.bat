@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

REM ============================================
REM Git 代码分析器 - 直接使用 Gemini API (Windows 版本)
REM 使用 API Key 认证，不依赖 Gemini CLI
REM ============================================

set "PROJECT_ROOT=%~1"
if "%PROJECT_ROOT%"=="" (
    for /f "delims=" %%i in ('git rev-parse --show-toplevel 2^>nul') do set "PROJECT_ROOT=%%i"
)

if "%PROJECT_ROOT%"=="" (
    echo 错误: 无法确定项目根目录
    exit /b 1
)

REM 获取 GitAnalyzer 主目录
if not exist "%USERPROFILE%\.git-analyzer\config\analyzer_home" (
    echo 错误: GitAnalyzer 未正确安装
    exit /b 1
)

set /p ANALYZER_HOME=<"%USERPROFILE%\.git-analyzer\config\analyzer_home"

REM 项目信息
for %%F in ("%PROJECT_ROOT%") do set "PROJECT_NAME=%%~nxF"
set "PROJECT_LOGS_DIR=%ANALYZER_HOME%\%PROJECT_NAME%"
set "CONFIG_FILE=%PROJECT_ROOT%\.git-scripts-logs\.git-analyzer-config.json"
set "LOG_FILE=%PROJECT_LOGS_DIR%\analyzer.log"

REM 创建项目日志目录
if not exist "%PROJECT_LOGS_DIR%" mkdir "%PROJECT_LOGS_DIR%"
if not exist "%PROJECT_LOGS_DIR%\code_summaries" mkdir "%PROJECT_LOGS_DIR%\code_summaries"

REM 日志函数
call :log_info "========== Git 代码分析开始 =========="
call :log_info "项目: %PROJECT_NAME%"
call :log_info "项目路径: %PROJECT_ROOT%"

REM 检查配置文件
if not exist "%CONFIG_FILE%" (
    call :log_error "配置文件不存在: %CONFIG_FILE%"
    exit /b 1
)

REM 读取配置 (使用 PowerShell 解析 JSON)
for /f "delims=" %%i in ('powershell -Command "(Get-Content '%CONFIG_FILE%' | ConvertFrom-Json).enabled"') do set "ENABLED=%%i"
for /f "delims=" %%i in ('powershell -Command "(Get-Content '%CONFIG_FILE%' | ConvertFrom-Json).gemini_model"') do set "GEMINI_MODEL=%%i"
for /f "delims=" %%i in ('powershell -Command "(Get-Content '%CONFIG_FILE%' | ConvertFrom-Json).max_diff_size"') do set "MAX_DIFF_SIZE=%%i"
for /f "delims=" %%i in ('powershell -Command "(Get-Content '%CONFIG_FILE%' | ConvertFrom-Json).timeout_seconds"') do set "TIMEOUT=%%i"
for /f "delims=" %%i in ('powershell -Command "(Get-Content '%CONFIG_FILE%' | ConvertFrom-Json).gemini_api_key"') do set "GEMINI_API_KEY=%%i"
for /f "delims=" %%i in ('powershell -Command "(Get-Content '%CONFIG_FILE%' | ConvertFrom-Json).http_proxy"') do set "HTTP_PROXY=%%i"
for /f "delims=" %%i in ('powershell -Command "(Get-Content '%CONFIG_FILE%' | ConvertFrom-Json).https_proxy"') do set "HTTPS_PROXY=%%i"

REM 检查是否启用
if /i "%ENABLED%"=="False" (
    call :log_info "代码分析功能已禁用，跳过分析"
    exit /b 0
)

REM 检查全局服务状态
if exist "%USERPROFILE%\.git-analyzer\config\service_status" (
    set /p SERVICE_STATUS=<"%USERPROFILE%\.git-analyzer\config\service_status"
    if /i "!SERVICE_STATUS!" neq "enabled" (
        call :log_info "全局服务已禁用，跳过分析"
        exit /b 0
    )
)

REM 检查 API Key
if "%GEMINI_API_KEY%"=="" (
    call :log_error "未配置 Gemini API Key"
    call :log_error "请在配置文件中添加: gemini_api_key"
    exit /b 1
)

REM 设置代理
if not "%HTTP_PROXY%"=="" (
    set "http_proxy=%HTTP_PROXY%"
    call :log_info "使用 HTTP 代理: %HTTP_PROXY%"
)
if not "%HTTPS_PROXY%"=="" (
    set "https_proxy=%HTTPS_PROXY%"
    call :log_info "使用 HTTPS 代理: %HTTPS_PROXY%"
)

REM 获取提交信息
cd /d "%PROJECT_ROOT%"
for /f "delims=" %%i in ('git rev-parse HEAD 2^>nul') do set "COMMIT_HASH=%%i"
for /f "delims=" %%i in ('git log -1 --pretty^=%%B 2^>nul') do set "COMMIT_MESSAGE=%%i"
for /f "delims=" %%i in ('git log -1 --pretty^=%%an 2^>nul') do set "COMMIT_AUTHOR=%%i"
for /f "delims=" %%i in ('git log -1 --pretty^=%%ad --date^=format:%%Y-%%m-%%d %%H:%%M:%%S 2^>nul') do set "COMMIT_DATE=%%i"

if "%COMMIT_HASH%"=="" set "COMMIT_HASH=unknown"
if "%COMMIT_MESSAGE%"=="" set "COMMIT_MESSAGE=unknown"
if "%COMMIT_AUTHOR%"=="" set "COMMIT_AUTHOR=unknown"

call :log_info "提交哈希: %COMMIT_HASH%"
call :log_info "提交信息: %COMMIT_MESSAGE%"

REM 获取差异内容
set "TEMP_DIFF=%TEMP%\git_diff_%RANDOM%.txt"
git diff HEAD^ HEAD > "%TEMP_DIFF%" 2>nul

REM 检查差异是否为空
for %%A in ("%TEMP_DIFF%") do set "DIFF_SIZE=%%~zA"
if "%DIFF_SIZE%"=="0" (
    call :log_warning "没有检测到代码变更"
    del "%TEMP_DIFF%" 2>nul
    exit /b 0
)

call :log_info "代码差异大小: %DIFF_SIZE% 字节"

if %DIFF_SIZE% gtr %MAX_DIFF_SIZE% (
    call :log_warning "代码差异过大，可能导致分析超时"
)

REM 调用 Gemini API
call :log_info "正在调用 Gemini API 进行分析..."
call :log_info "使用模型: %GEMINI_MODEL%"

set "API_URL=https://generativelanguage.googleapis.com/v1beta/models/%GEMINI_MODEL%:generateContent?key=%GEMINI_API_KEY%"
set "TEMP_REQUEST=%TEMP%\gemini_request_%RANDOM%.json"
set "TEMP_RESPONSE=%TEMP%\gemini_response_%RANDOM%.json"

REM 构建 prompt (使用 PowerShell)
powershell -Command "$diff = Get-Content '%TEMP_DIFF%' -Raw -Encoding UTF8; $prompt = @\"
请分析以下 Git 提交的代码差异，并严格按照要求的 Markdown 格式输出。

**提交信息:**
- 项目名称: %PROJECT_NAME%
- 提交哈希: %COMMIT_HASH%
- 提交信息: %COMMIT_MESSAGE%
- 提交作者: %COMMIT_AUTHOR%
- 提交时间: %COMMIT_DATE%

**输出格式要求 (严格遵守):**

# [简短功能标题，用于文件名，不超过50字符]

---

## ✨ 功能总结

[简明扼要地总结本次提交实现的功能，3-5句话]

## 🧠 AI 代码分析

### 代码质量
[评估代码质量、可读性、可维护性]

### 潜在问题
[指出可能存在的问题或风险]

### 最佳实践
[评估是否遵循最佳实践]

## 🚀 优化建议

[提供3-5条具体的、可操作的优化建议]

## 📝 变更文件列表

[列出本次提交涉及的主要文件]

---

**代码差异:**

\`\`\`diff
$diff
\`\`\`
\"@; $json = @{ contents = @(@{ parts = @(@{ text = $prompt }) }) } | ConvertTo-Json -Depth 10; $json | Out-File -FilePath '%TEMP_REQUEST%' -Encoding UTF8"

REM 发送 API 请求
curl -s -X POST "%API_URL%" -H "Content-Type: application/json" -d @"%TEMP_REQUEST%" --connect-timeout 30 --max-time %TIMEOUT% -o "%TEMP_RESPONSE%"

if errorlevel 1 (
    call :log_error "API 调用失败"
    del "%TEMP_DIFF%" "%TEMP_REQUEST%" "%TEMP_RESPONSE%" 2>nul
    exit /b 1
)

REM 解析响应 (使用 PowerShell)
for /f "delims=" %%i in ('powershell -Command "$json = Get-Content '%TEMP_RESPONSE%' -Raw | ConvertFrom-Json; $json.candidates[0].content.parts[0].text"') do set "AI_RESULT=%%i"

if "%AI_RESULT%"=="" (
    call :log_error "API 返回空结果"
    del "%TEMP_DIFF%" "%TEMP_REQUEST%" "%TEMP_RESPONSE%" 2>nul
    exit /b 1
)

REM 保存完整结果到临时文件
set "TEMP_RESULT=%TEMP%\ai_result_%RANDOM%.txt"
powershell -Command "$json = Get-Content '%TEMP_RESPONSE%' -Raw | ConvertFrom-Json; $json.candidates[0].content.parts[0].text | Out-File -FilePath '%TEMP_RESULT%' -Encoding UTF8"

call :log_success "AI 分析完成"

REM 提取标题 (使用 PowerShell)
for /f "delims=" %%i in ('powershell -Command "$line = (Get-Content '%TEMP_RESULT%' -Encoding UTF8 | Select-String -Pattern ''^#'' | Select-Object -First 1).Line; if ($line) { $title = $line -replace ''^# '', '''' -replace ''^\s+'', '''' -replace ''\s+$'', ''''; $title = $title -replace ''[/\\:*?\"<>|；；]'', ''_''; $title.Substring(0, [Math]::Min(50, $title.Length)) }"') do set "TITLE=%%i"

if "%TITLE%"=="" (
    set "TITLE=代码提交摘要"
)

REM 创建目录结构
for /f "tokens=1-2 delims= " %%a in ("%DATE:~0,10%") do set "TODAY=%%a"
for /f "tokens=1-3 delims=/-" %%a in ("%TODAY%") do set "YEAR_MONTH=%%a%%b" & set "DAY=%%c"

set "SAVE_DIR=%PROJECT_LOGS_DIR%\code_summaries\%YEAR_MONTH%\%DAY%"
if not exist "%SAVE_DIR%" mkdir "%SAVE_DIR%"

REM 保存文件
set "FILE_PATH=%SAVE_DIR%\%TITLE%.md"

REM 如果文件已存在，添加时间戳
if exist "%FILE_PATH%" (
    for /f "tokens=1-3 delims=:." %%a in ("%TIME: =0%") do set "TIME_SUFFIX=%%a%%b%%c"
    set "FILE_PATH=%SAVE_DIR%\%TITLE%_%TIME_SUFFIX%.md"
)

copy "%TEMP_RESULT%" "%FILE_PATH%" >nul

call :log_success "分析结果已保存到: %FILE_PATH%"
call :log_success "========== Git 代码分析完成 =========="

REM Windows 通知
powershell -Command "Add-Type -AssemblyName System.Windows.Forms; $notification = New-Object System.Windows.Forms.NotifyIcon; $notification.Icon = [System.Drawing.SystemIcons]::Information; $notification.BalloonTipTitle = 'Git Analyzer'; $notification.BalloonTipText = '项目: %PROJECT_NAME%\n%TITLE%'; $notification.Visible = $true; $notification.ShowBalloonTip(3000)" 2>nul

REM 清理临时文件
del "%TEMP_DIFF%" "%TEMP_REQUEST%" "%TEMP_RESPONSE%" "%TEMP_RESULT%" 2>nul

exit /b 0

REM ============================================
REM 日志函数
REM ============================================

:log_info
echo [%DATE% %TIME%] [INFO] %~1 >> "%LOG_FILE%"
echo [i] %~1
exit /b

:log_success
echo [%DATE% %TIME%] [SUCCESS] %~1 >> "%LOG_FILE%"
echo [✓] %~1
exit /b

:log_warning
echo [%DATE% %TIME%] [WARNING] %~1 >> "%LOG_FILE%"
echo [!] %~1
exit /b

:log_error
echo [%DATE% %TIME%] [ERROR] %~1 >> "%LOG_FILE%"
echo [X] %~1
exit /b
