---
name: lc-seo-page-rewrite
description: SEO 页面改写技能（kejinshou_m → h5-nuxt）。用户给一个路由（如 /intro/judicial），自动探索 kejinshou_m（SPA）中该页面的完整实现，在 h5-nuxt 中走 lc-feat 流水线完成 SEO 重写——功能完全一致、界面体验完全一致、实现尽可能符合 SEO（SSR + 语义化 HTML + 完整 TDK）。当用户说"seo改写"、"seo重写"、"把 xx 路由/页面迁到 nuxt"、"用 nuxt 重写 xx 页面"、"m站页面搬到 nuxt"、"xx 页面要能被百度/搜索引擎收录"并给出路由时触发；只要涉及把 kejinshou_m 现有页面迁移/重写到 h5-nuxt（即使没提"SEO"），都应使用本技能。
license: MIT
metadata:
  author: kejinshou-team
  version: "0.1.0"
  source_project: "/Users/gaochunfa/project/project_fe/kejinshou/kejinshou_m"
  target_project: "h5-nuxt（在 h5-nuxt 项目内调用本技能）"
---

# SEO 页面改写（kejinshou_m → h5-nuxt）

给定一个路由，从 kejinshou_m（Vue 3 SPA，无 SSR）完整还原页面的功能与视觉，在 h5-nuxt（Nuxt 3 SSR）中重写为 SEO 友好实现，并接入 lc-feat 流水线管理全流程。

**三条铁律（优先级从高到低）**：
1. **功能完全一致**——交互、跳转、登录态分支、query 参数、埋点事件名，逐项与源页面对照，一个不落
2. **界面体验完全一致**——视觉 1:1 还原（布局、配色、渐变、圆角、动效），用户看不出差别
3. **实现尽可能符合 SEO**——在 1、2 前提下：SSR 直出、图片文案转语义化 HTML、完整 TDK、唯一 h1

---

**Input**: `/lc-seo-page-rewrite <route> [--until=<step>] [--auto] [pipeline 其余参数]`

- `<route>`: kejinshou_m 中的路由路径（必填），如 `/intro/judicial`、`/intro/transfer`
- 其余参数原样透传给 `/lc-feat:pipeline`（`--until=design` 白天只出设计、`--auto` 全自动等）
- 功能名从路由取末段 kebab-case（`/intro/judicial` → `judicial-page`），流水线目录遵循 pipeline skill 的分支归档规则 `docs/pipeline/{branch-name}/{pipeline-name}/`

**Steps**

1. **前置检查**

   - 确认当前在 h5-nuxt 项目内、源项目路径存在（见 frontmatter `source_project`）
   - 检查 h5-nuxt 是否已存在该路由页面（`pages/` 目录 + `app/router.options.ts`）：已存在 → 提示用户是重写还是放弃
   - 检查 `composables/usePageUtil.ts` 是否已预留该路由的 URL 函数（多数介绍页已预留，说明站内入口已就位）

2. **源页面探索（kejinshou_m）**

   使用 **Explore agent（very thorough）** 探索源项目，必须查明：
   - **路由定义**：`src/router/index.ts` + `src/router/routerKey.ts` 中该路径的组件、meta.title、auth
   - **页面组件全文**：template 结构、script 逻辑、scoped 样式（含 CSS 变量 `--app-width`/`--k-page-margin` 用法）
   - **子组件与第三方库**：逐个列出（XNavBar、Vue3SeamlessScroll 之类），记录 props/事件
   - **静态资源**：`src/utils/cons.ts` 的 `kjsCdnResources` 中该页面的全部 CDN 图片 URL + ossStyle 处理方式
   - **接口**：`src/services/` 下的调用（URL、方法、参数、返回结构）
   - **交互清单**：每个可点击元素 → 跳转目标/行为，含 query 参数（`is_back` 等）、登录态分支（isLogin/jumpAppLogin）、UA 分支（isFromAndroidApp/isFromAppFinish）、埋点（gEvent 事件名）
   - **store 依赖**：poppy/user 等 store 的具体取值路径（如 `core.same.xxx`）
   - **入口引用**：该路由被哪些页面链接（评估切流影响面）

3. **图片文案提取（SEO 语义化的关键，不可跳过）**

   源页面内容多由 CDN 大图承载。对每张**含文案的**内容图：
   - `curl` 下载到临时目录，用 **Read tool 读取图片**，提取全部文字（标题、段落、列表、Q&A、小字注释）
   - 记录图片尺寸（源图通常 1500px 宽 = 375 设计稿 4x，裁切分辨率足够）
   - **小字/注释 OCR 不清晰的，必须在 spec 中标注「实现时放大原图逐字复核」**，禁止编造文案
   - 产出**图片素材清单**三分类：
     1. **必须切图**：照片、插画、图标（CSS 无法还原）——列建议文件名与尺寸；理想为设计出透明底，无设计资源时可从原图按坐标直裁（背景同色可无缝衔接）
     2. **原样复用**：本身独立成图的（如整图按钮），直接用现有 CDN URL
     3. **CSS 还原**：渐变背景、卡片、徽章、按钮、标签等——不切图

