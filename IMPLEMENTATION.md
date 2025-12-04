# GitAnalyzer 实现方案说明

## 📐 架构设计

### 观察者模式实现

本项目采用**观察者模式**设计，实现了以下架构：

```
┌─────────────────────────────────────────────────────────┐
│                    GitAnalyzer                          │
│                  (全局服务/观察者)                        │
│                                                         │
│  ├── .git-scripts/              核心分析脚本            │
│  ├── .git-scripts-install/      安装管理脚本            │
│  ├── 项目A/                     项目A日志               │
│  ├── 项目B/                     项目B日志               │
│  └── 项目C/                     项目C日志               │
└─────────────────────────────────────────────────────────┘
                        ▲
                        │ 注册/订阅
        ┌───────────────┼───────────────┐
        │               │               │
    ┌───▼────┐     ┌───▼────┐     ┌───▼────┐
    │ 项目A   │     │ 项目B   │     │ 项目C   │
    │        │     │        │     │        │
    │ Git    │     │ Git    │     │ Git    │
    │ Hooks  │     │ Hooks  │     │ Hooks  │
    └────────┘     └────────┘     └────────┘
```

## 🔧 核心组件

### 1. 全局安装脚本
**文件**: `.git-scripts-install/git-analyzer-global-installer.sh`

**功能**:
- 创建全局配置目录 `~/.git-analyzer`
- 复制管理脚本到全局 bin 目录
- 配置环境变量和命令别名
- 记录 GitAnalyzer 主目录位置

**执行时机**: 仅需执行一次

### 2. 项目注册脚本
**文件**: `.git-scripts-install/register.sh`

**功能**:
- 在项目的 `.git/hooks/` 创建 `post-commit` 钩子
- 创建项目配置文件 `.git-scripts-logs/.git-analyzer-config.json`
- 在 GitAnalyzer 目录创建项目日志目录

**执行时机**: 在每个需要分析的项目中执行一次

### 3. 项目注销脚本
**文件**: `.git-scripts-install/unregister.sh`

**功能**:
- 移除 Git 钩子
- 恢复备份的钩子（如果存在）
- 保留配置和日志（需手动删除）

**执行时机**: 当不再需要分析某个项目时

### 4. 服务控制脚本
**文件**: `.git-scripts-install/service-control.sh`

**功能**:
- 启动/停止全局服务（修改状态标记）
- 查看服务状态
- 列出所有已注册项目

**执行时机**: 随时可用

### 5. 跨项目分析包装脚本
**文件**: `.git-scripts-install/analyze_commit_wrapper.sh`

**功能**:
- 接收项目路径和代码差异作为参数
- 读取项目配置
- 调用 Gemini API 进行分析
- 保存结果到 `GitAnalyzer/项目名/code_summaries/`

**执行时机**: 由 Git 钩子自动触发

## 🔄 工作流程

### 安装流程

```
1. 用户执行全局安装脚本
   ↓
2. 创建 ~/.git-analyzer/ 目录结构
   ↓
3. 复制脚本到 ~/.git-analyzer/bin/
   ↓
4. 记录 GitAnalyzer 主目录到配置文件
   ↓
5. 添加环境变量到 shell 配置
   ↓
6. 完成安装
```

### 注册流程

```
1. 用户在项目目录执行 register.sh
   ↓
2. 检查是否为 Git 仓库
   ↓
3. 读取 GitAnalyzer 主目录位置
   ↓
4. 创建 post-commit 钩子
   ↓
5. 创建项目配置文件
   ↓
6. 在 GitAnalyzer 创建项目日志目录
   ↓
7. 完成注册
```

### 分析流程

```
1. 用户执行 git commit
   ↓
2. Git 触发 post-commit 钩子
   ↓
3. 钩子调用 analyze_commit_wrapper.sh
   ↓
4. 包装脚本读取项目配置
   ↓
5. 检查全局服务状态
   ↓
6. 获取代码差异
   ↓
7. 调用 Gemini API 分析
   ↓
8. 保存结果到 GitAnalyzer/项目名/
   ↓
9. 显示通知（Mac）
   ↓
10. 完成分析
```

## 📂 目录结构详解

### GitAnalyzer 项目目录

```
GitAnalyzer/
├── .git-scripts/                     # 原始分析脚本（保留兼容性）
│   ├── analyze_commit.sh             # 单项目分析脚本
│   └── toggle_analyzer.sh            # 开关控制脚本
│
├── .git-scripts-install/             # 安装和管理脚本
│   ├── git-analyzer-global-installer-new.sh  # 新版全局安装
│   ├── git-analyzer-global-installer.sh      # 旧版全局安装（保留）
│   ├── deploy-to-project.sh          # 旧版部署脚本（保留）
│   ├── register.sh                   # 项目注册脚本 ⭐
│   ├── unregister.sh                 # 项目注销脚本 ⭐
│   ├── service-control.sh            # 服务控制脚本 ⭐
│   └── analyze_commit_wrapper.sh     # 跨项目分析包装脚本 ⭐
│
├── .git-scripts-logs/                # 配置模板
│   └── .git-analyzer-config.json     # 默认配置模板
│
├── 项目A/                            # 项目A的分析数据
│   ├── logs/
│   │   └── analyzer.log              # 分析日志
│   └── code_summaries/
│       └── YYYYMM/DD/                # 按日期组织的分析结果
│
├── 项目B/                            # 项目B的分析数据
│   └── ...
│
├── README.md                         # 详细文档
├── QUICKSTART.md                     # 快速开始指南
└── IMPLEMENTATION.md                 # 本文档
```

