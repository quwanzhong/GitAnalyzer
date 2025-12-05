# ✅ GitAnalyzer 迁移检查清单

## 📋 重构完成项

### ✅ 核心脚本
- [x] 优化 `analyze_with_api.sh` (Mac/Linux)
- [x] 创建 `analyze_with_api.bat` (Windows)
- [x] 移除 `analyze_commit_wrapper.sh` → `deprecated/`
- [x] 移除 `analyze_commit_wrapper.bat` → `deprecated/`
- [x] 移除 `deploy-to-project.sh` → `deprecated/`

### ✅ 注册脚本
- [x] 更新 `register.sh` - 指向 `analyze_with_api.sh`
- [x] 更新 `register.bat` - 指向 `analyze_with_api.bat`
- [x] 添加跨平台系统检测
- [x] 更新默认配置模板 (包含 API Key 字段)

### ✅ 服务控制
- [x] 更新 `service-control.sh` - 移除 Gemini CLI 检查
- [x] 更新 `service-control.bat` - 移除 Gemini CLI 检查
- [x] 添加 API 配置检查函数
- [x] 更新启动提示信息

### ✅ 安装脚本
- [x] 更新 `git-analyzer-global-installer.sh` - 检查 curl + jq
- [x] 更新 `git-analyzer-global-installer.bat` - 检查 curl + PowerShell

### ✅ 配置文件
- [x] 创建 `config-template.json` - 新配置模板
- [x] 添加 `gemini_api_key` 字段
- [x] 添加 `http_proxy` / `https_proxy` 字段
- [x] 调整默认超时时间为 120 秒

### ✅ 文档
- [x] 创建 `QUICKSTART-API.md` - API Key 快速开始指南
- [x] 创建 `REFACTORING-SUMMARY.md` - 重构总结
- [x] 创建 `deprecated/README.md` - 废弃文件说明
- [x] 创建 `MIGRATION-CHECKLIST.md` - 本文件

---

## 🧪 测试清单

### Mac/Linux 测试

#### 全局安装测试
- [ ] 运行 `git-analyzer-global-installer.sh`
- [ ] 检查依赖 (curl, jq, git)
- [ ] 验证全局目录创建: `~/.git-analyzer/`
- [ ] 验证环境变量添加到 shell 配置

#### 项目注册测试
- [ ] 在测试项目中运行 `register.sh`
- [ ] 验证 Git 钩子创建: `.git/hooks/post-commit`
- [ ] 验证配置文件创建: `.git-scripts-logs/.git-analyzer-config.json`
- [ ] 验证钩子包含系统检测代码

#### 服务控制测试
- [ ] 运行 `git-analyzer-start`
- [ ] 验证提示信息 (API Key 相关)
- [ ] 运行 `git-analyzer-status`
- [ ] 运行 `git-analyzer-list`
- [ ] 运行 `git-analyzer-stop`

#### 分析测试
- [ ] 配置有效的 API Key
- [ ] 提交测试代码
- [ ] 验证后台进程启动
- [ ] 检查日志文件: `~/GitAnalyzer/项目名/analyzer.log`
- [ ] 验证分析报告生成: `~/GitAnalyzer/项目名/code_summaries/`
- [ ] 验证目录结构: `YYYYMM/DD/标题.md`

#### 代理测试
- [ ] 配置代理设置
- [ ] 验证代理生效 (检查日志)
- [ ] 测试无代理情况

### Windows 测试

