# Playwright E2E 测试通用指南

> **版本**：v2.1 | **更新**：2026-06-29
> **定位**：**项目无关、独立可用**的 H5/Web E2E 测试指南。核心内容（环境 → 配置 → 写用例 → 执行 → 排错）只依赖 Playwright，不绑定任何工作流或项目。
> **可选**：可与 lc-feat 流水线配合，按文档**自动生成**用例——见 [§十五](#十五可选与-lc-feat-流水线配合使用)，不需要时可完全忽略。
> 具体项目（kejinshou_m、h5-nuxt 等）仅作**配置举例**。

---

## 目录

**核心（独立可用）**
- [一、总览](#一总览)
- [二、标准目录结构（约定）](#二标准目录结构约定)
- [三、环境准备](#三环境准备)
- [四、配置：通用模板 + 项目配置矩阵](#四配置通用模板--项目配置矩阵)
- [五、选择器与等待策略](#五选择器与等待策略)
- [六、截图策略](#六截图策略)
- [七、哪些适合 E2E、哪些不适合](#七哪些适合-e2e哪些不适合)
- [八、失败诊断与修复](#八失败诊断与修复)
- [九、框架差异：SPA（Vite）vs SSR（Nuxt）](#九框架差异spavite-vs-ssrnuxt)
- [十、H5 移动端专项](#十h5-移动端专项)
- [十一、常见坑与解决方案](#十一常见坑与解决方案)
- [十二、测试模板](#十二测试模板)
- [十三、报告产出](#十三报告产出)
- [十四、命令速查](#十四命令速查)

**可选集成**
- [十五、（可选）与 lc-feat 流水线配合使用](#十五可选与-lc-feat-流水线配合使用)
- [附录：快速检查清单](#附录快速检查清单)

---

## 一、总览

本指南独立讲 Playwright E2E，**不依赖任何工作流**：照着 §二～§十四，手写 `*.spec.ts` 即可完整跑通。

E2E 有两种落地方式：

| 方式 | 说明 | 位置 |
|------|------|------|
| **① 手动写 spec** | 纯 Playwright，自己写用例。完整、可控、零额外依赖 | 本指南主体（§二～§十四）|
| **② 自动生成（可选）** | 配合 `lc-feat:e2e` 按文档自动生成并执行用例 | §十五，可忽略 |

两种方式产出同一套结构（`tests/e2e/specs/*.spec.ts` + 截图 + 报告），可混用。无论哪种，§五～§十二 的编写规则、模板、排错都通用。

---

## 二、标准目录结构（约定）

E2E 作为**独立子工程**放在 `tests/e2e/`，与主工程依赖隔离（浏览器二进制不污染主 build）。所有项目通用：

```
tests/e2e/
├── .gitignore              # 忽略 node_modules/ results/ report/
├── package.json            # 自包含子工程，仅依赖 @playwright/test
├── playwright.config.ts    # Playwright 配置（端口/设备/webServer 按项目填）
├── specs/                  # 测试文件目录
│   └── {feat-name}.spec.ts # 每个功能一个文件
├── results/                # 执行产物（gitignore）
│   └── screenshots/
│       └── {feat-name}/    # 截图按功能隔离
└── report/                 # HTML/JSON 报告（gitignore）
    ├── index.html
    └── results.json
```

> **为什么独立子工程**：Playwright + 浏览器内核体积大，独立 `package.json` 让它不进主工程依赖树，尤其适合 SSR 项目（避免干扰主 build）。

---

## 三、环境准备

### 3.1 一次性安装

子工程用项目自身的包管理器安装（`npm` / `pnpm` / `yarn` 任一）：

```bash
cd tests/e2e

# 安装 Playwright
npm install          # 或 pnpm install

# 安装 Chromium 浏览器内核
npx playwright install chromium
```

> ⚠️ **版本对齐坑**：Playwright 每个版本绑定特定浏览器 build。新装/升级 `@playwright/test` 后**必须重跑** `npx playwright install chromium`，否则报 `Executable doesn't exist at .../chromium_headless_shell-XXXX`。
> 若多进程并发安装出现 `__dirlock` 锁错误：`rm -rf ~/Library/Caches/ms-playwright/__dirlock` 后重装。

### 3.2 验证安装

```bash
cd tests/e2e && npx playwright test --list
```

能列出用例即环境就绪。

### 3.3 可选：Playwright MCP

```bash
claude mcp add playwright -s user -- npx @playwright/mcp@latest
```

---

## 四、配置：通用模板 + 项目配置矩阵

### 4.1 通用 playwright.config.ts 模板

各项目结构一致，**只需改 4 处**（`baseURL` / `webServer.command` / `timeout` / 设备）：

```typescript
import { defineConfig, devices } from '@playwright/test'
import path from 'path'

const projectRoot = path.resolve(__dirname, '../../')

export default defineConfig({
    testDir: './specs',
    outputDir: path.join(projectRoot, 'tests/e2e/results'),
    reporter: [
        ['html', { outputFolder: path.join(projectRoot, 'tests/e2e/report'), open: 'never' }],
        ['json', { outputFile: path.join(projectRoot, 'tests/e2e/report/results.json') }],
        ['list'],
    ],
    use: {
        baseURL: 'http://localhost:<PORT>',   // ← 改：项目 dev 端口
        screenshot: 'off',                     // 手动截图由测试代码控制
        video: 'retain-on-failure',
        trace: 'on-first-retry',
    },
    projects: [
        { name: 'Mobile Chrome', use: { ...devices['Pixel 5'] } },  // ← 改：H5 用移动设备，PC 用 Desktop Chrome
    ],
    webServer: {
        command: '<DEV_COMMAND>',              // ← 改：项目 dev 启动命令
        url: 'http://localhost:<PORT>',        // ← 改：同 baseURL
        reuseExistingServer: true,             // 已启动则复用，未启动则自动拉起
        timeout: <TIMEOUT>,                    // ← 改：SPA 60s，SSR 建议 120s
        cwd: projectRoot,
    },
})
```

### 4.2 项目配置矩阵（举例）

| 项目 | 框架 | 包管理 | dev 命令 | 端口 | 设备 | webServer timeout |
|------|------|--------|----------|------|------|-------------------|
| **kejinshou_m** | Vue 3 + Vite (H5) | npm | `npm run start:dev` | 9241 | Pixel 5 | 60s |
| **h5-nuxt** | Nuxt 3 (H5, SSR) | pnpm | `pnpm start:dev` | 9158 | Pixel 5 | 120s |
| **backend** | Vue 3 + Vite (PC) | npm | `npm run dev` | 5173 | Desktop Chrome | 60s |

> 参考值，**以各项目实际 `nuxt.config.ts` / `vite.config.ts` 端口和 `package.json` 脚本为准**。SSR 项目冷启慢，`timeout` 给足（≥120s）。

### 4.3 关键配置说明

| 配置项 | 推荐值 | 说明 |
|--------|--------|------|
| `screenshot` | `'off'` | 不自动截图，由测试代码 `page.screenshot()` 手动控制时机 |
| `video` | `'retain-on-failure'` | 仅失败保留录像 |
| `trace` | `'on-first-retry'` | 重试保留 trace，可 `npx playwright show-trace` 回放 |
| `webServer.reuseExistingServer` | `true` | 本地已开 dev 则复用 |
| `webServer.cwd` | 项目根目录 | 确保 dev 命令在正确位置执行 |

---

## 五、选择器与等待策略

### 5.1 选择器优先级（从高到低）

| 优先级 | 方式 | 示例 | 稳定性 |
|--------|------|------|--------|
| 1 | `getByRole` | `page.getByRole('button', { name: '提交' })` | 最高 |
| 2 | `getByText` | `page.getByText('操作成功')` | 高 |
| 3 | `getByPlaceholder` | `page.getByPlaceholder('请输入价格')` | 高 |
| 4 | `getByTestId` | `page.getByTestId('bargain-form')` | 中 |
| 5 | `locator(CSS)` | `page.locator('.van-button--primary')` | 低（最后手段）|

**禁止**：脆弱 XPath、深层级 CSS。

### 5.2 等待策略

| 场景 | 正确做法 | 禁止 |
|------|---------|------|
| 页面加载 | `await page.waitForLoadState('networkidle')` | `waitForTimeout` |
| API 请求 | `await page.waitForResponse('**/api/xxx')` | 硬编码延时 |
| 元素出现 | `await expect(locator).toBeVisible()` | `sleep(1000)` |
| 路由跳转 | `await page.waitForURL('/target')` | 轮询 URL |
| 动画完成 | `await expect(locator).toBeVisible()` | `waitForTimeout(300)`（仅动画兜底可破例）|

---

## 六、截图策略

### 6.1 核心原则

- config 的 `screenshot` 设为 `'off'`，由测试代码 `page.screenshot()` **手动控制**时机。
- 每个用例必须包含截图，使用 `fullPage: true`。
- 路径用 `path.resolve` + `path.join` 拼**绝对路径**，按功能隔离目录。

### 6.2 截图时机

| 时机 | 说明 |
|------|------|
| 页面首次加载完成 | 记录初始状态 |
| 执行关键操作前 | 如点击提交按钮前 |
| 操作完成后 | toast 出现、弹窗关闭 |
| 异常状态 | 空数据、错误提示 |

### 6.3 路径规则

```typescript
import path from 'path'

const screenshotDir = path.resolve(__dirname, '../results/screenshots/{feat-name}')

await page.screenshot({
    path: path.join(screenshotDir, '主流程-01-页面加载.png'), // {用例简称}-{序号}-{描述}.png
    fullPage: true,
})
```

---

## 七、哪些适合 E2E、哪些不适合

E2E 不是越多越好——**有些场景天然不适合自动化**，硬测只会产出脆弱、误报的用例。无论手动还是自动生成，落用例前都先按下表判断：

| 标签 | 判定 | 处理 |
|------|------|------|
| ✅ 可 E2E | 页面加载 / 路由跳转 / 表单填写提交 / 列表加载搜索 / 可见 UI 断言 | 写成用例 |
| 🔒 需登录 | 受登录态保护的页面或操作 | 准备测试 token（注入 localStorage）后再写；否则跳过并标注 |
| 🧩 需 mock | JSBridge / 原生能力 / 三方回调（App 内分享、关闭 WebView 等） | 不在 E2E 里测，记录说明 |
| ⬜ 不可 E2E | KeepAlive 缓存、IndexedDB/DexieDB、SSR 请求参数、"控制台无重复请求"等白盒断言 | 改用单测 |

> 这是通用原则。配合 lc-feat 自动生成时，skill 会自动按此打标分流（见 §十五）。

---

## 八、失败诊断与修复

### 8.1 诊断流程

```
执行 → 有失败 → 读失败截图 + 错误信息 → 判断类型
  ├── 测试问题（选择器/时序）→ 修测试代码 → 重跑
  └── 功能 Bug → 记录 → 等人工确认（不改源码）
```

### 8.2 错误类型判断表

| 错误信息 | 类型 | 处理 |
|---------|------|------|
| `Timeout waiting for locator` | 选择器/时序 | 修选择器或加等待 |
| `expect(received).toBe(expected)` | 数据断言 | 可能是功能 Bug |
| `waitForURL timeout` | 路由未跳转 | 可能是功能 Bug |
| `Element is not visible` | 元素遮挡 | 检查 z-index / v-if |
| `net::ERR_CONNECTION_REFUSED` | 服务未启动 | 检查 webServer / dev server |
| `Execution context was destroyed` | 页面重新导航 | 加 `networkidle` 等待 |
| `Executable doesn't exist at .../chromium_*` | 浏览器内核缺失/版本不符 | 重跑 `npx playwright install chromium` |

### 8.3 修复边界

- **可改**（测试代码问题）：选择器文本不符、缺等待、截图路径错。
- **不改**（功能 Bug）：点击无响应、提交后数据未更新、路由逻辑错、API 参数错 —— 记录待人工确认。

---

## 九、框架差异：SPA（Vite）vs SSR（Nuxt）

| 项 | SPA（Vue3 + Vite，如 kejinshou_m） | SSR（Nuxt3，如 h5-nuxt） |
|----|-----------------------------------|--------------------------|
| 启动命令 | `npm run start:dev` | `pnpm start:dev`（= `nuxt dev`）|
| 默认端口（举例） | 9241 | 9158 |
| 路由 | history（vue-router） | 文件系统路由（以项目实际路由配置为准）|
| 渲染 | 纯客户端 | 服务端渲染 + 客户端 hydration |
| 页面就绪 | `waitForLoadState('networkidle')` | `networkidle` 后还需等 hydration 才可交互 |
| 数据获取 | 客户端请求 | `useAsyncData` / `useFetch`（SSR 首屏已含数据）|
| 环境变量 | `VITE_*` | `NUXT_*`（如 `NUXT_PUBLIC_*`）|
| webServer timeout | 60s | ≥120s（冷启慢）|

### SSR 特有注意

```typescript
await page.goto('/page')
await page.waitForLoadState('networkidle')
// hydration 完成后元素才真正可交互，用可交互断言确认
await expect(page.getByRole('button', { name: '提交' })).toBeEnabled()
```

> ⚠️ **与单测框架隔离**：主工程若用 Vitest，其默认匹配 `*.spec.ts`，会误抓 `tests/e2e` 下的 Playwright spec。需在 `vitest.config.ts` 的 `test.exclude` 加 `'tests/e2e/**'`。

---

## 十、H5 移动端专项

### 10.1 Vant 等组件交互

```typescript
// Toast — 出现即截图+断言（很快消失）
await page.getByRole('button', { name: '提交' }).click()
await expect(page.getByText('提交成功')).toBeVisible()
await page.screenshot({ path: '...toast.png', fullPage: true })

// Popup 弹窗 — 等 transition 动画完成
await page.getByText('打开弹窗').click()
await expect(page.locator('.van-popup')).toBeVisible()
await page.waitForTimeout(300) // 仅此处允许短暂等待动画
await page.screenshot({ path: '...popup.png', fullPage: true })
```

### 10.2 移动端手势

```typescript
await page.touchscreen.swipe(200, 200, 200, 500)   // 下拉刷新 / 上滑加载
await page.waitForResponse('**/api/list')
```

### 10.3 软键盘处理

```typescript
const input = page.getByPlaceholder('请输入价格')
await input.scrollIntoViewIfNeeded()  // 操作前先滚到可视区
await input.fill('100')
```

---

## 十一、常见坑与解决方案

**坑 1：Vant Toast 转瞬即逝**
```typescript
// ❌ 等待后 Toast 已消失
await page.click('button'); await page.waitForTimeout(2000)
expect(page.getByText('成功')).toBeVisible()
// ✅ 点击后立即断言
await page.click('button')
await expect(page.getByText('成功')).toBeVisible()
```

**坑 2：接口未完成就断言** —— `Promise.all` 同时触发导航与等响应：
```typescript
await Promise.all([
    page.waitForResponse('**/api/goods/list'),
    page.goto('/goods/list'),
])
await expect(page.getByTestId('goods-item').first()).toBeVisible()
```

**坑 3：登录态丢失** —— `addInitScript` 注入 token（键名按项目实际，可能带环境前缀）：
```typescript
await context.addInitScript((token) => {
    localStorage.setItem('<token-key>', token)  // 如 'user:kjs-token' 或 'test4j-user:kjs-token'
}, process.env.E2E_TOKEN)
```

**坑 4：HMR 干扰** —— 测试期间不要编辑源码，或用构建产物预览模式跑。

**坑 5：浏览器版本不符** —— 升级 `@playwright/test` 后必跑 `npx playwright install chromium`（见 §3.1）。

---

## 十二、测试模板

> **项目无关**模板，示例路由/选择器按项目实际替换。

### 12.1 基础模板

```typescript
import { test, expect } from '@playwright/test'
import path from 'path'

const screenshotDir = path.resolve(__dirname, '../results/screenshots/{feat-name}')

test.describe('{功能名称}', () => {
    test.beforeEach(async ({ context }) => {
        // 如需登录态（键名按项目实际）
        // await context.addInitScript((t) => localStorage.setItem('<token-key>', t), process.env.E2E_TOKEN)
    })

    test('主流程：{流程描述}', async ({ page }) => {
        await page.goto('/{route-path}')
        await page.waitForLoadState('networkidle')
        await page.screenshot({ path: path.join(screenshotDir, '主流程-01-页面加载.png'), fullPage: true })

        await page.getByRole('button', { name: '操作按钮' }).click()
        await page.screenshot({ path: path.join(screenshotDir, '主流程-02-操作后.png'), fullPage: true })

        await expect(page.getByText('操作成功')).toBeVisible()
        await page.screenshot({ path: path.join(screenshotDir, '主流程-03-操作成功.png'), fullPage: true })
    })

    test('异常：{异常场景}', async ({ page }) => {
        await page.goto('/{route-path}')
        await page.waitForLoadState('networkidle')
        await page.getByRole('button', { name: '提交' }).click()
        await expect(page.getByText('请填写必填项')).toBeVisible()
        await page.screenshot({ path: path.join(screenshotDir, '异常-01-空表单提交.png'), fullPage: true })
    })
})
```

### 12.2 表单弹窗模板

```typescript
test('弹窗表单提交', async ({ page }) => {
    await page.goto('/{route-path}')
    await page.waitForLoadState('networkidle')

    await page.getByRole('button', { name: '打开' }).click()
    await expect(page.locator('.van-popup')).toBeVisible()

    await page.getByPlaceholder('请输入期望价格').fill('500')

    await Promise.all([
        page.waitForResponse('**/api/<submit-endpoint>'),
        page.getByRole('button', { name: '确认提交' }).click(),
    ])

    await expect(page.getByText('提交成功')).toBeVisible()
    await page.screenshot({ path: path.join(screenshotDir, '提交-成功.png'), fullPage: true })
})
```

### 12.3 列表搜索模板

```typescript
test('搜索', async ({ page }) => {
    await page.goto('/{list-route}')
    await page.waitForLoadState('networkidle')

    await page.getByPlaceholder('搜索').fill('关键词')
    await Promise.all([
        page.waitForResponse('**/api/<search-endpoint>**'),
        page.keyboard.press('Enter'),
    ])

    await expect(page.getByTestId('list-item').first()).toBeVisible()
    await page.screenshot({ path: path.join(screenshotDir, '搜索-结果.png'), fullPage: true })
})
```

---

## 十三、报告产出

### 13.1 内置报告（Playwright 原生）

执行后自动生成 HTML / JSON 报告，无需额外工具：

```bash
cd tests/e2e && npx playwright show-report report   # 打开 HTML 报告
```

失败用例的 video / trace 也在 `results/` 下，`npx playwright show-trace <trace.zip>` 可逐帧回放。

### 13.2 Markdown 汇总报告（可选）

需要可读的归档报告时，建议结构如下（配合 lc-feat 自动生成，见 §十五）：

```markdown
# {功能名称} E2E 测试报告
## 测试日期 / 框架 / 设备
## 用例取舍（✅可E2E / 🔒需登录 / 🧩需mock / ⬜不可E2E 各计数）
## 测试概览（用例数 / 通过 / 失败 / 截图数 / 耗时）
## 测试用例清单（名称 / 状态 / 耗时 / 截图）
## 截图索引 / 失败分析 / 发现的功能 Bug
```

---

## 十四、命令速查

```bash
# 环境
cd tests/e2e && npx playwright test --list           # 检查环境/列用例
cd tests/e2e && npx playwright install chromium       # 装/补浏览器内核
rm -rf ~/Library/Caches/ms-playwright/__dirlock       # 清并发安装锁

# 执行
cd tests/e2e && npx playwright test                   # 跑全部
cd tests/e2e && npx playwright test specs/x.spec.ts   # 跑单个
cd tests/e2e && npx playwright test --last-failed     # 重跑失败
cd tests/e2e && npx playwright test --headed          # 带界面调试
cd tests/e2e && npx playwright test --ui              # UI 交互模式

# 报告
cd tests/e2e && npx playwright show-report report      # 看 HTML 报告
cd tests/e2e && npx playwright show-trace <trace.zip>  # 回放 trace
```

> lc-feat 自动生成相关命令见 §十五。

---

## 十五、（可选）与 lc-feat 流水线配合使用

> 本节是**可选增强**。不用 lc-feat 时，前十四节已足够独立完成 E2E。

把"读文档 → 生成用例 → 执行 → 出报告"自动化，用 `lc-feat:e2e` skill。

### 15.1 流水线中的位置

```
requirement → design → implement → verify → 【e2e】   ← 流水线最后一步
```

环境未就绪时自动 `skipped`，不阻断流程。

### 15.2 双驱动模式

`/lc-feat:e2e <feat-name> [doc-path]` 自动判定生成依据：

```bash
# 模式 A —— 需求+设计驱动（存在 docs/pipeline/{feat}/requirement.md + design.md 时）
/lc-feat:e2e <feat-name>

# 模式 B —— 现有文档驱动（显式指定一份文档作为测试依据）
/lc-feat:e2e <feat-name> docs/<任意路径>/测试要点.md

# 模式 B —— 不传文档，自动发现现有文档（测试要点 / 模块文档）
/lc-feat:e2e <feat-name>
```

**判定优先级**：显式 `doc-path` → pipeline 文档 → 自动发现 `docs/**/*测试要点*.md`、模块文档 → 兜底 `git diff <base-branch>` + 源码。

> **「测试要点」式用例表**（含「操作 / 预期结果」列）是模式 B 最优来源——逐条映射：`操作`→action，`预期结果`→assert。

### 15.3 自动用例分流

生成前 skill 会自动按 [§七](#七哪些适合-e2e哪些不适合) 的标准对每条用例打标，只生成可 E2E 的，其余写入报告说明，避免脆弱误报用例。

### 15.4 相关命令

```bash
/lc-feat:e2e <feat-name>                  # 自动判定模式生成 + 执行
/lc-feat:e2e <feat-name> <doc-path>       # 指定文档驱动
/lc-feat:pipeline <feat-name> --from=e2e  # 流水线从 e2e 步恢复
```

> 生成逻辑细节见 `lc-feat-e2e/SKILL.md`，流水线集成见 `lc-feat-pipeline-guide.md` §4.5。

---

## 附录：快速检查清单

执行 E2E 前确认：

- [ ] `tests/e2e/` 为独立子工程（自带 `package.json`），`@playwright/test` 已安装
- [ ] `npx playwright install chromium` 已执行（升级后需重跑）
- [ ] `playwright.config.ts` 的 `baseURL` / `webServer.command` / `timeout` / 设备已按项目填对（见 §4.2 矩阵）
- [ ] `tests/e2e/.gitignore` 忽略 `node_modules/`、`results/`、`report/`
- [ ] 主工程若用 Vitest，已在 `test.exclude` 排除 `tests/e2e/**`
- [ ] 需登录的用例已准备测试 token（`tests/e2e/.env`，gitignore）

---

*项目无关通用版（核心独立可用）· lc-feat 集成为可选项（§十五）。*
