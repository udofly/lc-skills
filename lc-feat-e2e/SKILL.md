---
name: lc-feat-e2e
description: E2E 端到端测试技能。三种驱动模式——A 需求+设计驱动（配合流水线 spec.md，旧版 requirement.md+design.md）、B 现有文档驱动（测试要点/模块文档/指定文档路径，不依赖流水线）、C 测试用例驱动（从云效 Yunxiao MCP 读取测试用例库）——生成 Playwright E2E 测试，在真实浏览器中验证页面交互，保存截图。当用户说"E2E测试"、"端到端测试"、"浏览器测试"、"跑一下页面"、"基于文档生成测试"、"基于云效用例生成测试"时触发。
license: MIT
metadata:
  author: kejinshou-team
  version: "0.0.6"
  pipeline_guide: "~/.claude/skills/docs/lc-feat-pipeline-guide.md"
---

# E2E 端到端测试

根据需求文档和设计文档，自动生成 Playwright E2E 测试用例，在移动端模拟浏览器中执行，验证页面交互流程，保存每个步骤的截图。

---

**Input**: `/lc-feat:e2e <feat-name> [doc-path] [--yunxiao <目录ID|用例ID>]`

支持三种驱动模式（在 Step 2 自动判定）：

- **模式 A — 需求+设计驱动（配合流水线）**：从 lc-feat 流水线产物 `spec.md`（需求与设计文档；旧版功能为 `requirement.md` + `design.md`）生成。适合走流水线开发的新功能。
- **模式 B — 现有文档驱动（基于文档）**：从项目**已有文档**（测试要点文档 / 模块文档 / 显式指定的 `doc-path`）生成，**不依赖流水线**。适合已有文档但未走流水线的功能或老页面。
- **模式 C — 测试用例驱动（基于云效用例）**：从**云效 Yunxiao MCP** 测试用例库读取用例（`preCondition` + `testSteps`），逐条映射成 E2E。适合 QA 已在云效维护用例的功能。命令带 `--yunxiao <目录ID|用例ID>` 时触发。

三种模式入口不同、后续流程（用例分流 → 生成 → 执行 → 报告）完全共用。

**Steps**

1. **环境检测**

   一步验证 E2E 环境是否就绪：

   ```bash
   cd tests/e2e && npx playwright test --list 2>&1
   ```

   如果失败（Playwright 未安装或 Chromium 缺失）：
   - **在 pipeline 中执行时**：标记为 `skipped`，输出 "E2E 环境未就绪，跳过"，继续下一步
   - **独立调用时**：提示用户安装：
     > "E2E 测试环境未就绪。请执行以下命令：
     > ```
     > cd tests/e2e && npm install && npx playwright install chromium
     > ```"

   > **注意**：不需要手动检测 dev server。`playwright.config.ts` 已配置 `webServer`，Playwright 会自动检测并启动开发服务器。

