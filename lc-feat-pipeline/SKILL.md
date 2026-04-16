---
name: lc-feat-pipeline
description: 功能开发总控技能。串联需求分析→设计→设计审核→编码→Lint→测试→QA→CR的完整流水线，支持从任意步骤开始和断点恢复。当用户说"开始流水线"、"完整开发"、"走流程"、"pipeline"时触发。
license: MIT
metadata:
  author: kejinshou-team
  version: "0.0.2"
---

# 功能开发流水线（总控）

串联完整的功能开发流程，每步完成后等待确认再进入下一步。
**流水线不执行任何 git 操作（commit/push/PR），仅做分析和代码生成。**

---

**Input**: `/lc-feat:pipeline <feat-name> [--from=<step>] [--mode=full|lite]`

参数说明：
- `feat-name`: 功能名称（kebab-case）
- `--from=<step>`: 从指定步骤开始（可选，自动断点恢复时不需要）
- `--mode=full|lite`: 流水线模式（可选，默认根据需求类型自动选择）

可用步骤：`requirement` → `design` → `design-review` → `implement` → `lint` → `test` → `qa` → `cr`

**流水线模式**

| 模式 | 适用场景 | 执行步骤 |
|------|---------|---------|
| **full** | 新功能（需要新页面/新路由） | 全部 8 步 |
| **lite** | 功能扩展/Bug修复/小改动 | requirement → implement → lint → test → cr（5 步）|

**Steps**

1. **初始化流水线**

   ### 1.1 分支检测与 feat-name 解析

   运行 `git branch --show-current` 获取当前分支名：

   **规则 A — 在 master/main/develop 上：**
   - 如果用户提供了 feat-name，提示用户创建功能分支（不自动执行）
   - 如果没有 feat-name，询问

   **规则 B — 在功能分支上：**
   - 从分支名提取 feat-name，去掉 `feature/` 前缀直接使用
     - `feature/3.5-wx` → `3.5-wx`
     - `feature/3.32-xiaosuan-qr` → `3.32-xiaosuan-qr`
   - 用户显式提供的 feat-name 优先
   - **不要自行起 kebab-case 名称，直接用分支名中的命名**

   ### 1.2 初始化目录与进度文件

   检查 `docs/pipeline/{feat-name}/` 目录是否存在：
   - 不存在：创建目录，初始化 `progress.yaml`
   - 已存在：读取 `progress.yaml`，进入**自动断点恢复**流程（见第 3 节）

   **progress.yaml 格式**：

   ```yaml
   feat_name: {feat-name}
   mode: full|lite
   created: YYYY-MM-DD HH:mm
   updated: YYYY-MM-DD HH:mm
   steps:
     requirement: { status: pending, file: requirement.md }
     design: { status: pending, file: design.md, depends: [requirement] }
     design-review: { status: pending, file: design-review.md, depends: [design] }
     implement: { status: pending, file: "", depends: [design-review] }
     lint: { status: pending, file: lint-report.md, depends: [implement] }
     test: { status: pending, file: test-report.md, depends: [implement] }
     qa: { status: pending, file: qa-report.md, depends: [implement] }
     cr: { status: pending, file: "", depends: [lint] }
   decisions: []
   ```

   **status 取值**：`pending` | `in-progress` | `done` | `skipped` | `blocked`

2. **Preamble — 每步执行前的上下文注入**

   每个步骤执行前，必须先运行 Preamble 收集上下文，**注入到当前步骤的执行环境中**：

   ### 2.1 读取进度状态
   读取 `docs/pipeline/{feat-name}/progress.yaml`，获取：
   - 当前步骤名、模式（full/lite）
   - 前序步骤的完成状态
   - 历史 decisions 列表

   ### 2.2 加载相关 Memory
   检查 Claude Memory 中是否有与当前功能相关的记录：
   - 搜索 **project 类型** memory：当前项目的历史功能记录（如之前类似功能的决策）
   - 搜索 **feedback 类型** memory：用户的偏好和反馈（如"偏好新建组件而非复用"）
   - 最多加载 **3 条**最相关的 memory，避免上下文过载

   ### 2.3 加载前序产出摘要
   根据当前步骤的 `depends`，读取前序步骤产出文件的**关键信息**：

   | 当前步骤 | 需要加载的前序产出 |
   |---------|-------------------|
   | design | requirement.md 的"需求背景"和"功能描述"部分 |
   | design-review | design.md 全文 + requirement.md 的功能点清单 |
   | implement | design.md 的"改动文件清单"和"组件设计"部分 |
   | lint | implement 步骤改动的文件列表（从 design.md 或 git diff 获取） |
   | test | requirement.md 的用户故事 + implement 改动的文件列表 |
   | qa | requirement.md + design.md + implement 改动文件列表 |
   | cr | 全部已完成步骤的产出摘要 |

   > 注意：只加载必要的片段，不全文读取大文件，控制 token 消耗。

   ### 2.4 注入上下文
   将收集到的信息组装为结构化上下文，在步骤执行前输出：

   ```
   === Preamble: {step-name} ===
   功能：{feat-name}（{mode} 模式）
   前序状态：requirement ✅ → design ✅ → design-review ✅

   关键决策：
   - [requirement] 鉴定场景排除
   - [design] 选择方案B：新建组件

   相关经验（Memory）：
   - 用户偏好新建独立组件而非复用耦合组件

   前序产出要点：
   - 改动文件：DialogGoodsQrCode.vue（新建）、GoodsCreateV2.vue（修改）...
   ===
   ```

