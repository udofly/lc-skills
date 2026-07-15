# lc-skill-sync — 本地 skill 同步到公司仓库

把 `~/.claude/skills` 下**选定的** `lc-*` skill 单向同步到公司 agent-skills 仓库：
复制目录（含 references/ 等附属文件）→ 按映射表重命名（frontmatter `name` + 正文交叉引用）→ 可选一键 PR。

```
本地 ~/.claude/skills/lc-xxx   ──单向──▶   公司仓库 skills/fe-xxx
        （唯一源）                          （只读镜像，勿手改）
```

## 核心原则

1. **本地是唯一源**：同步会覆盖公司侧同名目录的一切改动。评审意见、公司侧的修改，都应改回本地再同步，不要直接改公司副本。
2. **映射表是白名单**：只有 `sync-map.conf` 里列出的 skill 会被同步；映射表外的 skill 无论如何不会被复制、不会被 `git add`、不会进 PR。
3. **默认不碰 git**：默认模式只把文件同步到公司仓库当前分支的工作区，提交和 PR 由你决定；`--pr` 才走全自动流程。

## 快速开始

```bash
# 看看本地和公司库差在哪（不做任何修改）
bash ~/.claude/skills/lc-skill-sync/scripts/sync.sh --check

# 同步（默认模式：复制+重命名到公司仓库工作区，不提交）
bash ~/.claude/skills/lc-skill-sync/scripts/sync.sh

# 全自动：建分支 → 提交 → 推送 fork → 向上游开 PR
bash ~/.claude/skills/lc-skill-sync/scripts/sync.sh --pr
```

对 Claude 说 **"同步公司skill"** 等价于交互式执行上述流程（先 check 汇报，确认后同步）。

## 配置：sync-map.conf

```
TARGET_REPO=/Users/gaochunfa/project/project-agent/agent-skills   # 公司仓库本地路径
TARGET_SUBDIR=skills            # skill 存放子目录
UPSTREAM_REMOTE=upstream        # 上游 remote 名（weiran-tech/skills）
UPSTREAM_BRANCH=main            # PR 目标分支
PR_REPO=weiran-tech/skills      # gh pr create 的目标仓库
FORK_OWNER=udofly               # 你的 fork 所有者（--head 用）

lc-backend-page -> fe-backend-page      # 一行一个映射：本地名 -> 公司名
```

- **改公司命名**：改右边即可，下次同步自动按新名字建目录并重写引用（旧目录不会自动删除，需要手动在公司仓库里删掉旧目录）。
- **新增同步项**：加一行。
- **停止同步某个 skill**：删掉那一行（公司库中已存在的副本会保留，只是不再更新）。

## 三种模式详解

### `--check`（只读）

对每个映射项，把本地版在内存中完成重命名后与公司版逐文件对比，输出：

```
本地 skill 与公司库存在差异：
  🆕 fe-mp-taobao 公司库中不存在（待首次同步）
  📝 fe-backend-page 有漂移（diff 184 行）
```

加 `--quiet`：无漂移时完全静默（适合放进 git hook / 定时任务做提醒）。

### 默认模式（同步，不碰 git）

把映射表内的 skill 全部同步到 `TARGET_REPO/skills/` 下、公司仓库**当前所在分支**的工作区，使用 `rsync --delete`（公司副本内多余的文件会被删除，保证和本地一致）。之后你自己 `git diff` 检查、提交、发 PR。

### `--pr`（全自动流程）

1. 校验公司仓库工作区干净（不干净直接中止，不会替你 stash）
2. `git fetch upstream` 后从 `upstream/main` 切出 `sync/skills-<时间戳>` 分支（保证 PR 干净、不带你 fork 上的其他改动）
3. 同步 + 只 `git add` 映射表内的目标目录
4. commit → push 到 origin（你的 fork）→ `gh pr create` 向 `weiran-tech/skills` 开 PR
5. 切回你原来的分支，打印 PR 链接

## 重命名到底改了什么

以 `lc-backend-page -> fe-backend-page` 为例：

| 位置 | 改动 |
|------|------|
| 目录名 | `lc-backend-page/` → `fe-backend-page/` |
| frontmatter `name:` | 强制改为 `fe-backend-page` |
| 正文交叉引用 | 所有 `.md` 文件里出现的**映射表内**本地名全部替换（如正文里的 `lc-kr36-ui-guide` → `fe-kr36-ui-guide`），词边界匹配，不会误伤 `lc-backend-page-v2` 这类相似名 |

**映射表外的 `lc-*` 引用**会原样保留并打印 ⚠️ 警告，因为公司库没有对应 skill，替换成什么需要人来决定。处理方式二选一：把被引用的 skill 也加入映射表，或在本地把该引用改为可选说明（"有则用，没有则忽略"），改完后把名字登记到 `sync-map.conf` 的 `IGNORE_REFS`，之后不再重复告警。新出现的未知引用仍会正常告警。

## 常见问题

**Q: 公司评审要求改内容怎么办？**
改**本地**的 skill，重新跑同步/`--pr`。直接改公司副本会在下次同步时被覆盖。

**Q: `--pr` 报"工作区不干净"？**
公司仓库有未提交改动。自己 commit 或 stash 后重跑。

**Q: PR 创建失败但分支已推送？**
手动开 PR：`https://github.com/weiran-tech/skills/compare/main...udofly:<分支名>`

**Q: 想在每次本地 skill 提交后自动提醒漂移？**
自行安装 post-commit 钩子（脚本不会替你装）：

```bash
cat > ~/.claude/skills/.git/hooks/post-commit <<'EOF'
#!/bin/sh
bash "$HOME/.claude/skills/lc-skill-sync/scripts/sync.sh" --check --quiet 2>/dev/null || true
EOF
chmod +x ~/.claude/skills/.git/hooks/post-commit
```

装好后每次 `git commit` 本地 skill 仓库，若映射表内 skill 有漂移会打印一行提醒；只提醒，绝不自动同步或发 PR。

## 文件清单

```
lc-skill-sync/
├── SKILL.md            # Claude 触发用（"同步公司skill"）
├── README.md           # 本文件
├── sync-map.conf       # 目标仓库配置 + 映射白名单
└── scripts/
    └── sync.sh         # 同步脚本（--check / 默认 / --pr）
```