2. **确定测试依据（三模式自动判定）**

   按以下优先级判定模式与依据来源：

   | 优先级 | 条件 | 模式 | 用例来源 |
   |--------|------|------|----------|
   | ① | 命令带 `--yunxiao <目录ID\|用例ID>` | **C 测试用例驱动** | 云效 MCP 用例库，见下方「模式 C：云效用例读取」 |
   | ② | 命令传入了 `[doc-path]` | **B 现有文档驱动** | 该指定文档 |
   | ③ | `docs/pipeline/{feat-name}/spec.md` 存在（或旧版 `requirement.md` + `design.md`） | **A 需求+设计驱动** | spec.md（或旧版两个文档） |
   | ④ | 自动发现到现有文档 | **B 现有文档驱动** | 见下方「自动发现顺序」 |
   | ⑤ | 以上都没有 | **兜底** | `git diff --name-only master` + 源码 |

   ### 模式 C：云效用例读取（Yunxiao MCP）

   前置：云效 MCP 已配置（`~/.claude.json` 的 `mcpServers.yunxiao`，包 `alibabacloud-devops-mcp-server`）。**若新增配置后本会话无 `mcp__yunxiao__*` 原生工具**，可临时用 `npx -y alibabacloud-devops-mcp-server` 走 stdio RPC（initialize → tools/call）读取。

   读取链路（已验证）：
   1. `get_current_organization_info` → 拿 `organizationId`
   2. `list_test_repos({organizationId, name})` → 按名字定位 `testRepoId`（**默认页只返回前几个，按 name 过滤更稳**）
   3. `list_testcase_directories({organizationId, testRepoId})` → 目录树，取目标 `directoryId`
   4. `search_testcases({organizationId, testRepoId, directoryId, page, perPage})` → 用例列表。**`directoryId` 必填，否则报「不能为空」**
   5. `get_testcase({organizationId, testRepoId, testcaseId})` → 拿 `preCondition` + `testSteps.content[]{step, expected}`

   逐条映射：`testSteps.content[].step` → Playwright action，`expected` → assert，`preCondition` → `beforeEach`/前置步骤，一条用例对应一个 `test()`。若用例标题带分流前缀（如 `[✅P0]`/`[🧩P1]`/`[⬜P2]`），直接据此分流。

   > 氪金兽项目参考 ID（见记忆 `reference-yunxiao-mcp`）：org `62ac9a6364c8a06be2d5db5d`；用例库 氪金兽2.0=`d73b0e40233d3779c5c716b560`、ai测试库=`289032c822ff9cd561715c29da`。其它项目须先用 `list_test_repos` 查实际 ID。

   **现有文档自动发现顺序**（命中即用，可命中多个则合并）：
   1. `docs/**/*测试要点*.md`、`docs/**/*test*.md` — **已是用例表（操作/预期结果），最优来源**
   2. `docs/**/modules/{页面目录}/*.md`、`docs/**/{feat-name}/*.md` — 模块/功能文档
   3. `docs/**/{feat-name}*.md` — 其它命名匹配的功能文档

   **统一提取**（两模式一致，源代码始终作为补充依据）：
   - **页面路由**：需要访问哪些页面（path + 参数），**以 `app/router.options.ts` 为准**（文件路径 ≠ URL）
   - **用户操作流程**：按钮点击、表单填写、弹窗交互
   - **预期结果**：toast 提示、页面跳转、数据变化
   - **接口依赖**：哪些 API 请求需要等待

   > **模式 B 提示**：若来源是「测试要点」式用例表（含 `操作 / 预期结果` 列），逐条直接映射 —— `操作` → Playwright action，`预期结果` → assert，每条用例对应一个 `test()`。
   >
   > 开始生成前，**简要回显本次判定的模式与文档来源**，便于用户确认。

3. **制定测试策略**

   ### 3.0 用例分流（必做，尤其模式 B）

   文档（特别是「测试要点」表）里**并非每条都能自动 E2E**。先对提取出的每条用例打标，**只为「✅ 可 E2E」生成用例**，其余记入报告并说明原因，**禁止把不可自动化的用例硬写成会误报的脆弱断言**：

   | 标签 | 判定 | 处理 |
   |------|------|------|
   | ✅ 可 E2E | 纯页面加载 / 路由跳转 / 表单填写提交 / 列表加载搜索 / 可见 UI 断言 | 生成 `test()` |
   | 🔒 需登录 | 访问受登录态保护的页面或操作 | 有 token fixture 则生成；否则记为 `skipped`，报告标注「需测试 token」 |
   | 🧩 需 mock | JSBridge / 原生能力 / 三方平台回调（如 App 内分享、关闭 WebView） | 不生成，记入报告 |
   | ⬜ 不可 E2E | KeepAlive 缓存、IndexedDB/DexieDB、SSR 请求参数、控制台无重复请求等白盒断言 | 不生成，记入报告，建议改用单测 |

   分流结果在报告的「用例分流」小节列出统计（各标签数量），让覆盖范围透明。

   根据需求类型确定 E2E 测试范围：

   | 需求类型 | E2E 测试重点 |
   |---------|-------------|
   | **新页面** | 页面加载 + 主流程走通 + 关键交互截图 |
   | **功能扩展** | 新增功能路径 + 原有功能不受影响 |
   | **表单/弹窗** | 打开/填写/提交/关闭全流程 |
   | **列表/搜索** | 加载/搜索/分页/空数据 |

   ### 3.1 截图策略

   **每个测试用例必须在关键步骤保存截图**，截图保存规则：

   ```
   tests/e2e/results/screenshots/{feat-name}/
   ├── {用例名}-01-初始状态.png
   ├── {用例名}-02-操作后.png
   ├── {用例名}-03-结果确认.png
   └── ...
   ```

   截图时机：
   - 页面首次加载完成后
   - 执行关键操作前（如点击提交按钮前）
   - 操作完成后的结果状态（如 toast 出现、弹窗关闭）
   - 异常状态（空数据、错误提示）

