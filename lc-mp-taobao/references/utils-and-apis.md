# 工具函数与原生 API 约定

来自 `utils/utils.js` 和 `utils/GlobalConst.js`。优先用这些封装，别重复造轮子。

## 提示 / 交互

- `showToast(content, type = 'none')` — Promise 化的 `my.showToast`，默认 1000ms。**所有提示走它**，记得 `import { showToast } from "<相对路径>/utils/utils"`。
- `isPreventClick(stopTime = 1000)` — 防连点；返回 `true` 表示应阻止本次点击。提交类按钮常 `if (isPreventClick(3000)) return;`。
- 复制：`my.setClipboard({ text })` 后 `showToast('已复制')`。

## 图片 / OSS（必过封装）

仅对自家域名（kejinshou / kejinlianmeng / kejinxia / iliexiang）且 url 无 `?` 时才加 OSS 参数。

- `cdnOssImage(url)` — 列表/通用，按可视区宽度自适配。
- `cdnOssImageStyle(url, style)` — 按预设 style（如 `'xxl'`/`'xl'`/`'l'`）。
- `ossImage(url, size)` — 按目标显示宽度 + 设备像素比。
- `ossVideo(url)` — 视频首帧截图。

典型用法：拉到列表后 `data.map(it => { it.img_url = cdnOssImage(it.img_url); return it; })` 再 `setData`。

## 存储

- 同步：`getStorageSync(key)` / `setStorageSync(key, data)` / `removeStorageSync(key)`。
- 异步：`getStorage` / `setStorage` / `removeStorage`（Promise）。`clearStorage()`。
- Key 集中在 `GlobalConst.js` 的 `StorageConst`（`USER_KJS_INFO`/`USER_KJS_TOKEN`/`USER_IM_TOKEN`/`USER_OPEN_ID`）；业务临时 key 直接字符串（如 `'history&game'` 最近游戏，最多 5 条）。

## 登录态 / 用户

- `getKjsToken()` / `getImToken()` / `getImAppKey()` / `getUserInfo()` / `getUserAccid()` — 先读 `globalData` 再读 storage。
- `clear_401()` — 清 token、userInfo、storage、tab 红点。`status === 401` 时 `apiCloudRequest` 已自动调用。
- 淘宝登录：`my.authorize` + `my.getAuthUserInfo` 拿头像昵称 → `apiGiraffeCenterUserInfo`(注册) 返回 openid 等 → 存 `globalData`。

## 跨小程序跳转

参数短：直接
```js
my.navigateToMiniProgram({ appId, path, extraData: { params: JSON.stringify({...}) } });
```
参数长 → 先存短参再传哈希 id：
```js
const extraData = { params: { iId, cId, sId } };
apiMiscShortParamsSet({ data: JSON.stringify(extraData) }).then(({ status, data }) => {
  if (status === 0) {
    my.navigateToMiniProgram({
      appId, path,
      extraData: { params: JSON.stringify({ gId: goodsId, hId: data.hashed_id }) },
    });
  }
});
```
跳氪金兽统一用 `toKjsMiniProgram(extraData)`（内部 `getKjsMiniProgramAppId` 取 appId，目标路径 `pages/message/message`）。

## 客服（淘宝原生）

```js
my.tb.openMessage({
  params: { itemId: globalData.sellerItemId },
  sellerNick: globalData.sellerNick,         // 来自 apiGiraffeCenterMiscTaobaoName
  fail: (res) => showToast(res.errorMessage),
});
```
`sellerNick`/`sellerItemId` 通常在进页时 `apiGiraffeCenterMiscTaobaoName` 拉取并写入 `globalData`。

## 表单 / 校验 / 价格

- `validatePhone(phone)`（`/^1[3-9]\d{9}$/`）、`isMobile(str)`。
- `calcFee(val, rate, min, max)` — 手续费计算（带最小/最大封顶），到手价 = `price - fee`。发布页价格输入时实时算。
- 必填校验套路：`forEach` 属性数组，检查 `is_required === 1` 的项 `val` 是否为空（`!v || v === '' || JSON.stringify(v) === '[]'`），缺失则 `showToast` 并 `return`。

## TabBar 控制

`my.showTabBar()` / `my.hideTabBar()`（自定义 TabBar，`app.json` 里 `custom: true`）；红点 `my.showTabBarRedDot`/`my.hideTabBarRedDot`。弹窗打开常 `hideTabBar`，关闭 `showTabBar`。

## 埋点

```js
const content = tjPageViewEvent(open_id, pageName, pageModule, obType, obName, obCode, obLabel);
apiLogReport({ content }).then(...);
```
通常在 `onLoad` 或关键点击时调用。

## 环境常量（GlobalConst.js）

`CloudEnv`(online) / `API_ENV`(production) / `API_UPLOAD_*` 上传地址 / `PAGE_H5_URL`(内嵌 h5) / `StorageConst` / `TEAM_TYPE`(群类型枚举) / `INPUT_CREATE_SHOW_NUM`。切测试环境时是注释切换，不要硬编码地址。

## lodash 用法

按需引入：`import get from "lodash/get"`。常用 `get(obj, 'a.b', default)`、`set`、`find`、`remove`、`forEach`、`head`、`chunk`、`includes`、`isEmpty`。避免直接深层取值，用 `get` 兜底。
