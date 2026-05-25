---
name: lc-feat-pipeline
description: 功能开发总控技能。串联需求分析→设计→设计审核→编码→Lint→测试→E2E→QA的完整流水线（不含CR/PR），支持从任意步骤开始和断点恢复。CR/PR请单独使用 /lc-feat:pr。当用户说"开始流水线"、"完整开发"、"走流程"、"pipeline"时触发。
license: MIT
metadata:
  author: kejinshou-team
  version: "0.0.3"
  guide: "~/.claude/skills/docs/lc-feat-pipeline-guide.md"
---

# 功能开发流水线（总控）

串联完整的功能开发流程，每步完成后等待确认再进入下一步。
**流水线不执行任何 git 操作（commit/push/PR），仅做分析和代码生成。**

**每步暂停时的交互格式**：
```
是否继续 Step N（步骤名）？
  y — 继续
  s — 跳过此步骤
```
- 用户输入 `y` 或 `Y`：执行当前步骤
- 用户输入 `s` 或 `S` 或 `skip` 或 `跳过`：跳过当前步骤，标记为 `skipped`，进入下一步

---

**Input**: `/lc-feat:pipeline <feat-name> [--from=<step>] [--mode=full|lite] [--auto]`

参数说明：
- `feat-name`: 功能名称（kebab-case）
- `--from=<step>`: 从指定步骤开始（可选，自动断点恢复时不需要）
- `--mode=full|lite`: 流水线模式（可选，默认根据需求类型自动选择）
- `--auto`: 全自动模式，跳过所有中间确认，一口气跑完全部步骤。适合自己用的小功能快速开发

可用步骤：`requirement` → `design` → `design-review` → `implement` → `lint` → `test` → `e2e` → `qa`

> **CR/PR 不在流水线中执行**，请在流水线完成后单独使用 `/lc-feat:pr` 进行 Code Review 和 PR 创建。

**流水线模式**

