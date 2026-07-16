---
name: lc-kejinshou-h5-nuxt
description: 氪金兽 H5 Nuxt 项目编码规范。在 h5-nuxt 项目中开发、重构或审查代码时必须应用此技能。当工作目录为 h5-nuxt 且涉及 Vue 组件、请求层（useMwpRequest/useAppFetch）、路由、样式、SSR/SEO（TDK、预渲染、chunk error 防护）、composables、Pinia、Nuxt 配置等编码时自动触发，即使用户没有明确要求加载规范。
license: MIT
metadata:
  author: kejinshou-team
  version: "2.1"
  project: h5-nuxt
---

# 氪金兽 H5 Nuxt 编码规范

> 本技能定义编码约束和项目特有模式。目录结构、环境配置等基础信息见 CLAUDE.md，此处不再重复。

---

## 1. Vue 组件规范

### 1.1 基本结构

所有组件必须使用 `<script setup lang="ts">` + Composition API：

```vue
<template>
    <Head>
        <Title>{{ pageTitle }}</Title>
        <Meta name="keywords" :content="keywords" />
        <Meta name="description" :content="description" />
    </Head>
    <NuxtLayout name="layoutName">
        <main class="PageName">
            <!-- 页面内容 -->
        </main>
    </NuxtLayout>
</template>

<script setup lang="ts">
// 1. 外部库导入
import { get, truncate } from 'lodash-es'

// 2. 类型导入
import type { GameDetailInfo } from '~/utils/types/category'

// 3. 服务层导入
import { reqV2MarketContentDetail } from '~/utils/services/v2/market'

// 4. 工具/常量导入
import { copyText, sentryEmits } from '~/utils/utils'

// 5. 组合式函数（自动导入，无需显式 import）
// useAppFetch, useAppStore, useRouter 等均自动可用

// --- 初始化 ---
const router = useRouter()
const appStore = useAppStore()

// --- reactive 用于复杂对象状态，变量名统一为 trans ---
const trans = reactive({
    data: {},
    loading: false,
    page: 1,
})

// --- ref 用于简单状态 ---
const listData = ref([])

// --- computed ---
const displayName = computed(() => get(trans.data, 'title', ''))

// --- 数据获取：setup 阶段使用 IIFE ---
;(async () => {
    const { data } = await reqV2MarketContentDetail({ id: 1 })
    const status = get(data.value, 'status')
    if (status != 0) {
        toast(get(data.value, 'message', ''))
        return
    }
    trans.data = data.value?.data
})()

// --- watch ---
watch(
    () => appStore.latestGameId,
    (newValue) => {
        if (newValue) fetchData()
    },
)

// --- 业务方法 ---
const fetchData = async () => {
    // ...
}

// --- 生命周期 ---
onMounted(() => {
    // 仅客户端初始化
})
</script>

<style lang="less" scoped>
@import "pageName";
</style>
```

### 1.2 关键约定

| 约定 | 说明 |
|------|------|
| 复杂状态变量名 | 统一使用 `trans`（`reactive({ ... })`） |
| 简单状态 | 使用 `ref()` |
| 属性访问 | **必须**使用 lodash `get(obj, 'path', defaultValue)` 做安全访问 |
| 导入路径 | 全部使用 `~/` 前缀（Nuxt 别名），**禁止** `@/` 和相对路径 |
| setup 阶段数据获取 | 使用 IIFE `(async () => { ... })()` 模式 |
| SSR 检查 | 客户端逻辑使用 `if (import.meta.client)` 保护 |
| 服务端检查 | 服务端逻辑使用 `if (import.meta.server)` 保护 |
| SEO | 页面必须包含 `<Head>` + `<Title>` + `<Meta>` |
| 代码缩进 | **4 空格**缩进 |
| 引号 | **单引号** |
| 分号 | **无分号** |

> 存量代码中仍有少量分号和 `@/` 导入（历史遗留，约占 15%）。修改老文件时，新增/改动的行遵循上述规范即可，不要为统一风格大规模重排无关代码。

