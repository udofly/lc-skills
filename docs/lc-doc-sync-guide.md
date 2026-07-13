# lc-doc-sync 文档时间同步使用指南

> 版本: 1.0 | 更新日期: 2026-07-13 | 全局 skill，适用于所有项目（约定从项目自身技能读取）

---

## 目录

- [1. 概述](#1-概述)
- [2. 核心机制：一本账 + 两枚戳 + 一个锚点](#2-核心机制一本账--两枚戳--一个锚点)
- [3. 命令用法](#3-命令用法)
- [4. 与 lc-feat:document-release 的分工](#4-与-lc-featdocument-release-的分工)
- [5. 项目接入：需要声明的约定](#5-项目接入需要声明的约定)
- [6. 变更 → 文档映射规则](#6-变更--文档映射规则)
- [7. 常用场景速查](#7-常用场景速查)
- [8. 注意事项 & FAQ](#8-注意事项--faq)
- [9. 实例：kejinshou_m 的接入](#9-实例kejinshou_m-的接入)

---

## 1. 概述

`lc-doc-sync` 按**时间 / commit 粒度**兜底同步项目文档：`lc-feat:document-release` 在 PR 合并后按**功能粒度**精细更新本功能文档，但 hotfix、重构、直接提交、他人合并的功能会绕过流水线——本 skill 负责把这些"漏网"变更对应的文档补齐。

两者共写同一本更新账本、同一套 frontmatter 时间戳，互为补充而非替代。

## 2. 核心机制：一本账 + 两枚戳 + 一个锚点

| 要素 | 说明 |
|------|------|
| 更新账本 | 项目文档根目录下的 `updates.md`：frontmatter `last_sync`（commit / date / by）+「更新记录」表（新记录在最上） |
| 记录行格式 | `日期 / 同步范围（起止 commit）/ 来源 / 更新文档 / 摘要` |
| 文档时间戳 | 每篇被更新的文档 frontmatter 打 `updated: YYYY-MM-DD` + `commit: <对齐的源码短 hash>` |
| 增量锚点 | `last_sync.commit`；**只由 lc-doc-sync 完整同步到 HEAD 后推进**，document-release 只打戳 + 记账 |
| 幂等判断 | 目标文档 `commit` 等于变更 commit 或是其后代 → 已同步，跳过（两个 skill 重叠运行不重复劳动）；文档无戳时回退比较文档与源码各自的最后提交时间 |

## 3. 命令用法

| 命令 | 行为 | 何时用 |
|------|------|--------|
| `/lc-doc-sync` | 增量：账本锚点 → HEAD 的源码变更映射到文档并更新，打戳、记账、推进锚点 | 版本合入 master 后；document-release 收尾报告提示有漏网时 |
| `/lc-doc-sync --since=<日期或commit>` | 从指定起点 → HEAD（日期折算为 commit） | 锚点失效 / 回溯补某段时间的文档 |
| `/lc-doc-sync --scan` | 全局扫描：逐篇比对文档 frontmatter `commit` 与源码最新提交 | 季度体检 / 怀疑大面积过时 |
| 任意模式 + `--check` | **只输出报告，不改任何文件（含账本）** | 先看欠账再决定 |

`--check` 报告内容：过时文档清单（每篇的落后 commit 区间与原因摘要）、未映射变更、工作区未提交改动附注、锚点信息。

## 4. 与 lc-feat:document-release 的分工

| | `lc-feat:document-release` | `lc-doc-sync` |
|---|---|---|
| 时机 | PR 合并后（流水线收尾） | 定期 / 按需 |
| 粒度 | 功能（feat-name） | 时间 / commit 区间 |
| 信息源 | 流水线 spec.md（需求+设计）+ 代码 | git diff + 代码 |
| 职责 | 精细更新本功能文档 + 收尾杂务 | 兜底捕捉绕过流水线的变更 |
| 账本 | 打戳 + 追加记录 | 打戳 + 追加记录 + **推进锚点** |

**协作点**：document-release（≥0.0.8）收尾时自动跑一次 `lc-doc-sync --check`（只读），在总结里列出同期漏网变更；补齐由用户显式跑 `/lc-doc-sync`。

## 5. 项目接入：需要声明的约定

本 skill **不硬编码任何项目路径**，运行时按以下链路读约定（与 document-release 同款委托模式，见 [lc-feat-coding-standard-loading.md](./lc-feat-coding-standard-loading.md)）：

```
项目 .claude/CLAUDE.md
  → 引用的项目编码规范技能（如 lc-kejinshou-h5-vue）
    → 其「文档维护约定」章节（单一事实源）
```

项目技能的「文档维护约定」需声明：

1. 文档根目录、业务文档结构（如 1:1 镜像 `src/views`）、页面模板、命名规则、侧边栏文件、校验命令（document-release 也读这些）；
2. **更新账本位置**（如 `docs/<站点目录>/updates.md`）、记录行格式、frontmatter 时间戳与幂等约定、锚点推进规则；
3. （可选）临时文档区（如 `docs/temp/`：不挂侧边栏、不入账本、不打戳、不入库）。

项目未声明账本 → skill 会提示并可代为初始化（锚点取用户指定 commit 或当前 HEAD）。

## 6. 变更 → 文档映射规则

以 1:1 镜像结构为例（具体以项目约定为准）：

| 变更源码 | 目标文档 |
|----------|----------|
| 页面 `.vue` | 对应页面文档；新增页面或**历史漏建**均按模板新建 + 更新模块 index + 挂侧边栏 |
| 页面子组件 | grep 引用它的页面 → 页面文档「组件依赖」；引用方是公共组件 → 归入公共组件顶层文档 |
| 路由文件 | diff 受影响路由 → 页面文档「路由」段 |
| 请求层 | 引用页面的「接口依赖」表 + 顶层 api 文档 |
| 公共组件 / 工具 / composables | 项目声明的顶层文档（components / utils 等） |
| 删除的页面 | 文档标注废弃或删除（删除需用户确认）+ 从 index / 侧边栏摘除 |

映射不到的变更列入报告「未映射变更」，**不静默丢弃**。

## 7. 常用场景速查

| 场景 | 做法 |
|------|------|
| 功能发布收尾 | `/lc-feat:document-release`（自动含漏网检查） |
| 版本合入 master 后 | `/lc-doc-sync` 补齐同期漏网 + 推进锚点 |
| 想先看欠了多少账 | `/lc-doc-sync --check` |
| 季度 / 大重构后体检 | `/lc-doc-sync --scan --check` → 看清单再决定全量更新 |
| 新项目首次接入 | 项目技能声明约定 → 初始化账本（锚点=当前文档对齐的 commit）→ 首次 `/lc-doc-sync` 补齐欠账 |

## 8. 注意事项 & FAQ

- **只覆盖已提交内容**：工作区未提交改动不在 `起点..HEAD` 范围，报告附注会提醒。
- **过时文档 > 15 篇**：先出清单让用户圈范围（全部 / 核心模块 / 自选），避免海量低质更新；`--check` 不触发圈范围，直接输出全量清单。
- **锚点只增不减**：`--since` 早于当前锚点属回溯同步，只记账不回退锚点。
- **不自动 git commit**：文档改动建议独立 `docs:` 提交。
- **内容纪律**：以代码为准、只写业务层面；改已有文档 Edit 相关字段，不重写整篇（与 document-release 同款 Guardrails）。

## 9. 实例：kejinshou_m 的接入

| 项 | 值 |
|----|----|
| 约定声明 | Skill `lc-kejinshou-h5-vue` §16「文档维护约定」（v1.6 起含账本/时间戳/temp 区） |
| 账本 | `docs/kejinshou-h5-vue/updates.md`（基线锚点 `05a2e51b`，2026-06-24） |
| 文档结构 | `docs/kejinshou-h5-vue/modules/` 1:1 镜像 `src/views/`，模板 `_TEMPLATE.md` |
| 临时区 | `docs/temp/`（gitignore，仅 README 入库） |
| 站内指南 | `docs/kejinshou-h5-vue/doc-maintenance.md`（文档站侧使用向导） |
| 校验 | `pnpm docs:build` |
