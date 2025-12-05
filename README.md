# Git 代码分析器 (GitAnalyzer)

基于观察者模式的 Git 提交代码分析工具，使用 Gemini AI 自动分析每次代码提交。

## 🌐 跨平台支持

✅ **macOS** - 完整支持  
✅ **Windows** - 完整支持 (查看 [Windows 安装指南](./README-WINDOWS.md))  
✅ **Linux** - 使用 macOS 版本脚本

## 🎯 设计思想

采用**观察者模式**架构：
- **GitAnalyzer** 作为全局服务（观察者中心）
- **项目A/B/C** 通过简单的注册/注销来订阅分析服务
- 所有分析日志集中存储在 GitAnalyzer 目录下，按项目分类

## ✨ 核心特性

- ✅ **一次安装，全局共享** - 所有项目共用一套分析脚本
- ✅ **集中管理** - 所有项目的分析日志集中在 GitAnalyzer 目录
- ✅ **简单注册** - 项目中只需运行 `register.sh` 即可
- ✅ **易于维护** - 更新 GitAnalyzer 即可影响所有项目
- ✅ **干净隔离** - 项目目录保持干净，只有配置文件
- ✅ **智能分析** - 使用 Gemini AI 提供代码质量评估和优化建议

## 📁 目录结构

```
GitAnalyzer/                          # 全局服务主目录
├── .git-scripts/                     # 核心分析脚本（原始版本）
│   ├── analyze_commit.sh
│   └── toggle_analyzer.sh
├── .git-scripts-install/             # Mac/Linux 安装脚本
│   ├── git-analyzer-global-installer.sh  # 全局安装脚本
│   ├── register.sh                   # 项目注册脚本
│   ├── unregister.sh                 # 项目注销脚本
│   ├── service-control.sh            # 服务控制脚本
│   └── analyze_commit_wrapper.sh     # 跨项目分析包装脚本
├── .git-scripts-install-windows/     # Windows 安装脚本
│   ├── git-analyzer-global-installer.bat
│   ├── register.bat
│   ├── unregister.bat
│   ├── service-control.bat
│   └── analyze_commit_wrapper.bat
├── .git-scripts-logs/                # 默认配置模板
│   └── .git-analyzer-config.json
├── 项目A/                            # 项目A的分析日志
│   ├── logs/
│   │   └── analyzer.log
│   └── code_summaries/
│       └── YYYYMM/DD/
├── 项目B/                            # 项目B的分析日志
│   └── ...
└── README.md                         # 本文档

~/.git-analyzer/                      # 全局安装目录
├── bin/                              # 可执行脚本
│   ├── register.sh
│   ├── unregister.sh
│   └── service-control.sh
├── config/                           # 全局配置
│   ├── analyzer_home                 # GitAnalyzer 主目录路径
│   └── service_status                # 服务状态
└── README.md                         # 使用说明

项目A/                                # 你的实际项目
├── .git/
│   └── hooks/
│       └── post-commit               # Git 钩子（自动创建）
└── .git-scripts-logs/                # 项目本地配置
    └── .git-analyzer-config.json     # 项目配置文件
```

## 🚀 快速开始

### 第一步：全局安装（仅需一次）

#### macOS / Linux

在 GitAnalyzer 项目目录下运行：

```bash
cd /path/to/GitAnalyzer
bash .git-scripts-install/git-analyzer-global-installer.sh
```

安装完成后，重新加载 shell 配置：

```bash
source ~/.zshrc  # 或 source ~/.bash_profile
```

#### Windows

在 GitAnalyzer 项目目录下运行：

```batch
cd C:\path\to\GitAnalyzer
.git-scripts-install-windows\git-analyzer-global-installer.bat
```

然后重新打开命令提示符或 PowerShell。

**详细 Windows 安装说明**: 查看 [README-WINDOWS.md](./README-WINDOWS.md)

### 第二步：配置 Gemini API

在开始使用前，需要配置 Gemini API Key：

```bash
# 运行配置向导
cd /path/to/GitAnalyzer
./setup_gemini_api.sh
```

**配置向导会：**
1. 提示你输入 API Key（从 https://aistudio.google.com/app/apikey 获取）
2. 自动测试 API Key 是否有效
3. 更新项目配置文件
4. 部署新的分析脚本

**手动配置方式：**
如果配置向导不可用，你可以手动编辑配置模板文件：
```bash
# 编辑配置模板
vim /path/to/GitAnalyzer/.git-scripts-logs/.git-analyzer-config.json
```

配置示例：
```json
{
  "enabled": true,
  "output_base_dir": "code_summaries",
  "gemini_model": "gemini-2.0-flash",
  "gemini_api_key": "",
  "http_proxy": "http://127.0.0.1:7897",
  "https_proxy": "http://127.0.0.1:7897",
  "log_file": ".git-analyzer.log",
  "max_diff_size": 50000,
  "timeout_seconds": 60,
  "notification": {
    "show_success": true,
    "show_errors": true
  }
}
```

### 第三步：查看服务状态

```bash
git-analyzer-status
```

或

```bash
bash ~/.git-analyzer/bin/service-control.sh status
```

### 第四步：列出已注册项目

```bash
git-analyzer-list
```

查看当前已经注册到 GitAnalyzer 的所有项目。

### 第五步：启动服务

```bash
git-analyzer-start
```

启动 GitAnalyzer 全局服务，所有已注册项目的提交都将被自动分析。

