---
name: lc-kejinshou-h5-vue
description: 氪金兽 H5 移动端项目编码规范。在 kejinshou_m 项目中开发、重构或审查代码时必须应用此技能。当工作目录为 kejinshou_m 且涉及 Vue 组件、请求层、路由、样式等编码时自动触发。
license: MIT
metadata:
  author: kejinshou-team
  version: "1.1"
  project: kejinshou_m
---

# 氪金兽 H5 移动端编码规范

本技能定义了 `kejinshou_m` 项目的完整编码规范，适用于所有新增和修改的代码。

---

## 项目概况

- **项目名**: 氪金兽 H5 移动端 (kejinshou_m)
- **技术栈**: Vue 3.4 + TypeScript + Vite + Vant 4 + Pinia + Less
- **构建目标**: H5 网页（多端适配：浏览器、微信小程序 WebView、支付宝小程序、百度小程序、抖音小程序、B站、鸿蒙）
- **包管理器**: pnpm

---

## 1. 目录结构

```
src/
├── views/              # 页面组件（按业务模块分子目录）
├── components/         # 可复用组件
│   ├── app/            # 全局应用级组件（XPopup, XNavBar, Dialog）
│   ├── base/           # 基础组件（IconFont）
│   ├── goods/          # 商品相关组件
│   ├── order/          # 订单相关组件
│   ├── pay/            # 支付相关组件（PaymentMethod, PopupWxQrPay）
│   └── other/          # 其他通用组件
├── composables/        # Vue 3 组合式函数
├── request/            # API 请求层
│   ├── MwpApi.ts       # API 路径枚举定义
│   ├── MwpTrade.ts     # 交易相关请求函数
│   ├── MwpEstimate.ts  # 鉴定相关请求函数
│   ├── MwpProduct.ts   # 商品相关请求函数
│   ├── MwpUser.ts      # 用户相关请求函数
│   ├── mwpRequest.ts   # 请求入口（薄封装，对外暴露 mwpRequest 函数）
│   ├── core/           # 请求核心实现
│   │   ├── MwpRequestManager.ts  # 请求管理器（队列、重试、签名）
│   │   ├── TokenManager.ts       # Token 获取与刷新
│   │   └── RequestQueue.ts       # 请求队列管理
│   └── types/          # 请求相关类型定义
│       └── index.ts    # MWPRequestOptions, MWPRequestSign, RequestResponse 等
├── router/
│   ├── routerKey.ts    # 路由名称 + 路径常量
│   └── index.ts        # 路由配置
├── piniaStore/modules/ # Pinia 状态管理
├── utils/
│   ├── conf.ts         # 全局配置、枚举、常量
│   ├── cons.ts         # TypeScript 枚举定义
│   ├── utils.ts        # 通用工具函数
│   ├── app.ts          # 业务工具函数（导航、格式化）
│   ├── PayManager.ts   # 支付业务逻辑（组合式函数）
│   ├── jump.ts         # 页面跳转工具
│   └── tjReport.ts     # 埋点上报
├── services/           # 第三方服务对接（IM 等）
├── layouts/            # 布局组件（H5Layout, EmptyLayout）
├── assets/             # 静态资源 + 样式
│   └── style/          # 全局 Less 样式（_variables.less, _common.less）
└── main.ts             # 应用入口
```

---

## 2. Vue 组件规范

### 2.1 基本结构

所有组件必须使用 `<script lang="ts" setup>` + Composition API：

