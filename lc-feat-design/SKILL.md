---
name: lc-feat-design
description: 技术设计技能。根据需求文档生成技术设计文档，包括组件设计、路由配置、Service层设计、状态管理等。当用户说"出设计文档"、"技术设计"、"设计方案"时触发。
license: MIT
metadata:
  author: kejinshou-team
  version: "0.0.1"
---

# 技术设计

根据需求文档生成技术设计文档，包含组件结构、路由、Service 层、权限等完整设计。

---

**Input**: `/lc-feat:design <feat-name>`，feat-name 对应 `docs/pipeline/{feat-name}/requirement.md`。

**Steps**

1. **读取需求文档**

   读取 `docs/pipeline/{feat-name}/requirement.md`，如果不存在则提示先执行 `/lc-feat:requirement`。

   检查需求类型：
   - 如果是"功能扩展/Bug修复/重构"且改动量极小，建议跳过设计直接实现
   - 如果是"新功能"或较大改动，继续设计流程

2. **加载项目编码规范（最高优先级）**

   按以下顺序查找并加载项目编码规范：

   1. 读取项目 `.claude/CLAUDE.md`（如存在）— 获取项目指定的编码规范技能名称
   2. 如果其中提到的编码规范技能（如 `lc-kejinshou-h5-vue`、`lc-kejinshou-backend-page`、`lc-kejinshou-h5-nuxt` 等）在当前可用技能列表中存在，**加载该技能的完整规范作为设计标准**
   3. 如果以上均不存在，通过读取 `package.json` 和 `src/` 目录结构自行判断项目类型

   > 项目编码规范技能中的组件库、请求模式、路由模式等，优先级高于本技能的通用描述。
   - 页面组件：`<script setup lang="ts">` + Composition API + KrForm schema 驱动

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

5. **输出确认**

   展示设计摘要，使用 **AskUserQuestion tool**：
   > "设计文档已生成，请查看 `docs/pipeline/{feat-name}/design.md`。如需对照截图/文档进行审核，请执行 `/lc-feat:design-review {feat-name}`。"

**Guardrails**
- **必须先检测项目类型**，使用对应的组件库、请求模式、路由模式
- H5 项目不要使用 KrCard/KrForm/KrTable 等后台组件
- 后台项目不要使用 Vant/XPopup 等移动端组件
- 使用 `<script setup lang="ts">` + Composition API（两种项目通用）
- 设计必须参考项目中相似模块的实际代码，不能凭空设计
- 设计必须覆盖：路由、页面、Service/Request、权限（如适用）四个维度
