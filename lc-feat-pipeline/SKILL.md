---
name: lc-feat-pipeline
description: 功能开发总控技能。串联需求分析→设计(含自审)→编码→验证→E2E的完整流水线（不含CR/PR），流水线按分支归档（docs/pipeline/{分支名}/{流水线名}/），一个分支下可有多条流水线，一条流水线可容纳多个功能（多份需求+设计，汇总报告），支持从任意步骤开始、断点恢复、--until 只出设计、--start 批量执行已审核功能（适合白天出设计晚上跑）。CR/PR请单独使用 /lc-feat:pr。当用户说"开始流水线"、"完整开发"、"走流程"、"pipeline"时触发。
license: MIT
metadata:
  author: kejinshou-team
  version: "0.2.0"
  guide: "~/.claude/skills/docs/lc-feat-pipeline-guide.md"
---

# 功能开发流水线（总控）

串联完整的功能开发流程，每步完成后等待确认再进入下一步。
**流水线不执行任何 git 操作（commit/push/PR），仅做分析和代码生成。**

## 核心模型：流水线按分支归档，一个分支下可有多条流水线

- **分支目录**：`docs/pipeline/{branch-name}/`，branch-name 取当前分支名去 `feature/` 前缀。**一个分支的所有流水线都必须创建在该分支目录下**
- **流水线（pipeline）**：分支目录下的子文件夹 `docs/pipeline/{branch-name}/{pipeline-name}/`，一个分支可有多条流水线（如主功能一条、顺路的独立需求另开一条）
- **功能（feature）对齐需求**：流水线文件夹内每个功能一份独立的「需求+设计」文档 `spec-{n}-{feat-name}.md`，编号自动递增
- **汇总报告**：verify-report.md / e2e-report.md 每条流水线各一份，**按功能分章节**，更新时只覆盖对应功能的章节，不整份重写

```
docs/pipeline/{branch-name}/          ← 分支目录（分支名去 feature/ 前缀）
├── {pipeline-name-1}/                ← 流水线目录（一个分支可有多条）
│   ├── progress.yaml                 ← 本流水线总进度（features 数组，管所有功能）
│   ├── spec-1-coupon-list.md         ← 需求+设计，每个功能一份，编号递增
│   ├── spec-2-coupon-export.md
│   ├── verify-report.md              ← 汇总一份，按功能分章节
│   ├── e2e-report.md                 ← 汇总一份，按功能分章节
│   └── start-report.md               ← 批量执行总结（--start 产出）
└── {pipeline-name-2}/                ← 同分支的另一条流水线
```

**需求与设计合并产出一份 spec**：requirement 步骤写「基本信息 + 一、需求」，design 步骤在同一文件追加「二、设计 + 自审修订」。full 模式下这两步**连续执行、中间不暂停**，design 完成后展示需求+设计合并摘要，**只审核一次**。

**每步暂停时的交互格式**：
```
是否继续 Step N（步骤名）？
  y — 继续
  s — 跳过此步骤
```
- 用户输入 `y` 或 `Y`：执行当前步骤
- 用户输入 `s` 或 `S` 或 `skip` 或 `跳过`：跳过当前步骤，标记为 `skipped`，进入下一步

> **例外**：full 模式下 Step 1（需求分析）完成后**不暂停**，直接进入 Step 2（技术设计）；需求与设计在 Step 2 完成后合并审核一次。

---

**Input**: `/lc-feat:pipeline [pipeline-name] [--feat=<id|name>] [--from=<step>] [--until=<step>] [--mode=full|lite] [--auto] [--start] [需求描述]`

参数说明：
- `pipeline-name`: 流水线名称（可选）。**用户显式指定的名字优先**；不指定则默认取分支名（去 `feature/` 前缀）
- `--feat=<id|name>`: 定位流水线内的某个功能（编号或功能名），用于恢复/重跑指定功能
- `--from=<step>`: 从指定步骤开始（可选，自动断点恢复时不需要）
- `--until=<step>`: 执行到指定步骤（含该步骤的人工审核）后**结束流水线**。典型用法 `--until=design`：白天只出需求+设计，审核通过后标记 `design_approved: true` 结束
- `--mode=full|lite`: 流水线模式（可选，默认根据需求类型自动选择，**按功能各自记录**）
- `--auto`: 全自动模式，跳过所有中间确认，一口气跑完全部步骤。适合自己用的小功能快速开发
- `--start`: 批量执行模式，串行执行流水线内所有已审核设计（`design_approved: true`）且未实现的功能，沿用 `--auto` 门控规则，产出 start-report.md（适合白天出设计、晚上批量跑实现）

