# 废弃文件说明

本目录包含已废弃的脚本文件,这些文件已被新的实现替代。

## 废弃文件列表

### 1. analyze_commit_wrapper.sh (Mac 版本)
**废弃原因**: 使用 Gemini CLI,需要 OAuth 认证  
**替代方案**: `analyze_with_api.sh` - 直接使用 API Key 调用 Gemini API

### 2. analyze_commit_wrapper.bat (Windows 版本)
**废弃原因**: 使用 Gemini CLI,需要 OAuth 认证  
**替代方案**: `analyze_with_api.bat` - 直接使用 API Key 调用 Gemini API

### 3. deploy-to-project.sh
**废弃原因**: 旧的独立部署模式,每个项目独立复制脚本  
**替代方案**: 使用观察者模式的全局安装 + 项目注册方式

## 新架构优势

### API Key 方式 vs Gemini CLI

| 特性 | Gemini CLI (废弃) | API Key (当前) |
|------|-------------------|----------------|
| 认证方式 | OAuth (复杂) | API Key (简单) |
| 安装依赖 | 需要安装 CLI | 只需 curl + jq |
| 代理支持 | 依赖 CLI 配置 | 直接在配置文件中设置 |
| CI/CD 友好 | ❌ | ✅ |
| 配置灵活性 | 低 | 高 |

### 观察者模式 vs 独立部署

| 特性 | 独立部署 (废弃) | 观察者模式 (当前) |
|------|-----------------|-------------------|
| 脚本位置 | 每个项目独立 | 全局共享 |
| 更新方式 | 需要重新部署到每个项目 | 更新一次影响所有项目 |
| 日志管理 | 分散在各项目 | 集中在 GitAnalyzer 目录 |
| 维护成本 | 高 | 低 |

## 迁移指南

如果你还在使用旧版本:

### 从 Gemini CLI 迁移到 API Key

1. 获取 API Key: https://aistudio.google.com/app/apikey
2. 更新配置文件 `.git-scripts-logs/.git-analyzer-config.json`:
   ```json
   {
     "gemini_api_key": "YOUR_API_KEY_HERE",
     "http_proxy": "http://127.0.0.1:7897",
     "https_proxy": "http://127.0.0.1:7897"
   }
   ```
3. 重新注册项目: `register.sh` (会自动使用新脚本)

### 从独立部署迁移到观察者模式

1. 运行全局安装:
   ```bash
   cd GitAnalyzer
   bash .git-scripts-install/git-analyzer-global-installer.sh
   ```

2. 在每个项目中重新注册:
   ```bash
   cd /path/to/project
   register.sh
   ```

3. 删除项目中的旧脚本 (可选):
   ```bash
   rm -rf .git-scripts/
   ```

## 保留原因

这些文件被保留在 `deprecated/` 目录中,而不是直接删除,原因:

1. **历史参考**: 可以查看旧的实现方式
2. **回滚需要**: 如果新版本有问题,可以临时回滚
3. **学习价值**: 展示了不同的技术实现路线

## 删除时间

计划在 **2025年6月** 之后删除这些文件,届时新版本应该已经稳定运行。

---

**最后更新**: 2024-12-04
