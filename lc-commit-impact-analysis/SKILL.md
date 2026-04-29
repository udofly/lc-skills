---
name: "commit-impact-analysis"
description: "Analyzes code changes for logic, bugs, and behavioral impact. ALWAYS use this skill when the user asks to analyze uncommitted changes, says things like '分析未提交' / '分析一下' / '有没有问题' / '对逻辑有啥影响' / '重新分析' / '看看这些改了什么' / '影响范围' / '未提交的内容', or is about to commit code. Also trigger on any git diff analysis request."
---

# Commit Impact Analysis Skill

## 触发场景
- 用户准备提交代码（commit、提交、准备提交）
- 用户说"分析一下"、"重新分析"、"有没有问题"、"对原来逻辑有啥影响"
- 用户询问变更范围、影响点、潜在风险
- 用户说"分析未提交"
- 用户查看未提交内容（未提交、未暂存、staged、unstaged）

## 执行步骤

### 1. 获取变更范围

同时获取两类变更，明确区分：

```bash
# 已暂存（将进入下次提交）
git diff --cached --name-only
git diff --cached

# 所有未提交变更（含未暂存）
git diff HEAD --name-only
git diff HEAD
```

- 若 staged 和 unstaged 都有内容，分别分析
- 若暂存区为空，分析全部未提交变更
- 在报告开头标注两类变更的文件数量

### 2. 分析修改逻辑

- 识别文件、函数、组件、类的变化
- 中文描述修改意图（"将 X 替换为 Y"、"删除了 Z 功能"）
- 对删除代码特别关注：标记被删除的公共函数/接口/类

### 3. Bug 检测（主动扫描）

在 diff 中识别以下常见 Bug 模式，标记为 🔴：

| 模式 | 说明 |
|---|---|
| **属性当函数调用** | boolean 属性后加 `()` 会导致永远 truthy |
| **未使用的导入** | import 了某符号，但代码中从未使用 |
| **使用但未导入** | 代码中出现了未 import/未声明的符号 |
| **参数签名不匹配** | 函数去掉了参数，但调用处仍然传参（或反之） |
| **方法名改变后旧调用未同步** | 旧函数被删/改名，仍有地方调用旧名 |
| **API 返回值解构变更** | 返回结构从 `{ data: Ref }` 变为 `Promise<T>` 等，调用方解构方式未同步 |
| **临时代码残留** | `// todo`、`// hack`、未说明原因的 `return;` 跳过逻辑、被注释掉的整块代码 |
| **框架上下文问题** | composable/hook 在错误的生命周期或作用域中调用（如模块顶层 vs 函数内部） |
| **类型不匹配** | 变更后参数类型、返回类型与调用方期望不一致 |

### 4. 删除/重命名验证（主动 grep）

**当 diff 中有函数、组件、类、变量被删除或重命名时，必须执行：**

```bash
# 对每个被删除/重命名的公共符号，grep 全局确认无残留调用
grep -rn '符号名' --include='*.vue' --include='*.ts' --include='*.js' --include='*.kt' --include='*.java' --include='*.xml' | grep -v node_modules | grep -v .nuxt | grep -v dist | grep -v build/
```

- grep 结果不为空 → 🔴 Bug（残留引用将导致编译/运行时报错）
- 对 import 路径变更，确认新路径文件存在
- 对组件/类重命名，确认所有引用点已同步

### 5. 配置文件变更检测

当变更涉及以下类型文件时，需单独分析其全局影响：

**前端项目：**
- 构建配置（`nuxt.config.ts`、`vite.config.ts`、`webpack.config.js` 等）
- 路由配置（`router.options.ts`、路由定义文件）
- 环境变量（`.env.*`）
- 包管理（`package.json`、`pnpm-lock.yaml`）
- 样式配置（`tailwind.config.js`、`postcss.config.js`）
- TypeScript 配置（`tsconfig.json`）

**Android 项目：**
- `build.gradle` / `build.gradle.kts`
- `AndroidManifest.xml`
- `proguard-rules.pro`
- `gradle.properties`

关注点：viewport/meta 变更、编译选项、依赖版本、代理配置、权限声明等。

### 6. 行为变更检测（主动扫描）

识别可能改变运行时行为的修改，标记为 🟡：

| 类型 | 说明 |
|---|---|
| **条件判断被移除/新增** | 某个 `if` 条件被去掉或增加，改变了代码执行路径 |
| **函数语义变更** | 函数名不变但内部逻辑改变（如判断范围收窄/扩大），需对比新旧实现列出行为差异 |
| **接口签名变更** | 参数增减、类型变更，调用方可能受影响 |
| **功能完全删除** | 某公共函数/模块/Activity 被移除，需确认无调用方 |
| **执行环境变更** | 原本仅在特定环境执行（客户端/服务端/特定线程），现在执行环境改变 |
| **API 调用方式变更** | 同步改异步、返回类型变更、请求方式变更 |
| **默认值变更** | 参数默认值改变可能影响未显式传参的调用方 |

### 7. 过滤无风险项

以下变更直接跳过，不纳入行为变更或风险汇总：
- `package.json` 中仅 `version` 字段变更

### 8. 兼容性与风险评估

- 检查公共接口、Props/参数、导出函数/类的变化
- 评估修改范围（公共模块 vs 私有模块）
- 风险等级判定：
  - 🔴 **高**：影响公共接口/组件，可能破坏下游功能，或存在明确 Bug
  - 🟡 **中**：行为发生变化，需要确认是否有意为之
  - 🟢 **低**：局部私有逻辑修改，风险极小

## 输出报告（中文）

```markdown
## 📊 变更范围
- 已暂存（staged）：X 个文件
- 未暂存（unstaged）：Y 个文件

## 🔴 Bug（需修复）
- `文件路径:行号` — 具体问题描述

## 🟡 行为变更（需确认）
- `文件路径:行号` — 变更描述，新旧行为对比

## ⚙️ 配置变更
- `配置文件名` — 变更内容及全局影响

## ⚠️ 临时代码
- `文件路径:行号` — todo/hack 描述

## 📝 修改逻辑摘要
- **文件名**: 修改意图描述

## 📋 风险汇总

| 风险项 | 等级 | 文件 | 说明 |
|---|---|---|---|
| 具体风险 | 🔴/🟡/🟢 | 文件:行号 | 简要说明 |

## ✅ 建议
- 具体可操作的建议
```

报告应简洁，每条问题一行，包含文件名和行号（如能定位）。没有 Bug 或行为变更时，对应区块可省略。风险汇总表始终输出。