可用步骤：`requirement` → `design` → `implement` → `verify` → `e2e`

> **CR/PR 不在流水线中执行**，请在流水线完成后单独使用 `/lc-feat:pr` 进行 Code Review 和 PR 创建。

**流水线模式（按功能独立选择）**

| 模式 | 适用场景 | 执行步骤 |
|------|---------|---------|
| **full** | 新功能（需要新页面/新路由） | 全部 5 步（requirement → design → implement → verify → e2e） |
| **lite** | 功能扩展/Bug修复/小改动 | requirement → implement → verify（3 步，design/e2e 跳过）|

**Steps**

1. **初始化流水线（入口逻辑）**

   ### 1.1 pipeline-name 解析

   运行 `git branch --show-current` 获取当前分支名：

   **branch-name（分支目录名，硬性规则）**：分支名去掉 `feature/` 前缀直接使用（`feature/3.5-wx` → `3.5-wx`），不要自行起名。

   **pipeline-name 命名优先级（硬性规则）**：
   1. **用户显式指定的 pipeline-name 优先**（如 `/lc-feat:pipeline 3.40-batch`）
   2. 未指定 → 默认与 branch-name 相同（此时目录为 `docs/pipeline/{branch-name}/{branch-name}/`）
   3. **不要自行起 kebab-case 名称，直接用分支名/用户给定的命名**
   4. 在 master/main/develop 上且未指定名称 → 询问用户（并提示建议创建功能分支，不自动执行）

   **目录规则（硬性）**：流水线目录一律为 `docs/pipeline/{branch-name}/{pipeline-name}/` 两级结构——**无论用户是否自定义了 pipeline-name，都必须归档在当前分支目录下**，禁止在 `docs/pipeline/` 一级直接新建流水线目录。

   ### 1.2 目录初始化与入口分流

   检查 `docs/pipeline/{branch-name}/{pipeline-name}/` 目录：

   **A. 目录不存在 → 新建流水线**
   - 创建目录，初始化 `progress.yaml`（features 数组，首个功能 `id: 1`）
   - 功能名：用户在需求描述中给出功能名则使用之，否则暂用纯编号，requirement 完成后根据需求内容补一个 kebab-case 短名
   - spec 文件命名：`spec-{n}-{feat-name}.md`（无功能名时先用 `spec-{n}.md`，补名后重命名并同步 progress.yaml）

   **B. 目录已存在 → 读取 progress.yaml，按意图分流**
   - 用户带了**新的需求描述** → **新增功能**：features 数组追加一项，`id` 取当前最大值 **+1**，新建对应 spec 文件，从 requirement 开始
   - 用户带了 `--feat=<id|name>` → 定位到该功能，进入断点恢复（见第 4 节）
   - 用户什么都没带 → 扫描**分支目录** `docs/pipeline/{branch-name}/` 下的所有流水线：只有一条时直接进入其功能看板（见 4.4，单功能未完成直接自动恢复）；多条流水线时先列出流水线清单让用户选择，再进入对应看板
   - `--start` → 进入批量执行模式（见第 7 节）

   **progress.yaml 格式（features 数组版）**：

   ```yaml
   pipeline: {pipeline-name}
   branch: feature/xxx          # 创建时的分支名，入口扫描与看板按此归属
   created: YYYY-MM-DD HH:mm
   updated: YYYY-MM-DD HH:mm
   features:
     - id: 1
       name: coupon-list
       spec: spec-1-coupon-list.md
       mode: full               # full|lite，按功能独立
       design_approved: false   # 设计经人工审核通过后置 true（--start 只执行 true 的功能）
       steps:
         requirement: { status: pending }
         design: { status: pending, depends: [requirement] }
         implement: { status: pending, depends: [design] }
         verify: { status: pending, depends: [implement] }
         e2e: { status: pending, depends: [implement] }
       files_changed: []        # implement 完成后回写实际改动文件列表
     - id: 2
       name: coupon-export
       spec: spec-2-coupon-export.md
       ...
   decisions: []                # 每条记录带 feature 字段
   ```

   **status 取值**：`pending` | `in-progress` | `done` | `skipped` | `blocked`

   ### 1.3 旧版兼容

   两类旧布局均**沿用不迁移**，新建流水线一律使用新规则：
   - **旧版一级目录布局**：`docs/pipeline/{name}/` 一级目录下直接存在 progress.yaml 或 spec/requirement 文件（无分支层）的历史流水线，按原路径继续处理；入口扫描时同时兼顾一级旧目录（按 progress.yaml 的 branch 字段归属分支）
   - **旧版单功能布局**：progress.yaml **没有 features 数组**（顶层 steps + `spec.md`/`requirement.md`+`design.md`），按旧逻辑继续处理该流水线