4. **生成测试文件**

   在 `tests/e2e/specs/{feat-name}.spec.ts` 生成测试代码。

   ### 4.1 测试文件模板

   ```typescript
   import { test, expect } from '@playwright/test';
   import path from 'path';

   const screenshotDir = path.resolve(__dirname, '../results/screenshots/{feat-name}');

   test.describe('{功能名称}', () => {
       test.beforeEach(async ({ page }) => {
           // 如需登录态，注入 token
           // await page.evaluate(() => localStorage.setItem('token', 'test-token'));
       });

       test('主流程：{流程描述}', async ({ page }) => {
           // 1. 进入页面
           await page.goto('/{route-path}');
           await page.waitForLoadState('networkidle');
           await page.screenshot({
               path: path.join(screenshotDir, '主流程-01-页面加载.png'),
               fullPage: true,
           });

           // 2. 执行操作
           await page.getByRole('button', { name: '操作按钮' }).click();
           await page.screenshot({
               path: path.join(screenshotDir, '主流程-02-点击后.png'),
               fullPage: true,
           });

           // 3. 验证结果
           await expect(page.getByText('操作成功')).toBeVisible();
           await page.screenshot({
               path: path.join(screenshotDir, '主流程-03-操作成功.png'),
               fullPage: true,
           });
       });
   });
   ```

   ### 4.2 编写规则

   **选择器优先级**（从高到低）：
   1. `getByRole('button', { name: '...' })` — 语义化，最稳定
   2. `getByText('...')` — 可见文本
   3. `getByPlaceholder('...')` — 表单输入
   4. `getByTestId('...')` — data-testid 属性
   5. `locator('.class-name')` — CSS 选择器（最后手段）

   **等待策略**：
   - 页面加载：`await page.waitForLoadState('networkidle')`
   - API 请求：`await page.waitForResponse('**/api/xxx')`
   - 元素出现：`await expect(locator).toBeVisible()`
   - 路由跳转：`await page.waitForURL('/target')`
   - **禁止** `waitForTimeout`（硬编码等待）

   **截图规则**：
   - 截图路径必须使用 `path.resolve` + `path.join` 拼接绝对路径
   - `screenshotDir` 基于 `__dirname`（即 `specs/`）相对定位：`path.resolve(__dirname, '../results/screenshots/{feat-name}')`
   - 截图命名：`{用例名简称}-{序号}-{描述}.png`
   - 所有截图使用 `fullPage: true`

   **H5 移动端注意**：
   - Vant Toast 出现后很快消失，出现即截图+断言
   - 弹窗（Popup）需等 transition 动画完成再截图
   - 下拉刷新/上滑加载：`page.touchscreen.swipe()`
   - 软键盘遮挡：操作 input 前先滚动到可视区域

5. **执行测试**

   ```bash
   cd tests/e2e && npx playwright test specs/{feat-name}.spec.ts --config=playwright.config.ts 2>&1
   ```

   ### 5.1 全部通过 → 跳到 Step 6

   ### 5.2 有失败 → 自动诊断修复

   对每个失败用例：

   1. **读取失败截图**（Playwright 自动保存在 results/ 目录）
   2. **判断失败原因**：

      | 错误信息 | 类型 | 处理 |
      |---------|------|------|
      | `Timeout waiting for locator` | 选择器/时序 | 修复测试代码 |
      | `expect(received).toBe(expected)` | 数据断言 | 可能是功能 bug |
      | `waitForURL timeout` | 路由未跳转 | 可能是功能 bug |
      | `Element is not visible` | 元素遮挡 | 检查 z-index / v-if |
      | `net::ERR_CONNECTION_REFUSED` | 服务未启动 | 提示启动 dev server |

   3. **测试代码问题** → 修复测试代码，重跑
   4. **功能 Bug** → 记录到报告，不修改源代码
   5. 最多重试 **3 轮**