| 模式 | 适用场景 | 执行步骤 |
|------|---------|---------|
| **full** | 新功能（需要新页面/新路由） | 全部 8 步（requirement → design → design-review → implement → lint → test → e2e → qa） |
| **lite** | 功能扩展/Bug修复/小改动 | requirement → implement → lint → test（4 步，e2e/qa 跳过）|

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
     e2e: { status: pending, file: e2e-report.md, depends: [implement] }
     qa: { status: pending, file: qa-report.md, depends: [implement] }
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
   | e2e | requirement.md 的用户操作流程 + design.md 的路由和页面结构 + implement 改动文件列表 |
   | qa | requirement.md + design.md + implement 改动文件列表 |

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
   - **暂停**：`是否继续 Step 2（技术设计）？ y — 继续 / s — 跳过`

   ### Step 2: 技术设计（lite 模式跳过，标记 skipped）
   - **前置检查**：`requirement.md` 必须存在
   - **Preamble**：加载 requirement.md 摘要 + 相关 memory
   - 执行 `/lc-feat:design` 逻辑
   - 产出：`design.md`
   - **暂停**：`是否继续 Step 3（设计审核）？ y — 继续 / s — 跳过`

   ### Step 3: 设计审核（lite 模式跳过，标记 skipped）
   - **前置检查**：`design.md` 必须存在
   - **Preamble**：加载 design.md + requirement.md 功能点 + 相关 memory
   - 执行 `/lc-feat:design-review` 逻辑
   - 产出：`design-review.md` + 修订后的 `design.md`
   - **质量门控**：如果审核发现 P1 级严重问题，使用 **AskUserQuestion** 提示：
     > "设计审核发现 {N} 个严重问题（已自动修订）。请确认修订后的设计文档是否满意，或需要进一步调整后再进入编码阶段。"
   - **暂停**：`是否继续 Step 4（编码实现）？ y — 继续 / s — 跳过`

   ### Step 4: 编码实现
   - **前置检查**：
     - full 模式：`design.md` 必须存在（或 `design-review.md` 存在表示已审核）
     - lite 模式：`requirement.md` 必须存在
   - **Preamble**：加载 design.md 的改动文件清单和组件设计 + decisions + 相关 memory
   - **【强制·阻断性前置条件】必须先通过 Skill tool 调用项目编码规范 skill（不可跳过、不可凭记忆替代）**：

     > **⛔ 阻断规则：在 Skill tool 调用返回结果之前，禁止编写任何业务代码（包括 Service、页面、路由、权限）。违反此规则等同于步骤未执行。**

     1. 读取项目 `CLAUDE.md`，查找其中提到的编码规范 skill 名称
     2. **项目→skill 映射表（硬性约束）**：
        | 项目类型 | 必须使用的 skill |
        |---------|-----------------|
        | h5-vue 项目（如 kejinshou_m） | `lc-kejinshou-h5-vue` |
        | h5-nuxt 项目 | `lc-kejinshou-h5-nuxt` |
        | backend 后台项目（如 backend-kejinshou） | `lc-kejinshou-backend-page` |
     3. **必须使用 Skill tool 实际调用对应的项目 skill**，获取完整编码规范。**"已知规范内容"不能替代实际调用——必须产生一次 Skill tool call。**
     4. 编码时**严格遵循该 skill 定义的所有规范**（组件库、命名、Toast、Service 格式、取值方式等），规范优先级高于 implement skill 中的通用规范
     5. 如果 CLAUDE.md 未指定编码规范 skill，则根据项目目录结构自动匹配上述映射表中的 skill 并加载
   - 执行 `/lc-feat:implement` 逻辑
   - 产出：源代码文件
   - **暂停**：`是否继续 Step 5（代码检查）？ y — 继续 / s — 跳过`

   ### Step 5: 代码检查
   - **前置检查**：implement 步骤必须为 done
   - **Preamble**：加载改动文件列表
   - 执行 `/lc-feat:lint` 逻辑（直接执行 ESLint 检查并自动修复）
   - 产出：`lint-report.md`
   - **质量门控**：
     - 新增代码 0 error → 自动通过，继续下一步
     - 新增代码有 error → 尝试 `--fix` 自动修复，修复后仍有 error 则**暂停**：
       > "Lint 检查发现 {N} 个无法自动修复的错误，建议手动修复后再继续。"
   - **暂停**：`是否继续 Step 6（自动化测试）？ y — 继续 / s — 跳过`

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
   - **暂停**：`是否继续 Step 7（E2E 测试）？ y — 继续 / s — 跳过`

   ### Step 7: E2E 端到端测试（full 模式执行，lite 模式跳过）
   - **前置检查**：implement 步骤必须为 done + 检测 Playwright 是否可用 + dev server 是否运行
   - **Preamble**：加载 requirement.md 的用户操作流程 + design.md 的路由和页面结构 + 改动文件列表
   - 执行 `/lc-feat:e2e` 逻辑（根据需求和设计生成 E2E 测试 → 浏览器执行 → 保存截图 → 自动修复失败用例）
   - 产出：测试文件 + 截图（`tests/e2e/results/screenshots/{feat-name}/`）+ `e2e-report.md`
   - **质量门控**：
     - 全部通过 → 自动继续
     - 有失败（3 轮修复后仍失败）→ **暂停**：
       > "E2E 测试发现 {N} 个失败用例，可能是页面交互 bug，请检查截图后继续。"
   - 如果项目未配置 Playwright → 跳过并标记 skipped，记录 decision
   - **暂停**：`是否继续 Step 8（QA 分析）？ y — 继续 / s — 跳过`

   ### Step 8: QA 分析（lite 模式跳过，标记 skipped）
   - **Preamble**：加载 requirement.md + design.md 摘要 + 改动文件列表
   - 执行 `/lc-feat:qa` 逻辑
   - 产出：`qa-report.md`
   - **流水线结束**
   - 输出总结：改动文件列表 + 建议 commit message
   - 提示用户：如需 Code Review 和 PR 创建，请单独使用 `/lc-feat:pr`

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

   当流水线全部完成（qa.status = done，或 lite 模式最后一步完成）时，自动将以下信息写入 Claude Memory：
   - **project 类型**：功能名称、涉及模块、完成日期
   - **feedback 类型**：流水线中用户的关键反馈和偏好
   - 不写入临时性信息（具体代码细节、文件路径等）

   > 注意：仅在所有步骤完成后执行，中途中断不写入。

