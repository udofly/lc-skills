---
name: lc-skill-sync
description: 把本地 ~/.claude/skills 下选定的 lc-* skill 单向同步到公司 agent-skills 仓库（复制 + 按映射表重命名 + 建分支 + 提交 + 推送 + 开 PR，一条命令完成）。当用户说"同步公司skill"、"skill同步到公司"、"同步到公司仓库"、"发公司skill PR"、"公司skill落后了"时触发；用户修改了映射表内的 skill 并提到要给公司仓库发 PR 时也应使用本技能。
---

# Skill 同步到公司仓库

本地 `~/.claude/skills` 是唯一源（single source of truth），同步永远单向：本地 → 公司。公司侧的手工改动会被覆盖，需要保留的改动应先反向合入本地。

## 配置

映射表与目标仓库配置都在 `sync-map.conf`（与本 SKILL.md 同目录）：

- `TARGET_REPO` / `PR_REPO` / `FORK_OWNER` 等：目标仓库参数
- `本地名 -> 公司名`：一行一个映射。**只有列在映射表里的 skill 会被同步**；调整公司命名改右边即可，新增同步项加一行。

**硬性边界：映射表外的 skill 一律不同步、不进提交。** 脚本只遍历映射表，`git add` 也只加映射表内的目标目录。

## 执行

```bash
bash ~/.claude/skills/lc-skill-sync/scripts/sync.sh          # 默认：同步到公司仓库当前分支工作区，不碰 git
bash ~/.claude/skills/lc-skill-sync/scripts/sync.sh --check  # 只报告漂移，不做任何修改
bash ~/.claude/skills/lc-skill-sync/scripts/sync.sh --pr     # 可选全流程：分支→提交→推送→开 PR
```

同步时的重写：frontmatter `name` 改为公司名；正文里映射表内的所有本地名同步替换（交叉引用不会指向不存在的名字）。

`--pr` 全流程：校验公司仓库工作区干净 → 从 `upstream/main` 切出 `sync/skills-<时间戳>` 分支 → 同步 → 只提交映射目录 → 推送到 fork（origin）→ `gh pr create` 向上游开 PR → 切回原分支并打印 PR 链接。

## 使用本技能时的操作步骤

1. 先跑 `--check` 给用户看漂移情况（哪些 skill 有差异、差多少）
2. 用户确认后跑默认同步；**只有用户明确要求发 PR 时才跑 `--pr`**
3. 把脚本输出的 ⚠️ 警告和 PR 链接原样转告用户；脚本失败时把 stderr 原样给用户看，常见原因见下

## 警告与失败处理

- **⚠️ lc- 引用不在映射表中**：某个被同步的 skill 正文引用了未同步的本地 skill（如 `lc-doc-sync`）。公司库没有对应物，引用按原名保留。处理方式二选一：把被引用的 skill 也加入映射表，或在本地把该引用改成可选说明。
- **工作区不干净**：公司仓库有未提交改动，脚本会中止。先让用户处理（commit/stash），不要替用户 stash。
- **gh 未登录 / PR 创建失败**：分支此时已推送到 fork，把手动建 PR 的 compare 链接给用户：`https://github.com/<PR_REPO>/compare/main...<FORK_OWNER>:<分支名>`。
- **PR 被评审要求修改**：在**本地** skill 上改（保持单一源），重新跑全流程会生成新分支新 PR；旧 PR 手动关闭。

## 自动提醒

`~/.claude/skills/.git/hooks/post-commit` 安装了钩子：每次本地 skill 仓库 commit 后自动跑 `--check --quiet`，映射表内的 skill 有漂移时打印一行提醒。只提醒，不自动发 PR——发 PR 的时机由用户决定。
