# 组件编写模式

自定义组件用 `Component({})`，放在 `pages/components/`（弹窗类历史上也有放 `pages/componentsPopup/`）。`.json` 必须含 `{ "component": true }`。

## 标准结构（照抄）

```js
Component({
  mixins: [],
  data: {            // 组件内部 UI 状态
    autoplay: true,
  },
  props: {           // 父传数据；直接声明，给个默认值即可
    list: [],
    loading: true,
  },
  didMount() {},     // 挂载后（≈ mounted）：取系统信息、初始化
  didUpdate(prevProps, prevData) {}, // props/data 变化时：常用于监听 gameId 变化重新拉数据
  didUnmount() {},   // 卸载：清定时器
  methods: {
    onItemTap(e) {
      const item = e.currentTarget.dataset.item;
      this.props.onTapGoGoodsDetails(item);   // ← 子传父：调用父传进来的回调
    },
  },
});
```

生命周期对照：`onInit`(初始化,≈created) → `didMount`(≈mounted) → `didUpdate`(≈watch) → `didUnmount`(≈beforeDestroy)。`mixins: []` 项目里保留但未实际使用。

## 父子通信：props-callback（本项目核心约定）

**不要用微信的 `triggerEvent`。** 淘宝小程序这里靠"把函数当 prop 传下去"：

子组件：
```js
methods: {
  onTabsChange(e) {
    this.props.onTabsChange(e);   // 直接调用 props 上的同名函数
  }
}
```

父页面 axml 用属性注册（属性名 = 子组件里 `this.props.onXxx` 的名字）：
```axml
<tabs items="{{items}}" current="{{current}}" onTabsChange="tabsChange" />
```

父页面 methods 实现 handler：
```js
tabsChange(e) { this.setData({ current: e }); }
```

回调命名约定：
- 点击/事件类：`onXxx` / `onTapXxx`（如 `onTapMorePopup`、`onTapGoGoodsDetails`）。
- 筛选类带类型参数：`onFilterRadioUpdate(type, item)`、`onFilterPriceUpdate(type, value, index)`。
- 组件内部私有方法用 `handleXxx`。

payload 维度按需：一维 `this.props.onUpdate(value)`；二维 `this.props.onFilterRadioUpdate(type, item)`；三维 `this.props.onFilterCheckboxUpdate(type, data, condition)`。

## ref：父页面命令式调用子组件

当父需要主动调用子方法（如 `resetSearch()`），用淘宝小程序 ref 机制：

父 axml：`<search ref="searchRefs" ... />`
父 js：定义同名方法接住子实例，存到 this 上：
```js
searchRefs(ref) { this.searchRef = ref; }
gameFilter(ref) { this.gameFilters = ref; }
moreRef(ref) { this.myRef = ref; }
```
之后命令式调用：`this.searchRef.resetSearch()`、`this.gameFilters.backfillFilterData(data)`。

（home.js 的 `searchRefs`/`gameFilter`/`moreRef` 即此用法。优先用 props-callback；只有确实需要"父主动驱动子"时才用 ref。）

## 数据更新

组件内一律 `this.setData(obj, callback)`，需要更新后接着做事就用回调参数。props 变化的联动写在 `didUpdate` 里比较前后值。

## 组件分类（已有，优先复用）

- **录入 `Input*`**：`InputText` `InputRadio` `InputCheckbox` `InputImage` `InputChannel`(渠道/大区/服务器级联) `InputTextHConst` 等。props 常含 `property`(配置对象 `{title, is_required, type, ...}`)、`activeValue`(当前值)、`isDisable`；值变化回调 `onTapUpdateProperty(property, value)`。
- **筛选 `filter*`**：`filterTabs` `filterPrice` `filterRadio` `filterCheckbox` `filterInput` `filterSearch`。
- **复合筛选 `GameFilter`**：排序 + 渠道/大区/服务器级联 + 安全/属性 + 价格 中枢，对外回调 `onTapSortChange`/`onTapFilterChange`/`onTabBarChange`，含 `backfillFilterData` 回填。
- **列表**：`GoodsList` `Games` `GoodsImageXXL` `GoodsDetailInfo` `GoodsBaseInfo`。
- **弹窗**：`MorePopup`(字母索引+搜索) `PopPreviewImage` `PopKjsLogin` `HpjyScanPopup` `PopRealName`。
- **基础**：`Tabs` `TabBar` `Banner` `Search` `Kefu` `TextExpand` `Zones` `bindPhone`。

新组件命名、props 形态、回调命名都向上面已有组件看齐。
