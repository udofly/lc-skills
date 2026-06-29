# 组件目录（可直接调用清单）

写页面前先查这里：能复用就别重写。**props / 回调均从项目源码逐个提取，准确可用。**

## 注册路径约定

`.json` 的 `usingComponents` 里写相对路径：
- 从 `pages/Foo/Foo` 引用公共组件：`"goods-list": "../components/GoodsList/GoodsList"`
- antd-mini：`"ant-icon": "antd-mini/es/Icon/index"`
- 页面私有子组件（sell/RecycleHome/RecycleDetails/GoodsCreate 各自的 `components/`）：`"./components/Xxx/Xxx"`
- 组件标签名用 kebab-case，自取（如 `GoodsList` → `goods-list`）。

---

## 一、antd-mini 组件（项目实际使用，按使用频次）

| 标签 | import 路径 | 用途 / 高频场景 |
|---|---|---|
| `ant-icon` | `antd-mini/es/Icon/index` | 图标（`type="SearchOutline"`/`CloseCircleOutline`/`CloseOutline`…）最常用 |
| `ant-popup` | `antd-mini/es/Popup/index` | 弹层容器（`position="bottom"`），所有自定义弹窗底座 |
| `ant-input` | `antd-mini/es/Input/index` | 输入框 |
| `ant-dialog` | `antd-mini/es/Dialog/index` | 确认对话框（`footer` 配按钮，`onButtonTap`） |
| `ant-tabs` | `antd-mini/es/Tabs/index` | 标签页（详情多级 tab、商品管理状态 tab） |
| `ant-divider` | `antd-mini/es/Divider/index` | 分割线 |
| `ant-loading` | `antd-mini/es/Loading/index` | 加载圈（列表 footer：`type="mini" color="#FF6600"`） |
| `ant-number-keyboard` | `antd-mini/es/NumberKeyboard/index` | 数字键盘（改价、验证码、报价） |
| `ant-toast` | `antd-mini/es/Toast/index` | 轻提示（也可直接用 `showToast` 工具） |
| `ant-list` / `ant-list-item` | `antd-mini/es/List/index`、`.../List/ListItem/index` | 列表（我的、GameList） |
| `ant-steps` | `antd-mini/es/Steps/index` | 步骤条（交易流程） |
| `ant-index-bar` | `antd-mini/es/IndexBar/index` | 字母索引（GameList 全部游戏） |
| `ant-sticky` | `antd-mini/es/Sticky/index` | 吸顶容器 |
| `ant-countdown` | `antd-mini/es/Countdown/index` | 倒计时 |
| `ant-action-sheet` | `antd-mini/es/ActionSheet/index` | 操作菜单（商品管理「更多操作」） |

> 需要 antd-mini **其它没用过的组件**（Picker / DatePicker / Switch / Stepper / SwipeAction / Form / Tag / Badge / NoticeBar / Collapse / Result / Card / Grid / Avatar / Skeleton / Slider / Rate / Checkbox / Radio …）→ 看 `references/antd-mini.md`，有准确 props/事件/用法。那里也列了 antd-mini **没有**的组件（Image/SearchBar/PullToRefresh 等）该用什么原生替代，别 import 不存在的路径。

---

## 二、自定义组件目录

格式：**组件 — 用途**；`props`；`回调(this.props.xxx)`。回调即父页面要在标签上注册的属性名。

### 基础 / 展示

**Banner — 轮播图**
- props：`list`（`[{img_url, jump_url}]`）
- 回调：无（内部点击 `jump_url` 自动 `navigateTo` 到 `/pages/Web/Web`）
- 用法：`<banner a:if="{{banners.length}}" list="{{banners}}" />`

**Tabs — 标签页**
- props：`items`、`current`
- 回调：`onTabsChange`
- 用法：`<tabs items="{{items}}" current="{{current}}" onTabsChange="tabsChange" />`

**Search — 顶部搜索框（带游戏切换按钮）**
- props：`searchValue`、`leftShow`、`isSearch`、`gameInfo`
- 回调：`onSearch`、`onClearSearch`、`onTapGame`
- 含 ref 方法 `resetSearch()`（父用 `ref` 拿实例调用）

**TextExpand — 文本展开/收起**
- props：`content`；回调：无

