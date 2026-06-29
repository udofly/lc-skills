# lc-feat 工作流更新日志

> 记录 lc-feat 流水线所有 skill 的版本变更、功能新增与修复。

---

## Skill 版本总览

| Skill | 版本 | 最近更新 |
|---|---|---|
| lc-feat-pipeline | 0.0.5 | 2026-05-29 |
| lc-feat-requirement | 0.0.2 | 2026-05-25 |
| lc-feat-design | 0.0.3 | 2026-05-29 |
| lc-feat-implement | 0.0.2 | 2026-05-25 |
| lc-feat-verify | 0.0.1 | 2026-05-29 |
| lc-feat-e2e | 0.0.4 | 2026-06-29 |
| lc-feat-pr | 0.0.2 | 2026-05-25 |
| lc-feat-document-release | 0.0.4 | 2026-05-25 |
| lc-feat-api-sync | 0.0.2 | 2026-05-25 |

---

## 更新记录

### 2026-06-29 — E2E 双驱动模式 + 用例分流

**lc-feat-e2e** v0.0.4：从「仅需求+设计驱动」扩展为双驱动模式
- **模式 A — 需求+设计驱动**：`docs/pipeline/{feat}/requirement.md` + `design.md`（流水线默认，行为不变）
- **模式 B — 现有文档驱动**：从项目已有文档生成，**不依赖流水线**——支持显式 `doc-path` 参数、自动发现 `docs/**/*测试要点*.md` 与模块文档
- 输入扩展：`/lc-feat:e2e <feat-name> [doc-path]`，Step 2 改为按优先级自动判定模式与文档来源
- 新增 **用例分流**（Step 3.0）：每条用例打标 ✅可E2E / 🔒需登录 / 🧩需mock / ⬜不可E2E，只生成可自动化的，其余记入报告，避免把白盒断言硬写成脆弱用例
- 报告模板新增「驱动模式 / 文档来源 / 用例分流」小节
- 「测试要点」式用例表（操作/预期结果列）作为模式 B 最优来源，逐条直接映射为 `test()`
- 同步更新 `lc-feat-pipeline-guide.md` §4.5
- `lc-feat-e2e-guide.md` 升 **v2.1**：从绑定 kejinshou_m 抽离为**项目无关、独立可用**版——核心（环境/配置/编写/排错）只依赖 Playwright，lc-feat 集成收敛为可选 §十五；新增配置矩阵；修正 h5-nuxt 端口 9158/`pnpm start:dev`；修正过时的「第7步/共8步」

### 2026-05-29 — 流水线精简（design-review 合并 + lint/test/qa 合并）

**lc-feat-design** v0.0.3：design-review 合并到 design 中
- 设计自审（5 维度）作为设计步骤的一部分，生成后立即执行
- 不再单独生成 `design-review.md`，自审修订记录写入 `design.md`
- 删除 `lc-feat-design-review` skill

**lc-feat-verify** v0.0.1：lint + test + qa 合并为统一验证步骤
- 三阶段验证：静态检查（Lint）→ 单元测试（Test）→ 综合质量分析（QA）
- 输出统一的 `verify-report.md`（含三个章节），替代原来的 `lint-report.md` + `test-report.md` + `qa-report.md`
- 删除 `lc-feat-lint`、`lc-feat-test`、`lc-feat-qa` 三个 skill

**lc-feat-pipeline** v0.0.5：流水线从 8 步精简到 5 步
- Full 模式：requirement → design → implement → verify → e2e（5 步）
- Lite 模式：requirement → implement → verify（3 步）
- 更新 progress.yaml 模板、示例、交互提示

### 2026-05-25 — qa v0.0.3

**lc-feat-qa** 新增第 6 维度「变更影响分析」：

- 参考 `lc-branch-impact-analysis` 和 `lc-commit-impact-analysis` 的分析手法
- 新增 4.6 变更影响分析（回归安全性）：Bug 模式检测（8 patterns）、删除/重命名 grep 验证、行为变更检测、配置影响评估
- QA 报告模板增加「变更影响分析」section 和评分维度（5 → 6）
- pipeline-guide 同步更新为六维度评审

### 2026-05-25 — e2e v0.0.3

**lc-feat-e2e** 环境检测与截图策略优化：

- 简化 Step 1 环境检测：3 条 bash → `npx playwright test --list` 一步验证
- 删除 Step 1.1 手动 dev server 检测（`playwright.config.ts` 的 `webServer` 已覆盖）
- 修正 screenshotDir 路径：`../results/screenshots/{feat-name}`（之前 `../../..` 层级有误）
- `playwright.config.ts` 的 `screenshot` 从 `only-on-failure` 改为 `off`，由测试代码手动控制截图
- 补充 `tests/e2e/.gitignore`（忽略 node_modules/results/report）
- pipeline-guide 补充 4.7 E2E 详细描述段落和 walkthrough Step 8

### 2026-05-25 — document-release v0.0.4

**lc-feat-document-release** 从 post-ship 重命名并重写：

- 核心职责变更：从"收尾检查"改为"增量更新项目功能文档"
- 产出目标：`docs/kjs-main-h5-vue/modules/{module}.md` 按模块持续增长
- 新增独立调用模式：`/lc-feat:document-release --module=goods`
- 合并重复 CLAUDE.md 步骤，移除 pipeline-status.md
- PR 搜索改用当前分支，Memory 仅写 feedback 类型
- 所有关联文档中 `post-ship` 引用替���为 `document-release`

### 2026-05-25 — test v0.0.3 + pipeline v0.0.3

**lc-feat-test** 测试策略聚焦：

- 移除组件测试模板和描述（与 "不测组件" 顶层规则矛盾）
- Step 3.2 改为仅测核心函数（纯函数/工具函数）
- Step 4.1 模板替换为 `formatPrice`/`getStatusLabel` 纯函数示例

**lc-feat-pipeline** 全自动模式：

- 新增 `--auto` 参数支持无确认连续执行

### 2026-05-25 — 全量 v0.0.2 升级

**共享文档抽取：**

- 新建 `lc-feat-coding-standard-loading.md`，5 个 skill 共用的编码规范加载逻辑
- design / design-review / qa 简化为引用共享文档

**各 skill 改动：**

- **e2e**：新增 pipeline 降级策略（环境不就绪时自动 skipped）
- **implement**：阻断性规范加载
- **lint**：安全修复白名单
- **pr**：CR 分阶段 + 自动修复白名单
- **api-sync**：项目类型检测

**pipeline-guide v1.3：**

- 修复 section 3 编号（3.1→3.4 → 顺序 3.1-3.4）
- 修正 skill 数量 11→12，section 4 标题改为"8步"
- 更新测试示例（14 组件测试 → 8 核心函数测试）

### 2026-04-15 — v0.0.1 初始版本

- P1：步骤间自动状态感知
- P2：跨会话恢复（progress.yaml）
- P3：产出物结构化依赖
- P4：质���门控（lint 阻塞 + design-review 阻塞）
- P5���学习和反馈积��（decisions + Memory 写入）
- Preamble：每��执行前上下文注入

---

## 版本规划

| 版本 | 状��� | 说明 |
|---|---|---|
| **0.0.x** | 当前 | 预发��验证，实际���目中跑通全流程 |
| **1.0.0** | 待定 | 确认无问题后正���发布 |
