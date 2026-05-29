---
name: lc-feat-design
description: 技术设计技能。根据需求文档生成技术设计文档，包括组件设计、路由配置、Service层设计、状态管理等。当用户说"出设计文档"、"技术设计"、"设计方案"时触发。
license: MIT
metadata:
  author: kejinshou-team
  version: "0.0.3"
  pipeline_guide: "~/.claude/skills/docs/lc-feat-pipeline-guide.md"
---

# 技术设计（含设计自审）

根据需求文档生成技术设计文档，包含组件结构、路由、Service 层、权限等完整设计。生成后自动执行设计自审，发现问题直接修订。

---

**Input**: `/lc-feat:design <feat-name>`，feat-name 对应 `docs/pipeline/{feat-name}/requirement.md`。

**Steps**

1. **读取需求文档**

   读取 `docs/pipeline/{feat-name}/requirement.md`，如果不存在则提示先执行 `/lc-feat:requirement`。

   检查需求类型：
   - 如果是"功能扩展/Bug修复/重构"且改动量极小，建议跳过设计直接实现
   - 如果是"新功能"或较大改动，继续设计流程

2. **加载项目编码规范**

   按 `~/.claude/skills/docs/lc-feat-coding-standard-loading.md` 流程加载项目编码规范，作为设计的技术标准。规范中的组件库、请求模式、路由模式等，优先级高于本技能的通用描述。

   并行检查以下内容以确保设计与项目风格一致：
   - 读取一个相似业务模块的页面文件
   - 读取对应的 service/request 文件
   - 读取路由配置文件

3. **尝试获取 API 接口**

   - 通过 Apifox MCP 工具获取相关接口（工具名从当前可用的 apifox MCP 工具列表中选取）
   - 如果获取到接口，记录到设计文档中
   - 如果未获取到，标注使用 mock 数据，并设计 mock 数据结构

4. **生成设计文档**

   在 `docs/pipeline/{feat-name}/` 下生成 `design.md`，根据项目类型使用对应模板：

   ```markdown
   # {功能名称} 技术设计文档

   ## 基本信息
   - **需求文档**: requirement.md
   - **项目类型**: H5 移动端 / 后台管理
   - **设计日期**: {YYYY-MM-DD}
   - **状态**: 待审核

   ## 目录结构设计
   {根据项目类型列出新增/修改的文件树}

   ## 路由设计
   {根据项目类型：H5 用 routerKey 模式，后台用 LAYOUT 模式}

   ## 页面组件设计
   ### {PageName}.vue
   - **组件结构**: {根据项目 UI 框架描述}
   - **核心逻辑**: {状态管理、事件处理、生命周期}

   ## Service/Request 层设计
   {根据项目类型：H5 用 MwpXxx 模式，后台用 ApiUrl 模式}

   ## 接口数据
   ### 已有接口（来自 Apifox）
   {接口列表}

   ### Mock 数据设计（待接口）
   {mock 数据结构}

   ## 权限设计（后台项目）
   | 权限常量名 | 值 | 用途 |
   |-----------|-----|------|
   | {ConstName} | {permission_key} | {说明} |

   ## 状态管理
   {如需 Pinia store，则设计 store 结构；简单页面可不需要}

   ## 组件交互流程
   {用户操作 → 代码执行的详细流程}

   ## 注意事项
   - {特殊逻辑}
   - {边界情况}
   ```

5. **设计自审（生成后立即执行）**

   设计文档生成后，立即进行自审，**不作为独立步骤**。

   ### 5.1 收集参考材料
   如果用户在调用时附带了截图路径或参考文档，使用 **Read tool** 读取截图并纳入审查依据。

   ### 5.2 按维度审查

   #### A. 需求覆盖度
   - 需求文档中的每个功能点是否都有对应设计
   - 页面清单 / 改动文件清单是否完整覆盖
   - 数据字段是否全部涵盖

   #### B. UI/交互一致性（有截图时）
   - 页面布局是否与参考截图一致
   - 交互流程、操作按钮/入口是否完整

   #### C. 技术合理性（根据项目类型）

   **H5 移动端项目**：
   - 是否使用了正确的组件（Vant / XPopup / XNavBar 等）
   - Request 层是否遵循 `src/request/MwpXxx.ts` 模式
   - 路由是否使用 `routerName` + `routerPathKey` 模式

   **后台管理项目**：
   - 组件选型是否合适（KrCard/KrForm/KrTable/KrDialog）
   - Service 层是否遵循 `ApiUrl` + `request.post/get` 模式
   - 路由是否使用 LAYOUT 常量 + `meta.permissions`

   #### D. 架构快检
   - 组件间数据流是否清晰（props/events/emitter）
   - 是否存在不必要的状态提升，Pinia 是否真的需要
   - 组件职责是否单一，拆分粒度是否合适
   - 是否与项目现有同类模块架构一致

   #### E. 边界场景
   - 空数据、加载状态、错误处理是否考虑
   - 大列表是否需要虚拟滚动/分页
   - 搜索/输入是否需要防抖

   ### 5.3 自动修订
   发现问题后直接修改 `design.md`，在文档头部追加修订记录：
   ```markdown
   ## 自审修订
   | 项目 | 原设计 | 修订后 | 原因 |
   |------|--------|--------|------|
   ```

   ### 5.4 质量门控
   - 无严重问题 或 严重问题已修订 → 通过
   - 有 P1 级严重问题（架构方向错误、核心组件选型不当）→ 使用 **AskUserQuestion** 提示用户确认修订后的设计是否满意

6. **输出确认**

   展示设计摘要（含自审结果），使用 **AskUserQuestion tool**：
   > "设计文档已生成并通过自审{自审修订了 N 个问题}。请查看 `docs/pipeline/{feat-name}/design.md`。确认后可执行 `/lc-feat:implement {feat-name}` 开始编码。"

**Guardrails**
- **必须先检测项目类型**，使用对应的组件库、请求模式、路由模式
- H5 项目不要使用 KrCard/KrForm/KrTable 等后台组件
- 后台项目不要使用 Vant/XPopup 等移动端组件
- 使用 `<script setup lang="ts">` + Composition API（两种项目通用）
- 设计必须参考项目中相似模块的实际代码，不能凭空设计
- 设计必须覆盖：路由、页面、Service/Request、权限（如适用）四个维度
- 设计自审是设计步骤的一部分，不是独立步骤，不单独生成 `design-review.md`