2. **Preamble — 每步执行前的上下文注入**

   每个步骤执行前，必须先运行 Preamble 收集上下文，**注入到当前步骤的执行环境中**：

   ### 2.1 读取进度状态
   读取 `progress.yaml`，获取：
   - 当前功能（id/name/spec/mode）、当前步骤名
   - 当前功能前序步骤的完成状态
   - **同流水线其他功能的状态概览**（名称 + 进度 + files_changed）
   - 历史 decisions 列表（当前功能的全部 + 其他功能中与本功能相关的）

   ### 2.2 加载相关 Memory
   检查 Claude Memory 中是否有与当前功能相关的记录：
   - 搜索 **project 类型** memory：当前项目的历史功能记录（如之前类似功能的决策）
   - 搜索 **feedback 类型** memory：用户的偏好和反馈（如"偏好新建组件而非复用"）
   - 最多加载 **3 条**最相关的 memory，避免上下文过载

   ### 2.3 加载前序产出摘要
   根据当前步骤的 `depends`，读取当前功能 spec 文件的**关键信息**：

   | 当前步骤 | 需要加载的前序产出 |
   |---------|-------------------|
   | design | spec-{n}「一、需求」的"需求背景"和"功能描述" |
   | implement | spec-{n}「二、设计」的"改动文件清单"和"页面组件设计" |
   | verify | spec-{n} 需求+设计摘要 + 本功能 files_changed |
   | e2e | spec-{n} 需求部分的用户操作流程 + 设计章节的路由和页面结构 + 本功能 files_changed |

   > 注意：只加载必要的片段，不全文读取大文件，控制 token 消耗。

   ### 2.4 注入上下文
   将收集到的信息组装为结构化上下文，在步骤执行前输出：

   ```
   === Preamble: {step-name} ===
   流水线：{pipeline-name}（分支 {branch}）
   当前功能：#2 coupon-export（full 模式）
   前序状态：requirement ✅ → design ✅（已审核）
   同流水线其他功能：#1 coupon-list（已完成，改动 3 个文件）

   关键决策：
   - [#1/design] 选择方案B：新建组件
   - [#2/requirement] 导出上限 5000 条

   相关经验（Memory）：
   - 用户偏好新建独立组件而非复用耦合组件

   前序产出要点：
   - 改动文件：DialogExport.vue（新建）、CouponList.vue（修改）...
   ===
   ```

