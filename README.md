# Claude Code Skills 清单

> 全局安装目录：`~/.claude/skills/`
> 最近更新：2026-07-15

---

## fe-workflow 前端功能开发流水线

单一 skill 承载完整开发流程，每步产出可追溯文档，全程零 git 操作：

```
需求描述 → ①需求分析 → ②技术设计(含自审) → ③编码 → ④验证 → ⑤E2E → 完成
            写 spec     ★人工审核(唯一必停)   规范强制   Lint/Test   浏览器执行
                                              前置加载   QA+CR(独立   +截图
                                                        子代理)★有问题才停
```

**核心特性**：按分支归档、一条流水线容纳多个功能（files_changed 按功能隔离）｜昼夜工作流（`--until=design` 白天出设计 + `--start` 晚上批量执行 + 早上按报告逐功能 commit）｜full/lite 双模式｜验证内置 CR（独立子代理，编码与审查隔离）｜编码前强制加载项目规范 skill（全自动也不豁免）｜progress.yaml 断点恢复 + 多功能看板。

> 完整介绍（流程详解 / 典型一天 / 命令速查）：[fe-workflow/README.md](fe-workflow/README.md)
> 执行规则单一事实源：[fe-workflow/SKILL.md](fe-workflow/SKILL.md) + references/
> 新项目 E2E 接入（安装 + config 模板）：[references/e2e-setup.md](fe-workflow/references/e2e-setup.md)
> 文档时间同步指南（lc-doc-sync + 更新账本约定）：[lc-doc-sync-guide.md](docs/lc-doc-sync-guide.md) (v1.1)

| 入口 | 命令 | 说明 |
|------|------|------|
| 流水线 | `/fe-workflow [需求描述]` | 新功能/追加功能/看板恢复自动分流；`--until` `--start` `--auto` `--mode=lite` `--feat` `--from` |
| 独立验证 | `/fe-workflow verify` | 验证当前分支改动，不依赖流水线（git diff 兜底） |
| 独立 E2E | `/fe-workflow e2e [doc-path] [--yunxiao <ID>]` | 存量页面按文档/云效用例直接跑 |
| 接口同步 | `/fe-workflow api-sync` | Apifox 真实接口替换 mock |
| 发布收尾 | `/fe-workflow release` | 增量更新项目功能文档 + 打戳记账 + 归档 + 漏网检查 |
| 提交出口 | `/fe-workflow pr` | 提交前汇总 + 按功能 commit 引导 + 建 PR（git 操作逐步确认） |
| 文档兜底 | [`/lc-doc-sync`](lc-doc-sync/SKILL.md) | 按账本锚点时间粒度补文档，捕捉绕过流水线的变更（`--since` / `--scan` / `--check`） |

### 📦 lc-feat 系列已归档（2026-07-15）

原 lc-feat 九件套（requirement/design/implement/verify/e2e/pr/api-sync/document-release/pipeline）及 4 份配套指南已被 fe-workflow 完全取代，归档于 `~/Desktop/lc-feat-archive-20260715/`（历史版本也可从本仓库 git 记录找回）。

---

## lc-kejinshou 项目编码规范

各项目的编码规范 skill，编码阶段由 fe-workflow 自动加载。

| Skill | 版本 | 说明 |
|-------|------|------|
| [lc-kejinshou-h5-vue](lc-kejinshou-h5-vue/SKILL.md) | 1.6 | kejinshou_m H5 移动端规范（Vue 3 + Vant + Composition API），§16 含文档维护约定（账本/时间戳/temp 区） |
| [lc-kejinshou-h5-nuxt](lc-kejinshou-h5-nuxt/SKILL.md) | 2.1 | h5-nuxt 项目规范（含 SSR/SEO、composables 索引） |
| [lc-backend-page](lc-backend-page/SKILL.md) | - | backend-kejinshou 后台页面生成（KR36 + CRUD） |
| [lc-kejinshou-android](lc-kejinshou-android/SKILL.md) | 1.0 | kejinshou_android 原生项目规范 |
| [lc-kr36-ui-guide](lc-kr36-ui-guide/SKILL.md) | - | kr36-ui 组件库 API 参考（KrForm/KrTable/KrDialog） |