### 1.3 KeepAlive 排除

`app.vue` 中配置了 KeepAlive，LoginPage、ResetPwdPage、TiebaSearchPage 被排除缓存：

```vue
<NuxtPage :keepalive="{ exclude: ['LoginPage', 'ResetPwdPage', 'TiebaSearchPage'] }" />
```

需要排除缓存的页面，在 `definePageMeta` 中设置组件名后加入 exclude 列表。

---

## 2. UI 组件库

### 2.1 Vant 组件（通过 @vant/nuxt 自动注册）

```vue
<VanButton type="primary" size="large" @click="onSubmit">提交</VanButton>
<VanField v-model="trans.name" label="名称" placeholder="请输入" />
<VanPopup :show="trans.isShowPop" position="bottom" round @close="onClose" />
```

### 2.2 @nuxt/ui 组件

项目集成了 `@nuxt/ui`（v2），可使用 U 前缀组件。颜色配置在 `app.config.ts`：primary: blue, grey: grey。

### 2.3 自定义组件

组件按功能分目录放在 `components/` 下，Nuxt 自动导入，无需手动 import：

```vue
<BaseIconFont name="search" />
<InputSearch v-model="keyword" />
<FilterCategory :list="categories" />
```

### 2.4 提示方式

```typescript
import { showToast } from 'vant'

showToast('操作成功')
showToast({ message: '加载中...', type: 'loading' })

// 项目 toast 工具（在 utils.ts 中定义）
toast(message)
```

---

## 3. API 请求层规范

本项目有三套请求方式，按场景选择：

### 3.1 基础响应类型

```typescript
// utils/services/base.ts
export interface RespResult<T> {
    status: number
    message: string
    data?: T
}
```

### 3.2 MWP 协议请求（useMwpRequest）

适用于 MWP 协议接口，定义在 `utils/services/mwp/` 下：

```typescript
// utils/services/mwp/game.ts
import { useMwpRequest } from '~/composables/useMwpRequest'
import type { HeadersToPassthrough } from '~/plugins/types'
import type { RespResult } from '~/utils/services/base'

// API 路径定义：对象常量
const ApiMwpGame = {
    homeGameDetail: 'mwp.kjs_game.home.game.detail',
    gameList: 'mwp.kjs_game.game.list',
}

// 请求函数命名格式: req{Mwp}{Domain}{Action}
export const reqMwpGameHomeGameDetail = (
    params: object = {},
    mwpHeaders: Partial<HeadersToPassthrough> = {}
) => {
    return useMwpRequest<any>(ApiMwpGame.homeGameDetail, params, { method: 'get' }, mwpHeaders)
}
```

### 3.3 V2 HTTP 请求（useAppFetch / appFetch）

适用于标准 REST API，定义在 `utils/services/v2/` 下：

```typescript
// utils/services/v2/market.ts
import { appFetch, useAppFetch } from '~/composables/useAppFetch'

// API 路径定义
const Api = {
    contentDetail: 'api/market/content/detail',
}

// ★ setup 同步阶段使用 useAppFetch（基于 useFetch，支持 SSR）
export const reqV2MarketContentDetail = (params: ContentDetailParam) => {
    return useAppFetch<RespResult<ContentDetailDate>>(Api.contentDetail, {
        body: { ...params },
        method: 'post',
    })
}

// ★ 异步事件/onMounted 中使用 appFetch（命令式调用）
export const reqV2MarketConsultListDirect = (params: ConsultListParam) => {
    return appFetch<RespResult<ConsultListData>>(Api.consultList, {
        body: { ...params },
        method: 'post',
    })
}
```

### 3.4 IM 请求（useImRequest）

适用于 IM 即时通讯接口，带签名和 token 处理：

```typescript
import { useImRequest } from '~/composables/useImRequest'
```

### 3.5 useAppFetch vs appFetch 关键区别

