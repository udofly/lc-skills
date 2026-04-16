---
name: lc-kejinshou-h5-nuxt
description: 氪金兽 H5 Nuxt 项目编码规范。在 h5-nuxt 项目中开发、重构或审查代码时必须应用此技能。当工作目录为 h5-nuxt 且涉及 Vue 组件、请求层、路由、样式等编码时自动触发。
license: MIT
metadata:
  author: kejinshou-team
  version: "1.0"
  project: h5-nuxt
---

# 氪金兽 H5 Nuxt 编码规范

本技能定义了 `h5-nuxt` 项目的完整编码规范，适用于所有新增和修改的代码。

---

## 项目概况

- **项目名**: 氪金兽 H5 Nuxt (h5-nuxt)
- **技术栈**: Nuxt 3 + Vue 3 + TypeScript + Pinia + Tailwind CSS + LESS + Vant
- **构建目标**: SSR H5 网页（支持服务端渲染和客户端渲染）
- **包管理器**: pnpm
- **运行命令**: `pnpm start:test`（开发）| `pnpm build:prod`（生产构建）

---

## 1. 目录结构

```
.
├── pages/                  # 基于文件的路由页面（Nuxt 自动路由）
├── components/             # 可复用 Vue 组件（自动导入）
│   ├── base/              # 基础/原始组件
│   ├── input/             # 输入相关组件
│   └── filter/            # 筛选组件
├── stores/                 # Pinia 状态管理
│   ├── app.ts             # 应用级状态
│   ├── user.ts            # 用户认证和个人资料
│   ├── mwp.ts             # MWP 相关状态
│   └── poppy.ts           # Poppy 服务状态
├── composables/            # Vue 3 组合式函数（自动导入）
│   ├── useAppFetch.ts     # HTTP 请求主封装
│   ├── useInit.ts         # 应用初始化
│   ├── useSocket.ts       # WebSocket 管理
│   ├── usePageUtil.ts     # 页面工具函数
│   └── useMwpRequest.ts   # MWP API 请求
├── utils/                  # 工具函数
│   ├── services/          # API 服务层（按域组织）
│   │   ├── base.ts        # 基础响应类型 RespResult<T>
│   │   ├── mwp/           # MWP 协议接口
│   │   ├── v2/            # V2 版本接口
│   │   └── model/         # TypeScript 类型定义
│   ├── core/              # 核心工具
│   ├── app/               # 应用特定工具
│   ├── types/             # TypeScript 类型定义
│   ├── utils.ts           # 通用工具函数
│   ├── constants.ts       # 应用常量
│   └── cons.ts            # 控制台/日志工具
├── plugins/                # Nuxt 插件
│   ├── mwpHeaders.ts      # MWP 请求头注入
│   ├── socket.client.ts   # WebSocket 初始化（仅客户端）
│   ├── loadJsSdk.client.ts # 外部 SDK 加载（仅客户端）
│   └── detectUserAgent.ts # UA 检测
├── server/                 # 服务端代码
│   ├── middleware/        # 服务端中间件
│   └── plugins/           # 服务端插件
├── layouts/                # 布局组件
├── middleware/             # 路由中间件
├── assets/                 # 静态资源
├── types/                  # 全局类型声明
├── env/                    # 环境配置文件
└── tests/                  # 测试文件
```

---

## 2. Vue 组件规范

### 2.1 基本结构

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
import type { PropType } from 'vue'
import type { GameDetailInfo } from '~/utils/types/category'

// 3. 服务层导入
import { reqV2MarketContentDetail } from '~/utils/services/v2/market'
import { reqMwpGameHomeGameDetail } from '~/utils/services/mwp/game'

// 4. 组合式函数（自动导入，无需显式 import）
// useAppFetch, useAppStore, useRouter 等均自动可用

// 5. 工具/常量导入
import { copyText, sentryEmits } from '~/utils/utils'

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

### 2.2 关键约定

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

---

## 3. UI 组件库

### 3.1 Vant 组件（通过 @vant/nuxt 自动注册）

