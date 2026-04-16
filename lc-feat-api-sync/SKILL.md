---
name: lc-feat-api-sync
description: 接口同步技能。当真实接口就绪后，从Apifox MCP读取接口定义，替换代码中的mock数据为真实接口调用。当用户说"接口来了"、"替换mock"、"同步接口"、"接口对接"时触发。
license: MIT
metadata:
  author: kejinshou-team
  version: "0.0.1"
---

# Mock 转真实接口

接口就绪后，从 Apifox MCP 读取接口定义，替换 mock 数据为真实接口调用。

---

**Input**: `/lc-feat:api-sync <feat-name> [接口模块名或关键词]`

**Steps**

1. **检测项目类型**

   通过读取 `package.json` 和 `src/` 目录结构判断项目类型，确定接口层的位置和模式：
   - H5 移动端：`src/request/MwpXxx.ts` + `src/request/MwpApi.ts`
   - 后台管理：`src/services/{module}/index.ts` + `ApiUrl` 模式

2. **扫描现有 mock 标记**

   在功能相关代码中查找所有 mock 标记：
   ```
   // TODO: 替换为真实接口
   ```

   根据项目类型确定扫描范围：
   - H5 项目：`src/request/`、`src/views/`、`src/components/`
   - 后台项目：`src/services/{module}/`、`src/pages/{module}/`

3. **从 Apifox 获取接口**

   使用 Apifox MCP 工具获取接口定义（工具名从当前可用的 apifox MCP 工具列表中选取）。

   如果 Apifox 中找不到对应接口，使用 **AskUserQuestion tool** 询问用户。

4. **接口映射**

   将 Apifox 接口与 mock 逐一映射，使用 **AskUserQuestion tool** 确认映射关系。

5. **替换接口层**

   根据项目类型执行替换：

   ### H5 移动端项目
   - 在 `src/request/MwpApi.ts` 中添加 API 枚举
   - 在 `src/request/MwpXxx.ts` 中添加请求函数
   - 更新页面/组件中的接口调用

   ### 后台管理项目
   - 更新 `src/services/{module}/index.ts` 中的 ApiUrl 和请求函数
   - 更新 TypeScript 类型定义

6. **替换页面中的内联 mock**

   如果页面组件中有内联的 mock 数据，替换为接口调用。

7. **移除所有 TODO 标记**

8. **验证**

   替换完成后：
   - 再次扫描确认无遗留 mock 标记
   - 运行 TypeScript 类型检查确保类型匹配

9. **生成同步报告**

   在 `docs/pipeline/{feat-name}/` 下生成 `api-sync-report.md`。

10. **输出结果**

    使用 **AskUserQuestion tool** 展示替换结果。

**Guardrails**
- 替换前必须与用户确认接口映射关系，不能盲目替换
- 保留未找到接口的 mock，不要删除
- 替换时不能改变业务逻辑，只替换数据来源
- TypeScript 类型必须与接口响应结构匹配
- **根据项目类型使用对应的接口层模式**，不要混用
- 替换完成后必须运行类型检查