**Guardrails**
- **【强制·阻断】编码阶段必须通过 Skill tool 实际调用项目对应的编码规范 skill**（h5-vue→`lc-kejinshou-h5-vue`，h5-nuxt→`lc-kejinshou-h5-nuxt`，backend→`lc-kejinshou-backend-page`），每次编码都必须产生一次 Skill tool call，不可凭记忆替代，未调用不得编码
- **流水线全程不执行任何 git 操作**（不 add、不 commit、不 push、不创建 PR）
- git 操作由用户自行决定和执行
- 每步完成必须暂停等待确认（lint 自动通过时除外），提示格式统一为 `y — 继续 / s — 跳过`
- **progress.yaml 必须在每步前后更新**，保证断点恢复的准确性
- **Preamble 必须在每步执行前运行**，不能跳过
- Preamble 加载 Memory 最多 3 条，避免上下文过载
- Preamble 加载前序产出只取摘要片段，不全文读取
- 用户随时可以说"跳过"或"回退到{步骤}"
- lite 模式适用于小改动，避免为 10 行代码跑完 7 步
- 跳过的步骤标记为 `skipped` 而非 `done`
- **修改任何 lc-feat-* skill 后，必须同步更新流水线使用指南**（路径：`~/.claude/skills/docs/lc-feat-pipeline-guide.md`）。更新内容包括：步骤说明、命令参数、产出文件、质量门控规则等与 skill 变更相关的章节。同时更新指南头部的版本号和更新日期

**`--auto` 全自动模式规则**

当传入 `--auto` 参数时，流水线进入全自动模式：

- **不暂停、不等待确认**，所有步骤连续执行，中间不询问用户
- **⚠️ --auto 模式同样必须调用 Skill tool 加载项目编码规范 skill，不可跳过**
- **默认走完整流程（full 模式）**，除非用户显式指定 `--mode=lite`
- 质量门控自动决策：lint error 自动 `--fix`；测试/E2E 失败自动修复最多 2 轮，仍失败则标记 skipped 继续
- 设计审核发现的问题自动修订，不暂停
- 仍然生成产出文档（requirement.md / design.md 等），确保可追溯和断点恢复
- 仍然更新 `progress.yaml`，确保可追溯
- 流水线结束后输出一份简要总结（改动文件列表 + 建议 commit message）
- 触发方式：`/lc-feat:pipeline --auto <需求描述>` 或用户说"全自动"、"自动跑"、"不用确认"
- 前置检查失败时不直接报错，而是提示并建议补充执行

---

## 使用示例

### 示例 1：在功能分支上启动完整流水线

```bash
# 当前在 feature/3.38-coupon 分支
用户：/lc-feat:pipeline
```

AI 自动从分支名提取 `feat-name = 3.38-coupon`，创建 `docs/pipeline/3.38-coupon/`，初始化 `progress.yaml`，进入 Step 1 需求分析。

```
AI：流水线已初始化：3.38-coupon（检测为新功能，建议 full 模式）
    📁 docs/pipeline/3.38-coupon/progress.yaml 已创建

    是否继续 Step 1（需求分析）？
      y — 继续
      s — 跳过
```

```bash
用户：y
AI：请描述你想要实现的功能（文字、截图路径或文档链接均可）。
用户：后台新增优惠券管理，列表页 + 新增/编辑弹窗 + 停用/启用 + 领取记录子页面。截图 /tmp/coupon.png
```

AI 生成 `requirement.md`，暂停等待确认，之后每步输入 `y` 即可推进。

---

### 示例 2：显式指定 feat-name + lite 模式

```bash
用户：/lc-feat:pipeline fix-price-display --mode=lite
```

```
AI：流水线已初始化：fix-price-display（lite 模式，4 步）
    执行步骤：requirement → implement → lint → test
    跳过步骤：design / design-review / e2e / qa

    是否继续 Step 1（需求分析）？
      y — 继续
      s — 跳过
```