6. **生成 E2E 测试报告**

   在 `docs/pipeline/{feat-name}/` 下生成 `e2e-report.md`：

   ```markdown
   # {功能名称} E2E 测试报告

   ## 测试日期: {YYYY-MM-DD}
   ## 测试框架: Playwright
   ## 设备模拟: Pixel 5 (Mobile Chrome)
   ## 驱动模式: {A 需求+设计驱动 / B 现有文档驱动 / C 测试用例驱动}
   ## 用例来源: {spec.md（旧版 requirement.md+design.md）/ 具体文档路径 / 云效用例库名+目录}

   ## 用例分流
   | 标签 | 数量 | 说明 |
   |------|------|------|
   | ✅ 可 E2E | {N} | 已生成用例 |
   | 🔒 需登录 | {N} | {已生成/skipped：缺测试 token} |
   | 🧩 需 mock | {N} | JSBridge / 原生能力，未生成 |
   | ⬜ 不可 E2E | {N} | 白盒断言（KeepAlive/DexieDB/SSR），建议单测 |

   ## 测试概览
   - 测试用例: {N} 个
   - 通过: {N} ✅
   - 失败: {N} ❌（已修复 {M} 个）
   - 截图数量: {N} 张
   - 执行耗时: {N}s

   ## 测试用例清单
   | 用例名称 | 状态 | 耗时 | 截图 |
   |---------|------|------|------|
   | {name} | ✅/❌ | {N}s | [查看](../../tests/e2e/results/screenshots/{feat-name}/{file}.png) |

   ## 截图索引
   | 步骤 | 截图 | 说明 |
   |------|------|------|
   | {步骤名} | ![](../../tests/e2e/results/screenshots/{feat-name}/{file}.png) | {描述} |

   ## 失败用例分析（如有）
   | 用例 | 失败原因 | 类型 | 处理 |
   |------|---------|------|------|
   | {name} | {reason} | 测试问题/功能bug | 已修复/待修复 |

   ## 发现的功能 Bug（如有）
   - {Bug 描述}
   - 修复状态：{已修复/待修复}
   - 相关截图：{path}
   ```

7. **输出确认**

   使用 **AskUserQuestion tool**：
   > "E2E 测试完成：{N} 个用例，{通过数} 个通过。截图保存在 `tests/e2e/results/screenshots/{feat-name}/`。
   > 报告：`docs/pipeline/{feat-name}/e2e-report.md`"

**Guardrails**
- **必须先检测 Playwright 环境和 dev server**，未就绪不执行
- **生成前回显驱动模式与用例来源**（模式 A / B / C + 具体文档或云效库目录），让覆盖范围对用户透明
- **模式 C（云效）**：`search_testcases` 必须带 `directoryId`；优先按用例标题分流前缀（✅/🔒/🧩/⬜）判定可自动化性；MWP 接口 mock 用网关 URL `**/h5/{apiKey}/1.0` 精确拦截，不打真实短信/账号
- **必做用例分流**：不可自动化的用例（需 mock / 白盒断言）记入报告，**禁止硬写成会误报的脆弱断言**；需登录的用例无 token 时记为 skipped
- **每个测试用例必须包含截图**，截图路径使用绝对路径（`path.resolve` + `path.join`），不用相对路径
- **截图目录按 feat-name 隔离**：`tests/e2e/results/screenshots/{feat-name}/`
- 选择器优先用语义化方式（role > text > testid > CSS），禁止脆弱 XPath
- **禁止 `waitForTimeout`**，使用 `waitForLoadState` / `waitForResponse` / `waitForURL`
- 失败用例优先修复测试代码，不随意修改源代码
- 功能 Bug 记录到报告并附截图，等待人工确认
- 最多重试 3 轮，不无限循环
- **修改此 skill 后，必须同步更新流水线使用指南**（路径：`~/.claude/skills/docs/lc-feat-pipeline-guide.md`）
