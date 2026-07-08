---
name: lc-feat-implement
description: 编码实现技能。根据设计文档进行编码，生成页面、组件、Service、路由、权限等代码。接口优先从Apifox MCP获取，无接口时使用mock数据。当用户说"开始编码"、"实现功能"、"写代码"时触发。
license: MIT
metadata:
  author: kejinshou-team
  version: "0.0.3"
  pipeline_guide: "~/.claude/skills/docs/lc-feat-pipeline-guide.md"
---

# 编码实现

根据设计文档（或需求文档），按项目规范生成完整的功能代码。

---

**Input**: `/lc-feat:implement <feat-name>`

**Steps**

1. **分支安全检查**

   运行 `git branch --show-current` 检查当前分支：
   - 如果在 `master`/`main`/`develop` 上：
     - 使用 **AskUserQuestion tool** 警告：
       > "当前在 `{branch}` 分支上，直接编码不安全。是否自动创建 `feat/{feat-name}` 分支？"
     - 用户确认后执行 `git checkout -b feature/{feat-name}`
   - 如果在功能分支上：继续

2. **加载需求与设计文档**

   读取 `docs/pipeline/{feat-name}/spec.md`（需求与设计文档，含「一、需求」和「二、设计」两部分）。
   **旧版兼容**：spec.md 不存在时回退并行读取 `design.md` + `requirement.md`。

   如果没有「二、设计」章节（或旧版无 design.md），检查需求部分：
   - 需求存在且改动量小（功能扩展/Bug修复）→ 直接基于需求部分编码
   - 需求也不存在 → 提示先执行 `/lc-feat:requirement`

3. **【强制·阻断性前置条件】加载项目编码规范 skill（最高优先级，不可跳过、不可凭记忆替代）**

   > **⛔ 阻断规则：必须通过 Skill tool 实际调用项目编码规范 skill，在 Skill tool 调用返回结果之前，禁止编写任何业务代码（包括 Service、页面、路由、权限）。"已知规范内容"或"上下文中已有规范"不能替代实际调用——每次编码都必须产生一次 Skill tool call。违反此规则等同于步骤未执行，代码需要重写。**

   按以下顺序查找并加载项目编码规范，找到即执行，作为后续编码的**首要参考**：

   1. 读取项目 `.claude/CLAUDE.md`（如存在）— 获取项目指定的编码规范技能名称和核心要点
   2. 检查 `.claude/CLAUDE.md` 中提到的编码规范技能，如果该技能在当前可用技能列表中存在，则**必须使用 Skill tool 加载该技能的完整规范作为编码标准**
   3. **项目→skill 映射表（硬性约束）**：
      | 项目类型 | 必须使用的 skill |
      |---------|-----------------|
      | h5-vue 项目（如 kejinshou_m） | `lc-kejinshou-h5-vue` |
      | h5-nuxt 项目 | `lc-kejinshou-h5-nuxt` |
      | backend 后台项目（如 backend-kejinshou） | `lc-backend-page` |
   4. 如果 CLAUDE.md 未指定，则根据项目目录结构（package.json、nuxt.config 等）自动匹配上述映射表中的 skill 并加载
   5. 如果映射表中没有匹配的项目类型，才通过读取 `package.json` 和 `src/` 目录结构自行判断

   > **重要**：项目编码规范技能中定义的组件库、请求模式、路由模式、样式规范、命名约定等，优先级高于本技能中的通用规范。编码时必须严格遵循项目规范技能中的约定。

4. **获取接口数据**

   - 尝试通过 Apifox MCP 获取相关接口（工具名从当前可用的 apifox MCP 工具列表中选取）
   - 如果获取到接口：按接口文档定义 Service/Request 层
   - 如果未获取到接口：生成 mock 数据，并在代码中标注 `// TODO: 替换为真实接口`

5. **读取项目中相似模块作为参考**

   找到一个与当前功能最相似的已有模块，读取其关键文件作为编码风格参考。

6. **按项目类型生成代码**

   ### H5 移动端项目（如 kejinshou_m）

   代码风格要求：
   - `<script setup lang="ts">` + Composition API
   - 使用 `ref`、`reactive`、`computed`、`onMounted`、`watch`
   - UI 组件使用 Vant + 项目自定义组件（XPopup/XNavBar/XFooterBtn 等）
   - Request 层在 `src/request/MwpXxx.ts` 中定义，API 枚举在 `src/request/MwpApi.ts`
   - 路由在 `src/router/routerKey.ts` 中定义 routerName + routerPathKey
   - 提示使用 `toast()` / `xAlert()` / `xConfirm()`（来自项目 utils）
   - 状态管理使用 `src/piniaStore/modules/`（仅在需要跨组件共享时）
   - 事件通信使用 `emitter.emit()` / `emitter.on()` 模式
   - 配置常量在 `src/utils/conf.ts` 中定义枚举

   生成顺序：
   1. 配置常量（如需新增枚举/常量，在 `src/utils/conf.ts` 中添加）
   2. Request 层（如需新增接口，在 `src/request/` 中添加）
   3. 路由配置（如需新增路由，在 `src/router/routerKey.ts` 中添加）
   4. 页面/组件代码（在 `src/views/` 或 `src/components/` 中添加）

   ### 后台管理项目（如 backend-kejinshou）

   代码风格要求：
   - `<script setup lang="ts">` + Composition API
   - 组件使用 KR36（KrCard/KrForm/KrTable/KrDialog/KrButton）
   - KrForm 使用 schema 驱动，KrTable 使用 columns 定义
   - Service 层在 `src/services/{module}/index.ts`，使用 ApiUrl + `request.post/get`
   - 路由在 `src/router/modules/{module}.ts`，使用 LAYOUT 常量
   - 权限在 `src/services/permissions.ts`，格式 `kjs_backend.{module}.{sub}.{action}`
   - Toast 使用 `MessagePlugin.success/error/warning`
   - 弹窗使用 KrDialog + KrForm

   生成顺序：
   1. Service 层（`src/services/{module}/index.ts`）
   2. 路由配置（`src/router/modules/{module}.ts`）
   3. 权限配置（`src/services/permissions.ts`）
   4. 页面组件（`src/pages/{module}/`）

7. **代码自检**

   生成代码后自检：
   - TypeScript 类型是否完整
   - 导入路径是否正确
   - 是否遵循了项目现有的代码模式（对比参考模块）
   - mock 数据结构是否与接口定义匹配

8. **输出确认**

   展示生成的文件清单，使用 **AskUserQuestion tool**：
   > "编码完成，生成/修改了以下文件：\n{文件列表}\n\n建议执行 `/lc-feat:verify {feat-name}` 进行代码验证。"

**Guardrails**
- **【强制·阻断】必须通过 Skill tool 实际调用项目对应的编码规范 skill**（h5-vue→`lc-kejinshou-h5-vue`，h5-nuxt→`lc-kejinshou-h5-nuxt`，backend→`lc-backend-page`），每次编码都必须产生一次 Skill tool call，不可凭记忆替代，未调用不得编码
- **必须先检测项目类型**，使用对应的组件库、请求模式、路由模式
- 必须遵循项目现有代码风格，不得引入新的模式
- H5 项目不能使用 KrCard/KrTable 等后台组件，后台项目不能使用 Vant
- mock 数据必须标注 TODO 注释，便于后续替换
- 不要创建不必要的 Pinia store，简单状态用组件内 ref 管理
- 不要过度封装，保持与项目其他模块一致的复杂度
- 功能扩展型需求可直接基于 spec.md 的需求部分编码，不强制要求设计章节