```vue
<VanButton type="primary" size="large" @click="onSubmit">提交</VanButton>
<VanField v-model="trans.name" label="名称" placeholder="请输入" />
<VanPopup :show="trans.isShowPop" position="bottom" round @close="onClose" />
<VanCellGroup inset>
    <VanCell title="标题" :value="displayValue" />
</VanCellGroup>
```

### 3.2 @nuxt/ui 组件

项目集成了 `@nuxt/ui`，可使用 U 前缀组件。

### 3.3 自定义组件

组件按功能分目录放在 `components/` 下，Nuxt 自动导入，无需手动 import：

```vue
<!-- 自动导入，直接使用 -->
<BaseIconFont name="search" />
<InputSearch v-model="keyword" />
<FilterCategory :list="categories" />
```

### 3.4 提示方式

```typescript
import { showToast } from 'vant'

// 轻提示
showToast('操作成功')
showToast({ message: '加载中...', type: 'loading' })

// 项目 toast 工具（在 utils.ts 中定义）
toast(message)
```

---

## 4. API 请求层规范

本项目有两套请求方式，按场景选择：

### 4.1 基础响应类型

```typescript
// utils/services/base.ts
export interface RespResult<T> {
    status: number
    message: string
    data?: T
}
```

### 4.2 MWP 协议请求（useMwpRequest）

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

export const reqMwpGameGameList = (
    params = {},
    mwpHeaders: Partial<HeadersToPassthrough> = {}
) => {
    return useMwpRequest<RespResult<any>>(
        ApiMwpGame.gameList,
        params,
        { method: 'POST' },
        mwpHeaders
    )
}
```

### 4.3 V2 HTTP 请求（useAppFetch / appFetch）

适用于标准 REST API，定义在 `utils/services/v2/` 下：

```typescript
// utils/services/v2/market.ts
import type { RespResult } from '~/utils/services/base'
import { appFetch, useAppFetch } from '~/composables/useAppFetch'
import type { ContentDetailParam, ContentDetailDate } from '~/utils/services/model/market'

