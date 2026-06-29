# antd-mini 组件速查（淘宝小程序，v3.1.x）

> ⚠️ **优先级：本地已试用过的组件为准。** 选组件时先用 ① 项目自有组件，再用 ② 项目已用过的 15 个 antd-mini（均在 `components-catalog.md`，已在真实页面验证可跑）。**本文是 ③ 兜底**——这里的组件项目还没用过、API 取自官网源码，与本项目锁定的 `3.1.11` 可能有出入。用本文任一组件前，先核对本地 `node_modules/antd-mini/es/<Component>/` 确认存在且 props 一致，再写。

本项目已用 15 个 antd-mini 组件（见 `components-catalog.md` 第一节）。本文补充**项目还没用、但做新页面常需要的**组件，props/事件取自 antd-mini 官方源码 `src/<Component>/props.ts`。

## 通用约定

- **import 路径**：`"ant-xxx": "antd-mini/es/<Component>/index"`（淘宝/支付宝用 `es/`；子组件有子路径，如 `CheckboxGroup`、`DatePicker/RangePicker`）。
- **事件是属性回调**：`onChange="方法名"`，方法定义在 Page/Component，参数如 `(value, e)`——不是 React 的 `onChange={}`。
- **受控/非受控**：`value`/`checked`（受控）与 `defaultValue`/`defaultChecked`（非受控）二选一。
- **最终以本地为准**：项目锁 `antd-mini@3.1.11`，个别组件 API 跨版本有差异，落地有疑问时查 `node_modules/antd-mini/es/<Component>/` 源码。`Form` 必须开启 `component2`（本项目 `mini.project.json` 已开）。

---

## 一、表单录入

### Button（按钮）
- import：`antd-mini/es/Button/index`
- props：`type`(`default|primary|text`)、`danger`、`disabled`、`loading`、`inline`、`size`(`small|medium|large`)、`icon`、`subText`、`formType`(`button|submit|reset`)、`openType`/`scope`
- 事件：`onTap`、`catchTap`、`onGetPhoneNumber`、`onGetAuthorize`
```xml
<ant-button type="primary" loading="{{submitting}}" onTap="handleSubmit">提交</ant-button>
```

### Checkbox / CheckboxGroup（复选框）
- import：`antd-mini/es/Checkbox/index`、组：`antd-mini/es/Checkbox/CheckboxGroup/index`
- Checkbox props：`checked`/`defaultChecked`、`value`、`disabled`、`color`；事件 `onChange(checked, e)`
- Group props：`value`(string[])、`options`(`{label,value,disabled}[]`)、`position`(`horizontal|vertical`)、`color`；事件 `onChange(value[], e)`
```xml
<ant-checkbox-group options="{{options}}" value="{{checked}}" onChange="onChange" />
```

### Radio / RadioGroup（单选框）
- import：`antd-mini/es/Radio/index`、组：`antd-mini/es/Radio/RadioGroup/index`
- Group props：`value`(string)、`options`(`{label,value,disabled,color}[]`)、`position`、`color`；事件 `onChange(value, e)`
```xml
<ant-radio-group options="{{options}}" value="{{current}}" onChange="onChange" />
```

### Switch（开关）
- import：`antd-mini/es/Switch/index`
- props：`checked`/`defaultChecked`、`disabled`、`loading`、`color`、`checkedText`/`uncheckedText`、`size`(`medium|small|x-small`)；事件 `onChange(checked, e)`
```xml
<ant-switch checked="{{on}}" onChange="onSwitch" />
```

### Stepper（步进器）
- import：`antd-mini/es/Stepper/index`
- props：`value`/`defaultValue`、`min`、`max`、`step`(默认1)、`type`(`number|digit`)、`precision`、`disabled`；事件 `onChange(value,e)`、`onConfirm`、`onFocus`、`onBlur`
```xml
<ant-stepper value="{{count}}" min="{{1}}" max="{{99}}" onChange="onCount" />
```

### Picker（选择器，底部弹出滚动选择）
- import：`antd-mini/es/Picker/index`（级联：`antd-mini/es/Picker/CascaderPicker/index`）
- props：`value`/`defaultValue`、`options`(每列选项 `{value,label}[]` 的数组)、`visible`、`title`、`placeholder`(默认「请选择」)、`okText`/`cancelText`、`formattedValueText`、`disabled`、`maskClosable`
- 事件：`onOk(value, column, e)`(确定)、`onCancel(e)`、`onChange(value,column,e)`(滚动即触发)、`onFormat(value,column)=>string`、`onVisibleChange`
```xml
<ant-picker value="{{value}}" options="{{options}}" placeholder="请选择城市" onOk="onOk" />
```
```js
data: { value: '', options: [[{ value: 'hz', label: '杭州' }, { value: 'sh', label: '上海' }]] },
onOk(value) { this.setData({ value }); }
```

