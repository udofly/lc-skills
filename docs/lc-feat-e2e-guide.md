# lc-feat E2E 测试完整指南

> **版本**：v1.0 | **更新**：2026-05-25
> **适用**：kejinshou_m（Vue 3 + Vite H5）及所有 lc-feat 工作流项目
> **工具链**：Playwright + Claude Code + lc-feat pipeline

---

## 目录

- [一、E2E 在 lc-feat 工作流中的位置](#一e2e-在-lc-feat-工作流中的位置)
- [二、环境准备](#二环境准备)
- [三、项目配置详解](#三项目配置详解)
- [四、使用方式](#四使用方式)
- [五、测试生成规则](#五测试生成规则)
- [六、选择器与等待策略](#六选择器与等待策略)
- [七、截图策略](#七截图策略)
- [八、失败诊断与自动修复](#八失败诊断与自动修复)
- [��、Vue3 vs Nuxt3 差异](#九vue3-vs-nuxt3-差异)
- [十、H5 移动端专项](#十h5-移动端专项)
- [十一、常见坑与解决方案](#十一常见坑与解决方案)
- [十二、测试模板](#十二测试模板)
- [十三、报告产出](#十三报告产出)
- [十四、日常命令速查](#十四日常命令速查)

---

## 一、E2E 在 lc-feat 工作流中的位置

```
需求 → 设计 → 审核 → 编码 → Lint → 单元测试 → 【E2E 测试】 → QA → PR
                                                      ↑ 第7步
```

E2E 是流水线第 7 步（共 8 步主流程），位于单元测试之后、QA 分析之前。

### 触发方式

| 方式 | 命令 | 说明 |
|------|------|------|
| Pipeline 中自动执行 | `/lc-feat:pipeline <feat-name>` | 作为第 7 步自动运行 |
| 独立调用 | `/lc-feat:e2e <feat-name>` | 单独执行 E2E 测试 |
| 全自动模式 | `/lc-feat:pipeline <feat-name> --auto` | ���需确认连续执行 |
| 断点恢复 | `/lc-feat:pipeline <feat-name> --from=e2e` | 从 E2E 步骤开始 |

### Pipeline 降级

当环境不就绪时：
- **Pipeline 中**：自动标记为 `skipped`，继续执行 QA
- **独立调用**：提示安装命令，等待用户操作

---

## 二、环境准备

### 2.1 一次性安装

```bash
# 进入项目的 tests/e2e 目录（kejinshou_m 已有此目录）
cd tests/e2e

# 安装 Playwright
npm install @playwright/test

# 安装 Chromium 浏览器
npx playwright install chromium
```

### 2.2 验证安装

```bash
cd tests/e2e && npx playwright test --list
```

如果输出测试列表，说明环境 OK。

### 2.3 目录结构

```
tests/e2e/
├── .gitignore              # 忽略 node_modules/results/report
├── package.json            # @playwright/test 依赖
├── playwright.config.ts    # Playwright 配置
├── specs/                  # 测试文件目录
│   ├── demo.spec.ts        # 基础验证（已有）
│   └── {feat-name}.spec.ts # 每个功能一个文件
├── results/                # 执行产物（gitignore）
│   ├── .last-run.json
│   └── screenshots/        # 截图目录
│       └── {feat-name}/    # 按功能隔离
└── report/                 # HTML/JSON 报告（gitignore）
    ├── index.html
    └── results.json
```

### 2.4 可选：MCP 集成

```bash
# 全局注册 Playwright MCP（支持 AI 直接操控浏览器）
claude mcp add playwright -s user -- npx @playwright/mcp@latest
```

---

## 三、项目配置详解

### 3.1 kejinshou_m 的 playwright.config.ts

```typescript
import { defineConfig, devices } from '@playwright/test';
import path from 'path';

const projectRoot = path.resolve(__dirname, '../../');

export default defineConfig({
    testDir: './specs',
    outputDir: path.join(projectRoot, 'tests/e2e/results'),
    reporter: [
        ['html', { outputFolder: path.join(projectRoot, 'tests/e2e/report'), open: 'never' }],
        ['json', { outputFile: path.join(projectRoot, 'tests/e2e/report/results.json') }],
        ['list'],
    ],
    use: {
        baseURL: 'http://localhost:9241',
        screenshot: 'off',      // 手动截图由测试代码控制
        video: 'retain-on-failure',
        trace: 'on-first-retry',
    },
    projects: [
        { name: 'Mobile Chrome', use: { ...devices['Pixel 5'] } },
    ],
    webServer: {
        command: 'npm run start:dev',
        url: 'http://localhost:9241',
        reuseExistingServer: true,  // 已启动则复用，未启动则自动启动
        timeout: 60_000,
        cwd: projectRoot,
    },
});
```

### 3.2 关键配置说明

| 配置项 | 值 | 说明 |
|--------|---|------|
| `baseURL` | `http://localhost:9241` | kejinshou_m 的 dev server 端口 |
| `screenshot` | `'off'` | 不自动截图，由测试代码 `page.screenshot()` 手动控制 |
| `webServer.reuseExistingServer` | `true` | 已启动 dev server 则复用，不重复启动 |
| `webServer.cwd` | 项目根目录 | 确保 `npm run start:dev` 在正确位置执行 |
| `projects` | `Pixel 5` | H5 移动端模拟设备 |

### 3.3 不同项目类型的配置差异

| 项目类型 | baseURL | 设备 | webServer timeout |
|---------|---------|------|-------------------|
| kejinshou_m (Vue3 H5) | `localhost:9241` | Pixel 5 | 60s |
| h5-nuxt (Nuxt3 H5) | `localhost:3000` | Pixel 5 / iPhone 12 | 120s |
| backend (Vue3 PC) | `localhost:5173` | Desktop Chrome | 60s |

---

## 四、使用方式

### 4.1 在 Pipeline 中自动执行

```bash
# 完整流水线，E2E 作为第 7 步自动执行
/lc-feat:pipeline 3.37-bargain

# 从 E2E 步骤断点恢复
/lc-feat:pipeline 3.37-bargain --from=e2e
```

AI 自动完成：读取需求/设计 → 生成测试 → 执行 → 失败自动修复 → 生成报告

### 4.2 独立执行

```bash
# 对已完成的功能生成并执行 E2E 测试
/lc-feat:e2e 3.37-bargain
```

### 4.3 手动执行已有测试

```bash
# 跑全部测试
cd tests/e2e && npx playwright test

# 跑单个文件
cd tests/e2e && npx playwright test specs/demo.spec.ts

# 只跑上次失败的
cd tests/e2e && npx playwright test --last-failed

# 带浏览器界面调试
cd tests/e2e && npx playwright test --headed

# 查看 HTML 报告
cd tests/e2e && npx playwright show-report report
```

---

## 五、测试生成规则

### 5.1 AI 如何生成测试

当执行 `/lc-feat:e2e <feat-name>` 时，AI 会：

1. **读取需求和设计文档**
   - `docs/pipeline/{feat-name}/requirement.md`
   - `docs/pipeline/{feat-name}/design.md`
   - 功能涉及的源代码文件

2. **提取测试要素**
   - 页面路由（path + 参数）
   - 用户操作流程（按钮、表单、弹窗）
   - 预期结果（toast、跳转、数据变化）
   - 接口依赖（需要等待的 API）

3. **按需求类型确定测试重点**

| 需求类型 | 测试重点 |
|---------|----------|
| 新页面 | 页面加载 + 主流程走通 + 关键交互截图 |
| 功能扩展 | 新增功能路径 + 原有功能不受影响 |
| 表单/弹窗 | 打开/填写/提交/关闭全流程 |
| 列表/搜索 | 加载/搜索/分页/空数据 |

4. **生成测试文件** → `tests/e2e/specs/{feat-name}.spec.ts`

### 5.2 测试文件命名

```
tests/e2e/specs/
├── demo.spec.ts           # 基础验证（常驻）
├── 3.37-bargain.spec.ts   # 功能：商品议价
├── 3.38-coupon.spec.ts    # 功能：优惠券
└── ...
```

---

## 六、选择器与等待策略

### 6.1 选择器优先级（从高到低）

| 优先级 | 方式 | 示例 | 稳定性 |
|--------|------|------|--------|
| 1 | `getByRole` | `page.getByRole('button', { name: '提交' })` | 最高 |
| 2 | `getByText` | `page.getByText('操作成功')` | 高 |
| 3 | `getByPlaceholder` | `page.getByPlaceholder('请输入价格')` | 高 |
| 4 | `getByTestId` | `page.getByTestId('bargain-form')` | 中 |
| 5 | `locator` | `page.locator('.van-button--primary')` | 低 |

**禁止**：脆弱 XPath、深层级 CSS 选择器

### 6.2 等待策略

| 场景 | 正确做法 | 禁止 |
|------|---------|------|
| 页面加载 | `await page.waitForLoadState('networkidle')` | `waitForTimeout` |
| API 请求 | `await page.waitForResponse('**/api/xxx')` | 硬编码延时 |
| 元素出现 | `await expect(locator).toBeVisible()` | `sleep(1000)` |
| 路由跳转 | `await page.waitForURL('/target')` | 轮询 URL |
| 动画完成 | `await expect(locator).toBeVisible()` | `waitForTimeout(300)` |

---

## 七、截图策略

### 7.1 核心原则

- `playwright.config.ts` 的 `screenshot` 设为 `'off'`（不自动截图）
- 由测试代码通过 `page.screenshot()` **手动控制**截图时机
- 每个测试用例必须包含截图

### 7.2 截图时机

| 时机 | 说明 |
|------|------|
| 页面首次加载完成 | 记录初始状态 |
| 执行关键操作前 | 如点击提交按钮前 |
| 操作完成后 | toast 出现、弹窗关闭 |
| 异常状态 | 空数据、错误提示 |

### 7.3 截图路径规则

```typescript
import path from 'path';

// screenshotDir 基于 specs/ 目录相对定位
const screenshotDir = path.resolve(__dirname, '../results/screenshots/{feat-name}');

// 截图命名格式：{用例简称}-{序号}-{描述}.png
await page.screenshot({
    path: path.join(screenshotDir, '主流程-01-页面加载.png'),
    fullPage: true,
});
```

### 7.4 截图目录结构

```
tests/e2e/results/screenshots/
├── 3.37-bargain/
│   ├── 主流程-01-页面加载.png
│   ├── 主流程-02-打开弹窗.png
│   ├── 主流程-03-提交成功.png
│   └── 异常-01-空价格提示.png
└── 3.38-coupon/
    └── ...
```

---

## 八、失败诊断与自动修复

### 8.1 AI 诊断流程

```
测试执行 → 有失败
    ↓
读取失败截图 + 错误信息
    ↓
判断类型：测试问题 or 功能 Bug
    ↓
├── 测试问题 → 自动修复 → 重跑（最多 3 轮）
└── 功能 Bug → 记录到报告 → 等待人工确认
```

### 8.2 错误类型判断表

| 错误信息 | 类型 | AI 处理 |
|---------|------|---------|
| `Timeout waiting for locator` | 选择器/时序 | 自动修复选择器或加等待 |
| `expect(received).toBe(expected)` | 数据断言 | 可能是功能 Bug |
| `waitForURL timeout` | 路由未跳转 | 可能是功能 Bug |
| `Element is not visible` | 元素遮挡 | 检查 z-index / v-if |
| `net::ERR_CONNECTION_REFUSED` | 服务未启动 | 提示启动 dev server |
| `Execution context was destroyed` | 页面重新导航 | 加 networkidle 等待 |

### 8.3 自动修复边界

**AI 会自动修复的**（测试代码问题）：
- 选择器文本与实际 DOM 不一致
- 缺少等待（异步请求未完成就断言）
- 截图路径错误

**AI 不会自动修改的**（功能 Bug）：
- 按钮点击无响应
- 表单提交后数据未更新
- 路由跳转逻辑错误
- API 请求参数错误

---

## 九、Vue3 vs Nuxt3 差异

| 项目 | Vue3 + Vite (kejinshou_m) | Nuxt3 (h5-nuxt) |
|------|---------------------------|-----------------|
| 启动命令 | `npm run start:dev` | `npm run dev` |
| 默认端口 | 9241 | 3000 |
| 路由模式 | history（vue-router） | history（文件系统路由） |
| SSR | 无 | 有，需等 hydration |
| 页面加载等待 | `waitForLoadState('networkidle')` | `waitForLoadState('networkidle')` + hydration |
| 数据获取 | 接口请求（mwpRequest） | `useAsyncData` / `useFetch` |
| 环境变量 | `VITE_*` | `NUXT_*` |

### Nuxt3 SSR 特有注意

```typescript
// Nuxt3 必须等 hydration 完成，否则点击可能无效
await page.goto('/page');
await page.waitForLoadState('networkidle');
// hydration 完成后元素才可交互
await expect(page.getByRole('button', { name: '提交' })).toBeEnabled();
```

---

## 十、H5 移动端专项

### 10.1 Vant 组件交互

```typescript
// Toast — 出现即截图+断言（很快消失）
await page.getByRole('button', { name: '提交' }).click();
await expect(page.getByText('提交成功')).toBeVisible();
await page.screenshot({ path: '...toast.png', fullPage: true });

// Popup 弹窗 — 等 transition 动画完成
await page.getByText('打开弹窗').click();
await expect(page.locator('.van-popup')).toBeVisible();
// 等动画结束再截图
await page.waitForTimeout(300); // 仅此处允许短暂等待动画
await page.screenshot({ path: '...popup.png', fullPage: true });

// Dialog 确认框
await expect(page.locator('.van-dialog')).toBeVisible();
await page.getByRole('button', { name: '确认' }).click();
```

### 10.2 移动端手势

```typescript
// 下拉刷新
await page.touchscreen.swipe(200, 200, 200, 500);
await page.waitForResponse('**/api/list');

// 上滑加载更多
await page.touchscreen.swipe(200, 600, 200, 100);
await page.waitForResponse('**/api/list?page=2');
```

### 10.3 软键盘处理

```typescript
// 操作 input 前先滚动到可视区域
const input = page.getByPlaceholder('请输入价格');
await input.scrollIntoViewIfNeeded();
await input.fill('100');
```

---

## 十一、常见坑与解决方案

### 坑 1：Vant Toast 转瞬即逝

```typescript
// 错误：Toast 消失了才断言
await page.click('button');
await page.waitForTimeout(2000);  // ❌ Toast 已消失
expect(page.getByText('成功')).toBeVisible();

// 正确：点击后立即断言
await page.click('button');
await expect(page.getByText('成功')).toBeVisible();  // ✅
```

### 坑 2：Popup 动画未完成就截图

```typescript
// 正确：等 Popup 可见后再截图
await page.getByText('打开').click();
await expect(page.locator('.van-popup')).toBeVisible();
await page.screenshot({ ... });
```

### 坑 3：接口请求未完成就断言

```typescript
// 正确：等 API 返回后再断言列表
await Promise.all([
    page.waitForResponse('**/api/goods/list'),
    page.goto('/goods/list'),
]);
await expect(page.getByTestId('goods-item').first()).toBeVisible();
```

### 坑 4：登录态丢失

```typescript
test.beforeEach(async ({ page }) => {
    // 注入 token 模拟登录态
    await page.evaluate(() => {
        localStorage.setItem('token', 'test-token-xxx');
    });
});
```

### 坑 5：路由带参数

```typescript
// kejinshou_m 路由示例
await page.goto('/goods/detail?id=123&gameId=456');
await page.waitForLoadState('networkidle');
```

### 坑 6：HMR 热更新干扰

开发模式下代码保存会触发 HMR，导致测试中途页面刷新。解决方案：
- 测试期间不要编辑源���码
- 或使用 `npm run build && npm run serve` 静态预览模式

---

## 十二、测试模板

### 12.1 基础模板（kejinshou_m 适用）

```typescript
import { test, expect } from '@playwright/test';
import path from 'path';

const screenshotDir = path.resolve(__dirname, '../results/screenshots/{feat-name}');

test.describe('{功能名称}', () => {
    test.beforeEach(async ({ page }) => {
        // 如需登录态
        await page.evaluate(() => {
            localStorage.setItem('token', 'test-token');
        });
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
            path: path.join(screenshotDir, '主流程-02-操作后.png'),
            fullPage: true,
        });

        // 3. 验证结果
        await expect(page.getByText('操作成功')).toBeVisible();
        await page.screenshot({
            path: path.join(screenshotDir, '主流程-03-操作成功.png'),
            fullPage: true,
        });
    });

    test('异常：{异常场景}', async ({ page }) => {
        await page.goto('/{route-path}');
        await page.waitForLoadState('networkidle');

        // 触发异常
        await page.getByRole('button', { name: '提交' }).click();

        // 验证错误提示
        await expect(page.getByText('请填写必填项')).toBeVisible();
        await page.screenshot({
            path: path.join(screenshotDir, '异常-01-空表单提交.png'),
            fullPage: true,
        });
    });
});
```

### 12.2 表单弹窗模板

```typescript
test('弹窗表单提交', async ({ page }) => {
    await page.goto('/goods/detail?id=123');
    await page.waitForLoadState('networkidle');

    // 打开弹窗
    await page.getByRole('button', { name: '议价' }).click();
    await expect(page.locator('.van-popup')).toBeVisible();
    await page.screenshot({
        path: path.join(screenshotDir, '议价-01-弹窗打开.png'),
        fullPage: true,
    });

    // 填写表单
    await page.getByPlaceholder('请输入期望价格').fill('500');
    await page.getByPlaceholder('请输入留言').fill('诚心购买');

    // 提交并等待 API 返回
    await Promise.all([
        page.waitForResponse('**/api/bargain/submit'),
        page.getByRole('button', { name: '确认提交' }).click(),
    ]);

    // 验证提交成功
    await expect(page.getByText('提交成功')).toBeVisible();
    await page.screenshot({
        path: path.join(screenshotDir, '议价-02-提交成功.png'),
        fullPage: true,
    });
});
```

### 12.3 列表搜索模板

```typescript
test('搜索商品', async ({ page }) => {
    await page.goto('/goods/list');
    await page.waitForLoadState('networkidle');
    await page.screenshot({
        path: path.join(screenshotDir, '搜索-01-初始列表.png'),
        fullPage: true,
    });

    // 输入搜索关键词
    await page.getByPlaceholder('搜索商品').fill('王者荣耀');
    await Promise.all([
        page.waitForResponse('**/api/goods/search**'),
        page.getByRole('button', { name: '搜索' }).click(),
    ]);

    // 验证搜索结果
    await expect(page.getByTestId('goods-item')).toHaveCount(10);
    await page.screenshot({
        path: path.join(screenshotDir, '搜索-02-搜索结果.png'),
        fullPage: true,
    });
});
```

---

## 十三、报告产出

### 13.1 E2E 报告文件

每次执行 `/lc-feat:e2e <feat-name>` 后生成：

```
docs/pipeline/{feat-name}/e2e-report.md
```

### 13.2 报告格式

```markdown
# {功能名称} E2E 测试报告

## 测试日期: 2026-05-25
## 测试框架: Playwright
## 设备模拟: Pixel 5 (Mobile Chrome)

## 测试概览
- 测试用例: 4 个
- 通过: 4 ✅
- 失败: 0 ❌
- 截图数量: 12 张
- 执行耗时: 8.5s

## 测试用例清单
| 用例名称 | 状态 | 耗时 | 截图数 |
|---------|------|------|--------|
| ��流程：议价提交 | ✅ | 3.2s | 3 |
| 异常：空价格提交 | ✅ | 1.8s | 2 |
| 边界：最大价格 | ✅ | 2.1s | 2 |
| 边界：重复提交 | ✅ | 1.4s | 2 |

## 截图索引
| 步骤 | 截图 | 说明 |
|------|------|------|
| 页面加载 | screenshots/3.37-bargain/主流程-01-页面加载.png | 商品详情页 |
| 弹窗打开 | screenshots/3.37-bargain/主流程-02-弹窗打开.png | 议价弹窗 |
| ... | ... | ... |
```

### 13.3 查看 HTML 报告

```bash
cd tests/e2e && npx playwright show-report report
```

---

## 十四、日常命令速查

### 开发阶段

```bash
# 检查环境是否就绪
cd tests/e2e && npx playwright test --list

# 执行所有测试
cd tests/e2e && npx playwright test

# 执行单个文件
cd tests/e2e && npx playwright test specs/3.37-bargain.spec.ts

# 重跑上次失败
cd tests/e2e && npx playwright test --last-failed

# 带浏览器界面调试
cd tests/e2e && npx playwright test --headed

# 查看报告
cd tests/e2e && npx playwright show-report report
```

### lc-feat Pipeline 中

```bash
# 完整流水线
/lc-feat:pipeline 3.37-bargain

# 只跑 E2E
/lc-feat:e2e 3.37-bargain

# 从 E2E 步骤恢复
/lc-feat:pipeline 3.37-bargain --from=e2e
```

### 环境问题排查

```bash
# Chromium 未安装
cd tests/e2e && npx playwright install chromium

# 查看已安装浏览器
npx playwright install --dry-run

# Dev server 未启动（通常不需要手动启动，config 会自动处理）
npm run start:dev
```

---

## 附录：快速检查清单

在执行 E2E 测试前确认：

- [x] `tests/e2e/node_modules/@playwright/test` 已安装
- [x] `npx playwright install chromium` 已执行
- [x] `tests/e2e/playwright.config.ts` 配置正确（端口、设备）
- [x] `tests/e2e/.gitignore` 忽略了 `node_modules/`、`results/`、`report/`
- [ ] Dev server 已启动（或 config 中 webServer 会自动启动）
- [ ] 需求/设计文档存在于 `docs/pipeline/{feat-name}/`（Pipeline 模式需要）

---

*基于 vue3-nuxt3-claude-test-workflow v1.1 + lc-feat-e2e v0.0.3 整合*