---

### 示例 3：断点恢复（自动检测）

上次在 implement 步骤中断，重新进入流水线：

```bash
用户：/lc-feat:pipeline
```

```
AI：检测到已有进度，自动恢复：3.38-coupon（full 模式）
    ✅ requirement — done
    ✅ design — done
    ✅ design-review — done
    🔄 implement — 待执行 ← 从此继续
    ⏳ lint — pending
    ⏳ test — pending
    ⏳ e2e — pending
    ⏳ qa — pending

    历史决策：
    - [requirement] 发放渠道字段后续迭代再加
    - [design] 选择方案A：复用现有 FormDialog 组件

    是否继续 Step 4（编码实现）？
      y — 继续
      s — 跳过
```

---

### 示例 4：从指定步骤开始

```bash
用户：/lc-feat:pipeline 3.38-coupon --from=lint
```

```
AI：流水线从 lint 步骤开始：3.38-coupon
    ⏭️ requirement — 跳过
    ⏭️ design — 跳过
    ⏭️ design-review — 跳过
    ⏭️ implement — 跳过
    🔄 lint — 从此开始
    ⏳ test — pending
    ⏳ e2e — pending
    ⏳ qa — pending

    是否继续 Step 5（代码检查）？
      y — 继续
      s — 跳过
```

---

### 示例 5：全自动模式

```bash
用户：/lc-feat:pipeline --auto 新增商品标签筛选功能，在搜索页添加标签多选组件
```

AI 不暂停、不等待确认，连续执行 8 步。结束后输出总结：

```
AI：🏁 流水线全自动完成：商品标签筛选

    📊 执行结果：
    ✅ requirement — done（8 个功能点）
    ✅ design — done（3 个文件改动）
    ✅ design-review — done（1 个问题已自动修订）
    ✅ implement — done（新增 TagFilter.vue，修改 GoodsSearch.vue）
    ✅ lint — done（2 个 warning 已自动修复）
    ✅ test — done（5/5 用例通过）
    ⏭️ e2e — skipped（dev server 未启动）
    ✅ qa — done（8.2/10）

    📁 改动文件：
    - src/views/goods/components/TagFilter.vue（新增）
    - src/views/goods/GoodsSearch.vue（修改）
    - src/request/MwpGoods.ts（修改，新增 getTagList 接口）

    💡 建议 commit message：
    feat(goods): 添加商品标签筛选功能

    如需 Code Review 和 PR 创建，请使用 /lc-feat:pr
```

---

### 示例 6：H5 移动端项目（kejinshou_m）

```bash
# 当前在 feature/3.37-bargain 分支，kejinshou_m 项目
用户：/lc-feat:pipeline
```

与后台项目流程一致，区别在于 Step 4 编码时：
- 自动调用 `lc-kejinshou-h5-vue` 编码规范 skill（而非 backend-page）
- 使用 Vant 4 + XPopup/XNavBar 组件（而非 KrCard/KrTable）
- 请求层使用 `MwpXxx.ts` + `mwpRequest` 模式
- 路由使用 `routerKey.ts` + `routerName` 点分命名

---

### 示例 7：中途跳过步骤

```bash
AI：是否继续 Step 7（E2E 测试）？
      y — 继续
      s — 跳过

用户：s
```

```
AI：Step 7（E2E 测试）已跳过，标记为 skipped。
    是否继续 Step 8（QA 分析）？
      y — 继续
      s — 跳过
```

---

### 交互速查

| 场景 | 命令 |
|------|------|
| 新功能完整流水线 | `/lc-feat:pipeline` |
| 小改动精简流程 | `/lc-feat:pipeline --mode=lite` |
| 全自动不确认 | `/lc-feat:pipeline --auto <描述>` |
| 从指定步骤开始 | `/lc-feat:pipeline --from=implement` |
| 断点恢复 | `/lc-feat:pipeline`（自动检测） |
| 单独跑 PR | `/lc-feat:pr` |
| 发布后收尾 | `/lc-feat:document-release` |
| 接口同步 | `/lc-feat:api-sync` |
