---
name: lc-commit-check
description: 提交前运行代码质量检查（ESLint、Stylelint、TypeScript 类型检查）。当用户想要提交代码、说"检查一下代码"、"跑下 lint"、"提交前检查"，或即将生成 commit message 时调用。
---

# 代码提交检查 (Commit Code Check)

在提交前运行项目的标准质量检查，确保代码库处于可提交状态。用中文报告结果。

## 执行流程

先读 `package.json` 的 `scripts`，确认项目实际配置了哪些检查命令，再按下表选择——不要假设脚本一定存在：

| 检查项 | 优先使用 | 项目未配置时的降级方案 |
|-------|---------|---------------------|
| Lint | `npm run lint` | `npx eslint . --ext .js,.ts,.vue`；无 ESLint 配置文件则跳过并说明 |
| 样式 | `npm run stylelint` | `npx stylelint "**/*.{css,less,scss,vue}"`；无 Stylelint 配置文件则跳过并说明 |
| 类型 | `npm run typecheck` / `type-check` | Vue 项目 `npx vue-tsc --noEmit`；Nuxt 项目 `npx nuxi typecheck` |

按 Lint → 样式 → 类型 的顺序执行。某一项失败**不要立刻中止**，先把三项都跑完、汇总全部问题再统一处理，避免用户修一个才看到下一个。

## 错误处理

- **Lint / 样式错误**：先尝试自动修复（`npm run lint:fix` / `npm run stylelint:fix`，或对应 npx 命令加 `--fix`），修复后重跑对应检查确认通过。
- **类型错误**：无法自动修复，列出错误清单（`文件:行号` + 原因），协助用户逐个手动解决。
- 自动修复会改动工作区文件，修复完成后用 `git diff --stat` 向用户展示改动范围。

## 输出格式

```
📋 提交检查结果
✅ Lint：通过（自动修复 3 处）
✅ 样式：通过
❌ 类型：2 个错误
   - src/views/user.vue:45 类型 'string' 不能赋给 'number'
   - src/utils/format.ts:12 缺少返回值类型
```

## 交互指南

- 全部通过后才建议生成 commit message；存在未解决错误时明确告知不建议提交。
- 检查项被跳过（项目未配置）时在结果里注明，让用户知道覆盖范围。