```vue
<template>
    <!-- 模板在最上面 -->
</template>

<script lang="ts" setup>
// 1. 外部库导入（lodash、vant、vue）
import { debounce, get, set } from 'lodash-es';
import { showToast } from 'vant';
import { computed, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue';
import { useRouter } from 'vue-router';

// 2. 内部组件导入
import XNavBar from '@/components/app/XNavBar.vue';
import IconFont from '@/components/base/IconFont';

// 3. 请求层导入
import { mwpXxxYyy } from '@/request/MwpXxx';

// 4. 组合式函数导入
import useXxx from '@/composables/useXxx';

// 5. 工具/配置导入
import { routerName } from '@/router/routerKey';
import { appName, storageKeyPage } from '@/utils/conf';
import { appLocalStore, toast, isMpDouYin } from '@/utils/utils';

// 6. Pinia Store 导入
import { useStoreUser } from '@/piniaStore/modules/user';

// --- 初始化 ---
const router = useRouter();
const storeUser = useStoreUser();

// --- Props / Emits ---
const props = defineProps({
    show: { type: Boolean, required: true, default: false },
    payInfo: { type: Object, required: true },
});
const emits = defineEmits(['closePopup', 'payOver']);

// --- 简单状态用 ref ---
const loading = ref(false);
const listData = ref([]);

// --- 复杂状态用 reactive，变量名统一为 trans ---
const trans = reactive({
    isShowPop: false,
    searchText: '',
    currentTab: 0,
});

// --- computed ---
const displayName = computed(() => get(props.payInfo, 'name', ''));

// --- watch ---
watch(
    () => props.show,
    (newValue) => {
        trans.isShowPop = newValue;
    },
);

// --- 业务方法 ---
const onSubmit = async () => {
    try {
        const { success, data } = await mwpXxxYyy({ id: props.payInfo.id });
        if (success) {
            showToast('操作成功');
            emits('closePopup');
        }
    } catch (e) {
        showToast('操作失败');
    }
};

// --- 生命周期 ---
onMounted(() => {
    // 初始化
});

onBeforeUnmount(() => {
    // 清理
});
</script>

<style scoped lang="less">
// 样式
</style>
```

### 2.2 关键约定

| 约定 | 说明 |
|------|------|
| 复杂状态变量名 | 统一使用 `trans`（`reactive({ ... })`） |
| 简单状态 | 使用 `ref()` |
| 属性访问 | 使用 lodash `get(obj, 'path', defaultValue)` 做安全访问 |
| 属性设置 | 使用 lodash `set(obj, 'path', value)` 做嵌套设置 |
| 导入路径 | 跨模块导入使用 `@/` 绝对路径；同一模块/目录内可用 `./` 相对路径（如 `request/core/` 内部互相引用） |
| 类型导入 | 纯类型使用 `import type { Xxx }` 或 `import { type Xxx }` |
| 事件命名 | camelCase 定义（`paySuccess`、`updatePrice`、`closePopup`） |
| 方法命名 | camelCase（`onSubmit`、`onSearchClick`、`goPageDetail`） |

---

## 3. UI 组件库

### 3.1 Vant 4 组件

直接使用 Vant 组件，项目已全局注册：
```vue
<VanButton type="primary" size="large" @click="onSubmit">提交</VanButton>
<VanField v-model="trans.name" label="名称" placeholder="请输入" />
<VanPopup :show="trans.isShowPop" position="bottom" round @close="onClose" />
<VanCellGroup inset>
    <VanCell title="标题" :value="displayValue" />
</VanCellGroup>
```

### 3.2 项目自定义组件

| 组件 | 路径 | 用途 |
|------|------|------|
| `XPopup` | `@/components/app/XPopup.vue` | 底部弹窗（封装 VanPopup，统一圆角和关闭图标）|
| `XNavBar` | `@/components/app/XNavBar.vue` | 顶部导航栏 |
| `XFooterBtn` | `@/components/app/XFooterBtn.vue` | 底部固定按钮 |
| `IconFont` | `@/components/base/IconFont` | 图标字体 |
| `Price` | `@/components/other/GoodsPrice.vue` | 价格展示 |
| `Dialog (xAlert/xConfirm)` | `@/components/app/Dialog` | 对话框（封装 VanDialog）|

### 3.3 提示方式

