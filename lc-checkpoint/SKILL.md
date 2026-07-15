---
name: lc-checkpoint
description: 保存和恢复工作状态检查点（save/resume/list）。把当前会话的工作内容、决策、剩余任务和 git 状态写成 markdown 检查点，存到 ~/.claude/checkpoints/<项目名>/，跨会话、跨分支可恢复。当用户说"存档"、"保存进度"、"记录一下进度"、"checkpoint"、"打个检查点"、"恢复进度"、"我上次做到哪了"、"接着上次继续"、"列出检查点"时触发；会话即将结束、用户要切换任务或休息前，也应主动建议保存检查点。零外部依赖，仅使用 git 和文件读写。
---

# lc-checkpoint — 保存与恢复工作状态

你是一个记笔记严谨的资深工程师。你的任务是把当前工作上下文——在做什么、做了哪些决策、还剩什么——完整记录下来，让未来任何一个会话（哪怕换了分支）都能无缝接上。

**硬性约束：本 skill 只读取状态、只写检查点文件，绝不修改项目代码。**

## 存储位置

所有子命令共用同一个目录约定：

```bash
PROJECT=$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || basename "$PWD")
CP_DIR="$HOME/.claude/checkpoints/$PROJECT"
mkdir -p "$CP_DIR"
```

不在 git 仓库时退化为当前目录名，功能不受影响（git 相关字段留空即可）。

## 命令解析

- 无参数或 `save` → **保存**
- `resume [名称]` → **恢复**（可指定名称片段）
- `list`（可带 `--all`）→ **列表**
- `clean [--days N]` → **清理过期检查点**（默认 30 天）

标题优先级：
1. 用户在命令后明确给了标题（如 `保存进度 登录重构`）→ 用用户给的
2. 没给标题 → 用**当前分支名**做标题（slug 化，如 `feature/3.43-lingxiu` → `feature-3-43-lingxiu`）

---

## 保存（save）

### 1. 收集 git 状态

```bash
git rev-parse --abbrev-ref HEAD
git status --short
git diff --stat
git diff --cached --stat
git log --oneline -10
```

### 2. 总结上下文

结合 git 状态和**本次对话历史**，整理四块内容：

1. **在做什么** —— 高层目标或功能
2. **已做决策** —— 架构选择、取舍及理由（这是检查点最有价值的部分：git 能看出改了什么，看不出为什么这么改）
3. **剩余工作** —— 具体下一步，按优先级排序
4. **备注** —— 坑、被阻塞项、开放问题、试过但没成的方案

宁可从对话里推断，不要反问用户——只有标题实在推断不出时才问。

### 3. 写检查点文件

文件路径：`$CP_DIR/$(date +%Y%m%d-%H%M%S)-<title-slug>.md`。slug 用英文 kebab-case（中文标题翻成简短英文，如"登录重构" → `login-refactor`）。

文件格式：

```markdown
---
status: in-progress
branch: <当前分支>
timestamp: <ISO-8601 时间，如 2026-07-14T15:48:37+08:00>
files_modified:
  - path/to/file1
  - path/to/file2
---

## Working on: <标题>

### Summary

<1-3 句：目标与当前进度>

### Decisions Made

<决策列表，带理由>

### Remaining Work

<编号的下一步，按优先级>

### Notes

<坑、阻塞、开放问题>
```

`files_modified` 来自 `git status --short`（含 staged 和未 staged），用仓库根目录的相对路径；新增目录可整体列出并标注"(新增)"。

### 4. 确认输出

```
✅ 检查点已保存
标题：<标题>
分支：<分支>
文件：<完整路径>
改动：<N> 个文件
```

---

## 恢复（resume）

### 1. 找检查点

```bash
ls -1t "$CP_DIR"/*.md 2>/dev/null | head -20
```

列出**所有分支**的检查点（分支名记录在 frontmatter 里，跨分支恢复正是设计目标）。目录为空时告知："还没有检查点，说'保存进度'即可创建。"

### 2. 加载并呈现

**匹配优先级**（依次尝试）：
1. 用户给了名称片段（如 `恢复进度 登录重构` 或 `resume login`）→ 在文件名里做模糊匹配，取最近的那个
2. 用户给了编号（如 `恢复进度 2`）→ 对应 list 里的第 N 条
3. 什么都没给 → 先找文件名包含**当前分支名 slug** 的最新检查点；没有匹配的再取全局最新

模糊匹配时忽略大小写和语言（中文"登录"能匹配文件名里的"login-refactor"吗？尽量宽松，实在匹配不上就列出候选让用户选）。

读出后按此结构呈现：

```
📌 恢复检查点
标题：  <标题>
分支：  <frontmatter 中的分支>
保存于：<人类可读时间>
状态：  <status>

### Summary / Remaining Work / Notes
<对应内容>
```

若检查点分支与当前分支不一致，明确提示："此检查点保存于分支 `X`，你当前在 `Y`，继续前可能需要切换分支。"

### 3. 给出下一步

呈现后问用户：A) 继续做剩余工作（并点出第 1 项）；B) 看检查点原文；C) 只是要上下文。选 A 就从剩余工作第 1 项开始。

---

## 列表（list）

读取每个文件的 frontmatter（status、branch、timestamp），标题从文件名解析。**默认只显示当前分支**的检查点；`--all` 显示全部并加 Branch 列。

```
检查点（feature/xxx 分支）
#  日期        标题                Status
1  2026-07-14  seo-rewrite-batch   in-progress
2  2026-07-10  login-refactor      completed
```

没有检查点时提示用户如何创建。

---

## 清理（clean）

自动删除超过指定天数的检查点，**只删当前项目的**（`$CP_DIR` 下）。默认 **7 天**。

```bash
# 默认 7 天
find "$CP_DIR" -name "*.md" -mtime +7 -type f

# 用户指定天数，如 `clean --days 30`
find "$CP_DIR" -name "*.md" -mtime +30 -type f
```

执行前先列出将被删除的文件并让用户确认：

```
⚠️ 以下检查点将被删除（超过 7 天）：
  - 20260601-090000-login-refactor.md（保存于 2026-06-01，45 天前）
  - 20260610-143000-api-pagination.md（保存于 2026-06-10，34 天前）

确认删除？(y/n)
```

用户确认后执行删除，报告删了几个、释放了多少空间。用户说 n 则取消。

**触发词**：用户说"清理检查点"、"删过期的"、"clean checkpoint"、`--days N` 时触发。也可以在保存检查点时顺带提示（仅当过期文件超过 3 个时）："顺便提一下，你有 X 个超过 7 天的检查点，说'清理检查点'可以清理。"

---

## 规则

- **绝不修改代码。** 只读状态、只写检查点文件。
- **检查点只增不改。** 每次保存都新建文件，不覆盖不删除——历史检查点本身就是工作日志。
- **frontmatter 必须记录分支名**，这是跨分支恢复的前提。
- **推断优先于提问。** 用 git 状态和对话历史填内容，别把保存变成问卷。
