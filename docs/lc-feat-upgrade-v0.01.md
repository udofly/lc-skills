# lc-feat 工作流升级记录

> 全部 skill 统一版本：**0.0.1**（预发布验证阶段，确认无问题后发布 v1.0）
> 日期：2026-04-15
> 参考：gstack 工作流架构 + OpenSpec Artifact Graph 设计

---

## Skill 清单（11 个，全部 0.0.1）



| Skill | 文件 | 本次改动 |
|---|---|---|
| lc-feat-pipeline | `~/.claude/skills/lc-feat-pipeline/SKILL.md` | P1 + P2 + P3 + P4 + P5 + Preamble |
| lc-feat-requirement | `~/.claude/skills/lc-feat-requirement/SKILL.md` | 版本号统一 |
| lc-feat-design | `~/.claude/skills/lc-feat-design/SKILL.md` | 版本号统一 |
| lc-feat-design-review | `~/.claude/skills/lc-feat-design-review/SKILL.md` | P4 质量门控 |
| lc-feat-implement | `~/.claude/skills/lc-feat-implement/SKILL.md` | 版本号统一 |
| lc-feat-lint | `~/.claude/skills/lc-feat-lint/SKILL.md` | P4 质量门控 |
| lc-feat-test | `~/.claude/skills/lc-feat-test/SKILL.md` | 版本号统一 |
| lc-feat-qa | `~/.claude/skills/lc-feat-qa/SKILL.md` | 版本号统一 |
| lc-feat-pr | `~/.claude/skills/lc-feat-pr/SKILL.md` | 版本号统一 |
| lc-feat-post-ship | `~/.claude/skills/lc-feat-post-ship/SKILL.md` | P5 经验积累 |
| lc-feat-api-sync | `~/.claude/skills/lc-feat-api-sync/SKILL.md` | 版本号统一 |

---

## 改动详情

### P1 - 步骤间自动状态感知

每步执行前检查前置产出文件是否存在，不存在则提示补充。

### P2 - 跨会话恢复（progress.yaml）

`docs/pipeline/{feat-name}/progress.yaml` 记录每步 status + depends + decisions，新会话自动恢复。

### P3 - 产出物结构化依赖

每步声明 `depends` 字段，pipeline 检查依赖满足后才执行。

### P4 - 质量门控

- **lint**：实际执行 `npx eslint` + `--fix`，新增代码有 error 则阻塞
- **design-review**：P1 级问题阻塞，需求覆盖度 < 80% 阻塞

### P5 - 学习和反馈积累

- pipeline 中自动记录关键决策到 `progress.yaml.decisions`
- post-ship 完成后写入 Claude Memory（project + feedback 类型）

### Preamble - 每步执行前上下文注入

每步执行前自动运行 Preamble：
1. 读取 progress.yaml 获取进度状态和历史决策
2. 搜索 Claude Memory 加载最多 3 条相关经验
3. 读取前序产出的关键片段（按步骤类型裁剪，不全文加载）
4. 组装为结构化上下文输出后再执行当前步骤

---

## 版本规划

| 版本 | 状态 | 说明 |
|---|---|---|
| **0.0.1** | 当前 | 预发布验证，实际项目中跑通全流程 |
| **1.0.0** | 待定 | 确认无问题后正式发布 |