| 特性 | `useAppFetch` | `appFetch` |
|------|---------------|------------|
| 底层 | Nuxt `useFetch` | 原生 `$fetch` |
| SSR | 支持（服务端+客户端） | 仅客户端 |
| 调用时机 | setup 同步阶段（顶层或 IIFE） | onMounted / 事件回调 |
| 返回值 | `{ data, pending, error }` ref | Promise 直接返回数据 |
| 适用场景 | 页面首屏数据、SEO 数据 | 交互触发的请求 |

### 3.6 类型定义（Model）

```typescript
// utils/services/model/market.ts
export interface ContentDetailParam {
    id: number
    [property: string]: any
}

export interface ContentDetailDate {
    cat_title: string
    content: string
    title: string
    [property: string]: any
}
```

**命名约定**：
- 请求参数：`{Name}Param` 后缀
- 响应数据：`{Name}Date` 后缀（注意：项目约定用 Date 而非 Data）
- 接口始终使用 `[property: string]: any` 保持扩展性

### 3.7 API 响应处理模板

```typescript
// 标准处理模式（setup 阶段）
;(async () => {
    const { data } = await reqApiName(params)
    const status = get(data.value, 'status')
    if (status != 0) {
        toast(get(data.value, 'message', ''))
        return
    }
    trans.data = get(data.value, 'data', {})
})()

// 标准处理模式（事件/onMounted）
const handleAction = async () => {
    const result = await reqApiNameDirect(params)
    if (get(result, 'status') != 0) {
        toast(get(result, 'message', ''))
        return
    }
    listData.value = get(result, 'data.list', [])
}
```

> **重要**：status 判断使用 `!= 0`（宽松比较），`get()` 始终带默认值。

---

## 4. 路由规范

### 4.1 基于文件的路由

Nuxt 自动从 `pages/` 目录生成路由。

### 4.2 自定义路由（app/router.options.ts）

部分路由通过 `app/router.options.ts` 手动定义，使用 `routerName` 常量（来自 `utils/cons.ts`）：

```typescript
import { routerName } from '~/utils/cons'

// 已定义的自定义路由名称：
routerName.goodsDetails     // 'goods.details'    → /goods/details/:id
routerName.estimateCreate   // 'estimate.create'  → /estimate/create_:id
routerName.estimateResult   // 'estimate.result'  → /report/:type/d_:id
routerName.estimateResultList // 'estimate.result-list' → /report/:id/:page?
```

其他自定义路由：`/zixun/:slug?/:id.html`、`/goods/:id/:cate_id?/:type?`、`/v2/login/:go?` 等。

### 4.3 页面导航

```typescript
const router = useRouter()
router.push('/goods/123')
router.push({ path: '/category', query: { game_id: '456' } })
router.back()

const route = useRoute()
const id = route.params.id
const gameId = route.query.game_id
```

### 4.4 路由中间件

```typescript
// middleware/auth.ts
export default defineNuxtRouteMiddleware((to, from) => {
    const userStore = useUserStore()
    if (!userStore.token) {
        return navigateTo('/my/login')
    }
})

// 页面中使用
definePageMeta({
    middleware: ['auth'],
})
```

---

## 5. Pinia 状态管理

### 5.1 Store 定义（Options API 模式）

```typescript
export const useAppStore = defineStore('_app', {
    state: () => ({
        latestGames: [] as AppSelectedGame[],
    }),
    getters: { /* ... */ },
    actions: { /* ... */ },
    persist: {
        storage: piniaPluginPersistedstate.localStorage(),
    },
})
```

### 5.2 MWP Store 的 Cookie 持久化

`stores/mwp.ts` 中的 store 使用 cookie 持久化（非 localStorage）：

```typescript
// 服务端 token — cookie, 7 天过期
persist: {
    storage: piniaPluginPersistedstate.cookies({ maxAge: 60 * 60 * 24 * 7 }),
}

// 客户端 token — cookie, session 级别
persist: {
    storage: piniaPluginPersistedstate.cookies(),
}
```