3. **按顺序执行各步骤（针对当前功能）**

   每步执行前：运行 Preamble（第 2 节）→ 更新 progress.yaml（该功能该步 status = in-progress）
   每步执行后：更新 progress.yaml（status = done + updated 时间戳）

   > **`--until=<step>` 规则**：目标步骤执行并完成其人工审核后，流水线**结束**（不再询问是否继续下一步）。`--until=design` 时审核通过即置 `design_approved: true`。

   ### Step 1: 需求分析
   - **前置检查**：无
   - **Preamble**：加载项目 memory、分支信息、同流水线其他功能概览
   - 执行 `/lc-feat:requirement` 逻辑（跳过其独立的"输出确认"环节，暂停由流水线统一控制）
   - 产出：`spec-{n}-{feat-name}.md` 的「基本信息 + 一、需求」部分
   - 根据需求类型建议 full 或 lite 模式，记录到该功能的 `mode`
   - **full 模式：不暂停**，直接进入 Step 2（需求审核合并到 Step 2 完成后统一进行）
   - **lite 模式：暂停**（design 被跳过，需求部分是唯一文档）：`是否继续 Step 3（编码实现）？ y — 继续 / s — 跳过`

   ### Step 2: 技术设计（含自审）（lite 模式跳过，标记 skipped）
   - **前置检查**：本功能 spec 的「一、需求」部分必须存在
   - **Preamble**：加载本功能需求摘要 + 相关 memory + 其他功能概览
   - 执行 `/lc-feat:design` 逻辑（在本功能 spec 追加「二、设计」章节，已包含设计自审，生成后自动审查并修订）
   - **【多功能必做】跨功能文件冲突预检**：将本功能设计的"改动文件清单"与同流水线其他功能的清单（设计预估 + 已回写的 files_changed）对比：
     - 有重叠文件 → 在设计摘要中**明确标出重叠文件与建议执行顺序**（后跑的功能基于前者的改动编写），并记入 decisions
   - 产出：`spec-{n}-{feat-name}.md`（追加设计章节 + 自审修订记录）
   - **质量门控**：如果自审发现 P1 级严重问题，使用 **AskUserQuestion** 提示用户确认
   - **暂停（需求+设计合并审核，本功能第一次暂停）**：展示需求要点摘要 + 设计摘要 + 自审修订记录 + 冲突预检结果，审核通过后置 `design_approved: true`，然后：
     - `--until=design`：流水线结束，提示"设计已就绪，可继续添加下一个需求，或晚上用 --start 批量执行"
     - 否则：`是否继续 Step 3（编码实现）？ y — 继续 / s — 跳过`
     - 用户如对需求理解有异议：修订 spec 需求部分并同步重跑受影响的设计章节，记录到 decisions，再次展示确认

   ### Step 3: 编码实现
   - **前置检查**：
     - full 模式：本功能 spec 必须存在且包含「二、设计」章节
     - lite 模式：本功能 spec 的需求部分必须存在
     - **【多功能互斥】** 同流水线内不得有其他功能的 implement/verify/e2e 处于 `in-progress`——写代码阶段同一时刻只允许一个功能进行；发现冲突时提示先完成或标记 blocked
     - **【commit 边界提示】** 若工作区存在其他功能的未提交改动（对照其 files_changed），提示"建议先按功能 commit 上一个功能的改动再继续"，**提示但不阻断**
   - **Preamble**：加载本功能 spec 设计章节的改动文件清单和页面组件设计 + decisions + 相关 memory
   - **【强制·阻断性前置条件】必须先通过 Skill tool 调用项目编码规范 skill（不可跳过、不可凭记忆替代）**：

     > **⛔ 阻断规则：在 Skill tool 调用返回结果之前，禁止编写任何业务代码（包括 Service、页面、路由、权限）。违反此规则等同于步骤未执行。**

     1. 读取项目 `CLAUDE.md`，查找其中提到的编码规范 skill 名称
     2. **项目→skill 映射表（硬性约束）**：
        | 项目类型 | 必须使用的 skill |
        |---------|-----------------|
        | h5-vue 项目（如 kejinshou_m） | `lc-kejinshou-h5-vue` |
        | h5-nuxt 项目 | `lc-kejinshou-h5-nuxt` |
        | backend 后台项目（如 backend-kejinshou） | `lc-backend-page` |
     3. **必须使用 Skill tool 实际调用对应的项目 skill**，获取完整编码规范。**"已知规范内容"不能替代实际调用——必须产生一次 Skill tool call。**
     4. 编码时**严格遵循该 skill 定义的所有规范**（组件库、命名、Toast、Service 格式、取值方式等），规范优先级高于 implement skill 中的通用规范
     5. 如果 CLAUDE.md 未指定编码规范 skill，则根据项目目录结构自动匹配上述映射表中的 skill 并加载
   - 执行 `/lc-feat:implement` 逻辑
   - 产出：源代码文件
   - **【必做】回写 files_changed**：将本功能实际新增/修改的文件列表写入 progress.yaml 该功能的 `files_changed`——这是功能之间的代码边界，verify/e2e/commit 分组都依赖它
   - **暂停**：`是否继续 Step 4（代码验证）？ y — 继续 / s — 跳过`

   ### Step 4: 代码验证（Lint + Test + QA）
   - **前置检查**：本功能 implement 步骤必须为 done
   - **Preamble**：加载本功能需求+设计摘要 + files_changed
   - 执行 `/lc-feat:verify` 逻辑（三阶段：静态检查 → 单元测试 → 综合质量分析），**分析范围以本功能的 files_changed 为准**，不把同分支其他功能的未提交改动算进本功能的报告
   - 产出：写入 `verify-report.md` 中**本功能的章节**（`## #{id} {feat-name}`）——只新增/覆盖本功能章节，保留其他功能的章节
   - **质量门控**：
     - Lint 0 error + 测试通过 + QA >= 8 分 → 自动通过
     - 有阻塞问题 → **暂停**：
       > "代码验证发现 {N} 个问题需处理（详见 verify-report.md 对应章节）。"
   - **暂停**：`是否继续 Step 5（E2E 测试）？ y — 继续 / s — 跳过`

   ### Step 5: E2E 端到端测试（full 模式执行，lite 模式跳过）
   - **前置检查**：本功能 implement 步骤必须为 done + 检测 Playwright 是否可用 + dev server 是否运行
   - **Preamble**：加载本功能需求部分的用户操作流程 + 设计章节的路由和页面结构 + files_changed
   - 执行 `/lc-feat:e2e` 逻辑（根据需求和设计生成 E2E 测试 → 浏览器执行 → 保存截图 → 自动修复失败用例）
   - 产出：测试文件 + 截图（`tests/e2e/results/screenshots/{pipeline-name}/{feat-name}/`）+ `e2e-report.md` 中**本功能的章节**（章节化更新规则同 verify）
   - **质量门控**：
     - 全部通过 → 自动继续
     - 有失败（3 轮修复后仍失败）→ **暂停**：
       > "E2E 测试发现 {N} 个失败用例，可能是页面交互 bug，请检查截图后继续。"
   - 如果项目未配置 Playwright → 跳过并标记 skipped，记录 decision
   - **本功能完成**
   - 输出总结：本功能 files_changed 列表 + 建议 commit message（**建议按功能单独 commit**，方便 CR 与回滚）
   - 流水线内还有未完成功能 → 展示看板并询问是否继续下一个功能；全部完成 → 流水线结束
   - 提示用户：如需 Code Review 和 PR 创建，请单独使用 `/lc-feat:pr`

