# lc-feat 功能开发流水线使用指南

> 版本: 1.1 | 更新日期: 2026-04-14 | 全局 skill，适用于所有项目

---

## 目录

- [1. 概述](#1-概述)
- [2. 流水线全景图](#2-流水线全景图)
- [3. 快速开始](#3-快速开始)
    - [3.1 一键流水线](#31-一键流水线)
    - [3.2 逐步执行](#32-逐步执行)
    - [3.3 断点恢复](#33-断点恢复)
- [4. 主流程 Skill 详解（7步）](#4-主流程-skill-详解7步)
    - [4.1 需求分析 requirement](#41-需求分析-requirement)
    - [4.2 技术设计 design](#42-技术设计-design)
    - [4.3 设计审核 & 架构评审 design-review](#43-设计审核--架构评审-design-review)
    - [4.4 编码实现 implement](#44-编码实现-implement)
    - [4.5 代码检查 lint](#45-代码检查-lint)
    - [4.6 编写测试 test](#46-编写测试-test)
    - [4.7 QA 分析 qa](#47-qa-分析-qa)
- [4.8 CR / 创建 PR（独立步骤）](#48-创建-pr-pr)
- [5. 辅助 Skill 详解（3个）](#5-辅助-skill-详解3个)
    - [5.1 发布后处理 post-ship](#51-发布后处理-post-ship)
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

`lc-feat` 是一套 **端到端的功能开发流水线**，由 11 个 Claude Code skill 组成，覆盖从需求分析到 PR 发布的完整生命周期。

**核心特点：**
- **标准化流程** — 每个功能按统一流程开发，产出可追溯
- **逐步确认** — 每步完成后暂停，`y` 继续 / `s` 跳过
- **全自动模式** — `--auto` 参数一口气跑完，无需确认，适合小功能快速开发
- **断点恢复** — 流水线中断后可从任意步骤继续
- **质量门控** — 设计审核 + Lint + 测试 + QA 评分多重把关
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
  主流程（7 步，顺序执行，每步确认）
  ════════════════════════════════════════════════════════════════

  ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐    ┌──────────────┐
  │ 1. 需求分析   │ →  │ 2. 技术设计   │ →  │ 3. 设计审核      │ →  │ 4. 编码实现   │
  │ requirement   │    │ design       │    │ design-review    │    │ implement    │
  │               │    │              │    │ + 架构评审        │    │ Apifox/mock  │
  └──────────────┘    └──────────────┘    └──────────────────┘    └──────────────┘
        ↓ 输入                ↓ 输入               ↓ 输入                ↓ 输入
    文字/截图/文档      requirement.md       design.md + 参考材料    审核通过的 design.md

                      ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
                      │ 7. QA 分析   │ ←  │ 6. 编写测试   │ ←  │ 5. 代码检查   │
                      │ qa           │    │ test          │    │ lint          │
                      │ 五维度 0-10  │    │ Vitest        │    │ ESLint/TS     │
                      └──────────────┘    └──────────────┘    └──────────────┘

  独立步骤（流水线结束后按需执行）
  ════════════════════════════════════════════════════════════════

  ┌──────────────┐
  │ CR / 创建 PR │    ← 流水线完成后单独使用 /lc-feat:pr
  │ pr            │
  │ + code review │
  └──────────────┘

  辅助流程（按需触发）
  ════════════════════════════════════════════════════════════════

  ┌──────────────┐    ┌──────────────┐
  │ 9. 发布后处理  │    │ 10. 接口同步  │
  │ post-ship     │    │ api-sync     │
  │ PR 合并后触发  │    │ 接口就绪后触发 │
  └──────────────┘    └──────────────┘

  总控
  ════════════════════════════════════════════════════════════════

  ┌──────────────────────────────────────────────────┐
  │ pipeline — 一键串联 1→7，支持 --from 断点恢复     │
  └──────────────────────────────────────────────────┘
```

**数据流：** 每步的产出文件是下一步的输入，全部存储在 `docs/pipeline/{feat-name}/` 下。

---

## 3. 快速开始

### 3.1 一键流水线

```bash
/lc-feat:pipeline goods-manage
```

一条命令启动完整流水线。AI 按顺序执行 7 个步骤（不含 CR/PR），每步完成后暂停提示：
- 回复 **`y`** → 继续执行下一步
- 回复 **`s`** → 跳过当前步骤
- 回复 **修改意见** → 在当前步骤内修改后再继续
- 回复 **"回退到 design"** → 返回指定步骤

### 3.4 全自动模式

```bash
/lc-feat:pipeline --auto 需求描述...
```

全自动模式适合快速开发，不暂停、不确认，一口气跑完。**默认走完整流程（full 模式）**，除非显式指定 `--mode=lite`。结束后输出改动文件列表和建议 commit message。如需 CR/PR，流水线完成后单独使用 `/lc-feat:pr`。

### 3.2 逐步执行

根据需要单独调用某个步骤：

```bash
/lc-feat:requirement goods-manage     # 第1步：需求分析
/lc-feat:design goods-manage          # 第2步：技术设计
/lc-feat:design-review goods-manage   # 第3步：设计审核 + 架构评审
/lc-feat:implement goods-manage       # 第4步：编码实现
/lc-feat:lint goods-manage            # 第5步：代码检查
/lc-feat:test goods-manage            # 第6步：编写测试（仅核心函数，无则跳过）
/lc-feat:qa goods-manage              # 第7步：QA 分析
/lc-feat:pr goods-manage              # 独立步骤：创建 PR（不在流水线中）
```

### 3.3 断点恢复

流水线中断后，从指定步骤继续（前置产物必须存在）：

```bash
/lc-feat:pipeline goods-manage --from=implement   # 从编码开始
/lc-feat:pipeline goods-manage --from=test         # 从测试开始
```

可用的 step 值：`requirement`、`design`、`design-review`、`implement`、`lint`、`test`、`qa`

> **CR/PR 不在流水线中执行**，流水线完成后请单独使用 `/lc-feat:pr` 进行 Code Review 和创建 PR。

---

## 4. 主流程 Skill 详解（7步 + 独立 CR/PR）

### 4.1 需求分析 requirement

| 项目 | 说明 |
|------|------|
| **命令** | `/lc-feat:requirement <feat-name> [描述]` |
| **输入** | 文字描述、截图路径、外部文档 |
| **产出** | `docs/pipeline/{feat}/requirement.md` |
| **下一步** | `/lc-feat:design` |

**AI 执行内容：**
1. 分析用户输入（支持读取截图文件）
2. 检查项目中已有的相关模块，避免重复
3. 尝试从 Apifox MCP 获取相关接口信息
4. 生成结构化需求文档，包含：
    - 功能描述 & 用户操作流程
    - 页面清单 & 路由规划
    - 数据字段定义（列表/搜索/表单）
    - 接口需求（已有或待定）
    - 权限点定义

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
| **前置** | `requirement.md` 已存在 |
| **产出** | `docs/pipeline/{feat}/design.md` |
| **下一步** | `/lc-feat:design-review` |

**AI 执行内容：**
1. 读取需求文档
2. 分析项目中相似模块的代码风格作为参考
3. 尝试从 Apifox 获取接口，获取不到则设计 mock 数据结构
4. 生成完整技术设计文档，包含：
    - 目录结构设计
    - 路由配置（路径、meta、权限）
    - 页面组件设计（搜索 Schema、表格列、弹窗表单）
    - Service 层设计（ApiUrl、接口函数）
    - 权限常量定义
    - 状态管理方案（是否需要 Pinia）
    - 组件交互流程

---

### 4.3 设计审核 & 架构评审 design-review

| 项目 | 说明 |
|------|------|
| **命令** | `/lc-feat:design-review <feat-name> [参考材料]` |
| **前置** | `design.md` 已存在 |
| **产出** | `design-review.md` + 修订后的 `design.md` |
| **下一步** | `/lc-feat:implement` |

**六维度审查：**

| 维度 | 检查内容 |
|------|---------|
| **A. 需求覆盖度** | 功能点、页面、字段、权限是否全部覆盖 |
| **B. UI/交互一致性** | 对照截图检查布局、搜索条件、表格列、操作按钮 |
| **C. 技术合理性** | 组件选型、路由结构、Service 设计、边界场景 |
| **D. 架构评审** | 数据流分析、组件边界、性能瓶颈预判、扩展性评估、与现有架构一致性 |
| **E. 项目规范** | 文件命名、代码风格、Toast 方式、模块冲突 |

**架构评审细项（维度 D）：**
- **数据流** — 组件间通信是否清晰（props/events），是否需要 Pinia
- **组件边界** — 职责是否单一，拆分粒度是否合适，是否重复造轮子
- **性能瓶颈** — 大列表虚拟滚动、搜索防抖、大表单懒加载、图片压缩
- **扩展性** — 字段/功能/权限是否便于后续迭代
- **一致性** — 是否与项目现有模块架构保持一致

**发现问题后自动修订 design.md，生成审查报告。**

**示例：**
```bash
# 提供截图审核
/lc-feat:design-review goods-manage 参考截图 /tmp/prototype.png

# 纯自审
/lc-feat:design-review goods-manage 基于需求文档自审
```

---

### 4.4 编码实现 implement

| 项目 | 说明 |
|------|------|
| **命令** | `/lc-feat:implement <feat-name>` |
| **前置** | `design.md` 已审核通过 |
| **产出** | 页面、Service、路由、权限代码文件 |
| **下一步** | `/lc-feat:lint` |

**代码生成顺序：**
1. **Service 层** — `src/services/{module}/index.ts`（ApiUrl + 接口函数）
2. **路由配置** — `src/router/modules/{module}.ts`（LAYOUT + meta.permissions）
3. **权限常量** — 追加到 `src/services/permissions.ts`
4. **页面组件** — `src/pages/{module}/*.vue`（KrCard + KrForm + KrTable + KrDialog）

**接口策略：**
- 有 Apifox → 从 MCP 读取真实接口定义
- 无 Apifox → 生成 mock 数据，标注 `// TODO: 替换为真实接口`

---

### 4.5 代码检查 lint

| 项目 | 说明 |
|------|------|
| **命令** | `/lc-feat:lint <feat-name>` |
| **产出** | `docs/pipeline/{feat}/lint-report.md` |
| **下一步** | `/lc-feat:test` |

**三项检查并行执行：**
1. **ESLint** — JavaScript/TypeScript 代码规范
2. **Stylelint** — CSS/Less 样式规范
3. **TypeScript** — 类型检查（`vue-tsc --noEmit`）

可自动修复的问题自动修复，不可修复的手动处理后生成报告。

---

### 4.6 编写测试 test

| 项目 | 说明 |
|------|------|
| **命令** | `/lc-feat:test <feat-name>` |
| **产出** | 测试文件 + `docs/pipeline/{feat}/test-report.md` |
| **下一步** | `/lc-feat:qa` |

**测试覆盖维度：**
- 页面渲染（组件挂载）
- 搜索功能（表单交互）
- 列表操作（CRUD）
- 表单校验（必填、格式、边界值）
- 异常处理（空数据、接口错误）

**测试框架：** Vitest + Vue Test Utils + Pinia

---

### 4.7 QA 分析 qa

| 项目 | 说明 |
|------|------|
| **命令** | `/lc-feat:qa <feat-name>` |
| **产出** | `docs/pipeline/{feat}/qa-report.md`（含 0-10 评分） |
| **下一步** | `/lc-feat:pr`（评分 >= 8） |

**五维度评审：**

| 维度 | 关注点 |
|------|--------|
| 逻辑完整性 | 条件分支、异步错误处理、loading 状态 |
| 边界处理 | 表单校验、分页重置、空选择、删除确认 |
| 安全性 | XSS（v-html）、权限控制、敏感数据脱敏 |
| 性能 | 重复请求、分页、图片懒加载、重渲染 |
| 用户体验 | Toast 提示、防重复点击、loading 反馈 |

**评分门控：** 见 [第7节](#7-质量门控机制)

---

### 4.8 CR / 创建 PR（独立步骤，不在 pipeline 中执行）

| 项目 | 说明 |
|------|------|
| **命令** | `/lc-feat:pr <feat-name>` |
| **产出** | CR 报告 + PR URL |
| **触发时机** | 流水线完成后，用户手动调用 |

**执行内容：**
1. 对 diff 进行代码 Review（命名、规范、风险评估），自动修复安全类问题
2. 用户说"创建PR"时：创建功能分支、提交代码（Angular commit 规范）、创建 PR

> 此步骤从 pipeline 中独立出来，便于用户在流水线完成后自行决定何时做 CR 和提交 PR。

---

## 5. 辅助 Skill 详解（3个）

### 5.1 发布后处理 post-ship

| 项目 | 说明 |
|------|------|
| **命令** | `/lc-feat:post-ship <feat-name>` |
| **触发时机** | PR 合并后 |
| **产出** | `docs/pipeline/{feat}/post-ship.md` |
| **联动** | gstack `/document-release` |

**执行内容：**
1. 确认 PR 已合并
2. 联动 gstack `/document-release` 更新项目文档
3. 检查并更新 CLAUDE.md（新模块、路由、权限变更）
4. 归档 pipeline 产物，标记所有步骤完成
5. 扫描未替换的 mock 标记，提醒使用 `/lc-feat:api-sync`

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
| **命令** | `/lc-feat:pipeline <feat-name> [--from=<step>] [--auto]` |
| **产出** | `docs/pipeline/{feat}/pipeline-status.md` + 全部产物 |

**总控负责：**
- 按顺序串联 7 个主流程步骤（不含 CR/PR）
- 维护 `pipeline-status.md` 进度文件
- 每步暂停提示 `y — 继续 / s — 跳过`
- 支持 `--from` 参数断点恢复
- 支持 `--auto` 全自动模式（无确认，一口气跑完，适合小功能）
- QA 评分门控（< 8 分警告，< 6 分建议回退）

---

## 6. 产出文件总览

每个功能的所有产物集中存储在 `docs/pipeline/{feat-name}/`：

```
docs/pipeline/{feat-name}/
├── pipeline-status.md      # 流水线进度追踪（pipeline 模式自动维护）
├── requirement.md          # 需求文档
├── design.md               # 技术设计文档（审核后会被修订）
├── design-review.md        # 设计审查 + 架构评审报告
├── lint-report.md          # ESLint / Stylelint / TypeScript 检查报告
├── test-report.md          # 测试执行报告（含用例清单和覆盖率）
├── qa-report.md            # QA 五维度分析报告（含 0-10 评分）
├── pr-review.md            # PR 代码审查报告
├── post-ship.md            # 发布后总结（post-ship 后生成）
└── api-sync-report.md      # 接口同步报告（api-sync 后生成）
```

---

## 7. 质量门控机制

流水线内置多重质量关卡：

| 关卡 | 位置 | 规则 |
|------|------|------|
| **设计审核** | Step 3 → Step 4 | 六维度审查全部通过才进入编码 |
| **Lint 检查** | Step 5 → Step 6 | ESLint/Stylelint/TS 零错误 |
| **测试通过** | Step 6 → Step 7 | 全部用例通过 |
| **QA 评分** | Step 7 → Step 8 | >= 8 分可创建 PR |

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
| 设计审核 | `/lc-feat:design-review` | `/plan-eng-review` | lc-feat 标准审核 + gstack 深度架构讨论 |
| QA 分析 | `/lc-feat:qa`（静态分析） | `/qa`（浏览器实测） | 代码分析 + 实际操作验证 |
| 代码审查 | `/lc-feat:pr` | `/review` | PR 审查 + 安全/结构审查 |
| 发布 | `/lc-feat:pr` | `/ship` | 创建 PR + 合并/CI/CHANGELOG |
| 发布后 | `/lc-feat:post-ship` | `/document-release` | 自动联动更新文档 |
| 回归检测 | — | `/lc-branch-ui-fix` | PR 合并后检测 UI 回归 |

**推荐组合流程：**
```bash
/office-hours                          # 明确需求（可选）
/lc-feat:pipeline xxx                  # 走完 7 步流水线
/lc-feat:pr xxx                        # CR + 创建 PR（独立步骤）
/ship                                  # 合并 PR + CI
/lc-feat:post-ship xxx                 # 文档归档
/lc-feat:api-sync xxx                  # 接口就绪后替换 mock（按需）
```

---

## 9. 常用场景速查

| # | 场景 | 命令 |
|---|------|------|
| 1 | 完整新功能开发 | `/lc-feat:pipeline user-manage` |
| 2 | 已有需求直接出设计 | `/lc-feat:design user-manage` |
| 3 | 代码写完跑质量检查 | `/lc-feat:lint` → `/lc-feat:test` → `/lc-feat:qa` |
| 4 | 流水线断点恢复 | `/lc-feat:pipeline user-manage --from=test` |
| 5 | 对照原型审核设计 | `/lc-feat:design-review xxx 截图在 /tmp/proto.png` |
| 6 | PR 合并后收尾 | `/lc-feat:post-ship user-manage` |
| 7 | 后端接口就绪替换 mock | `/lc-feat:api-sync user-manage` |
| 8 | 只做架构评审 | `/lc-feat:design-review xxx 只做架构评审` |

---

## 10. 命令速查表

| 命令 | 说明 | 触发词 |
|------|------|--------|
| `/lc-feat:pipeline <name>` | 一键流水线 | "开始流水线"、"走流程"、"pipeline" |
| `/lc-feat:requirement <name>` | 需求分析 | "分析需求"、"新功能"、"我想做一个..." |
| `/lc-feat:design <name>` | 技术设计 | "出设计文档"、"技术设计" |
| `/lc-feat:design-review <name>` | 设计审核 + 架构评审 | "审核设计"、"架构评审" |
| `/lc-feat:implement <name>` | 编码实现 | "开始编码"、"实现功能" |
| `/lc-feat:lint <name>` | 代码检查 | "检查代码"、"lint" |
| `/lc-feat:test <name>` | 编写测试 | "写测试"、"测试用例" |
| `/lc-feat:qa <name>` | QA 分析 | "QA分析"、"质量检查" |
| `/lc-feat:pr <name>` | 创建 PR | "创建PR"、"提交PR" |
| `/lc-feat:post-ship <name>` | 发布后处理 | "发布完了"、"PR合并了"、"收尾" |
| `/lc-feat:api-sync <name>` | 接口同步 | "接口来了"、"替换mock"、"同步接口" |

---

## 11. 注意事项 & FAQ

### 命名规范
- **feat-name** 必须使用 kebab-case：`goods-manage`、`user-auth`、`order-detail`
- 名称用于：目录名、分支名（`feat/{name}`）、PR 标题

### 接口策略
- 优先通过 Apifox MCP 读取真实接口
- 未提供时自动 mock，标注 `// TODO: 替换为真实接口`
- 接口就绪后 `/lc-feat:api-sync` 一键替换

### 确认机制
- 每步完成后暂停提示：`y — 继续 / s — 跳过`
- `y` → 下一步 | `s` → 跳过 | 修改意见 → 当前步骤修改 | "回退到{步骤}" → 返回
- `--auto` 模式下跳过所有确认，全自动跑完

### FAQ

**Q: 可以跳过某些步骤吗？**
A: 可以。确认环节回复"跳过"，或直接单独调用某个步骤。

**Q: 产物文件会被 git 跟踪吗？**
A: `docs/pipeline/` 下的文件会被跟踪，作为开发记录。不需要可加到 `.gitignore`。

**Q: 同一个 feat-name 可以重复运行吗？**
A: 可以。会覆盖之前的产物，pipeline-status.md 会更新。

**Q: 只能用于 Vue 项目吗？**
A: skill 本身通用。implement 会参考项目的 CLAUDE.md 和现有代码来生成代码，适用于任何前端项目。

**Q: 如何查看流水线进度？**
A: 查看 `docs/pipeline/{feat-name}/pipeline-status.md`。

### 文件位置

| 类型 | 路径 |
|------|------|
| Skills | `~/.claude/skills/lc-feat-*` |
| Commands | `~/.claude/commands/lc-feat/*.md` |
| 本文档 | `~/.claude/docs/lc-feat-pipeline-guide.md` |

---

## 12. 完整使用用例：从零开发「优惠券管理」功能

以下是一个真实场景的完整演示，展示如何用 lc-feat 流水线从零开发一个「优惠券管理」功能。

### 背景

产品经理给了一个需求：后台需要新增一个优惠券管理模块，包含优惠券列表、创建优惠券、编辑、停用/启用、查看领取记录等功能。同时提供了一张 UI 原型截图。

---

### Step 1：启动流水线

```bash
用户：/lc-feat:pipeline coupon-manage
```

AI 创建 `docs/pipeline/coupon-manage/` 目录，初始化 `pipeline-status.md`，进入第一步。

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

AI 读取截图，分析需求，生成 `requirement.md`，包含：
- 2 个页面（列表页 + 领取记录页）
- 7 个搜索字段、10 个表格列、8 个表单字段
- 6 个权限点
- 接口标注"待定 - 使用 mock 数据"

```
AI：**[1/8 需求分析]** 已完成。请查看 requirement.md。
    回复"继续"进入设计阶段，或说明需要修改的内容。
```

```bash
用户：搜索条件加一个"发放渠道"筛选
```

AI 修改 requirement.md，追加发放渠道字段。

```bash
用户：继续
```

---

### Step 3：技术设计（design）

AI 读取 requirement.md，参考项目中 `src/pages/goods/` 的代码风格，生成 `design.md`：

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
AI：**[2/8 技术设计]** 已完成。请查看 design.md。
    回复"继续"进入设计审核，或提供截图/文档用于审核。
```

```bash
用户：继续，用之前的截图审核
```

---

### Step 4：设计审核 & 架构评审（design-review）

AI 对照截图和需求，六维度审查：

```
审查结果：
✅ A. 需求覆盖度: 100%
⚠️ B. UI 一致性: 截图中有"批量停用"按钮，设计中遗漏
✅ C. 技术合理性: 通过
⚠️ D. 架构评审:
   - 建议：CouponForm 组件的类型联动逻辑（满减/折扣切换不同字段）
     应使用 computed 动态 schema，而非 v-if 切换
   - 建议：领取记录列表数据量可能较大，预留虚拟滚动接口
✅ E. 项目规范: 通过

共发现 2 个问题，已自动修订 design.md。
```

```
AI：**[3/8 设计审核]** 已完成。发现 2 个问题已修订。
    回复"继续"开始编码。
```

```bash
用户：继续
```

---

### Step 5：编码实现（implement）

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
AI：**[4/8 编码实现]** 已完成。生成了 6 个文件。
    回复"继续"进行代码检查。
```

```bash
用户：继续
```

---

### Step 6：代码检查（lint）

```
检查结果：
- ESLint: 3 个警告（unused import），已自动修复
- Stylelint: 0 问题
- TypeScript: 0 错误

全部通过。
```

```
AI：**[5/8 代码检查]** 已完成。3 个问题已自动修复。
    回复"继续"编写测试用例。
```

```bash
用户：继续
```

---

### Step 7：编写测试（test）

AI 生成测试文件 `src/pages/coupon/__tests__/couponList.test.ts`：

```
测试用例：
├── 页面渲染（2 个）
│   ├── 应正确渲染搜索表单
│   └── 应正确渲染表格
├── 搜索功能（3 个）
│   ├── 搜索应传递正确参数
│   ├── 重置应清空搜索条件
│   └── 发放渠道筛选应正常工作
├── CRUD 操作（4 个）
│   ├── 点击新增应打开弹窗
│   ├── 编辑应回填表单数据
│   ├── 停用应弹出确认框
│   └── 批量停用应处理空选择
├── 表单校验（3 个）
│   ├── 名称必填校验
│   ├── 面额必须大于 0
│   └── 有效期结束时间必须晚于开始时间
└── 异常处理（2 个）
    ├── 接口错误应显示 Toast
    └── 空数据应显示提示

执行结果：14 个用例全部通过
```

```
AI：**[6/8 编写测试]** 已完成。14 个用例，通过率 100%。
    回复"继续"进行 QA 分析。
```

```bash
用户：继续
```

---

### Step 8：QA 分析（qa）

```
QA 分析报告：

需求覆盖率: 100%（8/8 功能点已实现）

各维度评分：
| 维度       | 评分 | 说明 |
|-----------|------|------|
| 逻辑完整性  | 9    | 所有分支覆盖，async 有 try/catch |
| 边界处理    | 8    | 表单校验完整，批量操作已处理空选择 |
| 安全性      | 9    | 无 v-html，权限控制到位 |
| 性能        | 8    | 搜索有防抖，分页参数正确重置 |
| 用户体验    | 9    | Toast 完整，提交有 loading |

总评: 8.6/10 ✅ 达标，可创建 PR
```

```
AI：**[7/8 QA 分析]** 已完成。评分 8.6/10，达到发布标准。
    回复"继续"创建 PR。
```

```bash
用户：继续
```

---

### Step 9：创建 PR（pr）

AI 进行代码 Review，创建分支和 PR：

```bash
git checkout -b feat/coupon-manage
git add src/pages/coupon/ src/services/coupon/ src/router/modules/coupon.ts ...
git commit -m "feat(coupon): 新增优惠券管理模块"
gh pr create --title "feat(coupon): 新增优惠券管理模块" --body "..."
```

```
AI：**[8/8 创建 PR]** 流水线完成！
    - PR: https://github.com/xxx/backend-kejinshou/pull/30
    - Review 报告: docs/pipeline/coupon-manage/pr-review.md
    - 全部产物在 docs/pipeline/coupon-manage/ 下
```

---

### Step 10：PR 合并后收尾（post-ship）

PR 经人工 review 后合并，执行收尾：

```bash
用户：/lc-feat:post-ship coupon-manage
```

```
AI：发布后处理完成：
    - CLAUDE.md 已更新（Main Business Modules 追加 coupon）
    - pipeline 产物已归档，所有步骤标记完成
    - 发现 6 处未替换的 mock 数据标记
    - 建议：接口就绪后执行 /lc-feat:api-sync coupon-manage
    - 总结: docs/pipeline/coupon-manage/post-ship.md
```

---

### Step 11：接口就绪后同步（api-sync）

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
├── pipeline-status.md      # 所有步骤 ✅ 已完成
├── requirement.md          # 需求文档（含发放渠道补充）
├── design.md               # 技术设计（经审核修订）
├── design-review.md        # 审查报告（2 个问题已修复）
├── lint-report.md          # Lint 通过（3 个自动修复）
├── test-report.md          # 14 个用例全部通过
├── qa-report.md            # 8.6/10 分
├── pr-review.md            # PR Review 通过
├── post-ship.md            # 发布总结
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
| 需求 | 输入描述 + 截图 + 1 次修改 | 生成 requirement.md |
| 设计 | "继续" | 生成 design.md |
| 审核 | "继续" | 六维度审查 + 自动修订 |
| 编码 | "继续" | 生成 6 个代码文件 |
| Lint | "继续" | 检查 + 自动修复 |
| 测试 | "继续" | 14 个测试用例 |
| QA | "继续" | 五维度评分 8.6/10 |
| PR | "继续" | 创建分支 + PR |
| 收尾 | `/lc-feat:post-ship` | 文档更新 + 归档 |
| 接口 | `/lc-feat:api-sync` + "确认" | 替换 5 个 mock |

**用户实际操作：1 次需求输入 + 1 次修改 + 8 次"继续" + 2 次后续命令 = 12 次交互，完成一个完整功能的开发全流程。**