### 5.3 使用约定

- Nuxt 自动导入，无需 import
- 简单页面状态不要使用 Pinia，用组件内 `ref` / `reactive` 即可
- 仅在需要跨组件/跨页面共享时才使用 Store

---

## 6. 组合式函数（Composables）完整索引

所有 composables 自动导入，无需显式 import。

| Composable | 用途 | 关键说明 |
|------------|------|---------|
| `useAppFetch` | HTTP 请求主封装 | 基于 useFetch，支持 SSR，自动注入认证头 |
| `useAppToken` | Token 管理 | 从 query string/localStorage 提取 token，自动登录 |
| `useAppUserUtil` | 用户工具 | `userLogout`/`isLogin`/`userToLogin`/`userLoginDo` |
| `useAppVersion` | 版本提取 | 从 UA 提取氪金兽 App 版本号 |
| `useCategoryCore` | 品类页核心 | 品类页状态与逻辑编排（Options/Instance 模式） |
| `useCategoryFilter` | 品类筛选 | 支持 `normal`/`yanxuan`/`tieba`/`tieba-search` 四种模式 |
| `useCategoryList` | 品类列表 | 品类页商品列表加载 |
| `useCategorySort` | 品类排序 | 品类页排序状态管理 |
| `useCollect` | 收藏 | 收藏操作，含 `getCollectQrText()` 收藏口令生成 |
| `useImagePreview` | 图片预览 | Vant ImagePreview 封装，增加 PC 端键盘操作（Esc/方向键） |
| `useImRequest` | IM 请求 | 带签名的即时通讯接口请求 |
| `useInjectAlter` | 模式配置 | 根据 appMode 返回 storeTokenKey 等配置 |
| `useInit` | 应用初始化 | 初始化逻辑入口 |
| `useMwpRequest` | MWP 协议请求 | MWP 签名、token 管理、请求队列 |
| `useOpenInstall` | 深度链接 | OpenInstall 渠道检测与安装追踪 |
| `useOpenInstallLoader` | SDK 懒加载 | 按需加载 OpenInstall SDK |
| `usePageUtil` | 页面工具 | `h5Url()`、`h5vMyLoginUrl()` 等 |
| `usePositionToTop` | 回到顶部 | 基于滚动位置的"回到顶部"按钮显隐控制 |
| `useScrollPosition` | 滚动位置持久化 | VanList 滚动位置存储与恢复（跨路由） |
| `useSocket` | WebSocket | Socket.IO 连接管理（IM 聊天） |
| `useTiebaScheme` | 贴吧协议入口 | 列表页/搜索页共用，入参经 `resolveTiebaEntryParams` 单点缓存 |
| `useTiebaTopBar` | 贴吧顶部 bar | URL 入参 `noKjsTopBar=1` 时隐藏氪金兽自绘顶部 bar |

> 页面离开确认（popstate 拦截）目前没有通用 composable，个别页面（如 `pages/estimate/result`）为页面内联实现；如需复用请先确认有没有新增的封装，不要凭空调用 `useLeaveConfirm`。

### 6.1 useScrollPosition 使用模式

```typescript
const { restoreScrollPosition, startScrollListener, cleanupScrollListener } = useScrollPosition({
    storageKey: 'page-category-scroll',
    listRef: vanListRef,
})

onMounted(() => {
    restoreScrollPosition()
    startScrollListener()
})

onBeforeUnmount(() => {
    cleanupScrollListener()
})
```

---

## 7. 自定义指令

### 7.1 v-tongji — 点击埋点

```vue
<!-- 单参数 -->
<VanButton v-tongji="'button_click_buy'">购买</VanButton>

<!-- 多参数（数组） -->
<VanButton v-tongji="['button_click', gameId, 'buy']">购买</VanButton>
```

底层调用 `tjClickEvent()`。**禁止**手写 click 事件做埋点，必须使用此指令。