4. **自动断点恢复（多功能看板）**

   当 `progress.yaml` 已存在且未带新需求描述时，自动执行恢复逻辑（不需要 `--from` 参数）：

   ### 4.1 读取进度
   读取 `progress.yaml`，确定每个功能每步的 status。

   ### 4.2 验证产出文件
   对每个 `status: done` 的步骤，检查对应产出文件是否确实存在：
   - requirement/design → 对应 `spec-{n}-*.md` 存在；**design 需额外包含「二、设计」章节**（两步共用一个文件，仅文件存在不够）
   - verify/e2e → 汇总报告中存在本功能的章节
   - 不存在 → 标记为 `pending`（进度文件可能不准）
   - **旧版兼容**：无 features 数组的旧目录（`spec.md` 或 `requirement.md`/`design.md` 布局）按旧文件判定并沿用，不迁移

   ### 4.3 确定继续位置
   - 带 `--feat` → 定位该功能，找到其第一个 `status: pending` 且所有 `depends` 均为 `done/skipped` 的步骤
   - 不带 `--feat` 且只有一个未完成功能 → 自动定位该功能
   - 多个未完成功能 → 展示看板让用户选择

   ### 4.4 展示看板

   ```
   流水线恢复：3.40-batch（分支 feature/3.40-batch）
   #1 coupon-list    ✅✅✅✅✅  已完成（3 个文件，建议已 commit）
   #2 coupon-export  ✅✅🔄⏳⏳  implement 待执行 ← 设计已审核
   #3 coupon-stats   ✅🔄⏳⏳⏳  design 待执行
   （步骤顺序：requirement / design / implement / verify / e2e）

   继续哪个功能？（输入编号 / 功能名 / "新增" 添加新需求）
   ```

   ### 4.5 加载历史决策
   读取 `progress.yaml.decisions` 数组，在对话中展示所选功能的关键决策记录，帮助恢复上下文。

   如果用户通过 `--from` 参数显式指定了步骤，以用户指定为准（跳过自动检测）。

