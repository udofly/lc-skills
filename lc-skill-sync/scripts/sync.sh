#!/usr/bin/env bash
# 同步本地 skill 到公司 agent-skills 仓库
# 只同步映射表（sync-map.conf）内的 skill，映射表外的一律不碰。
# 用法：
#   sync.sh              默认：复制+重命名到公司仓库当前分支工作区（不碰 git）
#   sync.sh --check      只报告漂移，不做修改（--quiet 时无漂移则静默）
#   sync.sh --pr         全流程：建分支 -> 同步 -> 提交 -> 推送 -> 开 PR
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONF="$SKILL_DIR/sync-map.conf"
LOCAL_ROOT="$HOME/.claude/skills"

MODE="sync"
QUIET=0
for arg in "$@"; do
    case "$arg" in
        --check) MODE="check" ;;
        --pr) MODE="full" ;;
        --quiet) QUIET=1 ;;
        *) echo "未知参数: $arg" >&2; exit 1 ;;
    esac
done

# ---- 解析配置 ----
declare -a SRC_NAMES=() DST_NAMES=()
while IFS= read -r line; do
    line="${line%%#*}"
    line="$(echo "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
    [ -z "$line" ] && continue
    if [[ "$line" == *"->"* ]]; then
        src="$(echo "${line%%->*}" | sed 's/[[:space:]]*$//')"
        dst="$(echo "${line##*->}" | sed 's/^[[:space:]]*//')"
        SRC_NAMES+=("$src"); DST_NAMES+=("$dst")
    elif [[ "$line" == *"="* ]]; then
        eval "${line%%=*}='${line#*=}'"
    fi
done < "$CONF"

TARGET_SKILLS="$TARGET_REPO/$TARGET_SUBDIR"
[ -d "$TARGET_SKILLS" ] || { echo "❌ 目标目录不存在: $TARGET_SKILLS" >&2; exit 1; }
[ "${#SRC_NAMES[@]}" -gt 0 ] || { echo "❌ 映射表为空: $CONF" >&2; exit 1; }

# ---- 复制到临时目录并重写名称 ----
# 重写规则：映射表内所有本地名 -> 公司名（含 frontmatter name 和正文交叉引用）
rewrite_and_stage() {
    local tmp="$1"
    for i in "${!SRC_NAMES[@]}"; do
        local src="${SRC_NAMES[$i]}" dst="${DST_NAMES[$i]}"
        local src_dir="$LOCAL_ROOT/$src"
        [ -d "$src_dir" ] || { echo "❌ 本地 skill 不存在: $src_dir" >&2; exit 1; }
        rsync -a --delete --exclude .DS_Store "$src_dir/" "$tmp/$dst/"
        # 全量替换映射表中的名字（词边界），并强制修正 frontmatter name
        MAP_SRC="$(printf '%s\n' "${SRC_NAMES[@]}")" MAP_DST="$(printf '%s\n' "${DST_NAMES[@]}")" \
        python3 - "$tmp/$dst" "$dst" <<'PYEOF'
import os, re, sys, pathlib
target_dir, dst_name = sys.argv[1], sys.argv[2]
pairs = list(zip(os.environ['MAP_SRC'].splitlines(), os.environ['MAP_DST'].splitlines()))
for md in pathlib.Path(target_dir).rglob('*.md'):
    text = md.read_text(encoding='utf-8')
    for s, d in pairs:
        text = re.sub(r'(?<![\w-])' + re.escape(s) + r'(?![\w-])', d, text)
    md.write_text(text, encoding='utf-8')
skill_md = pathlib.Path(target_dir) / 'SKILL.md'
if skill_md.exists():
    text = skill_md.read_text(encoding='utf-8')
    text = re.sub(r'^(name:\s*).*$', r'\g<1>' + dst_name, text, count=1, flags=re.M)
    skill_md.write_text(text, encoding='utf-8')
PYEOF
    done
    # 残留的 lc- 引用（映射表外的），提示人工确认；IGNORE_REFS 里登记的可选引用不告警
    local leftovers
    leftovers="$(grep -rn --include='*.md' -oE '(^|[^[:alnum:]-])lc-[a-z0-9:-]+' "$tmp" | sed 's/.*\(lc-[a-z0-9:-]*\)/\1/' | sort -u || true)"
    if [ -n "${IGNORE_REFS:-}" ]; then
        for ref in $IGNORE_REFS; do
            leftovers="$(echo "$leftovers" | grep -vx "$ref" || true)"
        done
    fi
    if [ -n "$leftovers" ]; then
        echo "⚠️  以下 lc- 引用不在映射表中，已原样保留（公司库可能没有对应 skill）："
        echo "$leftovers" | sed 's/^/    /'
        while IFS= read -r ref; do
            grep -rl --include='*.md' -F "$ref" "$tmp" 2>/dev/null || true
        done <<< "$leftovers" | sort -u | sed "s|$tmp/|    出现于: |"
    fi
}

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
rewrite_and_stage "$TMP"

# ---- check 模式：只报告漂移 ----
if [ "$MODE" = "check" ]; then
    drift=0
    report=""
    for i in "${!SRC_NAMES[@]}"; do
        dst="${DST_NAMES[$i]}"
        if [ ! -d "$TARGET_SKILLS/$dst" ]; then
            report+="  🆕 $dst 公司库中不存在（待首次同步）"$'\n'; drift=1
        else
            n="$( (diff -r --exclude .DS_Store "$TMP/$dst" "$TARGET_SKILLS/$dst" 2>/dev/null || true) | wc -l | tr -d ' ')"
            if [ "$n" != "0" ]; then
                report+="  📝 $dst 有漂移（diff $n 行）"$'\n'; drift=1
            fi
        fi
    done
    if [ "$drift" = "1" ]; then
        echo "本地 skill 与公司库存在差异："
        printf '%s' "$report"
        echo "执行同步：对 Claude 说\"同步公司skill\"，或运行 sync.sh"
        exit 0
    fi
    [ "$QUIET" = "1" ] || echo "✅ 公司库与本地一致，无需同步"
    exit 0
fi

# ---- 落盘到目标仓库 ----
do_copy() {
    for i in "${!SRC_NAMES[@]}"; do
        rsync -a --delete --exclude .DS_Store "$TMP/${DST_NAMES[$i]}/" "$TARGET_SKILLS/${DST_NAMES[$i]}/"
    done
}

if [ "$MODE" = "sync" ]; then
    do_copy
    echo "✅ 已同步 ${#SRC_NAMES[@]} 个 skill 到 ${TARGET_SKILLS}（当前分支 $(git -C "$TARGET_REPO" branch --show-current)，未提交）"
    echo "   提交/PR 请自行处理，或运行 sync.sh --pr 走全流程"
    exit 0
fi

# ---- 全流程：分支 -> 同步 -> 提交 -> 推送 -> PR ----
cd "$TARGET_REPO"
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ 公司仓库工作区不干净，请先处理未提交改动：" >&2
    git status --short >&2
    exit 1
fi
PREV_BRANCH="$(git branch --show-current)"
git fetch "$UPSTREAM_REMOTE" "$UPSTREAM_BRANCH" --quiet
BRANCH="sync/skills-$(date +%Y%m%d-%H%M%S)"
git checkout -q -b "$BRANCH" "$UPSTREAM_REMOTE/$UPSTREAM_BRANCH"

do_copy

if [ -z "$(git status --porcelain)" ]; then
    git checkout -q "$PREV_BRANCH"; git branch -D "$BRANCH" >/dev/null
    echo "✅ 与 $UPSTREAM_REMOTE/$UPSTREAM_BRANCH 相比无变化，无需 PR"
    exit 0
fi

SKILL_LIST="$(for i in "${!SRC_NAMES[@]}"; do echo "- ${SRC_NAMES[$i]} → ${DST_NAMES[$i]}"; done)"
# 只 add 映射表内的目标目录，映射表外的任何文件绝不进入提交
for i in "${!DST_NAMES[@]}"; do git add "$TARGET_SUBDIR/${DST_NAMES[$i]}"; done
git commit -q -m "feat(skills): 同步 fe 系列技能（${#SRC_NAMES[@]} 个）

来源：个人 skill 仓库（本地为唯一源，单向同步）
$SKILL_LIST

Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>"
git push -q -u origin "$BRANCH"
git checkout -q "$PREV_BRANCH"

PR_URL="$(gh pr create --repo "$PR_REPO" --base "$UPSTREAM_BRANCH" --head "$FORK_OWNER:$BRANCH" \
    --title "feat(skills): 同步 fe 系列技能（${#SRC_NAMES[@]} 个）" \
    --body "从个人 skill 仓库单向同步，frontmatter name 与正文交叉引用已按公司命名重写。

$SKILL_LIST

🤖 Generated with [Claude Code](https://claude.com/claude-code)")"
echo "✅ PR 已创建：$PR_URL"
