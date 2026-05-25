---
name: lc-feat-e2e
description: E2E 端到端测试技能。根据需求文档和设计文档生成 Playwright E2E 测试，在真实浏览器中验证页面交互，保存截图。当用户说"E2E测试"、"端到端测试"、"浏览器测试"、"跑一下页面"时触发。
license: MIT
metadata:
  author: kejinshou-team
  version: "0.0.3"
  pipeline_guide: "~/.claude/skills/docs/lc-feat-pipeline-guide.md"
---

# E2E 端到端测试

根据需求文档和设计文档，自动生成 Playwright E2E 测试用例，在移动端模拟浏览器中执行，验证页面交互流程，保存每个步骤的截图。

---

**Input**: `/lc-feat:e2e <feat-name>`

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

2. **加载需求和设计文档**

   并行读取：
   - `docs/pipeline/{feat-name}/requirement.md` — 功能需求（测试依据）
   - `docs/pipeline/{feat-name}/design.md` — 技术设计（路由、页面结构、组件交互）
   - 功能涉及的源代码文件（从 design.md 的文件清单或 `git diff --name-only master` 获取）

   从中提取：
   - **页面路由**：需要访问哪些页面（path + 参数）
   - **用户操作流程**：按钮点击、表单填写、弹窗交互
   - **预期结果**：toast 提示、页面跳转、数据变化
   - **接口依赖**：哪些 API 请求需要等待

3. **制定测试策略**

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
- **每个测试用例必须包含截图**，截图路径使用绝对路径（`path.resolve` + `path.join`），不用相对路径
- **截图目录按 feat-name 隔离**：`tests/e2e/results/screenshots/{feat-name}/`
- 选择器优先用语义化方式（role > text > testid > CSS），禁止脆弱 XPath
- **禁止 `waitForTimeout`**，使用 `waitForLoadState` / `waitForResponse` / `waitForURL`
- 失败用例优先修复测试代码，不随意修改源代码
- 功能 Bug 记录到报告并附截图，等待人工确认
- 最多重试 3 轮，不无限循环
- **修改此 skill 后，必须同步更新流水线使用指南**（路径：`~/.claude/skills/docs/lc-feat-pipeline-guide.md`）