5. **记录关键决策**

   在流水线执行过程中，遇到以下情况时自动追加到 `progress.yaml.decisions`（**必须带 feature 字段**）：
   - 用户确认排除某个场景（如"鉴定场景不需要处理"）
   - 选择了特定方案（如"选择方案B：新建组件"）
   - 后端接口待确认的 mock 决策
   - 用户跳过某个步骤的原因
   - 跨功能文件冲突的执行顺序约定

   **格式**：
   ```yaml
   decisions:
     - feature: coupon-list
       step: requirement
       time: "2026-07-09 14:30"
       content: "鉴定场景（EstimateHighCreateV2）排除，验证码走小算 iframe 内部处理"
     - feature: coupon-export
       step: design
       time: "2026-07-09 15:00"
       content: "与 #1 重叠改动 CouponList.vue，约定 #1 先实现，#2 基于其改动编写"
   ```

6. **功能完成后写入 Memory**

   当某个功能的全部步骤完成（最后一步 done/skipped）时，自动将以下信息写入 Claude Memory：
   - **project 类型**：功能名称、所属流水线/分支、涉及模块、完成日期
   - **feedback 类型**：该功能开发中用户的关键反馈和偏好
   - 不写入临时性信息（具体代码细节、文件路径等）

   > 注意：按**功能粒度**写入（一个功能完成写一次），中途中断不写入。

7. **`--start` 批量执行模式**

   `/lc-feat:pipeline --start` 用于"白天出设计、晚上跑实现"的昼夜工作流：

   ### 7.1 筛选
   读取当前分支目录 `docs/pipeline/{branch-name}/` 下各流水线的 progress.yaml（多条流水线时先让用户选择，或用户显式指定 pipeline-name），筛选出满足以下条件的功能：
   - `design_approved: true`（或 lite 模式下 requirement 为 done）
   - implement 为 `pending`
   - 不含 `blocked`

   筛选结果为空 → 提示"没有已审核待实现的功能"并结束。开跑前输出执行清单（功能列表 + 顺序）。

   ### 7.2 串行执行（硬性规则）
   - **严格串行**：一个功能完整跑完 implement → verify → e2e，再开始下一个功能。**禁止交叉执行**，否则 verify 会把多个功能的改动混在一起分析
   - 执行顺序：decisions 中有跨功能顺序约定的按约定，否则按功能 id 升序
   - 门控规则沿用 `--auto`：不暂停、不确认；lint 自动 fix；测试失败自动修最多 2 轮；E2E 失败自动修 2 轮，仍失败标记 skipped 继续
   - **编码规范 skill 调用规则不变**：每个功能的 implement 前必须实际调用 Skill tool 加载项目编码规范

   ### 7.3 失败不阻塞整晚
   某个功能 implement 失败或 verify 有无法自动修复的阻塞问题 → 该功能标记 `blocked`（记录原因到 decisions），**继续下一个功能**，不中断整批。

   ### 7.4 产出 start-report.md
   全部跑完后生成/更新 `start-report.md`：
   ```markdown
   # 批量执行报告 — 2026-07-09
   ## 执行概览
   | # | 功能 | implement | verify | e2e | 状态 |
   |---|------|-----------|--------|-----|------|
   | 1 | coupon-list | ✅ | ✅ 8.6/10 | ✅ 4/4 | 完成 |
   | 2 | coupon-export | ✅ | ⚠️ 7.2/10 | ⏭️ | 需人工看 verify 章节 |
   | 3 | coupon-stats | ❌ | — | — | blocked：接口字段与设计不符 |

   ## 逐功能 commit 建议（按功能分组，依次提交）
   ### #1 coupon-list
   files: src/pages/coupon/CouponList.vue, src/services/coupon/index.ts, ...
   commit: feat(coupon): 新增优惠券列表
   ### #2 coupon-export
   ...
   ```
   - 每个功能的 files_changed 分组 + 建议 commit message 是**早上人工按功能逐个 commit** 的依据
   - blocked 功能列明原因和建议的人工处理方式

