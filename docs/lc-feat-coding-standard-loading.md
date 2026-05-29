# 加载项目编码规范（共享流程）

> 本文档定义了 lc-feat 流水线中各 skill 加载项目编码规范的标准流程。
> 被引用于：pipeline、implement、design、qa

---

## 加载流程

1. 读取项目 `.claude/CLAUDE.md`（如存在）— 获取项目指定的编码规范 skill 名称
2. 如果其中提到的编码规范 skill 在当前可用技能列表中存在，**加载该技能的完整规范**
3. 如果 CLAUDE.md 未指定，根据项目目录结构自动匹配下表：

## 项目→Skill 映射表（硬性约束）

| 项目类型 | 判断依据 | 必须使用的 skill |
|---------|---------|-----------------|
| H5 Vue 移动端（如 kejinshou_m） | `src/views/` + Vant 依赖 | `lc-kejinshou-h5-vue` |
| H5 Nuxt 项目 | `nuxt.config.ts` 存在 | `lc-kejinshou-h5-nuxt` |
| Backend 后台项目（如 backend-kejinshou） | `src/pages/` + KR36 依赖 | `lc-kejinshou-backend-page` |

4. 如果映射表中没有匹配的项目类型，通过 `package.json` 和 `src/` 目录结构自行判断

## 阻断规则（仅 implement 和 pipeline 的编码阶段适用）

> ⛔ **在 Skill tool 调用返回结果之前，禁止编写任何业务代码。"已知规范内容"不能替代实际调用——每次编码都必须产生一次 Skill tool call。**

## 各 skill 的使用方式

| Skill | 用途 | 是否必须 Skill tool call |
|-------|------|------------------------|
| pipeline (Step 3) | 编码前加载规范 | ⛔ 必须（阻断） |
| implement (Step 3) | 编码前加载规范 | ⛔ 必须（阻断） |
| design (Step 2) | 设计时参考规范（含自审） | 建议加载，非阻断 |
| verify (Step 2) | 验证检查标准 | 建议加载，非阻断 |
