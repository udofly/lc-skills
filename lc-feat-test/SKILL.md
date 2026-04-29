---
name: lc-feat-test
description: 测试技能。仅针对页面新增的核心函数（纯函数、工具函数、常量）编写单测，无符合条件的函数则跳过。当用户说"写测试"、"测试用例"、"跑测试"时触发。
license: MIT
metadata:
  author: kejinshou-team
  version: "0.0.2"
---

# 自动化单元测试

根据需求文档和实现代码，**自动编写测试用例、自动执行、自动修复失败用例**。

---

**Input**: `/lc-feat:test <feat-name>`

## 测试范围规则（重要）

**页面级功能开发的测试原则：只测新增的核心函数，不测页面组件本身。**

### 什么是"核心函数"
- 新增的**纯函数**（如 label 映射、数据格式化、枚举转换）
- 新增的**工具函数**（如计算、校验、数据变换）
- 新增的**常量文件**（验证结构完整性、值正确性）

### 什么不测
- Vue 页面组件的渲染、交互、弹窗流程（需要完整的组件挂载环境和 UI 库 mock，投入产出比低）
- Service 层的 API 封装函数（只是 request 的简单包装，无逻辑可测）
- 路由配置、权限配置（静态声明，无逻辑）

### 跳过条件
如果本次改动**没有新增符合条件的核心函数**（例如只是在现有页面中追加模板和配置，没有独立的纯函数），则：
- 直接跳过测试步骤，标记为 `skipped`
- 在 `test-report.md` 中说明跳过原因："本次改动无新增核心函数，测试跳过"
- 不要强行为 Service 封装函数或 Vue 组件写无意义的测试

---

**Steps**

1. **环境检测**

   在编写任何测试前，必须先确认项目的测试能力：

   ```bash
   # 检查 vitest 是否可用
   npx vitest --version 2>&1
   ```

   如果 vitest 不可用，检查 jest：
   ```bash
   npx jest --version 2>&1
   ```

   如果两者都不可用，提示用户安装并停止：
   > "项目未配置测试框架。建议执行 `npm install -D vitest @vue/test-utils happy-dom` 后重试。"

   ### 1.1 检查 @vue/test-utils

   ```bash
   ls node_modules/@vue/test-utils/package.json 2>/dev/null
   ```

   如果不存在，自动安装（需用户确认）：
   > "项目缺少 @vue/test-utils，需要安装才能测试 Vue 组件。是否执行 `npm install -D @vue/test-utils`？"

   ### 1.2 检测测试配置

   读取 `vite.config.ts` 或 `vitest.config.ts` 中的 test 配置，确认：
   - test.environment（happy-dom / jsdom）
   - coverage 配置
   - 测试文件存放约定

   ### 1.3 检测已有测试文件

   ```bash
   find src -name "*.test.ts" -o -name "*.spec.ts" -o -name "*.test.vue" 2>/dev/null | head -5
   ```

   如果有已有测试文件，读取一个作为风格参考。
   如果没有，使用默认风格。

2. **加载上下文**

   并行读取：
   - `docs/pipeline/{feat-name}/requirement.md` — 需求（测试依据）
   - `docs/pipeline/{feat-name}/design.md` — 设计（技术实现细节，如存在）
   - 功能涉及的所有源代码文件（从 design.md 的文件清单或 `git diff --name-only master` 获取）

3. **制定测试策略**

   根据改动文件类型和需求类型，确定测试范围：

   ### 3.1 按文件类型分配测试重点

   | 文件类型 | 测试重点 | 优先级 |
   |---------|---------|--------|
   | Vue 组件（.vue） | 渲染、props、事件、插槽 | 高 |
   | 请求层（MwpXxx.ts） | 接口调用参数、响应处理 | 高 |
   | 工具函数（utils/） | 输入输出、边界值 | 高 |
   | 路由配置 | 路由注册、导航守卫 | 低 |
   | 样式文件 | 不测试 | — |

   ### 3.2 按需求类型分配测试策略

   | 需求类型 | 测试策略 |
   |---------|---------|
   | **新功能** | 新组件渲染测试 + 交互测试 + 接口 mock 测试 |
   | **功能扩展** | 新增分支测试 + 回归测试（确保原有逻辑不变） |
   | **Bug 修复** | 复现 bug 的测试（修复前应失败）+ 修复验证 |

   ### 3.3 确定测试文件位置

   优先与源文件同级：`src/views/goods/components/DialogGoodsQrCode.test.ts`
   如果项目有 `__tests__/` 目录约定则遵循。