**Guardrails**
- **【强制·阻断】编码阶段必须通过 Skill tool 实际调用项目对应的编码规范 skill**（h5-vue→`lc-kejinshou-h5-vue`，h5-nuxt→`lc-kejinshou-h5-nuxt`，backend→`lc-backend-page`），每次编码都必须产生一次 Skill tool call，不可凭记忆替代，未调用不得编码
- **流水线全程不执行任何 git 操作**（不 add、不 commit、不 push、不创建 PR）
- git 操作由用户自行决定和执行；流水线只在功能完成时输出 files_changed 分组 + 建议 commit message
- **流水线一律创建在分支目录下**：`docs/pipeline/{branch-name}/{pipeline-name}/` 两级结构，禁止在 `docs/pipeline/` 一级直接新建；用户指定的 pipeline-name 优先，否则默认同分支名；同流水线新增功能编号自动 +1；旧版一级目录布局沿用不迁移
- **写文档阶段（requirement/design）多功能可并行推进；写代码阶段（implement 及之后）同一时刻只允许一个功能进行**
- **`--start` 只执行 `design_approved: true` 的功能**（未经人工审核的设计不得夜间自动编码），且必须严格串行
- **implement 完成必须回写 files_changed**；verify/e2e 的分析范围以本功能 files_changed 为准
- **汇总报告（verify-report.md / e2e-report.md）按功能章节化更新**：只新增/覆盖本功能章节，不整份重写
- **design 完成时必须做跨功能文件冲突预检**，重叠文件标出执行顺序并记入 decisions
- 每步完成必须暂停等待确认（**requirement → design 连续执行不暂停**、lint 自动通过时除外），提示格式统一为 `y — 继续 / s — 跳过`
- **progress.yaml 必须在每步前后更新**，保证断点恢复的准确性
- **Preamble 必须在每步执行前运行**，不能跳过
- Preamble 加载 Memory 最多 3 条，避免上下文过载
- Preamble 加载前序产出只取摘要片段，不全文读取
- 用户随时可以说"跳过"或"回退到{步骤}"
- lite 模式适用于小改动，避免为 10 行代码跑完 5 步
- 跳过的步骤标记为 `skipped` 而非 `done`
- 旧版单功能目录（无 features 数组）按旧逻辑沿用，不迁移
- **修改任何 lc-feat-* skill 后，必须同步更新流水线使用指南**（路径：`~/.claude/skills/docs/lc-feat-pipeline-guide.md`）。更新内容包括：步骤说明、命令参数、产出文件、质量门控规则等与 skill 变更相关的章节。同时更新指南头部的版本号和更新日期

**`--auto` 全自动模式规则**

当传入 `--auto` 参数时，流水线进入全自动模式：

- **不暂停、不等待确认**，所有步骤连续执行，中间不询问用户
- **⚠️ --auto 模式同样必须调用 Skill tool 加载项目编码规范 skill，不可跳过**
- **默认走完整流程（full 模式）**，除非用户显式指定 `--mode=lite`
- 质量门控自动决策：verify 阶段 lint error 自动 `--fix`、测试失败自动修复最多 2 轮；E2E 失败自动修复最多 2 轮，仍失败则标记 skipped 继续
- 设计自审发现的问题自动修订，不暂停
- 仍然生成产出文档（spec 等），确保可追溯和断点恢复
- 仍然更新 `progress.yaml`，确保可追溯
- 流水线结束后输出一份简要总结（files_changed 列表 + 建议 commit message）
- 触发方式：`/lc-feat:pipeline --auto <需求描述>` 或用户说"全自动"、"自动跑"、"不用确认"
- 前置检查失败时不直接报错，而是提示并建议补充执行
- `--auto` 作用于**单个功能**；批量执行多个功能请用 `--start`

---

## 使用示例

### 示例 1：昼夜工作流（推荐：同分支多功能）

**白天——逐个出需求+设计（只写文档，可连续做多个）：**

```bash
# 当前在 feature/3.40-batch 分支
用户：/lc-feat:pipeline --until=design 优惠券列表页，搜索+表格+新增编辑弹窗
```

```
AI：流水线已初始化：3.40-batch（分支 feature/3.40-batch）
    新增功能 #1 coupon-list → spec-1-coupon-list.md
    [需求分析 → 技术设计（含自审）连续执行...]

    需求要点：... / 设计摘要：... / 自审修订：...
    审核通过后本功能设计就绪（--until=design，不进入编码）。
```

```bash
用户：没问题
AI：#1 coupon-list 设计已审核（design_approved: true），流水线结束。
    可继续添加下一个需求，或晚上用 --start 批量执行。

用户：/lc-feat:pipeline --until=design 优惠券导出功能，列表页加导出按钮
AI：新增功能 #2 coupon-export → spec-2-coupon-export.md
    ⚠️ 冲突预检：#2 与 #1 均改动 CouponList.vue，建议 #1 先实现（已记入 decisions）
    ...
```