### 7.2 v-exposure-report — 曝光上报

基于 IntersectionObserver（阈值 0.7），追踪元素进入/离开视口：

```vue
<div
    v-exposure-report="{
        item: goodsItem,
        onEnter: (item) => reportExposure(item),
        onLeave: (item) => reportLeave(item),
        options: { threshold: 0.5 },
    }"
>
    {{ goodsItem.title }}
</div>
```

**禁止**手写 IntersectionObserver 做曝光上报，必须使用此指令。

---

## 8. App Bridge 跳转（jump.ts）

在氪金兽 App WebView 内使用 `window.kjs` 桥接原生页面：

```typescript
import { jumpGoodsDetails, jumpEstimate, jumpWebview } from '~/utils/jump'

// 必须在 App 内调用，先检测 UA
if (useNuxtApp().$uaInKejinshouApp) {
    jumpGoodsDetails(goodsId)       // 跳转商品详情
    jumpEstimate(params)            // 跳转鉴定
    jumpWebview(title, url)         // 打开 App 内 WebView
    jumpFinishWeb()                 // 关闭当前 WebView
    jumpGeneralDetail(id)           // 通用品类详情
    jumpGoodsCollect()              // 收藏夹
    jumpMainActivity(goType, opts)  // 首页品类 tab
    jumpToAppChat(chatInfo)         // 客服聊天
    jumpGroupTeam(info)             // 加入群聊
}
```

---

## 9. Feature Flags（app.config.ts）

业务功能开关通过 `app.config.ts` 的 `kjs` 命名空间管理：

```typescript
const appConfig = useAppConfig()

// 使用示例
if (appConfig.kjs.sys.iosAlipayIsOpen) { /* iOS 支付宝支付 */ }
if (appConfig.kjs.estimate.detailGoodsRecommend) { /* 鉴定详情商品推荐 */ }
if (appConfig.kjs.category.indexGoodsRecommend) { /* 品类列表 SEO 商品推荐 */ }
if (appConfig.kjs.zixun.detailGoodsRecommend) { /* 资讯详情商品推荐 */ }
```

---

## 10. 错误处理策略

### 10.1 error-guard.client.ts

项目已有完整的错误防护机制（`plugins/error-guard.client.ts`），**不要**重复实现：

- **Suspense/KeepAlive 竞态**：拦截 `suspenseId`/`emitsOptions`/`subTree` 相关的 TypeError，上报 Sentry 后静默处理，防止白屏
- **Chunk 加载失败**：自动 `reloadNuxtApp({ force: true })`，最多重试 2 次（通过 sessionStorage 计数防循环）
- **App Bridge 兜底**：挂载已废弃的 `window.onSocketDisconnect` 防止 App 调用报错

### 10.2 error.vue

全局错误页面自动上报 Sentry（`SENTRY_EVENT_NUXT_ERROR` 标签），非生产环境显示错误详情。

### 10.3 Sentry 上报

```typescript
import { sentryEmits } from '~/utils/utils'

sentryEmits('事件标题', { extra: '信息' })
```

---

## 11. 小程序兼容层（mpUtils.ts）

在百度/支付宝小程序环境下，外链跳转受限。使用 `utils/mpUtils.ts` 处理：

```typescript
import { handleMpClickLink, handleMpHtmlLink, showDialogCopy, copyMpContent } from '~/utils/mpUtils'

// 处理链接点击（自动判断是否在小程序内，白名单内正常跳转，否则复制链接）
handleMpClickLink(url)

// 处理 v-html 中的 <a> 标签（渲染完成后调用）
handleMpHtmlLink(contentRef)

// 弹窗复制链接
showDialogCopy(url)
```

---

## 12. IndexedDB 缓存（dexieDb.ts）

使用 Dexie 封装 IndexedDB，缓存游戏筛选和商品数据：

