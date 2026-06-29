# Claude Code Skills 清单

> 全局安装目录：`~/.claude/skills/`
> 最近更新：2026-05-29

---

## lc-feat 功能开发流水线

端到端的功能开发流水线，10 个 skill 覆盖从需求分析到发布文档的完整生命周期。

> 详细使用指南：[lc-feat-pipeline-guide.md](docs/lc-feat-pipeline-guide.md) (v1.5)
> 
> E2E 测试指南（项目无关、独立可用，lc-feat 集成为可选）：[lc-feat-e2e-guide.md](docs/lc-feat-e2e-guide.md) (v2.1)
> 
> 更新日志：[lc-feat-changelog.md](docs/lc-feat-changelog.md)
> 
> 共享规范加载流程：[lc-feat-coding-standard-loading.md](docs/lc-feat-coding-standard-loading.md)

### 主流程（5 步）

| 序号 | Skill | 版本 | 命令 | 说明 |
|------|-------|------|------|------|
| 1 | [lc-feat-requirement](lc-feat-requirement/SKILL.md) | 0.0.2 | `/lc-feat:requirement` | 需求分析，文字/截图/文档转结构化需求文档 |
| 2 | [lc-feat-design](lc-feat-design/SKILL.md) | 0.0.3 | `/lc-feat:design` | 技术设计（含自审），生成组件/路由/Service/权限设计文档 |
| 3 | [lc-feat-implement](lc-feat-implement/SKILL.md) | 0.0.2 | `/lc-feat:implement` | 编码实现，按项目规范生成代码 |
| 4 | [lc-feat-verify](lc-feat-verify/SKILL.md) | 0.0.1 | `/lc-feat:verify` | 代码验证（Lint + Test + QA 三阶段合并） |
| 5 | [lc-feat-e2e](lc-feat-e2e/SKILL.md) | 0.0.4 | `/lc-feat:e2e` | E2E 测试，双驱动（需求+设计 / 现有文档），Playwright 浏览器验证 + 截图 |

### 独立步骤

| Skill | 版本 | 命令 | 说明 |
|-------|------|------|------|
| [lc-feat-pr](lc-feat-pr/SKILL.md) | 0.0.2 | `/lc-feat:pr` | Code Review + PR 创建（流水线外独立执行） |

### 辅助流程

| Skill | 版本 | 命令 | 说明 |
|-------|------|------|------|
| [lc-feat-document-release](lc-feat-document-release/SKILL.md) | 0.0.4 | `/lc-feat:document-release` | 发布后文档处理，增量更新项目功能文档 + 归档 |
| [lc-feat-api-sync](lc-feat-api-sync/SKILL.md) | 0.0.2 | `/lc-feat:api-sync` | 接口同步，Apifox 真实接口替换 mock |

### 总控

| Skill | 版本 | 命令 | 说明 |
|-------|------|------|------|
| [lc-feat-pipeline](lc-feat-pipeline/SKILL.md) | 0.0.5 | `/lc-feat:pipeline` | 一键串联 1-5 步，支持 `--from` 断点恢复、`--auto` 全自动 |

---

## lc-kejinshou 项目编码规范

各项目的编码规范 skill，编码阶段由 pipeline 自动加载。

| Skill | 版本 | 说明 |
|-------|------|------|
| [lc-kejinshou-h5-vue](lc-kejinshou-h5-vue/SKILL.md) | 1.1 | kejinshou_m H5 移动端规范（Vue 3 + Vant + Composition API） |
| [lc-kejinshou-h5-nuxt](lc-kejinshou-h5-nuxt/SKILL.md) | 2.0 | h5-nuxt 项目规范 |
| [lc-backend-page](lc-backend-page/SKILL.md) | - | backend-kejinshou 后台页面生成（KR36 + CRUD） |
| [lc-kejinshou-android](lc-kejinshou-android/SKILL.md) | 1.0 | kejinshou_android 原生项目规范 |
| [lc-kr36-ui-guide](lc-kr36-ui-guide/skill.md) | - | kr36-ui 组件库 API 参考（KrForm/KrTable/KrDialog） |

---

## lc-* 辅助工具

代码质量、分支管理、适配检测等独立工具。

| Skill | 命令 | 说明 |
|-------|------|------|
| [lc-branch-impact-analysis](lc-branch-impact-analysis/SKILL.md) | `/lc-branch-impact-analysis` | 分析当前分支与目标分支的代码差异，评估影响面 |
| [lc-branch-ui-fix](lc-branch-ui-fix/SKILL.md) | `/lc-branch-ui-fix` | 对比 master 检测并修复 UI 样式回归 |
| [lc-commit-check](lc-commit-check/SKILL.md) | `/lc-commit-check` | 提交前代码质量检查（Lint + Style + Types） |
| [lc-commit-impact-analysis](lc-commit-impact-analysis/SKILL.md) | `/lc-commit-impact-analysis` | 分析代码改动的逻辑影响和潜在 bug |
| [lc-mobile-pc-adaptive](lc-mobile-pc-adaptive/SKILL.md) | `/lc-mobile-pc-adaptive` | 检测并修复 H5 页面在 PC 屏幕上的布局问题 |
| [lc-html-css-seo-optimizer](lc-html-css-seo-optimizer/SKILL.md) | `/lc-html-css-seo-optimizer` | HTML/CSS SEO 优化，简化结构减少嵌套 |

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