```typescript
import { showToast } from 'vant';
import { xAlert, xConfirm } from '@/components/app/Dialog';

// 轻提示
showToast('操作成功');
showToast({ message: '加载中...', type: 'loading' });

// 确认对话框
xConfirm('确定删除吗？').then(() => {
    // 确认
}).catch(() => {
    // 取消
});

// 提示对话框
xAlert('提示内容');
```

---

## 4. 请求层规范

### 4.1 API 路径定义

在 `src/request/MwpApi.ts` 中按模块分组定义：

```typescript
// 命名格式: Api{Module}
export const ApiTrade = {
    // 命名格式: {Feature}{Action}（PascalCase）
    PayMethodFold: 'mwp.kjs_trade.pay.method_fold',
    MwpTradePayMethod: 'mwp.kjs_trade.pay.channel',
    MwpTradeOrderCreate: 'mwp.kjs_trade.order.create',
    MwpTradeOrderPay: 'mwp.kjs_trade.order.pay',
    MwpTradeOrderPaySync: 'mwp.kjs_trade.order.paySync',
};
```

### 4.2 请求函数定义

在 `src/request/Mwp{Module}.ts` 中定义，每个函数对应一个 API：

```typescript
import { ApiTrade } from '@/request/MwpApi';
import mwpRequest, { MWP_API_VERSION, MWPRequestSign } from '@/request/mwpRequest';
// 需要使用类型时：
// import type { RequestResponse } from '@/request/types';

// 函数命名格式: mwp{Module}{Feature}{Action}
export async function mwpTradePayMethod(params: object = {}) {
    return mwpRequest({
        sign: MWPRequestSign.SING,
        method: 'post',
        url: ApiTrade.MwpTradePayMethod,
        version: MWP_API_VERSION,
        params,
    });
}
```

### 4.3 在组件中调用

```typescript
const { success, data, message } = await mwpTradePayMethod({ orderId: '123' });
if (success) {
    // 处理成功
    trans.listData = get(data, 'list', []);
}
```

---

## 5. 路由规范

### 5.1 路由名称定义

在 `src/router/routerKey.ts` 中定义，格式为 `domain.feature` 或 `domain.feature-action`：

```typescript
export const routerName = {
    goodsDetails: 'goods.details',
    goodsSearch: 'goods.search',
    estimateWays: 'estimate.ways',
    estimateHigh: 'estimate.high',
    userOrderBuy: 'user.order-buy',
    userOrderDetails: 'user.order-details',
};

export const routerPathKey = {
    orderPayPath: '/my/order/pay-info',
    generalOrderPayPath: '/general/order/pay-info',
};
```

### 5.2 页面导航

```typescript
import { routerName } from '@/router/routerKey';

// 命名路由跳转
router.push({ name: routerName.goodsDetails, params: { id: goodsId } });
router.push({ name: routerName.estimateWays, query: { game_id: gameId } });

// 返回
router.back();
```

### 5.3 路由配置

```typescript
// src/router/index.ts
{
    path: '/estimate',
    component: H5Layout,
    children: [
        {
            path: 'ways',
            name: routerName.estimateWays,
            component: () => import('@/views/estimate/Ways.vue'),
            meta: { auth: true, title: '鉴定方式' },
        },
    ],
},
```

---

## 6. 常量与枚举规范

### 6.1 配置常量（conf.ts）

使用 `export const` 对象定义分组常量：

