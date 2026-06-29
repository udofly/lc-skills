---
name: lc-feat-document-release
description: 发布后文档处理技能。PR合并后将功能信息增量补充到项目文档中，逐步构建完整的项目功能手册。同时执行CLAUDE.md同步、pipeline归档、分支清理等收尾。当用户说"发布完了"、"PR合并了"、"更新文档"、"收尾"时触发。
license: MIT
metadata:
  author: kejinshou-team
  version: "0.0.5"
  pipeline_guide: "~/.claude/skills/docs/lc-feat-pipeline-guide.md"
---

# 发布后文档处理

PR 合并后的核心任务：**将本次功能的详细信息增量补充到项目功能文档中**，逐步构建完整的业务功能手册。附带 CLAUDE.md 同步、产物归档等收尾工作。

---

**Input**: `/lc-feat:document-release <feat-name>`

**Steps**

1. **确认发布状态**

   优先用当前分支查找 PR：
   ```bash
   gh pr list --head "$(git branch --show-current)" --state merged
   ```
   备选：`gh pr list --search "{feat-name}" --state merged`

   如果未找到已合并 PR：使用 **AskUserQuestion** 确认后继续，不阻塞。

2. **【核心】增量更新项目功能文档**

   这是本 skill 的核心步骤——把本次功能的业务说明写入项目文档，使文档随迭代逐步完善。

   ### 2.1 确定文档约定（**从项目自己的技能读取，不要内置某项目的路径**）

   本 skill 通用于所有项目，**绝不硬编码某个项目的文档路径/结构**。按以下顺序确定本次该怎么写文档：

   1. 读取项目 `.claude/CLAUDE.md`，找到它引用的**项目编码规范技能**（如 `lc-kejinshou-h5-vue` / `lc-kejinshou-h5-nuxt` / `lc-backend-page` / `lc-kejinshou-android`）。
   2. 读取该技能里的 **「文档维护约定」** 章节，获取：文档根目录、业务文档结构、页面文档模板、命名规则、侧边栏文件、更新规则、校验命令。
   3. **严格按该约定执行**后续 2.2 / 2.3 的写入（路径、结构、模板、命名全部以项目技能为准）。

   **回退**：若项目无此类技能、或该技能未声明「文档维护约定」→ 退化为通用结构 `docs/features/{module}.md`，并提示用户在项目技能里补充「文档维护约定」以获得更好的结构化文档。

   ### 2.2 确定本次功能所属模块

   从 `docs/pipeline/{feat-name}/requirement.md` 或改动文件路径中提取模块名：
   - `src/views/goods/` → 模块名：`goods`（商品模块）
   - `src/views/order/` → 模块名：`order`（订单模块）
   - 跨模块改动 → 归入主要改动所在模块

   ### 2.3 按项目约定写入文档

   **完全遵循 2.1 读到的项目「文档维护约定」**：用它声明的文档路径、目录结构、页面模板、命名规则写入。常见两种结构：

   **A. 结构化项目**（约定了 1:1 镜像 `src/views`、按页面拆分等）：
   - 按约定的模板（如项目的 `_TEMPLATE.md`）和命名规则写到对应路径（如 `modules/<view目录>/<PageName>.md`）。
   - 按约定的「更新规则」分流：
     - **新增页面** → 按模板新建页面文档 + 更新该模块 `index.md` 页面清单 + 挂进约定的侧边栏文件。
     - **改已有页面** → Edit 对应页面文档的相关字段（接口/交互/跳转/坑），不重写整篇。
     - **改子组件** → 改所属页面文档的「组件依赖」段。
   - **以项目约定为准，不要套用本 skill 内置的任何模板。**

   **B. 回退项目**（无项目约定，2.1 退化）：写到 `docs/features/{module}.md`，用下方通用模板：

   ```markdown
   # {模块中文名}模块

   ## 模块概述
   {模块的整体业务定位，一句话说明}

   ## 页面清单
   | 页面 | 路由 | 说明 |
   |------|------|------|

   ## 功能详情

   ### {功能名称}
   - **版本**: {分支名/PR号}　**日期**: {YYYY-MM-DD}
   - **入口**: {用户如何到达此功能}
   - **核心流程**: 1) … 2) …
   - **关键组件** / **接口依赖** / **业务规则**: …
   ```

   ### 2.4 内容来源（两种结构通用）

   - 从 `requirement.md` 提取：用户操作流程、业务规则
   - 从 `design.md` 提取：涉及组件、接口依赖
   - 从代码实际实现中补充：路由路径、关键配置、坑
   - **不写代码细节**，只写业务层面的"做什么"和"怎么用"
   - 同步更新页面/模块清单（如有新页面）

   ### 2.5 更新文档索引 + 校验

   - 若项目约定了侧边栏文件（如 VitePress sidebar），把新页面/模块挂进去。
   - 若项目约定了校验命令（如 `pnpm docs:build`），**收尾跑一次**，确保无编译错误/死链；失败则修复后再交付。

3. **更新 CLAUDE.md（如需要）**

   仅当本次变更属于"新增模块级别"时更新：
   - 新增业务模块 → 追加到模块列表
   - 新增公共组件/工具函数 → 追加到对应说明
   - 小功能扩展/Bug 修复 → 不更新

4. **归档 pipeline 产物**

   更新 `docs/pipeline/{feat-name}/progress.yaml`：
   - 所有步骤标记为 `done`
   - 追加 `shipped` 字段：

   ```yaml
   shipped:
     date: "YYYY-MM-DD HH:mm"
     pr_url: "{PR URL}"
     branch: "{分支名}"
   ```

5. **扫描 mock 标记**

   ```bash
   grep -rn "TODO: 替换为真实接口" {功能相关文件}
   ```

   如有未替换 mock → 提醒使用 `/lc-feat:api-sync {feat-name}`

6. **写入 Memory（仅非显而易见的决策）**

   从 `progress.yaml.decisions` 筛选，只写 **feedback 类型**：
   - 用户的技术偏好、被否决的方案、项目级约定
   - 不写功能完成日期、文件路径等可从 git/代码查到的信息

7. **分支清理提醒 + 输出总结**

   输出：
   - 文档更新情况（更新了哪个模块文档、追加了什么内容）
   - Mock 标记情况
   - 分支清理建议（不自动执行）

---

## 独立使用：补写历史功能文档

除了在 pipeline 结束后使用，也可以**独立调用**来补写已有功能的文档：

```bash
# 为已有的 goods 模块补写文档
/lc-feat:document-release goods-bargain

# 直接指定模块名补写（不需要 pipeline 产物）
/lc-feat:document-release --module=goods
```

**独立模式流程**：
1. 跳过 PR 确认和 pipeline 归档
2. 直接读取指定模块的代码（`src/views/{module}/`）
3. 分析路由、组件、接口调用，生成功能文档
4. 写入对应模块文档

> 这个模式适合逐步梳理项目中已有但未文档化的功能。

---

**Guardrails**
- **文档结构以项目技能「文档维护约定」为准**：不要内置/套用本 skill 的路径或模板；结构化项目按其约定（如 1:1 镜像 `src/views`、按页面拆分）写入，只有回退项目才用通用 `docs/features/` 结构。
- **文档内容只写业务层面**：写"做什么"和"怎么用"，不写代码实现细节
- 追加内容使用 Edit tool，不覆盖已有文档内容
- CLAUDE.md 只添加模块级新增信息
- Mock 标记只提醒不替换
- 分支清理只提醒不执行
- Memory 只写 feedback 类型
- 如果模块文档已有同名功能条目，更新而非重复追加
