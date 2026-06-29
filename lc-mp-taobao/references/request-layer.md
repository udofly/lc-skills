# 网络请求层

所有网络请求经由 `@tbmp/mp-cloud-sdk` 云函数代理，统一入口是 `request/request.js` 的 `apiCloudRequest`。**页面/组件永远不直接调用 `cloud.application.httpRequest` 或 `my.request`**，只调用 `request/*-request.js` 里导出的 `apiXxx` 函数。

## 目录分工

| 文件 | 用途 | 接口前缀 |
|---|---|---|
| `request/request.js` | 核心：`apiCloudRequest` + Header + 签名 + JWT 解码 | — |
| `request/giraffe-center-request.js` | 长颈鹿交易中心（**主业务**：商品/发布/回收/鉴定/租号/首页…） | `giraffe_center/...`、`tong_ji/...` |
| `request/kjs-request.js` | 氪金兽 KJS（用户/登录/实名/绑定/提现/IM） | `kjs/...` |
| `request/kr-request.js` | KR 相关 | — |

## apiCloudRequest 机制（理解即可，一般不改）

`context = { api, params, method }`：

- 自动注入 `params.timestamp`；非 `im/` 接口再注入 `params.nonce`（md5 签名，`getSignNonceValue`）。
- Header：`im/` 前缀用 `IMHeaders()`，其余用 `KJSHeaders()`。`KJSHeaders` 带 `Authorization: Bearer <kjsToken>`、`x-k3`(渠道 `getAppChannel()`)、`x-k7: mp-taobao`、`x-os: mp`、`x-k5`(JWT sub)。
- 实际路径 `${api}/${API_ENV}`（`API_ENV` 见 `utils/GlobalConst.js`，线上 `production`）。
- `POST` → `body.__bizParams = params`；`GET` → `params.__bizParams = JSON.stringify(params)`。
- 统一返回 `{ status, message, data, success }`。`status === 0` 成功（`success: true`）；`status === 401` 调 `clear_401()` 清登录态；其余失败。

## 新增一个接口（必背模板）

在对应的 `*-request.js` 里追加一个 `async` 函数。**严格照抄这个形状**：

```js
// 一句话注释说明接口用途，可附后端原始路径
export async function apiGiraffeCenterXxxYyy(params = {}) {
  return apiCloudRequest({
    api: "giraffe_center/api.module.action",   // 后端点分路径
    params,                                      // 调用方传入的业务参数
    method: "POST",                              // 或 "GET"
  });
}
```

要点：
- 命名 = `api` + 业务模块（驼峰）+ 动作。例：`apiGiraffeCenterAccountGoodsCreate`、`apiEstimateStatus`、`apiRentList`。
- `params = {}` 默认空对象。
- `method` 用大写 `"GET"`/`"POST"`（少数历史代码写了小写 `"get"`，新代码用大写）。
- 列表/查询类常用 `GET`；提交/发布/详情类常用 `POST`（本项目很多"详情"也是 POST，跟随同类接口）。

## 现成接口速查（按需 import，不要重复造）

**首页/通用**：`apiGiraffeCenterHomeGames`、`apiGiraffeCenterHomeBanner`、`apiMiscGetSoldAccountCount`、`apiGiraffeCenterMiscTaobaoName`(客服昵称)、`apiLogReport`(埋点)。

**商品列表/筛选/详情**：`apiGiraffeCenterGoodsPage`(搜索列表,POST)、`getGiraffeFilter`、`apiGiraffeCenterGamePropertys`、`apiKjsGoodsDetailBaseInfo`、`apiKjsGoodsDetail`、`apiGetGoodsDetailJumpInfo`。

**发布-寄售**：`apiGiraffeCenterAccountGoodsShopProperty`、`apiGiraffeCenterAccountGoodsFreeConfig`、`apiGiraffeCenterAccountGoodsCheckGameAllParams`、`apiGiraffeCenterAccountGoodsCreate`、`apiGiraffeCenterAccountGoodsEditProductGoods`。

**发布-回收**：`apiGiraffeCenterAccountGoodsRecycleProperty`、`apiGiraffeCenterAccountGoodsAddRecycleGoods`、`apiGiraffeCenterAccountGoodsEditRecycleGoods`。

**游戏配置**：`apiGiraffeCenterGameGameGetGameAreas`、`...GetGameServers`、`...GetGameProperty`、`apiGiraffeCenterGameOtherConfigGameConfig`。

**商品管理**：`apiGiraffeCenterGoodsList`(寄售)、`apiGiraffeCenterRecycleList`、`apiGiraffeCenterGoodsRecycleList`(竞价)、`apiGiraffeCenterGoodsChangeShelfStatus`(上下架)、`apiGiraffeCenterGoodsUpdatePrice`(改价)。

**回收竞价**：`getRecycleDetail`、`agreeRecycle`。

**鉴定估值**：`apiEstimateCreate`、`apiEstimateStatus`、`apiEstimateMyList`、`apiEstimateSummary`、`apiEstimateShare`、`apiEstimateDetail`、`apiEstimateSummaryText`、`apiEstimateProfile`、`apiEstimateGatherMethod`、`apiEstimateProductRecommend`。

**租号**：`apiRentList`、`apiRentSortTabs`、`apiRentDetail`。

**跨小程序**：`apiMiscShortParamsSet`、`apiMiscShortParamsGet`、`getKjsMiniProgramAppId`。

**协议**：`apiGetServiceAgreement`、`apiGetPrivacyPolicy`。

**KJS（kjs-request.js）**：`apiKjsUserUserInfo`、`apiKjsCaptchaSend`/`SendVerificationCode`、`apiKjsLogin`/`systemAuthLogin`、`apiKjsUserRealNameEys`、`apiKjsAccoutTaobaoCBind`(绑定淘宝)、`apiKjsBindGoods`(寄售绑定)。

> 找不到对应接口再新增；新增前先 grep 一遍 `request/` 目录避免重复。