// API 路径定义
const Api = {
    contentDetail: 'api/market/content/detail',
    consultList: 'api/market/content/lists',
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

### 4.4 类型定义（Model）

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
- 响应数据：`{Name}Date` 后缀
- 接口始终使用 `[property: string]: any` 保持扩展性

### 4.5 在组件中使用

```typescript
// setup 阶段（SSR 兼容）：使用 useAppFetch 系列
;(async () => {
    const { data } = await reqV2MarketContentDetail({ id: 1 })
    const status = get(data.value, 'status')
    if (status != 0) {
        toast(get(data.value, 'message', ''))
        return
    }
    trans.data = get(data.value, 'data', {})
})()

// onMounted / 事件回调中：使用 appFetch 系列
const handleClick = async () => {
    const result = await reqV2MarketConsultListDirect({ page: 1 })
    if (get(result, 'status') == 0) {
        listData.value = get(result, 'data.list', [])
    }
}
```

### 4.6 关键区别：useAppFetch vs appFetch

| 特性 | `useAppFetch` | `appFetch` |
|------|---------------|------------|
| 底层 | Nuxt `useFetch` | 原生 `$fetch` |
| SSR | 支持（服务端+客户端） | 仅客户端 |
| 调用时机 | setup 同步阶段（顶层或 IIFE） | onMounted / 事件回调 |
| 返回值 | `{ data, pending, error }` ref | Promise 直接返回数据 |
| 适用场景 | 页面首屏数据、SEO 数据 | 交互触发的请求 |

---

## 5. 路由规范

### 5.1 基于文件的路由

Nuxt 自动从 `pages/` 目录生成路由，无需手动配置：

```
pages/
├── index.vue              → /
├── category/
│   └── index.vue          → /category
├── goods/
│   └── [id].vue           → /goods/:id
├── my/
│   ├── login.vue          → /my/login
│   └── order/
│       └── index.vue      → /my/order
```

### 5.2 页面导航

```typescript
const router = useRouter()

// 路由跳转
router.push('/goods/123')
router.push({ path: '/category', query: { game_id: '456' } })

// 返回
router.back()

// 获取路由参数
const route = useRoute()
const id = route.params.id
const gameId = route.query.game_id
```

### 5.3 路由中间件

```typescript
// middleware/auth.ts
export default defineNuxtRouteMiddleware((to, from) => {
    const userStore = useUserStore()
    if (!userStore.token) {
        return navigateTo('/my/login')
    }
})
```

页面中使用：
```typescript
definePageMeta({
    middleware: ['auth'],
})
```

---

## 6. Pinia 状态管理

### 6.1 Store 定义（Options API 模式）

```typescript
// stores/app.ts
import { defineStore } from 'pinia'
import type { AppSelectedGame } from '~/utils/types/stores/app'

export const useAppStore = defineStore('_app', {
    state: () => ({
        latestGames: [] as AppSelectedGame[],
        moreGame: { id: '-1', title: '更多游戏', logo: '', uid: '' },
    }),

    getters: {
        latestGameId(state) {
            const firstGame = first(state.latestGames.filter(item => item.id !== '-1'))
            return firstGame ? get(firstGame, 'id') : ''
        },
        latestGamesWithMore(state) {
            return state.latestGames.concat([state.moreGame])
        },
    },

    actions: {
        updateLatestGame(game: AppSelectedGame) {
            const existingIndex = this.latestGames.findIndex(item => item.id === game.id)
            if (existingIndex !== -1) {
                this.latestGames.splice(existingIndex, 1)
            }
            this.latestGames.unshift(game)
            if (this.latestGames.length > 10) {
                this.latestGames.pop()
            }
        },
    },

    persist: {
        storage: piniaPluginPersistedstate.localStorage(),
    },
})
```

### 6.2 在组件中使用

```typescript
// Nuxt 自动导入，无需 import
const appStore = useAppStore()
const userStore = useUserStore()

// 读取（getters 或 state）
const gameId = computed(() => appStore.latestGameId)
const token = computed(() => userStore.token)

// 调用 action
appStore.updateLatestGame(game)
```

> **重要**：简单页面状态不要使用 Pinia，用组件内 `ref` / `reactive` 即可。仅在需要跨组件/跨页面共享时才使用 Store。

---

## 7. 组合式函数（Composables）

### 7.1 编写模式

```typescript
// composables/usePageUtil.ts
export default function usePageUtil() {
    const h5Url = () => useRuntimeConfig().public.pageUrl

    const h5vMyLoginUrl = () => {
        const go = window.btoa(router.currentRoute.value.fullPath)
        return `${h5Url()}/my/login?go=${go}`
    }

    return { h5Url, h5vMyLoginUrl }
}
```

### 7.2 关键约定

- composables 自动导入，无需显式 import
- 只在 setup 同步阶段调用 Nuxt composables（`useRuntimeConfig`, `useFetch` 等）
- 客户端逻辑必须用 `if (!import.meta.client) return` 保护
- 默认导出函数，函数名以 `use` 开头

---

## 8. 插件规范

### 8.1 通用插件

```typescript
// plugins/mwpHeaders.ts
export default defineNuxtPlugin((nuxtApp) => {
    const headersToPass: Partial<HeadersToPassthrough> = {}

    if (import.meta.server) {
        const event = nuxtApp.ssrContext?.event
        // 从请求头提取
    }
    if (import.meta.client) {
        // 从浏览器 API 获取
    }

    return {
        provide: {
            mwpHeaders: headersToPass,
        },
    }
})
```

### 8.2 客户端插件

文件名加 `.client.ts` 后缀：

```typescript
// plugins/socket.client.ts
export default defineNuxtPlugin(() => {
    const chatSocket = io(imUrl(), {
        transports: ['websocket'],
        reconnection: true,
        autoConnect: false,
    })
    // 无需 import.meta.client 检查，Nuxt 自动处理
})
```

---

## 9. SEO 规范

每个页面必须包含 SEO 元信息：

```vue
<template>
    <Head>
        <Title>{{ pageTitle }}</Title>
        <Meta name="keywords" :content="keywords" />
        <Meta name="description" :content="description" />
        <Link rel="canonical" :href="canonicalUrl" />
    </Head>
    <!-- 页面内容 -->
</template>

<script setup lang="ts">
// 动态 SEO 数据
const pageTitle = computed(() => `${get(trans.data, 'title', '')} - 氪金兽`)
const keywords = computed(() => get(trans.data, 'keywords', '氪金兽'))
const description = computed(() =>
    truncate(get(trans.data, 'description', ''), { length: 150 })
)
</script>
```

---

## 10. 样式规范

### 10.1 基本规则

- 使用 `<style lang="less" scoped>`
- 样式文件独立为 LESS 文件，通过 `@import` 引入
- Tailwind CSS 用于快速布局，Less 用于复杂组件样式
- 4 空格缩进

### 10.2 Tailwind CSS 使用

项目自定义颜色在 `tailwind.config.js` 中定义：

```vue
<template>
    <div class="flex items-center gap-2 p-4 bg-blue-50 rounded-lg">
        <span class="text-gray-950 text-sm">标题</span>
    </div>
</template>
```

### 10.3 组件样式（LESS）

```vue
<style lang="less" scoped>
@import "pageName";  // 导入同目录下的 pageName.less
</style>
```

### 10.4 Vant 组件样式覆盖

```less
::v-deep(.van-field__label) {
    width: 80px;
}
```

---

## 11. TypeScript 类型规范

### 11.1 类型定义文件

```typescript
// utils/types/category.d.ts
export interface GameDetailInfo {
    gameUid: string
    alias: string
    title: string
    categories: GameDetailCategory[]
}

export interface GameDetailCategory {
    isHot: number
    type: string
    cateId: number
    title: string
}
```

### 11.2 命名约定

- 接口/类型：PascalCase + 业务上下文（`AppSelectedGame`、`GameDetailInfo`）
- 请求参数类型：`{Name}Param` 后缀
- 响应数据类型：`{Name}Date` 后缀
- 类型文件：`.d.ts` 后缀
- `[property: string]: any` 保持 API 扩展性

---

## 12. 事件通信（Mitt）

```typescript
import { emitter } from '~/utils/mitt'

// 常量定义
const IM_MESSAGE = 'im_message'
const IM_CONNECTED = 'im_connected'

// 发送事件
emitter.emit(IM_MESSAGE, data)

// 监听（在 onMounted 中）
onMounted(() => {
    emitter.on(IM_MESSAGE, handleMessage)
})

// 清理（在 onBeforeUnmount 中）
onBeforeUnmount(() => {
    emitter.off(IM_MESSAGE)
})
```

---

## 13. 环境与运行时配置

```typescript
// 获取运行时配置
const config = useRuntimeConfig()
const appMode = config.public.appMode
const appUrl = config.public.appUrl
const appVersion = config.public.appVersion

// 关键变量
// appMode: 'dev' | 'test' | 'prod'
// appUrl: API 基础 URL
// pageUrl: H5 页面 URL
// imUrl: IM 服务 URL
// mwpAppKey: MWP 应用密钥
```

---

## 14. 平台检测（UA）

```typescript
// 通过插件注入，使用 useNuxtApp() 获取
const { $uaInKejinshouApp, $uaIsMiniApp } = useNuxtApp()

// 或使用工具函数
import { uaInKejinshouApp, uaIsMiniApp, uaIsAlipayMiniApp } from '~/utils/http/user-agent'
```

---

## 15. 测试规范

```typescript
// tests/utils/http-user-agent.test.ts
import { describe, expect, test } from 'vitest'
import { uaInKejinshouApp } from '~/utils/http/user-agent'

const UA_KEJINSHOU = 'Mozilla/5.0 ... kejinshou/3.2.1'

describe('uaInKejinshouApp', () => {
    test('氪金兽App UA → true', () => {
        expect(uaInKejinshouApp(UA_KEJINSHOU)).toBe(true)
    })

    test('非氪金兽 UA → false', () => {
        expect(uaInKejinshouApp('Mozilla/5.0')).toBe(false)
    })
})
```

- 测试框架：Vitest
- 测试文件在 `tests/` 目录，按功能组织
- 中文测试名称
- 使用 `vi.mock()` 模拟模块、`vi.spyOn()` 监控函数

---

## 16. 常用工具函数

```typescript
// utils/utils.ts
import { copyText, isNeedRealName, sentryEmits } from '~/utils/utils'

// 存储工具
import { localStore, sessionStore, appLocalStore, appSessionStore } from '~/utils/utils'

// 复制到剪贴板
copyText('文本内容')

// Sentry 事件上报
sentryEmits('事件标题', { extra: '信息' })
```

---

## 17. 禁止事项

- **禁止**使用 Options API（`data()`、`methods`、`this`）— 除 Pinia store 外
- **禁止**使用 `@/` 路径别名，本项目统一使用 `~/`
- **禁止**使用相对路径导入（`../`、`./`）
- **禁止**使用 `import _ from 'lodash'`，必须按需导入 `lodash-es`
- **禁止**使用 KrCard/KrForm/KrTable/KrDialog 等后台管理组件（那是 backend-kejinshou 项目的）
- **禁止**使用 `MessagePlugin`（那是 TDesign 的）
- **禁止**使用 `request.post/get` + `ApiUrl` 模式（那是后台项目的）
- **禁止**使用 `src/request/mwpRequest.ts` 模式（那是 kejinshou_m 项目的）
- **禁止**使用 `routerKey.ts` / `routerName` 路由模式（本项目用 Nuxt 文件路由）
- **禁止**在 SSR 阶段访问 `window`/`document`/`navigator`，必须用 `import.meta.client` 保护
- **禁止**在 `onMounted` 或事件回调中调用 `useAppFetch`，应使用 `appFetch`
- **禁止**在 setup 同步阶段外调用 Nuxt composables（`useFetch`、`useRuntimeConfig` 等）
- **禁止**添加分号
- **禁止**使用双引号（字符串用单引号）
- **禁止**使用 2 空格缩进（本项目使用 4 空格）

---

## 18. 与 kejinshou_m 项目的关键差异

| 特性 | h5-nuxt（本项目） | kejinshou_m |
|------|-------------------|-------------|
| 框架 | Nuxt 3（SSR） | Vue 3 + Vite（SPA） |
| 路径别名 | `~/` | `@/` |
| 路由 | 文件路由（pages/） | routerKey.ts |
| 请求层 | useAppFetch / appFetch + useMwpRequest | mwpRequest |
| 服务层 | utils/services/ | src/request/ |
| 组件导入 | 自动导入 | 手动 import |
| 状态管理 | pinia-plugin-persistedstate | 手动持久化 |
| CSS | Tailwind + LESS | LESS |
| SSR | 支持 | 无 |
| SEO | `<Head>` 组件 | 无 |

---

## 19. 新增页面 Checklist

创建新页面时，按以下顺序：

1. **页面文件**：在 `pages/` 对应目录创建 `.vue` 文件
2. **SEO**：添加 `<Head>` + `<Title>` + `<Meta>`
3. **类型定义**：在 `utils/types/` 或 `utils/services/model/` 定义类型
4. **服务层**：在 `utils/services/mwp/` 或 `utils/services/v2/` 添加接口
5. **组件**：复杂 UI 拆分到 `components/` 下
6. **Store**：仅在需要跨页面共享时添加
7. **中间件**：需要鉴权时使用 `definePageMeta({ middleware: ['auth'] })`

---

## 20. API 响应处理模板

```typescript
// 标准处理模式（setup 阶段）
;(async () => {
    const { data } = await reqApiName(params)
    const status = get(data.value, 'status')
    const message = get(data.value, 'message', '')

    if (status != 0) {
        toast(message)
        return
    }

    trans.data = get(data.value, 'data', {})
})()

// 标准处理模式（事件/onMounted）
const handleAction = async () => {
    const result = await reqApiNameDirect(params)
    const status = get(result, 'status')

    if (status != 0) {
        toast(get(result, 'message', ''))
        return
    }

    listData.value = get(result, 'data.list', [])
}
```

> **重要**：status 判断使用 `!= 0`（宽松比较），`get()` 始终带默认值。
