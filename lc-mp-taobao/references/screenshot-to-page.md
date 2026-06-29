# 截图转页面工作流（看图 → 选模板 → 拆区块 → 落地四件套）

用户给一张设计图/截图，要把它变成符合本项目约定、能直接合入的页面。按下面四步走，**每一步都先复用已有资产再考虑新写**。

---

## 第 0 步：先确认 3 件事（缺了就问，别猜）

1. **这页属于哪个业务** —— 买号 / 卖号 / 回收 / 租号 / 鉴定 / 我的 / 消息？决定接口模块和可复用组件。
2. **有没有接口 / Apifox** —— 有就按真实字段接；没有先 MOCK（参考 `RentList`/`RentDetail` 的占位写法），注释标明待联调。
3. **页面路由名** —— 用来建目录、在 `app.json` 注册、写跳转。

截图模糊或是长图时，请用户分段给或确认关键区块文案。

---

## 第 1 步：看图 → 判定页面原型，选模板

先把截图归类到一种「原型」，直接取 `references/templates.md` 对应骨架，不要从零写。

| 截图特征 | 原型 | 用模板 |
|---|---|---|
| 顶部搜索/筛选 + 下方同构卡片纵向滚动、能上拉加载 | **分页列表页** | templates.md · A |
| 单个对象的图文详情、价格、属性表、底部操作按钮 | **详情页** | templates.md · B |
| 一堆输入项 + 底部「提交/发布」 | **表单发布页** | 以 GoodsCreate 为参照 + Input* 组件 |
| 从底部/中间弹出的浮层 | **弹窗** | templates.md · D（`ant-popup` 底座） |
| 富文本长文（协议/说明） | **富文本页** | templates.md · F |
| 进页转圈、轮询出结果再跳转 | **轮询页** | templates.md · E |

判不准就同时具备多原型（如「详情页 + 底部弹窗」）：主体用详情模板，弹窗部分套 D。

---

## 第 2 步：拆区块（从上到下切，逐块标注）

把截图按视觉从上到下切成若干横向区块，对每块记录三件事：**①区块名 ②数据来源 ③交互**。例如一个回收列表页：

```
┌─ 导航标题「回收订单」………… titleBarColor，json 配
├─ 区块1: 顶部状态 Tab（待审核/成功/失败）… data.statusTabs + onTabChange
├─ 区块2: 卡片列表（图+标题+价格+状态）…… apiXxxList 分页，点击→详情
└─ 区块3: 加载态/空态/没有更多了 ………… loading/list.length 三态
```

切块时顺手判断每块的**复用对象**（下一步用）。常见映射：

- 顶部搜索框 → `Search` 组件 或 裸 `input + ant-icon`（home 的写法）
- 横向切换 Tab → `Tabs`（自定义）/ `ant-tabs`
- 轮播 → `Banner`；游戏宫格 → `Games` / `RecycleGamesList`
- 商品/账号卡片列表 → `GoodsList`（自带空态+loading+没有更多）
- 筛选浮层 → `GameFilter`（整套）或单个 `filter*`
- 价格/费率块 → `PriceCalculate`
- 表单字段 → `Input*` 系列（按字段类型逐个选）
- 底部确认/操作弹层 → `InputTipsDialog` / `ant-dialog` / `ant-popup` 自定义
- 客服入口 → `Kefu`；图片预览 → `PopPreviewImage`

> 区块对应的组件 props/回调去 `references/components-catalog.md` 查，命中就直接挂；只有截图里确实没有对应现成组件时才新写一个（新写遵循 `component-patterns.md`）。

---

## 第 3 步：落地四件套

按「数据 → 结构 → 交互 → 样式」顺序填，每条都套项目既有约定：

### 1) `Xxx.json`
- 配 `defaultTitle`、（列表页）`"pullRefresh": "true"`、`navigationBarTextStyle`、`titleBarColor`（取截图导航底色）。
- `usingComponents` 把第 2 步选中的组件全列进去（路径见 catalog 注册约定）。

### 2) `Xxx.js`
- `data` 按区块铺：列表页固定 `list/loading/page/pageSize/ddl`；表单页铺各字段 + `selectProperty`。
- 接口：第 0 步有真实接口就在 `request/*-request.js` 加 `apiXxx` 再调用；没有就 MOCK。响应判 `status === 0`，失败 `showToast(message)`。
- 生命周期、分页重置/追加、轮询、跳转、`stopPullDownRefresh` 全按 `page-patterns.md`。
- 子组件回调在这里实现（命名对齐组件要求的 `onXxx`）。

### 3) `Xxx.axml`
- 按第 2 步区块顺序拼标签：能用组件就用组件标签，列表用 `a:for` + `data-item` + `onTap`。
- 三态分支（loading / 有数据 / 空态）别漏，参考模板 A。

### 4) `Xxx.acss`
- `rpx` 单位（750 稿）；主色 `#FF6600`、文字 `#333/#999`、底色 `#f7f7f7`、卡片白底圆角 `12~16rpx`。
- 按截图还原间距/字号；做不到像素级时先合理近似，留给用户微调。

### 别忘了
- 新页面 → `app.json` 的 `pages` 数组注册。
- 图片字段过 `cdnOssImage`/`ossImage`/`cdnOssImageStyle`。
- 定时器在 `onUnload` 清。

---

## 第 4 步：交付时说清楚

给用户产出后，主动说明两点，方便快速迭代：
- **哪些块复用了现成组件、哪些是新写的**；
- **哪些数据是 MOCK、对应该接哪个接口**（待联调）。

像素细节（间距/字号/圆角）允许用户一句话回（"这里再紧一点"）来微调，不必一次到位。

---

## 一个完整示例（心智模型）

截图：一个「我的鉴定报告」列表 —— 顶部标题、下面一列卡片（左缩略图，右标题+状态标签+时间），可下拉刷新、上拉加载，点卡片进详情。

1. **原型**：分页列表页 → 模板 A。
2. **区块**：① 导航标题（json）② 卡片列表（`apiEstimateMyList` 分页，点击→`EstimateDetail`）③ 三态。卡片是「图+多行文字+状态标签」，`GoodsList` 样式不完全吻合 → 列表项自写 `a:for`，但 loading/空态/没有更多沿用模板 A 写法。
3. **落地**：`json` 配 pullRefresh + ant-loading；`js` 复制模板 A 改 `apiEstimateMyList`、`goDetail` 跳 `EstimateDetail?estimate_id=`；`axml` 卡片按截图排版 + 状态标签 class 区分 `completed/failed`；`acss` 还原。
4. **交付**：说明「列表项为新写、loading/空态复用模板、数据走 apiEstimateMyList 真接口」。
