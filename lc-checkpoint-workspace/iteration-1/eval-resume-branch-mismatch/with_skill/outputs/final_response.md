📌 恢复检查点
标题：  API 列表分页
分支：  feature/api-pagination
保存于：2026-07-10 10:15（周五）
状态：  in-progress

### Summary

给列表接口加游标分页，前端 Pager 组件已完成，后端联调到一半。

### Remaining Work

1. src/api/list.ts 处理 next_cursor 为空的边界
2. Pager 组件 loading 态防抖
3. 补分页 e2e 用例

### Notes

- 测试环境接口偶发 502，重试即可

⚠️ 此检查点保存于分支 `feature/api-pagination`，你当前在 `master`，继续前可能需要切换分支。

接下来你想怎么做？
A) 继续做剩余工作 —— 从第 1 项开始：处理 src/api/list.ts 中 next_cursor 为空的边界
B) 查看检查点原文
C) 只是要上下文，不用动手