**Zones — 金刚区/已售统计**
- props：`zones`、`count`；回调：无

**Kefu — 客服浮窗**
- props：`title`(默认'联系客服')、`showkefu`、`isHarmony`
- 回调：`onTapKefu`

**TabBar — 自定义底部导航**
- props：`path`（当前页路径）；回调：无（内部 `switchTab`）

**SectionTitle — 区块小标题**（sell 私有）
- props：`info`；回调：无

### 列表 / 商品

**GoodsList — 商品网格列表**
- props：`list`、`loading`
- 回调：`onTapGoGoodsDetails`（参数为点中的 item）
- 用法：`<goods-list list="{{goodsList}}" loading="{{loading}}" onTapGoGoodsDetails="goGoodsDetails" />`
- 内部含空态/「没有更多了」/loading 三态，**列表页首选**

**Games — 首页游戏金刚区**
- props：`games`
- 回调：`onGameChange`、`onTapGame`

**GoodsImageXXL — 商品大图（按 image_type 自适配）**
- props：`item`；回调：无

**GoodsBaseInfo — 商品/账号基础信息块**
- props：`baseInfos`；回调：无

**GoodsDetailInfo — 商品详情属性块（复杂嵌套）**
- props：`data`；回调：无

**RecycleGamesList — 回收游戏列表**（RecycleHome 私有）
- props：`gameList`；回调：`onTapGame`

**RecycleSection — 回收订单区块**（sell 私有）
- props：`recycleList`；回调：`onRecycleTap`

**QuestionsHelp — 常见问题列表**（sell 私有）
- props：`list`；回调：无

**SellSteps / TradeProcess — 卖号步骤 / 交易流程图**（sell 私有，纯展示）
- props：无；回调：无

**PriceCalculate — 手续费/到手价展示**（GoodsCreate 私有）
- props：`fee`(默认'0.00')、`money`(默认'0.00')；回调：无

**DetailsBaseInfo — 回收详情基础信息（展开+图片预览）**（RecycleDetails 私有）
- props：`sourceData`；回调：无（内部 `previewImage`）

**RecycleBargainItem — 回收报价列表 + 倒计时**（RecycleDetails 私有）
- props：`sourceData`
- 回调：`onTapBargainClick`（点报价）、`onUpdateData`（倒计时结束通知父刷新）
- 含 ref 方法 `queryData()`（父在详情加载后调用初始化）

### 表单录入 Input*（发布/鉴定页核心）

这一组共用约定：props 多含 `property`(配置对象 `{title, is_required, type, p_uid, course_img, course_title…}`)、`activeValue`(当前值)、`isDisable`；值变更回调统一 `onTapUpdateProperty(property, value)`；点说明回调 `onTapShowPopupExplain(exInfo)`。

| 组件 | 用途 | 额外 props / 回调 |
|---|---|---|
| `InputText` | 单行文本 | 回调：`onTapUpdateProperty`、`onTapShowPopupExplain` |
| `InputTextHConst` | 水平定宽文本（也用于改价输入） | `activeValue`；回调：`onTapUpdateProperty` |
| `InputTextVConst` | 竖排定宽文本 | 回调：`onTapUpdateProperty` |
| `InputRadio` | 单选 | `activeValue`；回调：`onTapUpdateProperty`、`onTapActiveValueBack`、`onTapShowPopupExplain` |
| `InputRadioConst` | 常量单选 | 回调：`onTapUpdateConstProperty` |
| `InputCheckbox` | 多选 | `activeValue`；回调同 InputRadio 组 + `onTapActiveValueBack` |
| `InputImage` | 图片上传 | `activeValue`；回调：`onTapUpdateProperty`、`onTapShowPopupExplain` |
| `InputChannel` | 渠道/大区/服务器级联选择 | props：`channelType/channelTitle/dataSource/selectValue/selectKey`；回调：`onTapUpdateChannel` |
| `InputCreateTemplate` | 模板（渠道/大区/服务器汇总展示） | props：`channelData`；回调：无 |
| `EstimateInputText` | 鉴定页带校验输入 | 回调：`onTapUpdateProperty`、`onTapShowPopupExplain` |

### 筛选 filter*（被 GameFilter 组合使用）