### DatePicker / RangePicker（日期选择器）
- import：`antd-mini/es/DatePicker/index`、区间：`antd-mini/es/DatePicker/RangePicker/index`
- props：`value`(`Date|string|number`)、`format`(默认 `YYYY/MM/DD`，同 dayjs)、`min`/`max`、`precision`(`year|month|day|hour|minute|second`)、`visible`、`title`、`placeholder`、`okText`/`cancelText`
- 事件：`onOk(date, dateStr, e)`、`onCancel`、`onPickerChange`、`onFormat`、`onVisibleChange`
```xml
<ant-date-picker value="{{date}}" format="YYYY-MM-DD" precision="day" placeholder="请选择日期" onOk="onOk" />
```

### Slider（滑动条）
- import：`antd-mini/es/Slider/index`
- props：`value`(`number|[number,number]`)、`min`(0)、`max`(100)、`step`(1)、`range`(双滑块)、`disabled`、`showTicks`、`showNumber`、`showTooltip`
- 事件：`onChange(value,e)`(实时)、`onAfterChange(value,e)`(松手)
```xml
<ant-slider value="{{val}}" min="{{0}}" max="{{100}}" onChange="onChange" />
```

### Rate（评分）
- import：`antd-mini/es/Rate/index`
- props：`value`/`defaultValue`、`count`(5)、`allowHalf`、`allowClear`、`readonly`、`gutter`；事件 `onChange(rate)`
```xml
<ant-rate value="{{score}}" count="{{5}}" onChange="onRate" />
```

### Selector（标签式筛选器，单/多选）
- import：`antd-mini/es/Selector/index`
- props：`value`/`defaultValue`、`options`(`{text,value,subText,disabled}[]`)、`multiple`、`minSelectedCount`/`maxSelectedCount`、`disabled`、`activeItemClassName`
- 事件：`onChange(value, item, e)`、`onSelectMax`、`onSelectMin`
```xml
<ant-selector options="{{options}}" value="{{selected}}" multiple onChange="onChange" />
```
> 注：项目自有 `filter*` 系列筛选组件（见 catalog），业务筛选优先用自有组件；通用标签选择才用 Selector。

### Form / FormItem（表单 + 校验，需 component2）
- import：预置项按需引入，如输入框 `antd-mini/es/Form/FormInput/index`；其它 `FormPicker`/`FormDatePicker`/`FormSwitch`/`FormStepper`/`FormSelector`/`FormRadioGroup`/`FormCheckboxGroup`/`FormTextarea`/`FormImageUpload` 同形；自定义项用 `antd-mini/es/Form/FormItem/index`
- 逻辑层：`import { Form } from 'antd-mini/es/Form/form'`，`new Form({ rules, initialValues })`，表单项 axml 上 `ref="handleRef"`，js 里 `handleRef(ref){ this.form.addItem(ref) }`，提交 `this.form.getFieldsValue()`
- FormItem props：`name`(必填)、`label`、`labelWidth`、`position`、`required`、`help`、`tooltip`、`validateStatus`、`errors`、`dependencies`
```xml
<form-input label="用户名" name="account" placeholder="请输入用户名" ref="handleRef" />
```
> Form 内部 API 跨版本有差异，落地以 `node_modules/antd-mini/es/Form/` 源码为准。本项目发布表单历史上是**手写校验**（见 GoodsCreate 的 `onVerificationParams`），新表单可评估用 Form 或沿用手写。

---

## 二、展示 / 反馈

### Tag（标签）
- import：`antd-mini/es/Tag/index`
- props：`type`(`outline|fill|fill-light`)、`color`(`primary|success|warning|danger|image`)、`icon`
```xml
<ant-tag type="fill-light" color="success">已认证</ant-tag>
```

### Badge（徽标/角标）
- import：`antd-mini/es/Badge/index`
- props：`type`(`dot|number|text|bubble`)、`text`、`position`(`top-right`等八方位)、`offsetX`/`offsetY`、`stroke`、`bgColor`
```xml
<ant-badge type="number" text="{{8}}"><view class="icon-bell" /></ant-badge>
```

### NoticeBar（通告栏）
- import：`antd-mini/es/NoticeBar/index`
- props：`icon`、`type`(`default|error|primary|info`)、`mode`(`link|closeable`)、`enableMarquee`、`loop`、`ellipsisRow`
- 事件：`onTap`(右侧图标)、`onActionTap(index)`
```xml
<ant-notice-bar type="info" mode="closeable" onTap="onClose">这是一条公告</ant-notice-bar>
```