```typescript
// 存储 Key
export const storageKey = {
    APP_TOKEN: 'user:kjs-token',
    APP_USER: 'app-user',
};

// 页面存储 Key
export const storageKeyPage = {
    HOME_OFFSET_Y: 'page-home-offset-y',
    SEARCH_HISTORY: 'page-search-history',
};

// 支付方式枚举
export const PayMethodEnum = {
    pay_wallet: 'wallet',
    pay_ali_h5: 'ali_lc_h5',
    pay_fh_t_qr: 'fh_t_qr',       // 汇付支付 - 微信扫码
    pay_ll_wx_qr: 'll_wx_qr',      // 连连微信二维码
    pay_tl_wx_qr_jy: 'tl_wx_qr_jy', // 通联支付 - 嘉游
};

// 事件 Key
export const PayEmitterEnum = {
    Success: 'pay_success',
    PopupClose: 'pay_popup_close',
    HfWxrqPay: 'pay_hf_wxrq',
    PcQrPay: 'pay_pc_qr_pay',
};

// 事件通信 Key
export const emiterKey = {
    OPEN_POP_WEBVIEW_HTML: 'open_pop_webview_html',
    CHANGE_MAIN_ROUTER: 'CHANGE_MAIN_ROUTER',
};
```

### 6.2 TypeScript 枚举（cons.ts）

枚举命名使用 `UPPER_SNAKE_CASE`，按业务分类定义：

```typescript
// 商品状态
export enum GOODS_STATUS {
    ALL = '',
    CHECK = '1',
    UPPER_ED = '8',
    SELL_ED = '16',
}

// 渠道
export enum CHANNEL_CODE {
    MP_ALIPAY = 'mp-alipay',
    MP_WEIXIN = 'mp-weixin',
    H5 = 'h5-nature',
}

// 其他常用枚举：
// SENTRY_EVENT       — Sentry 主动上报事件名
// SAFE_BT_TYPE       — 安全包赔类型
// TRANSFER_CHANNEL   — 账号转移渠道
// GAME_FILTER_TYPE   — 筛选类型
// EMITTER_TYPE       — emitter 事件类型
// H5_X_K7            — H5 渠道标识
// GAME_TYPE          — 游戏类型
// OS_TYPE            — 操作系统类型
// IM_MESSAGE_TYPE    — 消息体类型
// CHAT_TYPE          — 聊天类型
// APP_VERSION_CODE   — App 版本号特性开关
// APP_STATUS         — 业务状态码

export type GameType = 'home' | 'normal' | 'estimate' | 'estimate_high';
```

### 6.3 CDN 资源与外部 URL（conf.ts）

```typescript
import { cdnUrl, kjsCdnResources, ossStyle } from '@/utils/cons';

// CDN 基础地址
const cdnUrl = 'https://file.kejinshou.com';

// CDN 图片资源（按业务分组）
kjsCdnResources.ossTransfer.gameIntro  // 账号转移
kjsCdnResources.appIntro.videoPlay     // App 介绍
kjsCdnResources.download.qr           // 下载页

// OSS 图片裁剪样式
ossStyle.goods       // 670px
ossStyle.logo        // 80px
ossStyle.goodsSquare // 160px
```

---

## 7. 事件通信（Emitter）

项目使用 `poppy-util` 的 `emitter` 进行跨组件事件通信：

```typescript
import { emitter } from 'poppy-util';
import { PayEmitterEnum } from '@/utils/conf';

// 发送事件
emitter.emit(PayEmitterEnum.HfWxrqPay, payInfo);

// 监听事件（在 onMounted 中）
onMounted(() => {
    emitter.on(PayEmitterEnum.HfWxrqPay, (payInfo) => {
        trans.wxPayInfo = { price: props.payInfo.price, pay_qr: get(payInfo, 'payResponse') };
        trans.isShowWxPay = true;
    });
});

// 清理（在 onBeforeUnmount 中）
onBeforeUnmount(() => {
    emitter.off(PayEmitterEnum.HfWxrqPay);
    emitter.off(PayEmitterEnum.PcQrPay);
});
```

---

## 8. 组合式函数（Composables）

### 8.1 文件位置

`src/composables/use{Feature}.ts`

### 8.2 编写模式

推荐使用命名导出 `export function`（利于 tree-shaking 和类型推导）：

