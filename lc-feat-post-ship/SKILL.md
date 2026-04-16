---
name: lc-feat-post-ship
description: 发布后处理技能。PR合并后执行文档更新、CHANGELOG记录、pipeline产物归档、CLAUDE.md同步等收尾工作。联动gstack /document-release。当用户说"发布完了"、"PR合并了"、"更新文档"、"收尾"时触发。
license: MIT
metadata:
  author: kejinshou-team
  version: "0.0.1"
---

# 发布后处理

PR 合并后的收尾工作：文档更新、产物归档、项目配置同步。

---

**Input**: `/lc-feat:post-ship <feat-name>`

**Steps**

1. **确认 PR 已合并**

   检查功能分支状态：
   ```bash
   gh pr list --search "feat/{feat-name}" --state merged
   ```

   如果 PR 未合并，使用 **AskUserQuestion tool** 确认。

2. **联动 gstack /document-release**

   调用 gstack 的 `/document-release` skill 逻辑，自动完成：
   - 读取本次变更的 diff
   - 检查并更新 README.md（如有相关内容）
   - 检查并更新 CLAUDE.md（如新增了模块、路由等）
   - 更新 CHANGELOG.md（如项目有维护）

3. **更新 CLAUDE.md**

   根据项目类型检查本次功能是否需要更新项目文档：
   - 新增了业务模块 → 更新模块列表
   - 新增了路由 → 更新路由说明
   - 新增了 Service/Request → 更新项目结构说明

4. **归档 pipeline 产物**

   将 `docs/pipeline/{feat-name}/` 下的产物整理：
   - 更新 `pipeline-status.md`，标记所有步骤为"已完成"
   - 追加发布信息（PR URL、合并时间、分支）

5. **清理 mock 标记提醒**

   扫描功能代码中是否还有 `// TODO: 替换为真实接口` 的标记。
   如果发现，提醒使用 `/lc-feat:api-sync` 替换。

6. **写入 Memory（经验积累）**

   读取 `docs/pipeline/{feat-name}/progress.yaml` 中的 `decisions` 数组，将有跨项目价值的决策写入 Claude Memory：

   ### 6.1 project 类型 Memory
   - 功能名称、涉及模块、完成日期
   - 例：`xiaosuan-qr 功能（商品上架验证码+二维码）已于 2026-04-15 完成`

   ### 6.2 feedback 类型 Memory
   - 用户在流水线中的关键偏好和反馈
   - 例：`用户偏好新建独立组件而非复用耦合组件`

   ### 6.3 筛选规则
   - 只写入**跨项目/跨会话有价值**的信息
   - 不写入：具体文件路径、代码片段、接口细节、临时 mock 数据
   - 不写入：已经可以从代码/git 推导出的信息

7. **更新 progress.yaml**

   将 `docs/pipeline/{feat-name}/progress.yaml` 中所有步骤标记为 `done`，追加发布信息。

8. **生成发布总结**

   在 `docs/pipeline/{feat-name}/` 下生成 `post-ship.md`。

9. **输出结果**

**Guardrails**
- 不要删除 pipeline 产物文件，它们是项目的开发记录
- CLAUDE.md 更新必须谨慎，只添加确实需要的信息
- 如果检测到 mock 未替换，只提醒不自动替换
- 文档更新使用 Edit tool，不要覆盖写入