#### 全局安装测试
- [ ] 运行 `git-analyzer-global-installer.bat`
- [ ] 检查依赖 (curl, git, PowerShell)
- [ ] 验证全局目录创建: `%USERPROFILE%\.git-analyzer\`
- [ ] 验证环境变量添加到 PATH

#### 项目注册测试
- [ ] 在测试项目中运行 `register.bat`
- [ ] 验证 Git 钩子创建: `.git\hooks\post-commit`
- [ ] 验证配置文件创建: `.git-scripts-logs\.git-analyzer-config.json`
- [ ] 验证钩子包含系统检测代码

#### 服务控制测试
- [ ] 运行 `git-analyzer-start`
- [ ] 验证提示信息 (API Key 相关)
- [ ] 运行 `git-analyzer-status`
- [ ] 运行 `git-analyzer-list`
- [ ] 运行 `git-analyzer-stop`

#### 分析测试
- [ ] 配置有效的 API Key
- [ ] 提交测试代码
- [ ] 验证后台进程启动
- [ ] 检查日志文件: `%USERPROFILE%\GitAnalyzer\项目名\analyzer.log`
- [ ] 验证分析报告生成: `%USERPROFILE%\GitAnalyzer\项目名\code_summaries\`
- [ ] 验证目录结构: `YYYYMM\DD\标题.md`

#### 代理测试
- [ ] 配置代理设置
- [ ] 验证代理生效 (检查日志)
- [ ] 测试无代理情况

### 跨平台测试

#### 同一项目在不同系统
- [ ] 在 Mac 上注册项目并提交
- [ ] 切换到 Windows,拉取代码
- [ ] 在 Windows 上提交,验证自动使用 `.bat` 脚本
- [ ] 切换回 Mac,提交,验证自动使用 `.sh` 脚本

---

## 🔍 验证要点

### 1. 配置文件格式
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

### 2. Git 钩子内容
- 包含系统检测: `if [[ "$OSTYPE" == "msys" ...`
- Mac 路径: `analyze_with_api.sh`
- Windows 路径: `analyze_with_api.bat`

### 3. 日志内容
- 包含 "正在调用 Gemini API"
- 包含 "使用模型: gemini-1.5-flash"
- 如果配置代理,包含 "使用 HTTP 代理"
- 成功时包含 "AI 分析完成"

### 4. 分析报告格式
- 文件名: `功能标题.md` 或 `功能标题_HHMMSS.md`
- 包含 Markdown 标题: `# [标题]`
- 包含章节: `## ✨ 功能总结`, `## 🧠 AI 代码分析`, `## 🚀 优化建议`

---

## 🐛 已知问题

### 1. PowerShell 执行策略 (Windows)
**问题**: PowerShell 可能阻止脚本执行  
**解决**: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

### 2. 中文路径 (Windows)
**问题**: 路径包含中文可能导致编码问题  
**解决**: 建议使用英文路径,或设置 `chcp 65001`

### 3. jq 未安装 (Mac)
**问题**: 安装脚本会报错  
**解决**: `brew install jq`

### 4. curl 证书问题
**问题**: 某些环境 curl 可能报证书错误  
**解决**: 添加 `-k` 参数 (不推荐) 或更新证书

---

## 📝 待办事项

### 短期 (1-2 周)
- [ ] 收集用户反馈
- [ ] 修复发现的 bug
- [ ] 优化错误提示信息
- [ ] 添加更多示例配置

### 中期 (1 个月)
- [ ] 添加配置验证工具
- [ ] 实现自动 API Key 测试
- [ ] 添加分析报告模板自定义
- [ ] 支持更多 AI 模型

### 长期 (3 个月+)
- [ ] Web UI 查看分析结果
- [ ] 批量分析历史提交
- [ ] 团队协作功能
- [ ] 分析结果统计和可视化

---

## 🎯 发布前检查

### 代码质量
- [ ] 所有脚本通过 shellcheck (Mac/Linux)
- [ ] 所有脚本在目标系统测试通过
- [ ] 错误处理完善
- [ ] 日志记录清晰

### 文档完整性
- [ ] README.md 更新
- [ ] QUICKSTART-API.md 完整
- [ ] 配置示例清晰
- [ ] 故障排查指南完善

### 用户体验
- [ ] 安装流程简单
- [ ] 错误提示友好
- [ ] 默认配置合理
- [ ] 命令响应快速

### 安全性
- [ ] API Key 不会泄露到日志
- [ ] 配置文件权限正确
- [ ] 代理设置安全
- [ ] 临时文件及时清理

---

## 📢 发布说明模板

```markdown
# GitAnalyzer v2.0 - API Key 版本

## 🎉 重大更新

- 🔑 使用 API Key 直接调用 Gemini API,无需 Gemini CLI
- 🚀 简化安装流程,减少依赖
- 🌐 更好的代理支持
- 🔧 更灵活的配置选项

## ⚠️ 破坏性变更

- 需要配置 Gemini API Key
- 移除 Gemini CLI 依赖
- 配置文件格式变更

## 📖 升级指南

详见: [QUICKSTART-API.md](./QUICKSTART-API.md)

## 🐛 Bug 修复

- 修复超时控制问题
- 改进错误处理
- 优化日志记录

## 📚 文档

- 新增 API Key 快速开始指南
- 新增重构总结文档
- 更新所有示例配置
```

---

**检查清单最后更新**: 2024-12-04
