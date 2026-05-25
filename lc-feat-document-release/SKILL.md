---
name: lc-feat-document-release
description: 发布后文档处理技能。PR合并后将功能信息增量补充到项目文档中，逐步构建完整的项目功能手册。同时执行CLAUDE.md同步、pipeline归档、分支清理等收尾。当用户说"发布完了"、"PR合并了"、"更新文档"、"收尾"时触发。
license: MIT
metadata:
  author: kejinshou-team
  version: "0.0.4"
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

   ### 2.1 确定文档位置

   检查项目文档目录结构：
   - 如果有 `docs/kjs-main-h5-vue/` → VitePress 文档，在此目录下维护
   - 如果有 `docs/` 但无子结构 → 使用 `docs/features/` 目录
   - 如果无 `docs/` → 创建 `docs/features/`

   ### 2.2 确定本次功能所属模块

   从 `docs/pipeline/{feat-name}/requirement.md` 或改动文件路径中提取模块名：
   - `src/views/goods/` → 模块名：`goods`（商品模块）
   - `src/views/order/` → 模块名：`order`（订单模块）
   - 跨模块改动 → 归入主要改动所在模块

   ### 2.3 更新或创建模块文档

   **文档文件**：`docs/kjs-main-h5-vue/modules/{module}.md`（或项目的对应文档路径）

   **如果模块文档已存在**：在对应模块文档中追加本次功能的条目。

   **如果模块文档不存在**：创建新文档，使用以下模板：

   ```markdown
   # {模块中文名}模块

   ## 模块概述
   {模块的整体业务定位，一句话说明}

   ## 页面清单
   | 页面 | 路由 | 说明 |
   |------|------|------|
   | {页面名} | {路由路径} | {功能说明} |

   ## 功能详情

   ### {功能名称}
   - **版本**: {分支名/PR号}
   - **日期**: {YYYY-MM-DD}
   - **入口**: {用户如何到达此功能}
   - **核心流程**:
     1. {步骤1}
     2. {步骤2}
   - **关键组件**: {涉及的核心组件列表}
   - **接口依赖**: {调用的核心接口}
   - **业务规则**:
     - {规则1}
     - {规则2}

   ## 数据流
   {模块内的数据流向说明，如需要}

   ## 配置与常量
   | 常量/枚举 | 位置 | 用途 |
   |----------|------|------|
   ```

   ### 2.4 追加功能条目的规则

   每次追加一个功能条目时：
   - 在对应模块文档的"功能详情"章节下追加一个 `###` 级别的小节
   - 从 `requirement.md` 提取：用户操作流程、业务规则
   - 从 `design.md` 提取：涉及组件、接口依赖
   - 从代码实际实现中补充：路由路径、关键配置
   - **不写代码细节**，只写业务层面的"做什么"和"怎么用"
   - 页面清单表格也同步更新（如有新页面）

   ### 2.5 更新文档索引（如有）

   如果项目使用 VitePress 且有 sidebar 配置，将新模块文档添加到导航中。

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
- **文档内容只写业务层面**：写"做什么"和"怎么用"，不写代码实现细节
- 功能文档按模块组织，一个模块一个文件，不要一个功能一个文件
- 追加内容使用 Edit tool，不覆盖已有文档内容
- CLAUDE.md 只添加模块级新增信息
- Mock 标记只提醒不替换
- 分支清理只提醒不执行
- Memory 只写 feedback 类型
- 如果模块文档已有同名功能条目，更新而非重复追加