### Result（结果页）
- import：`antd-mini/es/Result/index`
- props：`type`(`success|error|info|warning|wait`)、`image`、`title`、`message`；默认 slot 放底部按钮
```xml
<ant-result type="success" title="提交成功" message="我们将尽快处理">
  <ant-button type="primary" onTap="backHome">返回首页</ant-button>
</ant-result>
```
> 注：项目已有 `pages/CreateSuccess` 发布成功页，结构可参照；新结果页可用 Result 简化。

### Collapse（折叠面板 / 手风琴）
- import：`antd-mini/es/Collapse/index`
- props：`items`(`{title,content,disabled}[]`)、`current`(number[])、`accordion`(仅展开一个)；事件 `onChange(current[], e)`
```xml
<ant-collapse items="{{items}}" current="{{current}}" onChange="onChange" />
```

### Card（卡片容器）
- import：`antd-mini/es/Card/index`
- props：`title`、`operateText`(右上操作)、`needFold`/`foldStatus`(可折叠)、`headSticky`/`stickyTop`(吸顶)、`divider`
- 事件：`onOperateClick`、`onFoldChange`、`onTitleSticky(status)`
```xml
<ant-card title="基本信息" operateText="更多" onOperateClick="onMore"><view>内容</view></ant-card>
```

### Grid（宫格导航）
- import：`antd-mini/es/Grid/index`
- props：`items`(`{title,description,icon,iconStyle}[]`)、`columns`(5)、`mode`(`default|scroll`)、`gridItemLayout`(`vertical|horizontal`)、`iconStyle`(`normal|circle`)、`iconSize`、`showDivider`
- 事件：`onTap(item)`、`onFirstAppear(item)`
```xml
<ant-grid items="{{items}}" columns="{{4}}" onTap="onTap" />
```

### Avatar（头像）
- import：`antd-mini/es/Avatar/index`
- props：`src`、`size`(`x-small|small|medium|large`)
```xml
<ant-avatar src="{{avatarUrl}}" size="large" />
```

### Skeleton（骨架屏）
- import：`antd-mini/es/Skeleton/index`
- props：`loading`(true 占位/false 显示子内容)、`animate`、`title`、`avatar`(`bool | {shape,size}`)、`paragraph`(`bool | {rows}`)
```xml
<ant-skeleton loading="{{loading}}" animate avatar title>
  <view>真实内容</view>
</ant-skeleton>
```
> 列表/详情首屏 loading 占位优先用它，替代手写假列表。

### Mask（纯遮罩）
- import：`antd-mini/es/Mask/index`
- props：`show`；事件 `onMaskTap(v)`
> 「遮罩 + 弹层内容」用项目已在用的 **Popup** 更顺手；纯遮罩才用 Mask。

### SwipeAction（列表项滑动操作）
- import：`antd-mini/es/SwipeAction/index`
- props：`rightButtons`/`leftButtons`(`{text,width,bgColor,color,confirmType,confirmText}[]`)、`disabled`、`swiped`、`damping`、`elasticity`
- 事件：`onButtonTap(data, e)`(data 含 `direction`、`btnIdx`)、`onSwipeStart`、`onSwipeEnd`
```xml
<ant-swipe-action rightButtons="{{btns}}" onButtonTap="onTap">
  <view class="row">列表项内容</view>
</ant-swipe-action>
```
> 商品管理「删除/下架」等操作可用它替代 ActionSheet，体验更顺。

---

## 三、antd-mini 没有的组件 → 用原生替代（别瞎引）

经核对源码，下列名字 **库里不存在**，需求出现时用替代方案，**不要 import 不存在的路径**：

| 想要的能力 | antd-mini 无此组件 | 用什么替代 |
|---|---|---|
| 图片 Image | ✗ | 小程序原生 `<image src mode lazy-load onLoad onError onTap />` + 项目 `cdnOssImage` |
| 搜索栏 SearchBar | ✗ | `ant-input` 或原生 `input` + `ant-icon` 自拼（home 就是这么写的） |
| 浮动面板 FloatingPanel | ✗ | `ant-popup` 或原生实现 |
| 下拉刷新 PullToRefresh | ✗ | 页面 `onPullDownRefresh` + `.json` 配 `"pullRefresh":"true"`，或 `<scroll-view refresher-enabled>` |
| 无限滚动 InfiniteScroll | ✗ | `<scroll-view onScrollToLower>` 或页面 `onReachBottom` 分页 |

> 此外库还提供 `Empty`、`Progress`、`Pagination`、`Space`、`Typography`、`ImageUpload`、`Checklist` 等，需要时按 `antd-mini/es/<Name>/index` 引入并查源码 props。