**晚上——批量串行执行：**

```bash
用户：/lc-feat:pipeline --start
```

```
AI：批量执行模式：3.40-batch
    执行清单（串行）：#1 coupon-list → #2 coupon-export
    [每个功能：implement → verify → e2e，--auto 门控，失败标记 blocked 继续下一个]

    🏁 批量执行完成，详见 start-report.md：
    #1 coupon-list   ✅ 完成（verify 8.6/10，e2e 4/4）
    #2 coupon-export ✅ 完成（verify 8.2/10，e2e 3/3）

    早上请按 start-report.md 的分组逐功能 commit。
```

### 示例 2：不指定名字，默认分支名；再次进入展示看板

```bash
# 当前在 feature/3.38-coupon 分支
用户：/lc-feat:pipeline
```

首次：AI 建分支目录+默认流水线 `docs/pipeline/3.38-coupon/3.38-coupon/`，功能 #1 从需求分析开始。
再次进入（已有多个功能）：

```
AI：流水线恢复：3.38-coupon
    #1 coupon-list    ✅✅✅✅✅  已完成
    #2 coupon-export  ✅✅🔄⏳⏳  implement 待执行 ← 设计已审核
    #3 coupon-stats   ✅🔄⏳⏳⏳  design 待执行

    继续哪个功能？（编号 / 功能名 / "新增"）
```

### 示例 3：自定义流水线名 + 定位功能重跑

```bash
用户：/lc-feat:pipeline 3.40-batch --feat=2 --from=verify
```

```
AI：流水线 3.40-batch，功能 #2 coupon-export，从 verify 步骤开始
    分析范围：#2 的 files_changed（3 个文件）
    验证结果写入 verify-report.md 的「## #2 coupon-export」章节
```

### 示例 4：单功能全自动（小功能快速开发）

```bash
用户：/lc-feat:pipeline --auto 新增商品标签筛选功能，在搜索页添加标签多选组件
```

AI 不暂停、不等待确认，对该功能连续执行 5 步。结束后输出总结：

```
AI：🏁 功能 #1 tag-filter 全自动完成
    ✅ requirement / ✅ design（自审修订 1 个问题）/ ✅ implement / ✅ verify（QA 8.2/10）/ ⏭️ e2e（dev server 未启动）

    📁 files_changed：
    - src/views/goods/components/TagFilter.vue（新增）
    - src/views/goods/GoodsSearch.vue（修改）

    💡 建议 commit message：feat(goods): 添加商品标签筛选功能
    如需 Code Review 和 PR 创建，请使用 /lc-feat:pr
```

### 示例 5：lite 模式小改动

```bash
用户：/lc-feat:pipeline --mode=lite 修复价格显示精度问题
```

```
AI：新增功能 #{n} fix-price-display（lite 模式，3 步）
    执行步骤：requirement → implement → verify
    跳过步骤：design / e2e
```

### 示例 6：中途跳过步骤

```bash
AI：是否继续 Step 5（E2E 测试）？
      y — 继续
      s — 跳过

用户：s
AI：Step 5（E2E 测试）已跳过，标记为 skipped。
    功能 #2 完成。流水线内还有 #3 未完成，继续吗？
```

---

### 交互速查

| 场景 | 命令 |
|------|------|
| 新功能完整流水线 | `/lc-feat:pipeline [需求描述]` |
| 白天只出需求+设计 | `/lc-feat:pipeline --until=design <需求描述>` |
| 同流水线追加功能 | `/lc-feat:pipeline <新需求描述>`（编号自动 +1） |
| 晚上批量跑实现+验证 | `/lc-feat:pipeline --start` |
| 查看功能看板 / 断点恢复 | `/lc-feat:pipeline`（自动检测） |
| 定位某功能重跑 | `/lc-feat:pipeline --feat=2 --from=verify` |
| 小改动精简流程 | `/lc-feat:pipeline --mode=lite <描述>` |
| 单功能全自动 | `/lc-feat:pipeline --auto <描述>` |
| 单独跑 PR | `/lc-feat:pr` |
| 发布后收尾 | `/lc-feat:document-release` |
| 接口同步 | `/lc-feat:api-sync` |