4. **生成测试文件**

   ### 4.1 测试文件模板

   ```typescript
   import { describe, it, expect, vi, beforeEach } from 'vitest';
   import { mount, flushPromises } from '@vue/test-utils';
   // 按需导入被测组件和依赖

   // Mock 外部依赖
   vi.mock('@/request/MwpProduct', () => ({
       mwpProductCollectSubmitQrCode: vi.fn(),
   }));

   describe('ComponentName', () => {
       beforeEach(() => {
           vi.clearAllMocks();
       });

       // 渲染测试
       it('should render correctly with default props', () => { ... });

       // Props 测试
       it('should display QR code when qrCodeUrl is provided', () => { ... });

       // 事件测试
       it('should emit close when clicking 稍后授权', async () => { ... });

       // 接口调用测试
       it('should call API with correct params on submit', async () => { ... });

       // 边界测试
       it('should show error state when image fails to load', () => { ... });
   });
   ```

   ### 4.2 测试编写规则

   - **必须 mock 所有外部依赖**（API 调用、router、store）
   - **不 mock 组件内部逻辑**
   - **每个 it 只测一个行为**
   - **断言具体值**，不写 `expect(x).toBeTruthy()` 这种模糊断言
   - **测试用户行为而非实现细节**（测"点击按钮后弹窗关闭"而非"调用了 closeModal 方法"）

5. **执行测试**

   ```bash
   npx vitest run {测试文件路径} --reporter=verbose 2>&1
   ```

   ### 5.1 全部通过 → 继续
   ### 5.2 有失败 → 自动诊断修复

   对每个失败用例：

   1. **判断失败原因**：
      - 测试代码问题（mock 不完整、断言写错）→ 修复测试代码
      - 源代码 bug → 记录到报告，不修改源代码
      - 环境问题（缺少 polyfill 等）→ 添加必要的 setup

   2. **修复后重新执行**，最多重试 3 轮

   3. **仍然失败的**：标记到报告中，不无限重试

6. **执行回归测试（如有已有测试）**

   如果项目中有其他测试文件，运行全量测试确认没有引入回归：

   ```bash
   npx vitest run --reporter=verbose 2>&1
   ```

   - 全部通过 → 记录到报告
   - 有失败 → 区分是本次改动引起的还是原有失败
     - 本次引起的 → 标记为阻塞问题
     - 原有失败 → 记录但不阻塞

7. **生成测试报告**

   在 `docs/pipeline/{feat-name}/` 下生成 `test-report.md`：

   ```markdown
   # {功能名称} 测试报告

   ## 测试日期: {YYYY-MM-DD}
   ## 测试框架: Vitest {version}

   ## 测试概览
   - 新增用例: {N} 个
   - 通过: {N}
   - 失败: {N}（已修复 {M} 个）
   - 回归测试: {通过/有问题/无已有测试}

   ## 测试用例清单
   | 文件 | 用例名称 | 状态 | 类型 |
   |------|---------|------|------|
   | {file} | {test name} | 通过/失败 | 渲染/交互/接口/边界 |

   ## 失败用例分析（未修复）
   | 用例 | 失败原因 | 类型 | 建议 |
   |------|---------|------|------|
   | {name} | {reason} | 测试问题/源码bug | {建议} |

   ## 覆盖率（如可用）
   | 文件 | 行覆盖 | 分支覆盖 | 函数覆盖 |
   |------|--------|---------|---------|

   ## 未覆盖场景
   - {场景描述}（原因：{说明}）
   ```

8. **质量门控**

   ### 通过条件
   - 新增测试用例全部通过
   - 回归测试无本次改动引起的失败

   ### 阻塞条件
   - 有测试用例反复失败（3 轮修复后仍失败）
   - 回归测试中有本次改动引起的失败

   阻塞时输出：
   > "测试发现 {N} 个问题需处理（详见 test-report.md）。其中 {M} 个可能是源代码 bug。"

**Guardrails**
- **必须先检测环境**，vitest 不可用时不强行写测试
- **必须实际执行测试**（`npx vitest run`），不能只写不跑
- Mock 外部依赖（API、router、store），不 mock 组件内部逻辑
- 每个测试用例必须有明确的断言，不写 `toBeTruthy()` 之类的模糊断言
- 测试文件命名和存放位置遵循项目已有规范
- 失败用例优先修复测试代码，不随意修改源代码
- 回归测试失败需区分责任（本次 vs 原有）
- 最多重试 3 轮，不无限循环修复
