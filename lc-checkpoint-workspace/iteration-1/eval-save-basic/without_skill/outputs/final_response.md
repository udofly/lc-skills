进度已保存到检查点文件：`docs/checkpoints/2026-07-14-登录重构.md`

**记录内容摘要：**

- **分支**：`feature/login-refactor`（基线提交 `5294fcc`）
- **改动**：
  - `src/auth.ts`（修改）：`login()` 改为接收 token 并调用新增的 `verify()`
  - `src/session.ts`（新增，已暂存）：定义 `SESSION_TTL = 3600`
- **已定决策**：token 校验先做长度非空的占位实现，后续换 JWT
- **剩余工作**：
  1. `verify()` 接入真实 JWT 库
  2. `session.ts` 加过期刷新逻辑
  3. 补单元测试

检查点里附了关键代码快照和恢复步骤，下次打开会话直接读这个文件即可从「verify 接 JWT 库」继续。工作区的未提交改动我没有动，保持原样。
