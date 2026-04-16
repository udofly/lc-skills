---
name: lc-feat-pr
description: Code Review 与 PR 创建技能。分析代码改动并输出 CR 报告；仅在用户明确要求时才执行 git commit/push/PR 创建。当用户说"CR"、"代码审查"、"review"时做 CR 分析；当用户说"创建PR"、"提交PR"时才执行 PR 操作。
license: MIT
metadata:
  author: kejinshou-team
  version: "0.0.2"
---

# Code Review & PR

分两个阶段：**CR 分析 + 安全自动修复**（默认）和 **PR 创建**（用户明确要求时执行）。

---

**Input**: `/lc-feat:pr <feat-name>`

## 阶段一：CR 分析（默认执行）

**Steps**

1. **加载上下文**

   读取：
   - `docs/pipeline/{feat-name}/requirement.md`
   - `docs/pipeline/{feat-name}/design.md`（如存在）
   - `docs/pipeline/{feat-name}/lint-report.md`（如存在，避免重复报告 lint 已处理的问题）
   - 所有功能相关的源代码改动文件（通过 `git diff --name-only master` 得到的文件列表，用 Read 工具读取）

2. **代码审查分析**

   逐文件阅读改动代码，从以下维度分析：

   ### 2.1 变更概览
   - 变更文件列表及改动类型（新增/修改）
   - 改动量评估

   ### 2.2 代码审查
   - 风格一致性：命名、格式、注释是否与项目现有模式一致
   - 类型安全：TypeScript 类型是否正确
   - 逻辑完整性：条件分支是否完整覆盖，错误处理是否到位
   - 项目规范：是否遵循 `.claude/CLAUDE.md` 和项目规范技能的约定

   ### 2.3 风险评估
   - 对现有功能的影响范围
   - 是否有破坏性变更
   - 遗漏检查：是否有应改但未改的关联文件

3. **CR 问题分类与自动修复**

   将发现的问题分为三类：

   ### A. 自动修复项（直接改，不阻塞）

   以下问题不影响逻辑，CR 过程中发现即用 Edit 工具直接修复：

   | 类型 | 示例 |
   |------|------|
   | 未使用的 import/变量 | lint 遗漏的，或 lint 后新产生的 |
   | TODO 注释格式不规范 | `// TODO 替换接口` → `// TODO: 替换为真实接口` |
   | 多余的 console.log | 新增代码中遗留的调试输出 |
   | 空的代码块 | `if (x) {}` 没有逻辑的空块 |
   | 明显的拼写错误 | 注释或字符串中的 typo（不改变量名） |

   > 与 lint skill 的安全修复互补：lint 侧重 ESLint 规则，CR 侧重语义层面的清理。

   ### B. 建议项（报告 + 建议，不自动改）

   涉及代码质量但不影响功能的问题：

   | 类型 | 示例 |
   |------|------|
   | 命名不够语义化 | `trans.flag` → 建议 `trans.isXxxEnabled` |
   | 可以简化的逻辑 | 三层 if-else 可用 map 替代 |
   | 缺少边界处理 | 没有 loading/error 状态展示 |
   | 硬编码的魔法数字 | `setTimeout(() => {}, 10000)` |

   ### C. 阻塞项（必须修复，由用户处理）

   涉及正确性或安全性的问题：

   | 类型 | 示例 |
   |------|------|
   | 逻辑错误 | 条件判断写反、遗漏 else 分支 |
   | 接口参数不匹配 | 调用参数与接口定义不一致 |
   | 安全风险 | XSS、SQL 注入、敏感信息暴露 |
   | 破坏性影响 | 改动可能影响其他模块但未同步 |

4. **输出 CR 报告**

   直接在对话中输出结构化报告：

   ```markdown
   ### CR 分析

   **变更文件：**
   | 文件 | 改动 |
   |------|------|

   **自动修复（已完成）：**
   | 文件 | 问题 | 修复 |
   |------|------|------|
   | {file:line} | 未使用的 import `xxx` | 已删除 |

   **建议项（不阻塞，可后续优化）：**
   | # | 文件 | 建议 |
   |---|------|------|

   **阻塞项（需手动修复）：**
   | # | 文件 | 问题 | 建议修复方式 |
   |---|------|------|-------------|

   **Review 结果：**
   | 维度 | 评分 | 说明 |
   |------|------|------|
   | 风格一致性 | A/B/C | |
   | 类型安全 | A/B/C | |
   | 逻辑完整性 | A/B/C | |
   | 项目规范 | A/B/C | |

   **风险评估：** {低/中/高}
   **建议 commit message：** `feat/fix(scope): description`
   ```

   ### 门控判定

   - **无阻塞项** → "CR 通过，可以提交。"
   - **有阻塞项** → "CR 发现 {N} 个阻塞问题需修复后再提交。"

   **CR 完成后停止，不自动进入 PR 阶段。**

---

## 阶段二：PR 创建（仅在用户明确说"创建PR"/"提交PR"时执行）

用户确认要创建 PR 后，执行以下操作：

1. 检查当前分支，确认不在 master/main 上
2. 暂存并提交变更（commit message 遵循 Angular 规范）
3. Push 到远程（**需用户确认**）
4. 使用 `gh pr create` 创建 PR，描述包含 Summary、Changes、Test Plan

**Guardrails**
- **CR 阶段的自动修复仅限 A 类（不影响逻辑的清理类问题）**
- **绝不自动修改条件判断、数据流、函数签名、业务逻辑**
- 自动修复后必须重新 ESLint 验证，确认没有引入新错误
- 如果 lint-report.md 已记录某问题，CR 不重复报告
- PR 阶段必须逐步确认：commit → push → create PR，每步需用户同意
- 不要 force push，不要 push 到 master/main
- commit message 遵循 Angular 规范：`feat/fix/chore(scope): description`