```typescript
import DexieDatabase, { DB_GAME_TYPE } from '~/utils/dexieDb'

// 游戏筛选记录（最多保存 5 条，FIFO）
await DexieDatabase.addGameFilterRecord({ type: DB_GAME_TYPE.CATEGORY, id: gameId, title, logo, uid })
const records = await DexieDatabase.getGameFilterRecordByType(DB_GAME_TYPE.CATEGORY)

// 筛选条件记录
DexieDatabase.addFilterRecord({ game_id: gameId, content: filterContent })
const filters = await DexieDatabase.getFilterRecordByGameId(gameId)

// 商品数据
const items = await DexieDatabase.goodsGetItems(gameId, categoryId)
```

---

## 13. 存储 Key 管理（cons.ts）

**禁止**硬编码存储 key，必须使用 `utils/cons.ts` 中的常量：

```typescript
import { storageKey, storageKeyPage } from '~/utils/cons'

// 应用级存储
localStore(storageKey.APP_TOKEN, token)

// 页面级存储（sessionStorage）
appSessionStore(storageKeyPage.CATEGORY_CATEGORY_SELECTED, data)
```

主要存储工具函数（来自 `utils/utils.ts`）：
- `localStore(key, value?)` — localStorage 读写
- `appSessionStore(key, value?)` — sessionStorage 读写（带 app 前缀）
- `sessionStore(key, value?)` — sessionStorage 读写

---

## 14. 插件规范

### 14.1 通用插件

```typescript
export default defineNuxtPlugin((nuxtApp) => {
    if (import.meta.server) { /* 服务端逻辑 */ }
    if (import.meta.client) { /* 客户端逻辑 */ }
    return { provide: { key: value } }
})
```

### 14.2 客户端插件

文件名加 `.client.ts` 后缀，无需 `import.meta.client` 检查。

### 14.3 项目插件清单

| 插件 | 类型 | 用途 |
|------|------|------|
| `mwpHeaders.ts` | 通用 | MWP 协议头注入（mw-appkey, mw-sign 等） |
| `detectUserAgent.ts` | 通用 | UA 解析，提供 `$uaInKejinshouApp` 等 |
| `error-guard.client.ts` | 客户端 | Suspense 竞态防护 + chunk error 自动重载 |
| `socket.client.ts` | 客户端 | Socket.IO IM 初始化 |
| `loadJsSdk.client.ts` | 客户端 | 外部 SDK 加载（kjs-sdk、支付宝 JSSDK） |
| `directiveTongji.ts` | 通用 | v-tongji 点击埋点指令 |
| `directive-exposure-report.ts` | 通用 | v-exposure-report 曝光上报指令 |
| `vue-lazy-load.client.ts` | 客户端 | 图片懒加载（700ms 节流, 100px rootMargin） |
| `openinstall.client.ts` | 客户端 | 深度链接 SDK 加载 |
| `vconsole.client.ts` | 客户端 | 移动端调试工具（非生产环境） |

---

## 15. 平台检测（UA）

```typescript
// 通过插件注入
const {
    $uaInKejinshouApp,       // 氪金兽 App
    $uaInHarmonyApp,         // 鸿蒙 App
    $uaInIosEstimateApp,     // iOS 鉴定 App
    $uaIsMiniApp,            // 任意小程序
    $uaIsWechatMiniApp,      // 微信小程序
    $uaIsAlipayMiniApp,      // 支付宝小程序
    $uaIsBaiduMiniApp,       // 百度小程序
    $uaIsDouYinMiniApp,      // 抖音小程序
    $uaIsSimpleMiniApp,      // 简版小程序
    $uaExtractKejinshouVersion, // 提取版本号
} = useNuxtApp()

// 或使用工具函数（需传入 UA 字符串）
import { uaInKejinshouApp } from '~/utils/http/user-agent'
```

---

## 16. 样式规范

- 使用 `<style lang="less" scoped>`
- 样式文件独立为 LESS 文件，通过 `@import` 引入
- Tailwind CSS 用于快速布局，Less 用于复杂组件样式
- Vant 样式覆盖：`::v-deep(.van-field__label) { width: 80px; }`
- 4 空格缩进