3. **按顺序执行各步骤**

   每步执行前：运行 Preamble（第 2 节）→ 更新 progress.yaml（status = in-progress）
   每步执行后：更新 progress.yaml（status = done + updated 时间戳）

   ### Step 1: 需求分析
   - **前置检查**：无
   - **Preamble**：加载项目 memory、分支信息
   - 执行 `/lc-feat:requirement` 逻辑
   - 产出：`requirement.md`
   - 根据需求类型建议 full 或 lite 模式，记录到 `progress.yaml.mode`
   - **暂停等待用户确认**

   ### Step 2: 技术设计（lite 模式跳过，标记 skipped）
   - **前置检查**：`requirement.md` 必须存在
   - **Preamble**：加载 requirement.md 摘要 + 相关 memory
   - 执行 `/lc-feat:design` 逻辑
   - 产出：`design.md`
   - **暂停等待用户确认**

   ### Step 3: 设计审核（lite 模式跳过，标记 skipped）
   - **前置检查**：`design.md` 必须存在
   - **Preamble**：加载 design.md + requirement.md 功能点 + 相关 memory
   - 执行 `/lc-feat:design-review` 逻辑
   - 产出：`design-review.md` + 修订后的 `design.md`
   - **质量门控**：如果审核发现 P1 级严重问题，使用 **AskUserQuestion** 提示：
     > "设计审核发现 {N} 个严重问题（已自动修订）。请确认修订后的设计文档是否满意，或需要进一步调整后再进入编码阶段。"
   - **暂停等待用户确认**

   ### Step 4: 编码实现
   - **前置检查**：
     - full 模式：`design.md` 必须存在（或 `design-review.md` 存在表示已审核）
     - lite 模式：`requirement.md` 必须存在
   - **Preamble**：加载 design.md 的改动文件清单和组件设计 + decisions + 相关 memory
   - **必须先加载项目编码规范 skill**：
     1. 读取项目 `CLAUDE.md`，查找其中提到的编码规范 skill 名称（如 `lc-kejinshou-backend-page`、`lc-kejinshou-h5-vue`、`lc-kejinshou-h5-nuxt`）
     2. 如果该 skill 在当前可用 skill 列表中存在，**使用 Skill tool 加载该 skill**，获取完整编码规范
     3. 编码时**严格遵循该 skill 定义的所有规范**（组件库、命名、Toast、Service 格式、取值方式等），规范优先级高于 implement skill 中的通用规范
     4. 如果 CLAUDE.md 未指定编码规范 skill，则读取项目中相似模块的代码作为参考
   - 执行 `/lc-feat:implement` 逻辑
   - 产出：源代码文件
   - **暂停等待用户确认**

   ### Step 5: 代码检查
   - **前置检查**：implement 步骤必须为 done
   - **Preamble**：加载改动文件列表
   - 执行 `/lc-feat:lint` 逻辑（直接执行 ESLint 检查并自动修复）
   - 产出：`lint-report.md`
   - **质量门控**：
     - 新增代码 0 error → 自动通过，继续下一步
     - 新增代码有 error → 尝试 `--fix` 自动修复，修复后仍有 error 则**暂停**：
       > "Lint 检查发现 {N} 个无法自动修复的错误，建议手动修复后再继续。"

   ### Step 6: 自动化测试（full + lite 均执行）
   - **前置检查**：implement 步骤必须为 done + 检测 vitest 是否可用
   - **Preamble**：加载 requirement.md 的用户故事 + 改动文件列表
   - 执行 `/lc-feat:test` 逻辑（自动写测试 → 自动跑 → 自动修复失败用例）
   - 产出：测试文件 + `test-report.md`
   - **质量门控**：
     - 全部通过 → 自动继续
     - 有失败（3 轮修复后仍失败）→ **暂停**：
       > "测试发现 {N} 个失败用例，可能是源代码 bug，请检查后继续。"
   - 如果项目未配置 vitest/jest → 跳过并标记 skipped，记录 decision

   ### Step 7: QA 分析（lite 模式跳过，标记 skipped）
   - **Preamble**：加载 requirement.md + design.md 摘要 + 改动文件列表
   - 执行 `/lc-feat:qa` 逻辑
   - 产出：`qa-report.md`
   - **暂停等待用户确认**

   ### Step 8: Code Review（仅分析，不执行 git 操作）
   - **Preamble**：加载全部已完成步骤的产出摘要
   - 执行 `/lc-feat:pr` 的 CR 阶段逻辑
   - 产出：CR 分析报告（输出到对话）
   - 建议 commit message
   - **流水线结束**

