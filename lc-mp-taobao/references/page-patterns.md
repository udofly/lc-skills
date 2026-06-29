# 页面编写模式

页面 = `Page({ data, onLoad, ... })`。下面是项目里反复出现的真实套路。

## 生命周期惯例

- `onLoad(query)`：解析 query 参数、初始化、发起首次请求、（可选）埋点 `tjPageViewEvent`。
- `onShow()`：常用于"从别的页面返回时刷新"——检查 `globalData.homeGame` / `globalData.isType` 等回传标志，或用 `isLoaded` 标志位避免重复加载；也在这里控制 TabBar 显隐。很多页面 `onShow(){}` 留空。
- `onPullDownRefresh()`：下拉刷新（需 `.json` 配 `"pullRefresh": "true"`）。
- `onReachBottom()`：上拉触底分页。
- `onUnload()`：清理 `setInterval`/`setTimeout` 定时器。
- `onShareAppMessage()`：返回 `{ title, desc, path }`，分享可带关键参数（如 `estimate_no`）。

## 分页列表标准骨架（直接照抄改名）

来自 `pages/MyRecycleGoods`，是项目最干净的分页范式：

```js
import { showToast } from "../../utils/utils";
import { apiGiraffeCenterGoodsRecycleList } from "../../request/giraffe-center-request";

Page({
  data: {
    list: [],
    loading: true,
    page: 1,
    pageSize: 10,
  },
  onLoad(query) {
    this.queryList();
  },
  onShow() {},

  queryList() {
    const { page, pageSize } = this.data;
    apiGiraffeCenterGoodsRecycleList({ page, pageSize }).then(({ status, message, data }) => {
      const { list } = this.data;
      if (status === 0) {
        this.setData({
          loading: false,
          list: list.concat(data.list),       // 追加
        });
      } else {
        showToast(message);
      }
      my.stopPullDownRefresh();
    });
  },

  itemDetail(e) {
    const { item } = e.currentTarget.dataset;   // 取 data-item
    my.navigateTo({ url: `/pages/RecycleDetails/RecycleDetails?id=${item.id}` });
  },

  onPullDownRefresh() {
    this.setData({ page: 1, loading: true, list: [] }, () => {
      this.queryList();                         // 重置后再查
    });
  },

  onReachBottom() {
    this.setData({ page: this.data.page + 1, loading: true }, () => {
      this.queryList();
    });
  },
});
```

变体：列表很长时改用 `<scroll-view onScrollToLower="lower" lowerThreshold="360">` 包裹，`lower()` 里判断"是否到底"再 `page++`。是否到底的标志命名跟随文件：`ddl`（home/index）、`hasMore`（Estimate/Rent）、`isEnd`（MessageSystem）。判到底常用 `data.list.length >= total` 或本页返回数 `>= pageSize`。

## setData 链式回调

需要"改完状态立刻再做事"时，用 `setData` 第二个参数回调，而不是 setTimeout：

```js
this.setData({ page: 1, list: [], ddl: true }, () => {
  this.queryList();
});
```

## query 参数 & 跳转

- 取参：`onLoad(query){ const id = query.id }`。
- 跳转：`my.navigateTo({ url: '/pages/Xxx/Xxx?id=' + id })`；tab 页用 `my.switchTab`；替换当前页 `my.redirectTo`；返回 `my.navigateBack`。
- 跨页传游戏对象等复杂数据：写 `globalData.homeGame = item` 再 `switchTab`，目标页 `onShow` 读取并清理。

## 页面 .json 配置

```json
{
  "defaultTitle": "回收订单",
  "pullRefresh": "true",
  "titleBarColor": "#ffffff",
  "navigationBarTextStyle": "black",
  "usingComponents": {
    "ant-loading": "antd-mini/es/Loading/index",
    "goods-list": "../components/GoodsList/GoodsList"
  }
}
```

- antd-mini 组件路径形如 `antd-mini/es/Loading/index`，命名 `ant-xxx`。
- 自定义组件用相对路径，命名 kebab-case。
- **新页面记得在 `app.json` 的 `pages` 数组加路径**。

## 轮询（鉴定类页面）

- 状态轮询：`this.timer = setInterval(() => this.checkStatus(), 1000)`；命中终态 `clearInterval(this.timer)`；`onUnload` 里再兜底 `clearInterval`。
- 文本轮询：`setTimeout` 递归 + 次数上限（如最多 15 次、1.5s 间隔）+ `this._destroyed` 标志（`onUnload` 置真，递归里检查后停止）。

## AXML 要点

- 条件 `a:if`/`a:elif`/`a:else`，列表 `a:for`（默认 `item`/`index`，自定义 `a:for-item`/`a:for-index`）。
- 事件 `onTap`（冒泡）/`catchTap`（阻止冒泡）；传参用 `data-xxx="{{val}}"`，回调里 `e.currentTarget.dataset.xxx`。
- 富文本协议页：后端返回 HTML → `mini-html-parser2` 解析 → `<rich-text nodes="{{nodes}}" />`。
- 内嵌 H5：`<web-view src="{{webURL}}" />`（见 `pages/Web`）。