---

## lc-* 辅助工具

代码质量、分支管理、适配检测等独立工具。

| Skill | 命令 | 说明 |
|-------|------|------|
| [lc-checkpoint](lc-checkpoint/README.md) | `保存进度` / `恢复进度` / `列出检查点` | 保存/恢复会话工作状态，按分支隔离，7 天自动清理 |
| [lc-branch-impact-analysis](lc-branch-impact-analysis/SKILL.md) | `/lc-branch-impact-analysis` | 分析当前分支与目标分支的代码差异，评估影响面 |
| [lc-branch-ui-fix](lc-branch-ui-fix/SKILL.md) | `/lc-branch-ui-fix` | 对比 master 检测并修复 UI 样式回归 |
| [lc-commit-check](lc-commit-check/SKILL.md) | `/lc-commit-check` | 提交前代码质量检查（Lint + Style + Types） |
| [lc-commit-impact-analysis](lc-commit-impact-analysis/SKILL.md) | `/lc-commit-impact-analysis` | 分析代码改动的逻辑影响和潜在 bug |
| [lc-mobile-pc-adaptive](lc-mobile-pc-adaptive/SKILL.md) | `/lc-mobile-pc-adaptive` | 检测并修复 H5 页面在 PC 屏幕上的布局问题 |
| [lc-html-css-seo-optimizer](lc-html-css-seo-optimizer/SKILL.md) | `/lc-html-css-seo-optimizer` | HTML/CSS SEO 优化，简化结构减少嵌套 |
| [lc-seo-page-rewrite](lc-seo-page-rewrite/SKILL.md) | `seo改写` + 路由 | kejinshou_m 页面迁移到 h5-nuxt（SSR + TDK + SEO），内部走 fe-workflow 流水线 |
| [lc-mp-taobao](lc-mp-taobao/SKILL.md) | 在 tb-account-center 项目内自动触发 | 淘宝小程序编码规范与脚手架 |
| [lc-skill-sync](lc-skill-sync/README.md) | `同步公司skill` | 本地 skill 单向同步到公司 agent-skills 仓库（--check / 默认同步 / --pr） |

---

## 第三方 / 社区 Skills

### GStack 浏览器测试套件

| Skill | 说明 |
|-------|------|
| [gstack](gstack/SKILL.md) (v1.1.0) | 无头浏览器 QA 测试，页面导航、交互验证、截图对比 |

GStack 内置子 skill（`/qa`、`/browse`、`/ship`、`/review`、`/document-release` 等）详见 [gstack/CLAUDE.md](gstack/CLAUDE.md)。

### Vue 生态 Skills

| Skill | 说明 |
|-------|------|
| [vue-best-practices](vue-best-practices/SKILL.md) | Vue.js 最佳实践，推荐 Composition API + `<script setup>` |
| [vue-debug-guides](vue-debug-guides/SKILL.md) | Vue 3 调试与错误处理指南 |
| [vue-development-guides](vue-development-guides/SKILL.md) | Vue.js 开发技巧集合 |
| [vue-jsx-best-practices](vue-jsx-best-practices/SKILL.md) | Vue JSX 语法规范 |
| [vue-options-api-best-practices](vue-options-api-best-practices/SKILL.md) | Vue 3 Options API 风格指南 |
| [vue-pinia-best-practices](vue-pinia-best-practices/SKILL.md) | Pinia 状态管理模式 |
| [vue-router-best-practices](vue-router-best-practices/SKILL.md) | Vue Router 4 路由模式与导航守卫 |
| [vue-testing-best-practices](vue-testing-best-practices/SKILL.md) | Vitest + Vue Test Utils + Playwright 测试指南 |
| [create-adaptable-composable](create-adaptable-composable/SKILL.md) | 创建库级别的 Vue composable |

### 通用工具 Skills

| Skill | 说明 |
|-------|------|
| [skill-creator](skill-creator/SKILL.md) | 创建、修改、评估 skill |
| [find-skills](find-skills/SKILL.md) | 发现和安装社区 skill |