4. **SPA → Nuxt 等价映射（硬性对照表）**

   设计与编码时按此表替换，**禁止把 SPA 的模式带进 Nuxt**：

   | kejinshou_m（源） | h5-nuxt（目标） |
   |------------------|----------------|
   | XNavBar | KrNavBar（title-tag 可设 h1/h2） |
   | routerName/routerKey 路由 | `pages/` 文件路由（自定义 URL 才用 `app/router.options.ts`） |
   | `src/services/` + request() | `utils/services/v2/`：setup 用 `useAppFetch`（SSR），事件回调用 `appFetch` |
   | kjsCdnResources（cons.ts） | `utils/cons.ts` 的 `ossImageUrl` 登记，或本地 `public/app-nuxt/image/{page}/` |
   | isLogin/userToLogin + jumpAppLogin 分支 | `useAppUserUtil` 的 `isLogin()`（参照 `pages/p/app-intro/index.vue` 的 jumpKf 范式，不复刻 jumpAppLogin） |
   | goKf(router, params) | h5-nuxt `utils/utils.ts` 的 `goKf`（已存在，直接用） |
   | emitter APP_CALL_WEB token 监听 | **不复刻**——`useAppToken` 全局统一处理 |
   | gEvent 埋点 | `v-tongji` 指令，**事件名保持与源页一致** |
   | vue3-seamless-scroll 等客户端 DOM 库 | 优先 CSS 实现（keyframes 双份列表 + aria-hidden 副本）；确实需要库才 ClientOnly 包裹 |
   | document.title（路由 meta） | `<Head>` + `<Title>` + `<Meta>` 完整 TDK |
   | setLastInterRefer 等 SPA 内部归因 | 检查 h5-nuxt 有无对应实现，无则跳过并记录 decision |
   | poppy store 取值路径 | 同源数据，取值路径可直接沿用 |

5. **SEO 实现要求（写入设计并落实）**

   - **TDK**：Title 格式 `{页面关键词}_{扩展关键词} - 氪金兽`；keywords/description 基于提取的图片文案撰写
   - **标题层级**：唯一 h1（页面主标题，通常是 hero 标题而非导航栏）；区块标题 h2；子项 h3
   - **SSR 数据**：首屏/列表数据在 setup 阶段 IIFE + `useAppFetch` 直出，禁止挪到 onMounted
   - **图片**：alt 按区块语义细化（不要全页同一个 alt）；首屏图不懒加载（LCP），折下图片用项目懒加载插件
   - **canonical**：沿用 `layouts/default.vue` 全局逻辑，遵守 `tests/seo/canonical-mobile.test.ts` 约定
   - **禁止**：隐藏文本/堆砌关键词（cloaking 风险）；为 SEO 改变可见文案（与铁律 2 冲突）

6. **接入流水线**

   以上述探索产出为需求输入，执行 `/lc-feat:pipeline` 逻辑（透传用户参数）：
   - spec「一、需求」必须包含：**功能对照清单**（源页面逐交互项 → 目标行为）、图片文案还原、案例/列表数据字段
   - spec「二、设计」必须包含：等价映射后的改动文件清单、图片素材清单（三分类）、TDK 设计、**部署切流注意事项**
   - 编码阶段照常受 pipeline 阻断规则约束：**必须 Skill tool 调用 `lc-kejinshou-h5-nuxt`**
   - E2E/验证阶段建议：本地页面截图与源页面线上截图并排对比（视觉一致性验收）

7. **固定注意事项（每次都要写进 spec 的"注意事项"）**

   - **部署切流**：该路由当前由 kejinshou_m 承载（同域名），上线需网关/nginx 将路径切流到 h5-nuxt，需运维协同；切流前新旧并存，注意不要提前对外暴露链接
   - **PC 450px 适配**：`_pc-adapt.less` 自动生效，但 `position: fixed` 元素需按既有模式做居中修正（`left: 50%` + 负 margin）
   - 源页 scoped 样式中的 `--app-width` 计算式换算为 h5-nuxt 的 px/变量体系
   - scroll 监听等客户端逻辑：`onMounted` 注册 + `onBeforeUnmount` 清理

**Guardrails**
- **三条铁律不可妥协**；功能与视觉一致性优先于 SEO 技巧
- 含文案的内容图**必须下载并 Read 提取文字**，不得凭截图缩略猜测；不清晰处标注复核，禁止编造
- 探索必须完整覆盖：路由、组件、资源、接口、交互、store、入口引用，缺一项不得进入设计
- 等价映射表为硬性约束，发现表中未覆盖的 SPA 模式时：在 h5-nuxt 中找同类页面的既有做法（优先参照 `pages/p/app-intro`），找不到再设计新方案并记录 decision
- 不新增第三方依赖，除非 CSS/既有能力确实无法实现且经用户确认
- 流水线规则全部继承（分支归档目录、编码前 Skill 调用、files_changed 回写、不做 git 操作）
- 部署切流提醒必须出现在设计文档与功能完成总结中

---

## 使用示例

```bash
# 白天只出需求+设计（推荐首次）
用户：/lc-seo-page-rewrite /intro/transfer --until=design

AI：1. 检查 h5-nuxt 无 /intro/transfer 页面，usePageUtil 已预留 h5vIntroTransferUrl ✅
    2. [Explore] kejinshou_m 源页面：路由/组件/图片/接口/交互清单...
    3. 下载 N 张内容图，提取文案，产出素材三分类清单
    4. 接入流水线 docs/pipeline/{branch}/{pipeline}/spec-1-transfer-page.md
    5. 展示需求+设计合并审核（含功能对照清单、TDK、切流提醒）

# 全自动完整跑
用户：/lc-seo-page-rewrite /intro/indemnity-list --auto
```