共用约定：props 多含 `title`、`active`(当前选中)、`list`/`groups`(选项)、`type`(标识)；回调以 `onFilterXxxUpdate(type, …)` 形式上报。

| 组件 | 用途 | props | 回调 |
|---|---|---|---|
| `filterRadio` | 单选筛选 | `title/active/list/type` | `onFilterRadioUpdate` |
| `filterCheckbox` | 多选筛选（含「全要/任一」condition） | `+condition` | `onFilterCheckboxUpdate`、`onFilterCheckboxConditionUpdate` |
| `filterTabs` | 二级分组筛选 | `title/active/groups/type/condition` | `onFilterTabsUpdate`、`onFilterCheckboxConditionUpdate` |
| `filterPrice` | 价格区间 + 预设 | `Min/Max/Value/title/list/type` | `onFilterPriceUpdate(type, value, index)` |
| `filterInput` | 区间输入 | `title/active{min,max}` | `onFilterInputUpdate` |
| `filterSearch` | 筛选内搜索框 | `searchText` | `onFilterSearchUpdate` |

**GameFilter — 复合筛选中枢（排序+渠道/大区/服务器级联+安全/属性+价格）**
- props：`type`、`search`、`isTabBar`、`sticky`、`gameId`、`filterData`
- 回调：`onTapSortChange(type, params)`、`onTapFilterChange(type, params)`、`onTabBarChange(item)`
- ref 方法：`backfillFilterData(data)`（外投回填）
- 用法：`<game-filter ref="gameFilter" games="{{games}}" gameId="{{gameId}}" sticky="{{...}}" onTapSortChange="sortChange" onTapFilterChange="filterChange" onTabBarChange="tabBarChange" />`

### 弹窗 Pop* / Popup

**MorePopup — 更多游戏弹窗（字母索引+搜索）**
- props：`moreVisible`、`lettersList`(`{tempLetters, tempGames}`)
- 回调：`onTapMorePopup(item)`（关闭传 `{}`，选中传游戏对象）

**InputPropertyPopup — 多选属性弹窗**
- props：`type/title/showList/isDisable/activeValue/isVisible`
- 回调：`onTapPopupClose`、`onTapSure`、`onTapSelectAll`、`onTapClean`、`onTapUpdateProperty`

**InputPropertyExPopup — 属性说明弹窗（图文教程）**
- props：`type/title/courseImage/courseText/isVisible`
- 回调：`onTapPopupClose`

**InputTipsDialog — 通用确认弹窗**
- props：`isVisible`、`title`(默认'提示')、`content`、`cancelTitle`、`sureTitle`
- 回调：`onTapCancel`、`onTapSure`

**HpjyScanPopup — 和平精英扫码弹窗**
- props：`gameId/channelId/type/isVisible`
- 回调：`onTapPopupClose`、`onTapScan`

**PopPreviewImage — 图片预览（放大）**
- props：`visible`、`imgUrl`
- 回调：`onHandleClose`

**PopRealName — 实名认证弹窗**（componentsPopup）
- props：无
- 回调：`onIdNoConfirm`

**PopKjsLogin — 氪金兽登录弹窗** / **bindPhone — 绑定手机号**
- props：无明显对外 props（内部自管登录/绑定流程，按需挂载）

---

## 选型速查（看截图选组件）

- **商品/账号卡片列表** → `GoodsList`
- **顶部搜索 + 游戏入口** → `Search` 或裸 `input`+`ant-icon`（home 用裸 input）
- **横向切换标签** → `Tabs`（自定义）或 `ant-tabs`
- **轮播 banner** → `Banner`
- **首页游戏宫格** → `Games` / 回收用 `RecycleGamesList`
- **筛选浮层** → `GameFilter`（整套）或单独 `filter*`
- **底部弹层/确认框** → `ant-popup` 自定义 / `InputTipsDialog` / `ant-dialog`
- **发布表单字段** → `Input*` 系列（按字段类型选）
- **价格/费率展示** → `PriceCalculate`
- **图片预览** → `PopPreviewImage`
- **客服入口** → `Kefu` + `my.tb.openMessage`
- **更多游戏选择** → `MorePopup`
- **加载/空态** → `ant-loading` + 自带空态图（参考 templates.md A）
