---

name: "commit-check"

description: "提交前运行代码质量检查（Lint, Style, Types）。当用户想要提交代码或检查错误时调用。"

---


# 代码提交检查 (Commit Code Check)


此 Skill 运行项目的标准代码质量检查，以确保代码库准备好进行提交。


## 功能

- **代码规范检查 (Linting)**: 运行 ESLint 以捕获代码错误和样式违规。

- **样式检查 (Style Checks)**: 运行 Stylelint 检查 CSS/SCSS/Vue 样式。

- **类型检查 (Type Checking)**: 运行 `vue-tsc` 以确保 TypeScript 类型安全。


## 使用方法

按顺序运行以下命令。如果任何命令失败，请停止并向用户报告错误。


1. **Lint 检查**

   ```bash

   npm run lint

   ```


2. **样式检查**

   ```bash

   npm run stylelint

   ```


3. **类型检查**

   ```bash

   npx vue-tsc --noEmit

   ```


## 自动修复

## 如果发现 Lint 或样式错误，你可以尝试使用以下命令自动修复：

## - `npm run lint:fix`

## - `npm run stylelint:fix`


## 交互指南

- **用中文报告结果**。

- 始终在生成提交信息 (commit message) 之前运行这些检查。

- 如果自动修复后错误仍然存在，请帮助用户手动解决。