**⚠️ 重要提示：**
- 如果首次启动时未配置 API Key，系统会提示你进行配置
- 配置完成后，需要重新运行 `git-analyzer-start` 重启服务
- 重启后会自动更新所有已注册项目的全局配置

### 第六步（可选）：停止服务

```bash
git-analyzer-stop
```

如需暂停分析，可以停止服务。

### 第七步：在项目中注册

进入你想要分析的项目目录（与 .git 同级），运行：

```bash
cd /path/to/your/project
register.sh
```

或使用完整路径：

```bash
bash ~/.git-analyzer/bin/register.sh
```

### 第八步：正常使用 Git

```bash
git add .
git commit -m "your commit message"
# 代码分析会自动在后台运行
```

### 第九步：查看分析结果

分析结果保存在 GitAnalyzer 目录下：

```bash
cd /path/to/GitAnalyzer/项目名/code_summaries/
ls -la
```

## 🎮 命令参考

### 全局服务控制

```bash
# 启动全局服务
git-analyzer-start

# 停止全局服务
git-analyzer-stop

# 查看服务状态
git-analyzer-status

# 列出所有已注册项目
git-analyzer-list
```

### 项目管理

```bash
# 在项目目录中注册
cd /path/to/your/project
register.sh

# 在项目目录中注销
cd /path/to/your/project
unregister.sh
```

## ⚙️ 配置说明

### 项目配置文件

每个项目的配置文件位于：`项目根目录/.git-scripts-logs/.git-analyzer-config.json`

```json
{
  "enabled": true,                    // 是否启用分析
  "output_base_dir": "code_summaries", // 输出目录名（相对路径）
  "gemini_model": "gemini-2.0-flash-exp", // Gemini 模型
  "max_diff_size": 50000,             // 最大差异大小（字符）
  "timeout_seconds": 60               // API 超时时间（秒）
}
```

### 全局配置

- **服务状态**: `~/.git-analyzer/config/service_status`
  - `enabled` - 服务启用
  - `disabled` - 服务禁用

- **主目录路径**: `~/.git-analyzer/config/analyzer_home`
  - 存储 GitAnalyzer 项目的绝对路径

## 🔧 工作原理

1. **全局安装阶段**
   - 在 `~/.git-analyzer` 创建全局配置目录
   - 记录 GitAnalyzer 主目录位置
   - 将脚本复制到全局 bin 目录
   - 添加环境变量到 shell 配置文件

2. **项目注册阶段**
   - 在项目的 `.git/hooks/post-commit` 创建钩子
   - 钩子指向 GitAnalyzer 的分析包装脚本
   - 在项目根目录创建配置文件
   - 在 GitAnalyzer 目录创建项目日志目录

3. **代码提交阶段**
   - Git 提交触发 post-commit 钩子
   - 钩子调用 GitAnalyzer 的分析包装脚本
   - 脚本获取代码差异并调用 Gemini API
   - 分析结果保存到 `GitAnalyzer/项目名/code_summaries/`

4. **日志存储结构**
   ```
   GitAnalyzer/项目名/
   ├── logs/
   │   └── analyzer.log              # 分析日志
   └── code_summaries/
       └── YYYYMM/                   # 年月
           └── DD/                   # 日
               └── 功能标题.md       # 分析结果
   ```

## 📊 分析结果示例

每次提交的分析结果包含：

- ✨ **功能总结** - 简明扼要的功能描述
- 🧠 **AI 代码分析** - 代码质量、潜在问题、最佳实践评估
- 🚀 **优化建议** - 具体可操作的改进建议
- 📝 **变更文件列表** - 本次提交涉及的文件

## 🛠️ 依赖要求

- **必需**:
  - Git
  - Bash
  - Gemini API Key

- **可选**:
  - jq (用于 JSON 配置解析)
  - osascript (Mac 系统通知)
  - 代理软件（如果在中国大陆）

## 🔍 故障排查

### 问题：register.sh 找不到

**解决方案**：
```bash
# 确保已运行全局安装
bash /path/to/GitAnalyzer/.git-scripts-install/git-analyzer-global-installer-new.sh
source ~/.zshrc

# 或使用完整路径
bash ~/.git-analyzer/bin/register.sh
```

### 问题：分析没有运行

**检查步骤**：
1. 检查全局服务状态：`git-analyzer-status`
2. 检查项目配置：`cat .git-scripts-logs/.git-analyzer-config.json`
3. 检查 Git 钩子：`cat .git/hooks/post-commit`
4. 查看日志：`cat /path/to/GitAnalyzer/项目名/logs/analyzer.log`

### 问题：Gemini API 调用失败

**可能原因**：
- API 密钥未配置或无效
- 网络连接问题
- API 配额用尽

**解决方案**：
```bash
# 检查 API Key 配置
cat .git-scripts-logs/.git-analyzer-config.json | grep gemini_api_key

# 测试 API 连接
curl -s "https://generativelanguage.googleapis.com/v1/models?key=YOUR_API_KEY"
```

## 📝 注意事项

1. **首次提交**: 首次提交可能没有差异（没有 HEAD^），分析会自动跳过
2. **大型提交**: 差异过大可能导致 API 超时，建议分批提交
3. **网络要求**: 需要稳定的网络连接访问 Gemini API
4. **备份钩子**: 注册时会自动备份现有的 post-commit 钩子
5. **配置保留**: 注销项目时，配置和日志会保留，需要手动删除

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

MIT License

## 🔗 相关链接

- [Gemini API 文档](https://ai.google.dev/gemini-api/docs)
- [Git Hooks 文档](https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks)

---

**享受智能代码分析！** 🎉
