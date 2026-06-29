# 可复制脚手架模板

整段拷贝后改名、填业务。所有模板都符合本项目约定。

---

## A. 分页列表页（四件套）

### `Xxx.json`
```json
{
  "defaultTitle": "页面标题",
  "pullRefresh": "true",
  "navigationBarTextStyle": "black",
  "usingComponents": {
    "ant-loading": "antd-mini/es/Loading/index"
  }
}
```

### `Xxx.js`
```js
import { showToast } from "../../utils/utils";
import { apiXxxList } from "../../request/giraffe-center-request";

Page({
  data: {
    list: [],
    loading: true,
    page: 1,
    pageSize: 10,
    ddl: true,        // 是否还有更多
  },

  onLoad(query) {
    this.queryList();
  },
  onShow() {},

  queryList() {
    const { page, pageSize, list } = this.data;
    apiXxxList({ page, pageSize }).then(({ status, message, data }) => {
      if (status === 0) {
        this.setData({
          list: list.concat(data.list),
          ddl: data.list.length >= pageSize,
        });
      } else {
        showToast(message);
      }
    }).finally(() => {
      this.setData({ loading: false });
      my.stopPullDownRefresh();
    });
  },

  goDetail(e) {
    const { item } = e.currentTarget.dataset;
    my.navigateTo({ url: `/pages/XxxDetail/XxxDetail?id=${item.id}` });
  },

  onPullDownRefresh() {
    this.setData({ page: 1, list: [], loading: true, ddl: true }, () => {
      this.queryList();
    });
  },

  onReachBottom() {
    if (!this.data.ddl) return;
    this.setData({ page: this.data.page + 1, loading: true }, () => {
      this.queryList();
    });
  },
});
```

### `Xxx.axml`
```xml
<view class="page">
  <view class="list-item" a:for="{{list}}" key="item-{{index}}"
        data-item="{{item}}" onTap="goDetail">
    <image class="item-img" mode="aspectFill" src="{{item.img_url}}" />
    <view class="item-title">{{item.title}}</view>
    <view class="item-price">¥{{item.price}}</view>
  </view>

  <view a:if="{{loading}}" class="list-loading">
    <ant-loading type="mini" color="#FF6600" />
  </view>
  <view a:elif="{{!loading && list.length}}" class="list-footer">没有更多了</view>
  <view a:else class="list-empty">
    <image class="empty-img" src="/resource/images/search-empty.png" />
    <view class="empty-tip">暂无数据</view>
  </view>
</view>
```

### `Xxx.acss`
```css
.page { min-height: 100vh; background: #f7f7f7; }
.list-item { margin: 12rpx 16rpx; padding: 24rpx; background: #fff; border-radius: 16rpx; }
.item-img { width: 100%; height: 320rpx; border-radius: 12rpx; }
.item-title { font-size: 28rpx; color: #333; margin-top: 12rpx; }
.item-price { font-size: 32rpx; color: #FF6600; font-weight: 600; }
.list-loading, .list-footer { text-align: center; padding: 24rpx; color: #999; font-size: 24rpx; }
.list-empty { padding-top: 160rpx; text-align: center; }
.empty-img { width: 240rpx; height: 240rpx; }
.empty-tip { color: #999; font-size: 26rpx; margin-top: 16rpx; }
```

---

## B. 详情页（onLoad 取 id + 单次请求）

### `XxxDetail.js`
```js
import get from "lodash/get";
import { showToast, cdnOssImageStyle } from "../../utils/utils";
import { apiXxxDetail } from "../../request/giraffe-center-request";

Page({
  data: {
    id: "",
    loading: true,
    detail: {},
  },

  onLoad(query) {
    const id = get(query, "id", "");
    this.setData({ id }, () => this.queryDetail());
  },

  queryDetail() {
    apiXxxDetail({ id: this.data.id }).then(({ status, message, data }) => {
      if (status === 0) {
        this.setData({ detail: data });
      } else {
        showToast(message);
      }
    }).finally(() => {
      this.setData({ loading: false });
      my.stopPullDownRefresh();
    });
  },

  onCopy(e) {
    const { text } = e.currentTarget.dataset;
    my.setClipboard({ text: String(text) });
    showToast("已复制");
  },

  onPullDownRefresh() {
    this.queryDetail();
  },
});
```