4. **自动断点恢复**

   当 `progress.yaml` 已存在时，自动执行恢复逻辑（不需要 `--from` 参数）：

   ### 4.1 读取进度
   读取 `progress.yaml`，确定每步的 status。

   ### 4.2 验证产出文件
   对每个 `status: done` 的步骤，检查其 `file` 字段对应的文件是否确实存在：
   - 存在 → 确认完成
   - 不存在 → 标记为 `pending`（进度文件可能不准）

   ### 4.3 确定继续位置
   找到第一个 `status: pending` 且所有 `depends` 均为 `done/skipped` 的步骤。

   ### 4.4 展示恢复信息
   输出当前进度摘要：
   ```
   流水线恢复：{feat-name}（{mode} 模式）
   ✅ requirement — done
   ✅ design — done
   ✅ design-review — done
   🔄 implement — 待执行 ← 从此继续
   ⏳ lint — pending
   ⏳ cr — pending
   ```

   ### 4.5 加载历史决策
   读取 `progress.yaml.decisions` 数组，在对话中展示关键决策记录，帮助恢复上下文。

   如果用户通过 `--from` 参数显式指定了步骤，以用户指定为准（跳过自动检测）。

5. **记录关键决策**

   在流水线执行过程中，遇到以下情况时自动追加到 `progress.yaml.decisions`：
   - 用户确认排除某个场景（如"鉴定场景不需要处理"）
   - 选择了特定方案（如"选择方案B：新建组件"）
   - 后端接口待确认的 mock 决策
   - 用户跳过某个步骤的原因

   **格式**：
   ```yaml
   decisions:
     - step: requirement
       time: "2026-04-15 14:30"
       content: "鉴定场景（EstimateHighCreateV2）排除，验证码走小算 iframe 内部处理"
     - step: design
       time: "2026-04-15 15:00"
       content: "选择方案B：新建 DialogGoodsQrCode 组件，不复用 ScanQrcodePopup"
   ```

6. **流水线结束后写入 Memory**

   当流水线全部完成（cr.status = done）时，自动将以下信息写入 Claude Memory：
   - **project 类型**：功能名称、涉及模块、完成日期
   - **feedback 类型**：流水线中用户的关键反馈和偏好
   - 不写入临时性信息（具体代码细节、文件路径等）

   > 注意：仅在所有步骤完成后执行，中途中断不写入。

**Guardrails**
- **流水线全程不执行任何 git 操作**（不 add、不 commit、不 push、不创建 PR）
- git 操作由用户自行决定和执行
- 每步完成必须暂停等待确认（lint 自动通过时除外）
- **progress.yaml 必须在每步前后更新**，保证断点恢复的准确性
- **Preamble 必须在每步执行前运行**，不能跳过
- Preamble 加载 Memory 最多 3 条，避免上下文过载
- Preamble 加载前序产出只取摘要片段，不全文读取
- 用户随时可以说"跳过"或"回退到{步骤}"
- lite 模式适用于小改动，避免为 10 行代码跑完 8 步
- 跳过的步骤标记为 `skipped` 而非 `done`
- 前置检查失败时不直接报错，而是提示并建议补充执行
