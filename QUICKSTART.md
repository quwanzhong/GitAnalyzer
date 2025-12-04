# GitAnalyzer 快速开始指南

## 🎯 三步开始使用

### 步骤 1: 全局安装（仅需一次）

```bash
cd /path/to/GitAnalyzer
bash .git-scripts-install/git-analyzer-global-installer-new.sh
source ~/.zshrc
```

### 步骤 2: 注册项目

```bash
cd /path/to/your/project
register.sh
```

### 步骤 3: 正常提交代码

```bash
git add .
git commit -m "your message"
# 🚀 代码分析自动运行！
```

## 📊 查看分析结果

```bash
cd /path/to/GitAnalyzer/你的项目名
ls code_summaries/
```

## 🎮 常用命令

```bash
# 查看服务状态
git-analyzer-status

# 列出所有已注册项目
git-analyzer-list

# 注销当前项目
unregister.sh
```

## 💡 提示

- 分析结果保存在：`GitAnalyzer/项目名/code_summaries/YYYYMM/DD/`
- 日志文件位于：`GitAnalyzer/项目名/logs/analyzer.log`
- 项目配置位于：`项目根目录/.git-scripts-logs/.git-analyzer-config.json`

## ❓ 遇到问题？

查看详细文档：[README.md](./README.md)

---

**就这么简单！** 🎉