---

## 17. TypeScript 类型规范

- 接口/类型：PascalCase + 业务上下文（`AppSelectedGame`、`GameDetailInfo`）
- 请求参数类型：`{Name}Param` 后缀
- 响应数据类型：`{Name}Date` 后缀（注意：项目约定就是 Date，不是 Data）
- 类型文件：`.d.ts` 后缀，位于 `utils/types/` 或 `utils/services/model/`
- `[property: string]: any` 保持 API 扩展性

---

## 18. 事件通信（Mitt）

```typescript
import { emitter } from '~/utils/mitt'

// 监听（在 onMounted 中）
onMounted(() => {
    emitter.on(IM_MESSAGE, handleMessage)
})

// 清理（在 onBeforeUnmount 中）
onBeforeUnmount(() => {
    emitter.off(IM_MESSAGE)
})

// 发送
emitter.emit(IM_MESSAGE, data)
```

---

## 19. 测试规范

- 测试框架：Vitest，测试文件在 `tests/` 目录
- 中文测试名称
- 使用 `vi.mock()` 模拟模块、`vi.spyOn()` 监控函数

---

## 20. 关键 Nuxt 配置

- `asyncContext: true` — 启用异步上下文保持，`useNuxtApp()` 可在 async 函数中使用
- `payloadExtraction: false` — 禁用 payload 提取
- Sentry 集成已启用（org: kr36, project: kejinshou-nuxt-h5）
- 服务端插件 `server/plugins/redirectToPc.ts` — 非移动端请求重定向到 PC 域名

---

## 21. 禁止事项

- **禁止**使用 Options API（`data()`、`methods`、`this`）— 除 Pinia store 外
- **禁止**使用 `@/` 路径别名，本项目统一使用 `~/`
- **禁止**使用相对路径导入（`../`、`./`）
- **禁止**使用 `import _ from 'lodash'`，必须按需导入 `lodash-es`
- **禁止**使用 KrCard/KrForm/KrTable/KrDialog 等后台管理组件（那是 backend-kejinshou 项目的）
- **禁止**使用 `MessagePlugin`（那是 TDesign 的）
- **禁止**使用 `request.post/get` + `ApiUrl` 模式（那是后台项目的）
- **禁止**使用 `src/request/mwpRequest.ts` 模式（那是 kejinshou_m 项目的）
- **禁止**使用 `routerKey.ts` / `routerName` 路由模式做页面文件路由（`routerName` 仅用于 `app/router.options.ts` 中的自定义路由）
- **禁止**在 SSR 阶段访问 `window`/`document`/`navigator`，必须用 `import.meta.client` 保护
- **禁止**在 `onMounted` 或事件回调中调用 `useAppFetch`，应使用 `appFetch`
- **禁止**在 setup 同步阶段外调用 Nuxt composables（`useFetch`、`useRuntimeConfig` 等）
- **禁止**添加分号
- **禁止**使用双引号（字符串用单引号）
- **禁止**使用 2 空格缩进（本项目使用 4 空格）
- **禁止**手写 click 埋点逻辑，必须使用 `v-tongji` 指令
- **禁止**手写 IntersectionObserver 做曝光上报，必须使用 `v-exposure-report` 指令
- **禁止**硬编码存储 key 字符串，必须使用 `storageKey` / `storageKeyPage` 常量
- **禁止**手写错误重试逻辑（chunk error 等），已有 `error-guard.client.ts` 处理

---

## 22. 与 kejinshou_m 项目的关键差异

