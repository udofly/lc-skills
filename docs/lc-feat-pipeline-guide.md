# lc-feat 功能开发流水线使用指南

> 版本: 1.9 | 更新日期: 2026-07-08 | 全局 skill，适用于所有项目

---

## 目录

- [1. 概述](#1-概述)
- [2. 流水线全景图](#2-流水线全景图)
- [3. 快速开始](#3-快速开始)
  - [3.1 一键流水线](#31-一键流水线)
  - [3.2 全自动模式](#32-全自动模式)
  - [3.3 逐步执行](#33-逐步执行)
  - [3.4 断点恢复](#34-断点恢复)
- [4. 主流程 Skill 详解（5步）](#4-主流程-skill-详解5步)
  - [4.1 需求分析 requirement](#41-需求分析-requirement)
  - [4.2 技术设计 design](#42-技术设计-design)
  - [4.3 编码实现 implement](#43-编码实现-implement)
  - [4.4 代码验证 verify](#44-代码验证-verify)
  - [4.5 E2E 端到端测试 e2e](#45-e2e-端到端测试-e2e)
- [4.6 CR / 创建 PR（独立步骤）](#46-cr--创建-pr独立步骤不在-pipeline-中执行)
- [5. 辅助 Skill 详解（3个）](#5-辅助-skill-详解3个)
  - [5.1 发布后文档处理 document-release](#51-发布后文档处理-document-release)
  - [5.2 接口同步 api-sync](#52-接口同步-api-sync)
  - [5.3 总控 pipeline](#53-总控-pipeline)
- [6. 产出文件总览](#6-产出文件总览)
- [7. 质量门控机制](#7-质量门控机制)
- [8. 与 gstack 的协作](#8-与-gstack-的协作)
- [9. 常用场景速查](#9-常用场景速查)
- [10. 命令速查表](#10-命令速查表)
- [11. 注意事项 & FAQ](#11-注意事项--faq)
- [12. 完整使用用例：从零开发「优惠券管理」功能](#12-完整使用用例从零开发优惠券管理功能)

---

## 1. 概述

`lc-feat` 是一套 **端到端的功能开发流水线**，由 9 个 Claude Code skill 组成，覆盖从需求分析到 PR 发布的完整生命周期。

**核心特点：**
- **标准化流程** — 每个功能按统一流程开发，产出可追溯
- **逐步确认** — 每步完成后暂停，`y` 继续 / `s` 跳过（需求分析→技术设计连续执行、合并审核一次）
- **单文档产出** — 需求与设计合并为一份 `spec.md`（一、需求 + 二、设计 + 自审修订），重复内容只写一次
- **全自动模式** — `--auto` 参数一口气跑完，无需确认，适合小功能快速开发
- **断点恢复** — 流水线中断后可从任意步骤继续
- **质量门控** — Lint + 测试 + QA 评分多重把关
- **接口灵活** — 有接口走 Apifox MCP，无接口自动 mock，后续可同步替换
- **全局可用** — 安装在 `~/.claude/` 下，任何项目都可使用
- **gstack 联动** — 与 gstack 的 `/qa`、`/ship`、`/document-release` 等 skill 协作

**适用场景：**
- Vue 3 / React / 任意前端项目的功能开发
- 包含列表、搜索、表单、CRUD 的管理后台页面
- 需要规范化开发流程的团队协作

---

## 2. 流水线全景图

```
  主流程（5 步，顺序执行，每步确认）
  ════════════════════════════════════════════════════════════════

  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
  │ 1. 需求分析   │ ⇒  │ 2. 技术设计   │ →  │ 3. 编码实现   │
  │ requirement   │    │ design       │    │ implement    │
  │ 写spec.md需求 │    │ 追加设计+自审 │    │ Apifox/mock  │
  └──────────────┘    └──────────────┘    └──────────────┘
        ↓ 输入                ↓ 输入               ↓ 输入
    文字/截图/文档      spec.md(需求部分)    spec.md(需求+设计)

  ⇒ 表示连续执行不暂停：需求+设计在 Step 2 完成后合并审核一次

  ┌──────────────┐    ┌──────────────┐
  │ 5. E2E 测试  │ ←  │ 4. 代码验证   │
  │ e2e           │    │ verify        │
  │ Playwright    │    │ Lint+Test+QA  │
  └──────────────┘    └──────────────┘

  独立步骤（流水线结束后按需执行）
  ════════════════════════════════════════════════════════════════

  ┌──────────────┐
  │ CR / 创建 PR │    ← 流水线完成后单独使用 /lc-feat:pr
  │ pr            │
  │ + code review │
  └──────────────┘

  辅助流程（按需触发）
  ════════════════════════════════════════════════════════════════

  ┌──────────────────┐    ┌──────────────┐
  │ 发布后文档处理     │    │ 接口同步      │
  │ document-release  │    │ api-sync     │
  │ PR 合并后触发      │    │ 接口就绪后触发 │
  └──────────────────┘    └──────────────┘

  总控
  ════════════════════════════════════════════════════════════════

  ┌──────────────────────────────────────────────────┐
  │ pipeline — 一键串联 1→5，支持 --from 断点恢复     │
  └──────────────────────────────────────────────────┘
```

**数据流：** 每步的产出文件是下一步的输入，全部存储在 `docs/pipeline/{feat-name}/` 下。

---

## 3. 快速开始

### 3.1 一键流水线

```bash
/lc-feat:pipeline goods-manage
```

一条命令启动完整流水线。AI 按顺序执行 5 个步骤（不含 CR/PR），每步完成后暂停提示：
- 回复 **`y`** → 继续执行下一步
- 回复 **`s`** → 跳过当前步骤
- 回复 **修改意见** → 在当前步骤内修改后再继续
- 回复 **"回退到 design"** → 返回指定步骤

> **例外**：需求分析（Step 1）完成后不暂停，直接进入技术设计（Step 2）；两步产出同一份 `spec.md`，在设计+自审完成后展示需求要点+设计摘要，**合并审核一次**。对需求理解有异议在此时提出即可。

### 3.2 全自动模式

```bash
/lc-feat:pipeline --auto 需求描述...
```

全自动模式适合快速开发，不暂停、不确认，一口气跑完。**默认走完整流程（full 模式，5 步）**，除非显式指定 `--mode=lite`（3 步：requirement → implement → verify）。结束后输出改动文件列表和建议 commit message。如需 CR/PR，流水线完成后单独使用 `/lc-feat:pr`。

### 3.3 逐步执行

根据需要单独调用某个步骤：

```bash
/lc-feat:requirement goods-manage     # 第1步：需求分析（默认自动接续第2步设计，--only 只出需求）
/lc-feat:design goods-manage          # 第2步：技术设计（含设计自审；需求已存在时单独重跑设计用）
/lc-feat:implement goods-manage       # 第3步：编码实现
/lc-feat:verify goods-manage          # 第4步：代码验证（Lint + Test + QA）
/lc-feat:e2e goods-manage             # 第5步：E2E 端到端测试
/lc-feat:pr goods-manage              # 独立步骤：创建 PR（不在流水线中）
```

### 3.4 断点恢复

流水线中断后，直接重新进入即可**自动断点恢复**：读取 `progress.yaml` 确定各步状态，校验产出文件后从第一个未完成步骤继续，并展示进度摘要和历史决策。

```bash
/lc-feat:pipeline goods-manage                     # 自动检测进度，从中断处继续
/lc-feat:pipeline goods-manage --from=implement    # 显式指定从编码开始
/lc-feat:pipeline goods-manage --from=verify       # 显式指定从验证开始
```

可用的 step 值：`requirement`、`design`、`implement`、`verify`、`e2e`（`--from` 优先于自动检测）

> **CR/PR 不在流水线中执行**，流水线完成后请单独使用 `/lc-feat:pr` 进行 Code Review 和创建 PR。

---

## 4. 主流程 Skill 详解（5步）

### 4.1 需求分析 requirement

| 项目 | 说明 |
|------|------|
| **命令** | `/lc-feat:requirement <feat-name> [描述] [--only]` |
| **输入** | 文字描述、截图路径、外部文档 |
| **产出** | `docs/pipeline/{feat}/spec.md` 的「基本信息 + 一、需求」部分 |
| **下一步** | 默认**自动接续** `/lc-feat:design`（单独调用与流水线内均不暂停，设计完成后合并审核一次）；`--only` 或极小改动时不接续 |

**AI 执行内容：**
1. 分析用户输入（支持读取截图文件）
2. 检查项目中已有的相关模块，避免重复
3. 尝试从 Apifox MCP 获取相关接口信息
4. 将结构化需求写入 spec.md 需求部分，包含：
   - 功能描述 & 用户操作流程
   - 数据字段定义（列表/搜索/表单）
   - 影响面分析（功能扩展/Bug修复类）
   - 接口需求（一句话概括，细节在设计章节展开）

> 页面清单、路由规划不在需求部分单列——统一放在设计章节的"改动文件清单"，避免两处重复。

**示例：**
```bash
# 纯文字描述
/lc-feat:requirement goods-manage 商品管理页面，包含列表、搜索、新增编辑删除

# 带截图
/lc-feat:requirement goods-manage 参考截图 /tmp/goods-prototype.png
```

---

### 4.2 技术设计 design

| 项目 | 说明 |
|------|------|
| **命令** | `/lc-feat:design <feat-name>` |
| **前置** | `spec.md` 的需求部分已存在 |
| **产出** | `spec.md` 追加「二、设计」章节 + 自审修订记录（同一文件，不生成独立 design.md） |
| **下一步** | `/lc-feat:implement` |

**AI 执行内容：**
1. 读取 spec.md 的需求部分
2. 分析项目中相似模块的代码风格作为参考
3. 尝试从 Apifox 获取接口，获取不到则设计 mock 数据结构
4. 在 spec.md 追加设计章节，包含：
   - 改动文件清单（页面/路由/文件一张表）
   - 路由配置（路径、meta、权限）
   - 页面组件设计（搜索 Schema、表格列、弹窗表单）
   - Service 层设计（ApiUrl、接口函数）
   - 接口与 Mock、权限常量、状态管理方案
   - 组件交互流程（只写实现细节，不复述业务流程）
5. **设计自审**：自动对设计进行自审，检查需求覆盖度、技术合理性、架构一致性等

> **注意：** 设计审核已合并到本步骤；流水线内**需求审核也合并到此**——设计+自审完成后展示需求要点+设计摘要，一次确认。设计章节严格去重，不重复需求部分内容。

---

### 4.3 编码实现 implement

| 项目 | 说明 |
|------|------|
| **命令** | `/lc-feat:implement <feat-name>` |
| **前置** | `spec.md` 已存在且含「二、设计」章节（lite 模式：需求部分即可） |
| **产出** | 页面、Service、路由、权限代码文件 |
| **下一步** | `/lc-feat:verify` |

**代码生成顺序：**
1. **Service 层** — `src/services/{module}/index.ts`（ApiUrl + 接口函数）
2. **路由配置** — `src/router/modules/{module}.ts`（LAYOUT + meta.permissions）
3. **权限常量** — 追加到 `src/services/permissions.ts`
4. **页面组件** — `src/pages/{module}/*.vue`（KrCard + KrForm + KrTable + KrDialog）

**接口策略：**
- 有 Apifox → 从 MCP 读取真实接口定义
- 无 Apifox → 生成 mock 数据，标注 `// TODO: 替换为真实接口`

---

### 4.4 代码验证 verify

| 项目 | 说明 |
|------|------|
| **命令** | `/lc-feat:verify <feat-name>` |
| **产出** | `docs/pipeline/{feat}/verify-report.md`（含 Lint、Test、QA 三个章节） |
| **下一步** | `/lc-feat:e2e` |

verify 步骤将原来的 lint、test、qa 三个步骤合并为一个，产出一份包含三个章节的报告：

**章节一：Lint（静态检查）**
1. **ESLint** — JavaScript/TypeScript 代码规范
2. **Stylelint** — CSS/Less 样式规范
3. **TypeScript** — 类型检查（`vue-tsc --noEmit`）

可自动修复的问题自动修复，不可修复的手动处理。

**章节二：Test（单元测试）**
- 检测新增核心函数，生成测试用例
- 测试框架：Vitest + Vue Test Utils + Pinia
- 覆盖维度：页面渲染、搜索交互、CRUD 操作、表单校验、异常处理

**章节三：QA（质量分析，含 0-10 评分）**

| 维度 | 关注点 |
|------|--------|
| 逻辑完整性 | 条件分支、异步错误处理、loading 状态 |
| 边界处理 | 表单校验、分页重置、空选择、删除确认 |
| 安全性 | XSS（v-html）、权限控制、敏感数据脱敏 |
| 性能 | 重复请求、分页、图片懒加载、重渲染 |
| 用户体验 | Toast 提示、防重复点击、loading 反馈 |
| 变更影响分析 | Bug 模式检测、删除/重命名验证、行为变更、配置影响 |

**评分门控：** 见 [第7节](#7-质量门控机制)

---

### 4.5 E2E 端到端测试 e2e

| 项目 | 说明 |
|------|------|
| **命令** | `/lc-feat:e2e <feat-name> [doc-path] [--yunxiao <目录ID\|用例ID>]` |
| **产出** | 测试文件 `tests/e2e/specs/{feat}.spec.ts` + 截图 + `docs/pipeline/{feat}/e2e-report.md` |
| **下一步** | `/lc-feat:pr`（QA 评分 >= 8） |

**环境要求：** Playwright + Chromium（未安装则 pipeline 中自动跳过）

**三种驱动模式（自动判定）：**

| 模式 | 用例来源 | 适用 |
|------|----------|------|
| **A 需求+设计驱动（配合流水线）** | `docs/pipeline/{feat}/spec.md`（旧版：`requirement.md` + `design.md`） | 走流水线开发的新功能（pipeline 默认） |
| **B 现有文档驱动（基于文档）** | 显式 `doc-path` / `docs/**/*测试要点*.md` / 模块文档 | 已有文档但未走流水线的功能、老页面 |
| **C 测试用例驱动（基于云效用例）** | 云效 Yunxiao MCP 用例库（`--yunxiao <目录ID\|用例ID>`） | QA 已在云效维护用例的功能 |

> 判定优先级：`--yunxiao` → 显式 `doc-path` → pipeline 文档 → 自动发现现有文档 → 兜底 `git diff master`+源码。
> 模式 B/C 来源若是「测试要点」式用例表或云效 `testSteps`，逐条映射（操作/step→action、预期结果/expected→assert）。
> 模式 C 读取链路：`list_test_repos`→`list_testcase_directories`→`search_testcases`(必带 `directoryId`)→`get_testcase`(拿 `preCondition`+`testSteps`)。

**用例分流（生成前必做）：** 文档里并非每条都能自动化。按 ✅可E2E / 🔒需登录 / 🧩需mock / ⬜不可E2E（KeepAlive/DexieDB/SSR 等白盒）打标，只生成可 E2E 的，其余记入报告。

**测试重点（按需求类型）：**

| 需求类型 | E2E 测试重点 |
|---------|-------------|
| 新页面 | 页面加载 + 主流程走通 + 关键交互截图 |
| 功能扩展 | 新增功能路径 + 原有功能不受影响 |
| 表单/弹窗 | 打开/填写/提交/关闭全流程 |
| 列表/搜索 | 加载/搜索/分页/空数据 |

**注意事项：**
- Dev server 由 `playwright.config.ts` 的 `webServer` 自动管理，无需手动启动
- 截图由测试代码手动控制（`page.screenshot()`），config 中 `screenshot: 'off'`
- 截图保存在 `tests/e2e/results/screenshots/{feat-name}/`

---

### 4.6 CR / 创建 PR（独立步骤，不在 pipeline 中执行）

| 项目 | 说明 |
|------|------|
| **命令** | `/lc-feat:pr <feat-name>` |
| **产出** | CR 报告 + PR URL |
| **触发时机** | 流水线完成后，用户手动调用 |

**执行内容：**
1. **CR 分析（默认）**：对 diff 进行代码 Review（命名、规范、风险评估），自动修复不影响逻辑的清理类问题（A 类），输出 CR 报告后停止，不自动进入 PR 阶段
2. **PR 创建（仅用户明确说"创建PR"/"提交PR"时）**：提交代码（Angular commit 规范）、push（需确认）、`gh pr create` 创建 PR
3. PR 创建后提示：**合并后运行 `/lc-feat:document-release <feat-name>` 同步项目文档**（代码改动 → 文档更新闭环）

> 此步骤从 pipeline 中独立出来，便于用户在流水线完成后自行决定何时做 CR 和提交 PR。

> **文档读取（输入侧）**：design / implement / verify 通过共享流程 `lc-feat-coding-standard-loading.md` 加载项目规范时，会一并读取本次改动模块的已有页面文档（前提：项目 skill 声明了「文档维护约定」），以现有业务为基线做增量。

---

## 5. 辅助 Skill 详解（3个）

### 5.1 发布后文档处理 document-release

| 项目 | 说明 |
|------|------|
| **命令** | `/lc-feat:document-release <feat-name>` |
| **触发时机** | PR 合并后，或独立调用补写历史功能 |
| **产出** | 模块功能文档（增量追加）+ `docs/pipeline/{feat}/document-release.md` |

**核心定位：** 每次发布后将功能信息增量补充到项目文档中，逐步构建完整的业务功能手册。

**执行内容：**
1. 确认 PR 已合并
2. **【核心】增量更新项目文档**（结构以**项目技能的「文档维护约定」**为准）
   - 先读项目 `.claude/CLAUDE.md` 引用的编码规范技能（如 `lc-kejinshou-h5-vue`），取其「文档维护约定」（路径/结构/模板/侧边栏/校验）
   - 从 spec.md（旧版功能：requirement.md / design.md）/ 代码中提取功能信息，按该约定写入（结构化项目按页面拆分，无约定则回退 `docs/features/{module}.md`）
   - 只写业务层面（做什么、怎么用），不写代码细节；收尾按约定跑 `docs:build` 校验
3. 更新 CLAUDE.md（仅新增模块级别的变更）
4. 归档 pipeline 产物（progress.yaml 标记完成）
5. 扫描 mock 标记 + 分支清理提醒

**独立模式（补写历史功能）：**
```bash
/lc-feat:document-release --module=goods    # 为整个 goods 模块补写文档
/lc-feat:document-release goods-bargain     # 为某个已完成功能补写
```

---

### 5.2 接口同步 api-sync

| 项目 | 说明 |
|------|------|
| **命令** | `/lc-feat:api-sync <feat-name>` |
| **触发时机** | 真实接口就绪后 |
| **产出** | `docs/pipeline/{feat}/api-sync-report.md` |

**执行流程：**
1. 扫描所有 `// TODO: 替换为真实接口` 标记
2. 从 Apifox MCP 读取接口定义
3. 生成 mock → 真实接口映射表，等待用户确认
4. 逐一替换：ApiUrl、接口函数、TypeScript 类型
5. 移除 TODO 标记，运行类型检查验证

---

### 5.3 总控 pipeline

| 项目 | 说明 |
|------|------|
| **命令** | `/lc-feat:pipeline <feat-name> [--from=<step>] [--mode=full|lite] [--auto]` |
| **产出** | `docs/pipeline/{feat}/progress.yaml` + 全部产物 |

**总控负责：**
- 按顺序串联 5 个主流程步骤（不含 CR/PR）
- 维护 `progress.yaml` 进度文件（步骤状态 + decisions 关键决策记录）
- 每步执行前运行 **Preamble** 注入上下文：进度状态、历史决策、相关 Memory（最多 3 条）、前序产出摘要
- 每步暂停提示 `y — 继续 / s — 跳过`（requirement → design 连续执行不暂停，design 后合并审核一次）
- `progress.yaml` 已存在时自动断点恢复，`--from` 可显式指定起点
- 支持 `--mode=full|lite`（默认按需求类型自动选择）和 `--auto` 全自动模式（无确认，一口气跑完，适合小功能）
- QA 评分门控（< 8 分警告，< 6 分建议回退）
- 流水线全部完成后写入 Memory（project/feedback 类型，中途中断不写入）

---

## 6. 产出文件总览

每个功能的所有产物集中存储在 `docs/pipeline/{feat-name}/`：

```
docs/pipeline/{feat-name}/
├── progress.yaml           # 流水线进度与决策记录（pipeline 模式自动维护）
├── spec.md                 # 需求与设计文档（基本信息 + 一、需求 + 二、设计 + 自审修订）
├── verify-report.md        # 代码验证报告（含 Lint / Test / QA 三个章节 + 0-10 评分）
├── e2e-report.md           # E2E 端到端测试报告
├── pr-review.md            # PR 代码审查报告
├── document-release.md     # 发布后总结（document-release 后生成）
└── api-sync-report.md      # 接口同步报告（api-sync 后生成）
```

---

## 7. 质量门控机制

流水线内置多重质量关卡：

| 关卡 | 位置 | 规则 |
|------|------|------|
| **Lint 检查** | verify 内部 | ESLint/Stylelint/TS 零错误 |
| **测试通过** | verify 内部 | 全部用例通过 |
| **QA 评分** | Step 4 → Step 5 | >= 8 分可创建 PR |

**QA 评分标准：**

| 评分 | 状态 | 操作 |
|------|------|------|
| **8-10** | 达标 | 直接进入 PR 创建 |
| **6-7** | 需修复 | 修复严重问题后重新 QA |
| **< 6** | 不达标 | 建议回退到编码阶段重构 |

---

## 8. 与 gstack 的协作

lc-feat 流水线可与 gstack skill 组合使用，形成更强大的工作流：

| 阶段 | lc-feat skill | gstack skill | 组合方式 |
|------|---------------|--------------|---------|
| 需求探索 | — | `/office-hours` | 需求不明确时先 brainstorm |
| 技术设计 | `/lc-feat:design`（含设计自审） | `/plan-eng-review` | lc-feat 设计 + gstack 深度架构讨论 |
| 代码验证 | `/lc-feat:verify`（Lint+Test+QA） | `/qa`（浏览器实测） | 静态分析 + 实际操作验证 |
| 代码审查 | `/lc-feat:pr` | `/review` | PR 审查 + 安全/结构审查 |
| 发布 | `/lc-feat:pr` | `/ship` | 创建 PR + 合并/CI/CHANGELOG |
| 发布后 | `/lc-feat:document-release` | `/document-release` | 自动联动更新文档 |
| 回归检测 | — | `/lc-branch-ui-fix` | PR 合并后检测 UI 回归 |

**推荐组合流程：**
```bash
/office-hours                          # 明确需求（可选）
/lc-feat:pipeline xxx                  # 走完 5 步流水线
/lc-feat:pr xxx                        # CR + 创建 PR（独立步骤）
/ship                                  # 合并 PR + CI
/lc-feat:document-release xxx           # 文档归档
/lc-feat:api-sync xxx                  # 接口就绪后替换 mock（按需）
```

---

## 9. 常用场景速查

| # | 场景 | 命令 |
|---|------|------|
| 1 | 完整新功能开发 | `/lc-feat:pipeline user-manage` |
| 2 | 已有需求直接出设计 | `/lc-feat:design user-manage` |
| 3 | 代码写完跑质量检查 | `/lc-feat:verify user-manage` |
| 4 | 流水线断点恢复 | `/lc-feat:pipeline user-manage`（自动检测）或 `--from=verify` |
| 5 | 流水线后做 CR / 创建 PR | `/lc-feat:pr user-manage` |
| 6 | PR 合并后收尾 | `/lc-feat:document-release user-manage` |
| 7 | 后端接口就绪替换 mock | `/lc-feat:api-sync user-manage` |

---

## 10. 命令速查表

| 命令 | 说明 | 触发词 |
|------|------|--------|
| `/lc-feat:pipeline <name>` | 一键流水线 | "开始流水线"、"走流程"、"pipeline" |
| `/lc-feat:requirement <name>` | 需求分析（默认自动接续设计，`--only` 只出需求） | "分析需求"、"新功能"、"我想做一个..." |
| `/lc-feat:design <name>` | 技术设计（含设计自审） | "出设计文档"、"技术设计" |
| `/lc-feat:implement <name>` | 编码实现 | "开始编码"、"实现功能" |
| `/lc-feat:verify <name>` | 代码验证（Lint+Test+QA） | "验证代码"、"检查代码"、"质量检查" |
| `/lc-feat:e2e <name>` | E2E 端到端测试 | "E2E测试"、"端到端" |
| `/lc-feat:pr <name>` | 创建 PR | "创建PR"、"提交PR" |
| `/lc-feat:document-release <name>` | 发布后文档处理 | "发布完了"、"PR合并了"、"收尾" |
| `/lc-feat:api-sync <name>` | 接口同步 | "接口来了"、"替换mock"、"同步接口" |

---

## 11. 注意事项 & FAQ

### 命名规范
- **feat-name** 优先从当前功能分支名提取（去掉 `feature/` 前缀，如 `feature/3.38-coupon` → `3.38-coupon`）
- 无分支信息时使用 kebab-case 显式命名：`goods-manage`、`user-auth`、`order-detail`
- 名称用于：产物目录名 `docs/pipeline/{name}`、PR 标题

### 接口策略
- 优先通过 Apifox MCP 读取真实接口
- 未提供时自动 mock，标注 `// TODO: 替换为真实接口`
- 接口就绪后 `/lc-feat:api-sync` 一键替换

### 确认机制
- 每步完成后暂停提示：`y — 继续 / s — 跳过`
- **例外**：需求分析完成后不暂停，直接技术设计；需求+设计在设计完成后合并审核一次
- `y` → 下一步 | `s` → 跳过 | 修改意见 → 当前步骤修改 | "回退到{步骤}" → 返回
- `--auto` 模式下跳过所有确认，全自动跑完

### FAQ

**Q: 可以跳过某些步骤吗？**
A: 可以。确认环节回复"跳过"，或直接单独调用某个步骤。

**Q: 产物文件会被 git 跟踪吗？**
A: `docs/pipeline/` 下的文件会被跟踪，作为开发记录。不需要可加到 `.gitignore`。

**Q: 同一个 feat-name 可以重复运行吗？**
A: 可以。`progress.yaml` 已存在时自动进入断点恢复，已完成的步骤跳过；如需重跑某步，用 `--from` 显式指定。

**Q: 只能用于 Vue 项目吗？**
A: skill 本身通用。implement 会参考项目的 CLAUDE.md 和现有代码来生成代码，适用于任何前端项目。

**Q: 如何查看流水线进度？**
A: 查看 `docs/pipeline/{feat-name}/progress.yaml`（步骤状态 + 历史决策）。

### 文件位置

| 类型 | 路径 |
|------|------|
| Skills | `~/.claude/skills/lc-feat-*` |
| Commands | `~/.claude/commands/lc-feat/*.md` |
| 本文档 | `~/.claude/skills/docs/lc-feat-pipeline-guide.md` |

---

## 12. 完整使用用例：从零开发「优惠券管理」功能

> 本示例以**后台管理项目（backend-kejinshou）**为例。H5 移动端项目的流程相同，但使用 Vant + XPopup 等移动端组件。

以下是一个真实场景的完整演示，展示如何用 lc-feat 流水线从零开发一个「优惠券管理」功能。

### 背景

产品经理给了一个需求：后台需要新增一个优惠券管理模块，包含优惠券列表、创建优惠券、编辑、停用/启用、查看领取记录等功能。同时提供了一张 UI 原型截图。

---

### Step 1：启动流水线

```bash
用户：/lc-feat:pipeline coupon-manage
```

AI 创建 `docs/pipeline/coupon-manage/` 目录，初始化 `progress.yaml`，进入第一步。

---

### Step 2：需求分析（requirement）

```
AI：请描述你想要实现的功能，可以提供文字说明、截图路径或相关文档。
```

```bash
用户：优惠券管理功能，包含：
1. 优惠券列表页（搜索：名称、类型、状态、时间范围）
2. 新增/编辑优惠券弹窗（名称、类型[满减/折扣/直减]、面额、使用门槛、有效期、发放数量）
3. 停用/启用操作
4. 查看领取记录（子页面）
截图在 /tmp/coupon-prototype.png
```

AI 读取截图，分析需求，将「一、需求」写入 `spec.md`，包含：
- 2 个页面（列表页 + 领取记录页）
- 7 个搜索字段、10 个表格列、8 个表单字段
- 6 个权限点
- 接口标注"待定 - 使用 mock 数据"

```
AI：**[1/5 需求分析]** 已完成，写入 spec.md 需求部分。
    ↓ 不暂停，直接进入技术设计
```

---

### Step 3：技术设计（design，与需求合并审核）

AI 读取 spec.md 需求部分，参考项目中 `src/pages/goods/` 的代码风格，在同一文件追加「二、设计」：

```
生成的设计包含：
├── src/pages/coupon/
│   ├── couponList.vue          # 列表页（KrCard + KrForm + KrTable + KrDialog）
│   ├── couponRecord.vue        # 领取记录页
│   └── components/
│       └── CouponForm.vue      # 表单组件（新增/编辑复用）
├── src/services/coupon/
│   └── index.ts                # 6 个接口函数 + mock 数据
├── src/router/modules/
│   └── coupon.ts               # 路由配置（orderNo: 12）
└── permissions.ts              # 追加 6 个权限常量
```

```
AI：**[2/5 技术设计]** 已完成（含设计自审）。请查看 spec.md（需求+设计一份文档）。

    需求要点：2 个页面、7 个搜索字段、8 个表单字段、6 个权限点、接口待定（mock）

    设计自审结果：
    ✅ A. 需求覆盖度: 100%
    ⚠️ B. UI 一致性: 截图中有"批量停用"按钮，设计中遗漏 → 已自动修订
    ✅ C. 技术合理性: 通过
    ⚠️ D. 架构评审:
       - CouponForm 类型联动逻辑改用 computed 动态 schema → 已修订
       - 领取记录列表预留虚拟滚动接口 → 已修订
    ✅ E. 项目规范: 通过

    回复"继续"开始编码，或提出需求/设计的修改意见（需求+设计在此一并审核）。
```

```bash
用户：搜索条件加一个"发放渠道"筛选
```

AI 修订 spec.md 需求部分（追加发放渠道字段），并同步更新设计章节的搜索 Schema。

```bash
用户：继续
```

---

### Step 4：编码实现（implement）

AI 按设计文档生成代码：

```
生成文件：
1. src/services/coupon/index.ts          ✅ 6 个接口 + mock 数据
2. src/router/modules/coupon.ts          ✅ 2 个路由 + 权限
3. src/services/permissions.ts           ✅ 追加 6 个权限常量
4. src/pages/coupon/couponList.vue       ✅ 列表页（搜索+表格+弹窗）
5. src/pages/coupon/couponRecord.vue     ✅ 领取记录页
6. src/pages/coupon/components/CouponForm.vue  ✅ 表单组件

所有接口使用 mock 数据，标注了 // TODO: 替换为真实接口
```

```
AI：**[3/5 编码实现]** 已完成。生成了 6 个文件。
    回复"继续"进行代码验证。
```

```bash
用户：继续
```

---

### Step 5：代码验证（verify）

AI 执行 Lint + Test + QA 三合一验证：

```
=== Lint 检查 ===
- ESLint: 3 个警告（unused import），已自动修复
- Stylelint: 0 问题
- TypeScript: 0 错误
全部通过。

=== Test 单元测试 ===
检测到新增核心函数：
├── src/utils/coupon.ts
│   ├── formatCouponAmount(type, amount) — 根据类型格式化优惠券面额
│   ├── getCouponStatusLabel(status) — 状态枚举转显示文本
│   └── validateCouponDate(start, end) — 校验有效期合法性

生成测试文件 `src/utils/__tests__/coupon.test.ts`：
├── formatCouponAmount（3 个用例）
├── getCouponStatusLabel（2 个用例）
└── validateCouponDate（3 个用例）
执行结果：8 个用例全部通过

=== QA 质量分析 ===
需求覆盖率: 100%（8/8 功能点已实现）

各维度评分：
| 维度       | 评分 | 说明 |
|-----------|------|------|
| 逻辑完整性  | 9    | 所有分支覆盖，async 有 try/catch |
| 边界处理    | 8    | 表单校验完整，批量操作已处理空选择 |
| 安全性      | 9    | 无 v-html，权限控制到位 |
| 性能        | 8    | 搜索有防抖，分页参数正确重置 |
| 用户体验    | 9    | Toast 完整，提交有 loading |

总评: 8.6/10 ✅ 达标
```

```
AI：**[4/5 代码验证]** 已完成。Lint 通过（3 个自动修复），8 个测试用例通过，QA 评分 8.6/10。
    回复"继续"进行 E2E 测试。
```

```bash
用户：继续
```

---

### Step 6：E2E 端到端测试（e2e）

AI 检测 Playwright 环境：

```
环境检测：cd tests/e2e && npx playwright test --list
✅ Playwright 已安装，Chromium 可用

生成测试文件 tests/e2e/specs/coupon-manage.spec.ts：
├── 优惠券列表页加载（截图：列表初始状态）
├── 搜索优惠券（截图：搜索结果）
├── 创建优惠券弹窗流程（截图：弹窗打开 → 填写 → 提交成功）
└── 删除优惠券确认（截图：确认弹窗 → 删除成功）

执行结果：4 个用例全部通过，12 张截图已保存
截图目录：tests/e2e/results/screenshots/coupon-manage/
```

```
AI：**[5/5 E2E 测试]** 已完成。4 个用例通过，12 张截图。
    流水线全部完成，如需 Code Review 和 PR 创建，请使用 /lc-feat:pr
```

---

### Step 7：CR + 创建 PR（pr，独立步骤）

```bash
用户：/lc-feat:pr coupon-manage
```

AI 先输出 CR 分析报告（自动修复 2 个未使用 import，无阻塞项），停止等待用户决定：

```
AI：CR 通过，可以提交。建议 commit message：feat(coupon): 新增优惠券管理模块
```

```bash
用户：创建PR
```

AI 逐步确认后执行提交和 PR 创建：

```bash
git add src/pages/coupon/ src/services/coupon/ src/router/modules/coupon.ts ...
git commit -m "feat(coupon): 新增优惠券管理模块"
gh pr create --title "feat(coupon): 新增优惠券管理模块" --body "..."
```

```
AI：**创建 PR** 完成！
    - PR: https://github.com/xxx/backend-kejinshou/pull/30
    - Review 报告: docs/pipeline/coupon-manage/pr-review.md
    - 全部产物在 docs/pipeline/coupon-manage/ 下
```

---

### Step 8：PR 合并后收尾（document-release）

PR 经人工 review 后合并，执行收尾：

```bash
用户：/lc-feat:document-release coupon-manage
```

```
AI：发布后处理完成：
    - CLAUDE.md 已更新（Main Business Modules 追加 coupon）
    - pipeline 产物已归档，所有步骤标记完成
    - 发现 6 处未替换的 mock 数据标记
    - 建议：接口就绪后执行 /lc-feat:api-sync coupon-manage
    - 总结: docs/pipeline/coupon-manage/document-release.md
```

---

### Step 9：接口就绪后同步（api-sync）

两天后后端接口开发完成，Apifox 上已有接口文档：

```bash
用户：/lc-feat:api-sync coupon-manage
```

```
AI：从 Apifox 读取到 5 个接口，映射结果：

    | Mock                | 真实接口                    | 状态    |
    |--------------------|-----------------------------|---------|
    | /mock/coupon/list  | GET /api/coupon/page        | ✅ 匹配 |
    | /mock/coupon/create| POST /api/coupon/create     | ✅ 匹配 |
    | /mock/coupon/update| PUT /api/coupon/update      | ✅ 匹配 |
    | /mock/coupon/toggle| POST /api/coupon/toggleStatus| ✅ 匹配 |
    | /mock/coupon/record| GET /api/coupon/record/page | ✅ 匹配 |
    | /mock/coupon/detail| ❌ 未找到                    | 保留mock |

    5 个接口已匹配，1 个保留 mock。确认后开始替换。
```

```bash
用户：确认
```

```
AI：接口同步完成：
    - 5 个接口已替换为真实接口
    - 1 个保留 mock（详情接口待后端开发）
    - TypeScript 类型已更新
    - 类型检查通过
    - 报告: docs/pipeline/coupon-manage/api-sync-report.md
```

---

### 最终产物目录

```
docs/pipeline/coupon-manage/
├── progress.yaml           # 所有步骤 ✅ 已完成（含 shipped 归档信息）
├── spec.md                 # 需求与设计文档（含发放渠道补充 + 设计自审修订）
├── verify-report.md        # Lint 通过 + 8 个测试通过 + QA 8.6/10 分
├── e2e-report.md           # 4 个 E2E 用例通过
├── pr-review.md            # PR Review 通过
├── document-release.md     # 发布总结
└── api-sync-report.md      # 5/6 接口已同步

src/pages/coupon/
├── couponList.vue          # 列表页
├── couponRecord.vue        # 领取记录页
└── components/
    └── CouponForm.vue      # 表单组件

src/services/coupon/
└── index.ts                # 6 个接口函数（5 个真实 + 1 个 mock）

src/router/modules/
└── coupon.ts               # 路由配置
```

---

### 时间线总结

| 步骤 | 用户操作 | AI 自动完成 |
|------|---------|------------|
| 启动 | `/lc-feat:pipeline coupon-manage` | 初始化目录 |
| 需求+设计 | 输入描述 + 截图，合并审核时 1 次修改 + "继续" | 生成 spec.md（需求 + 设计 + 自审），中间不暂停 |
| 编码 | "继续" | 生成 6 个代码文件 |
| 验证 | "继续" | Lint 修复 + 8 个测试 + QA 8.6/10 |
| E2E | "继续" | 4 个 E2E 用例 + 12 张截图 |
| CR/PR | `/lc-feat:pr` + "创建PR" | CR 报告 + 提交 + PR |
| 收尾 | `/lc-feat:document-release` | 文档更新 + 归档 |
| 接口 | `/lc-feat:api-sync` + "确认" | 替换 5 个 mock |

**用户实际操作：1 次需求输入 + 1 次修改 + 3 次"继续" + 4 次后续命令/确认 = 9 次交互，完成一个完整功能的开发全流程。**