```typescript
// src/composables/useXxx.ts
import { get } from 'lodash-es';
import { ref, onMounted } from 'vue';
import { mwpXxxList } from '@/request/MwpXxx';
import { storageKey } from '@/utils/conf';
import { appSessionStore } from '@/utils/utils';

export function useXxx(type: string) {
    // 1. 先检查缓存
    const cached = appSessionStore(`${storageKey.XXX}_${type}`);
    if (cached) {
        return Promise.resolve({ data: get(cached, 'list', []) });
    }

    // 2. 调用接口
    return await mwpXxxList({ type }).then(({ success, data }) => {
        if (success) {
            const list = get(data, 'list', []);
            // 3. 写入缓存
            appSessionStore(`${storageKey.XXX}_${type}`, { list });
            return Promise.resolve({ data: list });
        }
    });
}
```

### 8.3 业务逻辑组合式函数（PayManager 模式）

适用于复杂业务逻辑需要跨多个组件复用的场景。通过参数传入依赖，避免使用 `getCurrentInstance()`：

```typescript
interface PayManagerOptions {
    payInfo: PayInfoProps;
}

export function usePayManager(options: PayManagerOptions) {
    const router = useRouter();

    const payValue = reactive({ method: '', curOrderId: '' });

    const goPayBtn = () => {
        if (!payValue.method) {
            showToast('请先选择支付方式');
            return;
        }
        getPayParams();
    };

    return { payValue, goPayBtn };
}
```

---

## 9. 样式规范

### 9.1 基本规则

- 使用 `<style scoped lang="less">`
- 使用 CSS 变量（`var(--k-color-theme)`）做主题色
- Vant 组件样式覆盖使用 `:deep(.van-xxx)`（Vue 3 推荐写法）
- 兼容写法 `::v-deep(.van-xxx)` 仍有效，但新代码统一用 `:deep()`
- **禁止**使用已废弃的 `/deep/` 写法

### 9.2 CSS 变量速查

```less
// 主题色
--k-color-theme: #5468FF;
--k-theme-bg-10: #ECEDFF;
--k-color-bg-main: #F3F5F9;

// 文字色
--k-color-text-black: #333;
--k-color-text-gray: #666;
--k-color-text-nine: #999;
--k-color-text-light: #CCC;

// 功能色
--k-color-red: #FF3c3c;
--k-color-yellow: #FFA333;
--k-color-green: #01B930;

// 间距
--k-page-margin: 12px;
--k-module-margin: 12px;

// 圆角
--k-radius-small: 4px;
--k-radius-middle: 8px;
--k-radius-large: 12px;

// 字号
--k-text-title-size: 16px;
--k-text-default-size: 14px;
--k-text-assist-size: 12px;

// 按钮高度
--k-button-height-large: 48px;
--k-button-height-middle: 44px;
```

### 9.3 Vant 组件样式覆盖

```less
// 覆盖 Vant 组件内部样式（使用 Vue 3 推荐的 :deep() 写法）
:deep(.van-field__label) {
    width: 80px;
}

:deep(.van-dialog__header) {
    font-size: 18px;
    font-weight: 500;
}
```

---

## 10. 平台适配

项目运行在多个平台，需要通过 UA 判断做差异化处理：

```typescript
import {
    isMpDouYin,       // 抖音小程序
    isMpWeChat,       // 微信小程序
    isMpAliPay,       // 支付宝小程序
    isMpBaidu,        // 百度小程序
    isMpBiliBili,     // B站
    isPCBrowser,      // PC 浏览器
    isFromHarmonyOsNext, // 鸿蒙系统
    isFromIosApp,     // iOS APP
    uaIsSimpleMiniApp, // 简版小程序
} from '@/utils/utils';

// 条件渲染
<div v-if="!isMpDouYin()" class="back-btn" @click="router.back()">返回</div>

// 条件逻辑
if (isPCBrowser()) {
    emitter.emit(PayEmitterEnum.PcQrPay, payInfo);
} else {
    goNewWindow(payResponse);
}
```