| 特性 | h5-nuxt（本项目） | kejinshou_m |
|------|-------------------|-------------|
| 框架 | Nuxt 3（SSR） | Vue 3 + Vite（SPA） |
| 路径别名 | `~/` | `@/` |
| 路由 | 文件路由 + router.options.ts | routerKey.ts |
| 请求层 | useAppFetch / appFetch + useMwpRequest | mwpRequest |
| 服务层 | utils/services/ | src/request/ |
| 组件导入 | 自动导入 | 手动 import |
| 状态管理 | pinia-plugin-persistedstate | 手动持久化 |
| CSS | Tailwind + LESS | LESS |
| SSR | 支持 | 无 |
| SEO | `<Head>` 组件 | 无 |

---

## 23. 新增页面 Checklist

1. **页面文件**：在 `pages/` 对应目录创建 `.vue` 文件（或在 `app/router.options.ts` 添加自定义路由）
2. **SEO**：添加 `<Head>` + `<Title>` + `<Meta>`
3. **类型定义**：在 `utils/types/` 或 `utils/services/model/` 定义类型
4. **服务层**：在 `utils/services/mwp/` 或 `utils/services/v2/` 添加接口
5. **组件**：复杂 UI 拆分到 `components/` 下
6. **Store**：仅在需要跨页面共享时添加
7. **中间件**：需要鉴权时使用 `definePageMeta({ middleware: ['auth'] })`
8. **存储 Key**：新增存储 key 到 `storageKey` 或 `storageKeyPage`
9. **埋点**：使用 `v-tongji` / `v-exposure-report` 指令
10. **小程序兼容**：如有外链，使用 `mpUtils.ts` 处理

---

## 24. 文档维护约定（供文档同步类技能读取）

> 本节是本项目**文档结构的单一事实源**。配套工具 `fe-workflow release`（可选）会在发布后读取本节按此结构增量更新文档；未安装则忽略工具名，人工维护文档时遵循同样结构即可。

| 项 | 值 |
|----|----|
| 文档根目录 | `docs/kejinshou-h5-nuxt/` |
| 业务文档目录 | `docs/kejinshou-h5-nuxt/modules/`，**1:1 镜像 `pages/`**（每个 `pages/<目录>` 一个文档目录） |
| 模块文档 | 每个 `modules/<pages目录>/index.md`：模块定位 + 页面清单 + 接口汇总 |
| 页面文档 | 每个页面一个 `.md`，与 `.vue` 同名；**单页面模块（仅 `index.vue`）详情合并进 `index.md`** |
| 页面模板 | `docs/kejinshou-h5-nuxt/modules/_TEMPLATE.md`（字段：定位/路由/SEO/状态/接口/Composables/组件/交互/跳转/存储/坑） |
| 约定文档 | `architecture.md`（结构）·`routing.md`（文件式+router.options.ts）·`development.md`（规范速查）·`mcp.md` |
| 形态 | **纯 Markdown**（未搭 VitePress，无侧边栏/构建校验；如需站点另行搭建） |

**命名规则**：文档目录与 `pages/` 目录同名；页面文档与 `.vue` 同名；子目录页面加目录前缀（`estimate/result/list.vue` → `result-list.md`、`p/app-intro/index.vue` → 详情写进 `p/index.md`）；子组件不单独成文，写入所属页面「组件依赖」。

**路由信息**：真实 URL 多在 `app/router.options.ts` 自定义（**文件路径 ≠ URL**），页面文档必须写清真实 URL 与 `routerName`，见 `routing.md`。

**更新规则（按改动类型）**：
- **新增页面** → 按 `_TEMPLATE.md` 新建页面文档（或合并进单页 `index.md`）+ 更新该模块 `index.md` 清单 + 更新 `modules/index.md` 模块表。
- **改已有页面** → Edit 对应页面文档相关字段（接口/交互/跳转/SEO/坑），不重写整篇。
- **改子组件** → 改所属页面文档「组件依赖」段。
- **新增整模块（新 `pages/` 目录）** → 新建 `modules/<目录>/` + 更新 `modules/index.md`。

⚠️ **禁止**回到"一模块一个扁平 `modules/<module>.md`"的旧结构；一律按 1:1 目录 + 按页面拆分。