---

## C. 自定义组件（四件套）

### `MyComp.json`
```json
{ "component": true }
```
若组件内还要用别的组件：
```json
{
  "component": true,
  "usingComponents": {
    "ant-icon": "antd-mini/es/Icon/index"
  }
}
```

### `MyComp.js`
```js
Component({
  mixins: [],
  data: {
    inner: "",
  },
  props: {
    list: [],
    title: "",
    // 回调函数也通过 props 传入：onItemTap、onClose 等（可不在此声明也能用 this.props.xxx）
  },
  didMount() {},
  didUpdate(prevProps) {
    // 监听某 prop 变化做联动，例如：
    // if (prevProps.gameId !== this.props.gameId) { this.refresh(); }
  },
  didUnmount() {},
  methods: {
    onItemTap(e) {
      const item = e.currentTarget.dataset.item;
      this.props.onItemTap(item);        // 子传父
    },
    onClose() {
      this.props.onClose();
    },
  },
});
```

### `MyComp.axml`
```xml
<view class="my-comp">
  <view class="my-comp-title">{{title}}</view>
  <view class="my-comp-item" a:for="{{list}}" key="c-{{index}}"
        data-item="{{item}}" onTap="onItemTap">
    {{item.name}}
  </view>
</view>
```

### 父页面使用
```xml
<my-comp list="{{games}}" title="选择游戏"
         onItemTap="handleItemTap" onClose="handleClose" />
```
```js
// 父页面 .json
"usingComponents": { "my-comp": "../components/MyComp/MyComp" }
// 父页面 methods
handleItemTap(item) { this.setData({ current: item.id }); },
handleClose() { this.setData({ visible: false }); },
```

---

## D. 弹窗组件（antd-mini ant-popup）

```xml
<ant-popup visible="{{visible}}" position="bottom" onClose="onClose">
  <view class="popup-body">
    <view class="popup-header">
      <text>{{title}}</text>
      <ant-icon type="CloseOutline" onTap="onClose" />
    </view>
    <!-- 内容 -->
  </view>
</ant-popup>
```
组件 props 含 `visible`，关闭走 `this.props.onClose()`，由父控制可见性。

---

## E. 轮询（鉴定状态类）

```js
Page({
  data: { estimateId: "" },

  onLoad(query) {
    this.setData({ estimateId: query.estimate_id }, () => this.startPoll());
  },

  startPoll() {
    this.timer = setInterval(() => this.checkStatus(), 1000);
  },

  checkStatus() {
    apiEstimateStatus({ estimate_id: this.data.estimateId }).then(({ status, data }) => {
      if (status !== 0) return;
      const s = data.status;
      if (s === 4 || s === 6) {            // 终态：完成
        clearInterval(this.timer);
        my.navigateTo({ url: `/pages/EstimateDetail/EstimateDetail?estimate_id=${this.data.estimateId}` });
      } else if (s === 5) {                // 终态：失败
        clearInterval(this.timer);
        showToast(data.err_msg || "鉴定失败");
      }
    });
  },

  onUnload() {
    clearInterval(this.timer);             // 兜底清理
  },
});
```

---

## F. 富文本协议页

```js
import parse from "mini-html-parser2";
import { apiGetServiceAgreement } from "../../request/giraffe-center-request";

Page({
  data: { nodes: [] },
  onLoad() {
    apiGetServiceAgreement().then(({ status, data }) => {
      if (status === 0) {
        parse(data.content, (err, nodes) => { if (!err) this.setData({ nodes }); });
      }
    });
  },
});
```
```xml
<rich-text class="agreement" nodes="{{nodes}}" />
```

---

## 尺寸 / 样式提示

- 单位用 `rpx`（750 设计稿）；少数全屏容器用 `vh`/`vw`。
- 主色 `#FF6600`，文字主色 `#333`，次要 `#999`，页面底色 `#f7f7f7`。
- 卡片圆角常 `12~16rpx`，白底 `#fff`。