---

## 11. 关键依赖用法

### 11.1 lodash-es

始终使用命名导入，不要 `import _ from 'lodash'`：

```typescript
import { get, set, debounce, filter, forEach, find, includes, map, remove, trim, head } from 'lodash-es';

// 安全属性访问（项目中最常用）
const name = get(data, 'user.name', '');
const list = get(response, 'data.list', []);

// 嵌套属性设置
set(payInfo, 'pay_name', '微信');

// 防抖
const onSearch = debounce(() => { /* ... */ }, 500, { leading: true, trailing: false });
```

### 11.2 dayjs

```typescript
import dayjs from 'dayjs';
const formatted = dayjs(timestamp).format('YYYY-MM-DD HH:mm:ss');
```

### 11.3 poppy-util

```typescript
import { emitter, deviceId, localStore, sessionStore } from 'poppy-util';

// 事件通信
emitter.emit('event_name', data);
emitter.on('event_name', handler);
emitter.off('event_name');
```

---

## 12. Pinia Store 规范

### 12.1 定义

```typescript
// src/piniaStore/modules/user.ts
import { defineStore } from 'pinia';

export const useStoreUser = defineStore('user', {
    state: (): UserTypes => ({
        token: '',
        user: {},
        sessions: [],
        unread_num: 0,
    }),
    getters: {
        unReadNum: (state) => state.unread_num,
    },
    actions: {
        async Fetch(options = {}) { /* ... */ },
    },
});
```

### 12.2 使用

```typescript
import { useStoreUser } from '@/piniaStore/modules/user';
const storeUser = useStoreUser();

// 读取
const accountId = computed(() => get(storeUser, 'user.accountId'));

// 调用 action
storeUser.Fetch({ force: true });
```

> 简单页面状态不要使用 Pinia，用组件内 `ref` / `reactive` 即可。仅在需要跨组件共享时才使用 Store。
> **注意**：Pinia Store 使用 Options 风格（`state`/`getters`/`actions`）是项目约定，与"Vue 组件禁止 Options API"不矛盾。

---

## 13. 禁止事项

- **禁止**在 Vue 组件中使用 Options API（`data()`、`methods`、`this`）— Pinia Store 的 Options 风格不受此限
- **禁止**跨模块使用相对路径导入（`../../`），跨模块必须用 `@/`；同模块内 `./` 允许
- **禁止**使用 `import _ from 'lodash'`，必须按需导入 `lodash-es`
- **禁止**使用 KrCard/KrForm/KrTable 等后台管理组件（那是 backend-kejinshou 项目的）
- **禁止**使用 `MessagePlugin`（那是 TDesign 的，本项目用 Vant 的 `showToast`）
- **禁止**使用 `request.post/get` + `ApiUrl` 模式（那是后台项目的，本项目用 `mwpRequest`）
- **禁止**在 `src/services/permissions.ts` 中定义权限（本项目无此文件）
- **禁止**使用 LAYOUT 常量做路由（本项目用 `H5Layout` 组件 + `routerName`）
- **禁止**使用 `/deep/` 做样式穿透（已废弃，使用 `:deep()` 替代）
- **禁止**在 Composable 中使用 `getCurrentInstance()` 获取 props（通过参数传入）

---

## 14. 错误监控（Sentry）

项目集成 Sentry 进行错误追踪，关键事件需主动上报：

```typescript
import { SENTRY_EVENT } from '@/utils/cons';
import { sentryEmits } from '@/utils/utils';

// 主动上报业务异常
sentryEmits(SENTRY_EVENT.MWP_SESSION_INVALID, { detail: '会话过期' });
sentryEmits(SENTRY_EVENT.KJS_UPLOAD, { detail: '上传失败', error });
```

常用事件名定义在 `SENTRY_EVENT` 枚举中（`src/utils/cons.ts`）。
