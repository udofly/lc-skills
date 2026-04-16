---
name: "mobile-pc-adaptive"
description: "检测并修复移动端 H5 页面在 PC 屏幕上的布局问题。严格限制仅针对用户提供的代码文件或片段进行修复，禁止进行全局搜索或修复。"
---

# 移动端 PC 适配助手

此 Skill 帮助你识别和修复移动端网页在 PC 屏幕（桌面端）显示时的布局问题。
它专门针对那些在 PC 上会拉伸至全屏宽度，而不是限制在移动应用容器宽度（例如 450px）内的 `position: fixed` 元素。

**重要限制：**
- **仅针对用户提供的文件或代码块**：请勿对整个项目进行全局搜索或修复。只处理用户明确指出或当前上下文中的文件。
- **局部修复**：即使在文件中，也优先关注用户选中的部分或明显有问题的部分，除非用户要求全文件检查。

## 常见问题

1.  **全宽固定元素**：`position: fixed; width: 100%` 的元素在 PC 上会占据整个浏览器宽度，破坏了移动端模拟效果。
2.  **偏离中心元素**：固定元素通常对齐到 `left: 0`，这导致它们在 PC 上紧贴屏幕左边缘，而不是与主要内容居中对齐。
3.  **内联样式**：硬编码的内联样式阻碍了使用媒体查询进行 PC 端特定的样式覆盖。

## 检测规则

扫描提供的代码片段查找：
-   `position: fixed` 或 `position: sticky`
-   `width: 100%` 或 `width: 100vw`
-   `left: 0`, `right: 0`, `bottom: 0`, `top: 0`
-   默认使用固定定位的 Vant UI 组件（如 `van-popup`, `van-tabbar`, `van-nav-bar`）。

## 修复策略

### 1. 提取内联样式
如果元素使用内联样式（例如 `<div style="position: fixed...">`），将其提取到 CSS 类中，以便使用媒体查询。

### 2. 使用全局变量控制宽度（推荐）
**必须优先使用 `--app-width` 全局变量，禁止硬编码 `450px`**。利用该变量（在 `App.vue` 中已定义响应式规则）来设置宽度，配合居中定位，即可同时适配移动端和 PC 端。

**标准修复模式：**

```css
.fixed-element {
    position: fixed;
    width: var(--app-width);      /* 核心：必须使用变量，自动适配移动端(100vw)和PC端(450px) */
    left: 0;                      /* 核心：配合 right: 0 和 margin: auto 实现居中 */
    right: 0;                     /* 核心：配合 left: 0 和 margin: auto 实现居中 */
    margin: 0 auto;               /* 核心：水平居中 */
    bottom: 0;
    /* 其他样式 */
}
```

### 3. 公共组件样式提取与统一修改
对于 Vant UI 等公共组件（如 `van-popup`, `van-tabbar`, `van-nav-bar`），**严禁直接修改组件库源码**，也**严禁在每个页面重复覆盖样式**。

**原则：**
1.  **不影响移动端显示**：任何修改必须保证在移动端（< 450px）下表现与原先完全一致。
2.  **统一提取**：将公共组件的覆盖样式提取到全局样式文件（如 `App.vue` 或 `common.less`）中。
3.  **Scoped 穿透慎用**：在局部组件中使用 `:deep()` 覆盖公共组件样式时，务必确保不影响其他页面；推荐优先使用全局类名覆盖。

**示例（在 `App.vue` 中统一处理）：**

```css
/* App.vue 或全局样式文件 */
@media only screen and (min-width: 450px) {
    /* 统一修正 Vant 弹窗在 PC 端的宽度和定位 */
    .van-popup--bottom,
    .van-tabbar,
    .van-nav-bar {
        max-width: var(--app-max-width);         /* 限制最大宽度 */
        left: 0 !important;                      /* 强制居中 */
        right: 0 !important;                     /* 强制居中 */
        margin: 0 auto !important;               /* 强制居中 */
        transform: none !important;              /* 移除 transform */
    }
    
    /* 针对底部弹窗的特殊处理 */
    .van-popup--bottom {
        bottom: 0;
        width: var(--app-width);
    }
}
```

### 4. 禁止硬编码宽度
禁止使用 `width: 450px` 或 `max-width: 450px` 等硬编码值。必须统一使用 `--app-width`（推荐）或 `--app-max-width` 变量，以确保全站统一配置和可维护性。**注意：项目可能未定义 `--app-max-width`，优先使用 `--app-width`**。

## 示例

**修复前：**
```html
<div style="position: fixed; bottom: 0; width: 100%; background: white;">
    提交
</div>
```

**修复后：**
```html
<div class="fixed-bottom-bar">
    提交
</div>

<style>
.fixed-bottom-bar {
    position: fixed;
    bottom: 0;
    width: var(--app-width);      /* 使用变量自动适配 */
    left: 0;                      /* 居中定位 */
    right: 0;                     /* 居中定位 */
    margin: 0 auto;               /* 居中定位 */
    background: white;
    z-index: 100;
}
</style>
```
