---
name: lc-mp-taobao
description: 淘宝/天猫小程序（tb-account-center 账号中心项目）编码规范与脚手架。当在该项目（appx-ng、my.* API、antd-mini、@tbmp/mp-cloud-sdk 云请求）中开发、重构或审查代码时必须使用——包括新建页面/组件、编写网络请求、写分页列表、表单发布、跨小程序跳转、轮询、下拉刷新等。当工作目录为 tb-account-center 或文件后缀涉及 .axml/.acss、或用户提到"淘宝小程序""买号/卖号/回收/租号/鉴定""my.navigateTo""giraffe_center 接口""写个页面/组件"时主动加载本技能，即使用户没有明确点名规范。
---

# 淘宝小程序「账号中心」编码规范（lc-mp-taobao）

本技能封装 `tb-account-center` 淘宝小程序项目的真实编码约定。目标：让新写的页面、组件、接口与现有代码**风格一致、可直接合入**，而不是写出通用但格格不入的小程序代码。

## 这是什么项目

游戏账号 **买号 / 卖号 / 回收 / 租号 / 鉴定估值** 交易平台。淘宝小程序（`my.*`），UI 用 `antd-mini`，网络走 `@tbmp/mp-cloud-sdk` 云函数代理，状态共享靠 `app.js` 的 `globalData`，**没有 TypeScript、没有 Redux/Pinia**。完整业务地图见仓库根目录 `项目分析文档.md`。

> **若用户给了截图/设计图要还原成页面**：直接按 `references/screenshot-to-page.md` 的四步走（看图→选模板→拆区块→落地四件套），全程优先复用 `references/components-catalog.md` 里的现成组件。

## 黄金法则（写任何代码前先记住）

1. **四件套**：每个页面/组件 = `Name.js` + `Name.axml` + `Name.acss` + `Name.json`，同名同目录。页面用 `Page({})`，组件用 `Component({})`。
2. **绝不直接发 HTTP**：所有接口都在 `request/*-request.js` 里包成 `apiXxx` 函数，页面 `import` 后调用。新增接口先去那里加函数。见 `references/request-layer.md`。
3. **响应判定恒为 `status === 0`**：`.then(({ status, message, data }) => { if (status === 0) {…} else { showToast(message) } })`。
4. **提示用 `showToast(message)`**（来自 `utils/utils.js`），不要裸用 `my.showToast`。**记得 import**——项目里有页面漏 import 导致报错，别学。
5. **子传父用 `this.props.onXxx(payload)` 回调**，不是微信的 `triggerEvent`。父页用属性注册 `<comp onXxx="handler" />`。
6. **组件选型严格按优先级**——**本地已试用过的优先**：
   ① 项目自有组件（`pages/components`，46 个）→ 最优先；
   ② 项目已用过的 antd-mini（15 个，已验证可跑）→ 次之；
   ③ 仅当①②都不满足时，才用 `references/antd-mini.md` 里官网查来的"未用过"组件，且用前先核对本地 `node_modules/antd-mini/es/<Component>/` 源码与 3.1.11 版本是否一致。
   能复用就别重写——清单见 `references/components-catalog.md`（props/回调/用法/看图选型）。
7. **跨页状态走 `globalData`**，不引入任何状态库。
8. **图片统一过 OSS 工具**：列表 `cdnOssImage(url)`、按尺寸 `ossImage(url, size)`、按 style `cdnOssImageStyle(url, style)`。
9. **新页面要在 `app.json` 的 `pages` 数组注册**，否则路由不到。

## 选择正确的参考文件

按任务读对应参考（不要全部塞进上下文）：

| 任务 | 读这个 |
|---|---|
| 新建/修改网络接口、看签名/Header | `references/request-layer.md` |
| 新建页面、分页列表、生命周期、下拉刷新、轮询 | `references/page-patterns.md` |
| 新建/修改组件、父子通信、ref、props-callback | `references/component-patterns.md` |
| **复用现成组件**（props/回调/标签）、项目已用的 antd-mini、看图选组件 | `references/components-catalog.md` |
| 需要项目**还没用过的 antd-mini 组件**（Picker/DatePicker/Switch/Stepper/SwipeAction/Form/Tag/NoticeBar/Collapse…）| `references/antd-mini.md` |
| 跨小程序跳转、客服、复制、价格、登录态、存储等工具 | `references/utils-and-apis.md` |
| 完整可复制的页面/组件骨架模板 | `references/templates.md` |
| **用户给了截图/设计图要还原成页面** | `references/screenshot-to-page.md`（看图→选模板→拆区块→落地四件套） |

## 标准请求-响应写法（最常用，先内化这个）

```js
import { showToast } from "../../utils/utils";
import { apiGiraffeCenterGoodsRecycleList } from "../../request/giraffe-center-request";

apiGiraffeCenterGoodsRecycleList({ page, pageSize }).then(({ status, message, data }) => {
  if (status === 0) {
    this.setData({ list: this.data.list.concat(data.list), loading: false });
  } else {
    showToast(message);
  }
  my.stopPullDownRefresh();
});
```

部分接口（尤其带 `success` 字段的）也可 `const { success, data, message } = await apiXxx()` 用 `success` 判断——跟随同模块既有写法即可。

## 分页列表三件事（项目里到处都是同一套）

`data` 里固定有：`list`、`loading`、`page`(或 `pagePage`)、`pageSize`(默认 10)，列表是否到底用 `ddl`/`hasMore`/`isEnd`（跟随所在文件的命名）。

- **首屏 / 筛选变化 / 下拉刷新**：重置 `page=1, list=[]` 再查。
- **触底**（`onReachBottom` 或 `scroll-view` 的 `onScrollToLower`）：`page+1` 后**追加** `list.concat(data.list)`。
- 每次请求收尾调用 `my.stopPullDownRefresh()`。

完整可复制骨架见 `references/page-patterns.md` 与 `references/templates.md`。

## 命名 / 风格速查

- 文件夹/组件名 PascalCase（`GoodsList`、`MorePopup`），少数历史页面小写（`home`、`index`、`sell`、`mine`、`message`）。
- 方法名 camelCase：`query*`（拉数据）、`on*`/`handle*`（交互）、`api*Req`（接口包装）。
- class 名 kebab-case；主色 `#FF6600`，页面背景 `#f7f7f7`。
- 接口函数名：`api` + 业务模块 + 动作，如 `apiGiraffeCenterGoodsPage`、`apiEstimateCreate`、`apiRentDetail`。

## 接口未就绪时

可先用 MOCK 数据占位（租号 `RentList`/`RentDetail` 即如此：接口函数已写好但注释、先渲染本地 mock），并在注释标明，联调时替换为真实 `apiXxx` 调用。如需对接 Apifox，可用配套技能 `lc-feat-api-sync`（可选，未安装则手动替换）。

## 写完自检

- [ ] 四件套齐全，`.json` 配了 `usingComponents`，新页面已在 `app.json` 注册
- [ ] 接口在 `request/*-request.js` 里有对应 `apiXxx`，页面只 import 不裸 HTTP
- [ ] 响应判 `status === 0`，失败 `showToast(message)`，`showToast` 已 import
- [ ] 列表分页重置/追加/`stopPullDownRefresh` 三处齐全
- [ ] 组件子传父用 `this.props.onXxx`，没用 `triggerEvent`
- [ ] 图片过了 `cdnOssImage`/`ossImage`/`cdnOssImageStyle`
- [ ] 定时器在 `onUnload`/`didUnmount` 清理