### 全局安装目录

```
~/.git-analyzer/
├── bin/                              # 可执行脚本
│   ├── register.sh                   # 从 GitAnalyzer 复制
│   ├── unregister.sh                 # 从 GitAnalyzer 复制
│   └── service-control.sh            # 从 GitAnalyzer 复制
│
├── config/                           # 全局配置
│   ├── analyzer_home                 # GitAnalyzer 主目录路径
│   └── service_status                # 服务状态 (enabled/disabled)
│
└── README.md                         # 使用说明
```

### 项目目录

```
your-project/
├── .git/
│   └── hooks/
│       └── post-commit               # Git 钩子（注册时创建）
│
├── .git-scripts-logs/                # 项目配置目录
│   └── .git-analyzer-config.json     # 项目配置文件
│
└── [项目文件...]
```

## 🎯 设计优势

### 1. 集中管理
- 所有项目的分析日志集中在 GitAnalyzer 目录
- 便于备份、查看和管理
- 避免项目目录混乱

### 2. 全局共享
- 一次安装，所有项目共享
- 更新 GitAnalyzer 即可影响所有项目
- 减少维护成本

### 3. 简单注册
- 项目中只需运行一个命令
- 自动创建所有必要的配置
- 支持快速注销

### 4. 灵活控制
- 全局服务开关
- 项目级别配置
- 支持独立启用/禁用

### 5. 干净隔离
- 项目目录保持干净
- 只有必要的配置文件
- Git 钩子自动管理

## 🔐 安全考虑

1. **备份机制**: 注册时自动备份现有的 Git 钩子
2. **权限控制**: 所有脚本都有执行权限检查
3. **错误处理**: 完善的错误处理和日志记录
4. **配置保留**: 注销时保留配置和日志，防止误删

## 🚀 扩展性

### 支持的扩展

1. **多模型支持**: 可在配置中切换不同的 Gemini 模型
2. **自定义分析**: 可修改 prompt 模板
3. **通知系统**: 支持 Mac 系统通知，可扩展其他平台
4. **日志格式**: 支持自定义日志格式和存储位置

### 未来改进方向

1. **Web 界面**: 提供 Web 界面查看分析结果
2. **统计报告**: 生成项目代码质量趋势报告
3. **团队协作**: 支持团队共享分析结果
4. **CI/CD 集成**: 集成到 CI/CD 流程

## 📝 关键实现细节

### 1. 路径解析

```bash
# 获取 GitAnalyzer 主目录
ANALYZER_HOME="$(cat ~/.git-analyzer/config/analyzer_home)"

# 获取项目根目录
PROJECT_ROOT="$(git rev-parse --show-toplevel)"

# 构建项目日志目录
PROJECT_LOGS_DIR="$ANALYZER_HOME/$PROJECT_NAME"
```

### 2. 配置读取

```bash
# 使用 jq 读取 JSON 配置
if command -v jq &> /dev/null; then
    ENABLED=$(jq -r '.enabled' "$CONFIG_FILE")
else
    # 降级到默认值
    ENABLED="true"
fi
```

### 3. 后台执行

```bash
# 使用 nohup 在后台执行，避免阻塞 Git 提交
nohup bash "$WRAPPER_SCRIPT" "$PROJECT_ROOT" "$DIFF_CONTENT" > /dev/null 2>&1 &
```

### 4. 状态管理

```bash
# 全局服务状态
SERVICE_STATUS=$(cat ~/.git-analyzer/config/service_status)

# 项目配置状态
ENABLED=$(jq -r '.enabled' "$CONFIG_FILE")
```

## 🧪 测试建议

### 测试场景

1. **全局安装测试**
   - 首次安装
   - 重复安装
   - 环境变量配置

2. **项目注册测试**
   - 正常注册
   - 重复注册
   - 非 Git 仓库注册

3. **分析功能测试**
   - 正常提交
   - 大型提交
   - 空提交
   - 首次提交

4. **服务控制测试**
   - 启动/停止服务
   - 查看状态
   - 列出项目

5. **注销测试**
   - 正常注销
   - 恢复备份钩子

## 📞 支持

如有问题，请查看：
- [README.md](./README.md) - 详细文档
- [QUICKSTART.md](./QUICKSTART.md) - 快速开始
- GitAnalyzer 项目日志文件

---

**实现完成！** ✅
