---
name: "html-css-seo-optimizer"
description: "Optimizes HTML/CSS for SEO by simplifying structure and reducing nesting while maintaining UI. Invoke when refactoring, cleaning up code, or improving semantic structure."
---

# HTML/CSS SEO Optimizer

此技能专注于优化 HTML/CSS 结构，旨在提升 SEO 表现、减少代码冗余并增强语义化，同时保持原有的 UI 视觉效果。

## ⚠️ 绝对原则 (Strict Principle)

**一定不要影响现有的 UI 以及现有的功能！只做标签和结构的优化。**
任何标签的替换、结构的精简或 CSS 的提取，都必须以**视觉效果 100% 还原**和**交互功能（如 JS 事件绑定、Vue/React 指令等）完全不受影响**为不可妥协的前提。

## 核心原则

1.  **语义化优先 (Semantic HTML)**：使用正确的标签（如 `<header>`, `<nav>`, `<main>`, `<article>`, `<footer>`）替代无意义的 `<div>`。但**不要硬套标签**，如果内容不符合语义，保留 `<div>` 更好。
2.  **内容可见性 (Content Visibility)**：**尽可能避免隐藏内容**。**不要使用 `visually-hidden` 或类似的技巧来隐藏内容**，包括不要为了 SEO 而隐藏大量堆砌的关键词。**防止降级**，确保关键内容在任何设备（包括禁用 CSS/JS 的环境）下都可访问。
3.  **移除 HTML 注释 (Remove HTML Comments)**：在生产环境代码中，**移除所有 HTML 注释**。因为注释内容也可能被爬虫索引，影响页面权重，且增加页面体积。
4.  **避免无效和多余属性 (Avoid Invalid & Redundant Attributes)**：不要为了所谓的 SEO 或无障碍访问给标签随意添加无效或不适当的属性（如给普通的 `<div>` 添加 `role="button"`，或者在不需要的地方滥用 `aria-label`）。如果不需要，请保持标签纯净。
5.  **结构扁平化 (Flatten Structure)**：减少不必要的 DOM 嵌套，避免 "div soup"。
6.  **样式与结构分离**：通过 CSS 处理布局和视觉效果，而不是依赖额外的 HTML 包装层。
7.  **无障碍性 (Accessibility)**：确保关键内容对屏幕阅读器和爬虫友好（如 `alt` 属性），但必须正确使用。
8.  **性能优化**：精简 CSS 选择器，减少渲染阻塞。

## 优化检查清单

### 1. 结构简化 (Structure Simplification)

- [ ] **移除 HTML 注释 (Remove Comments)**：**必须**移除模板中的所有 `<!-- comment -->` 注释，防止敏感信息泄露或被搜索引擎错误索引。
- [ ] **移除冗余容器 (Remove Redundant Wrappers)**：
    -   检查是否有仅用于设置 margin/padding 或背景色的外层 `<div>`，尝试将其样式合并到子元素或父元素中。
    -   **移除 Flex 包装层**：如果一个 `div` 仅用于 `display: flex` 且没有其他视觉效果，尝试将其样式合并到父容器或让子元素直接参与布局。
- [ ] **减少层级深度 (Minimize Nesting)**：DOM 树过深会影响爬虫抓取效率和渲染性能。**尽可能简化标签**，不要有多层无意义的嵌套。如果父子元素可以合并为一个元素而不影响布局，则应合并。
- [ ] **移除间隔 Div**：禁止使用空的 `<div>` 或 `<br>` 来制造间距，**必须**使用 CSS 的 `margin` 或 `gap` 属性来实现。
- [ ] **替代无语义标签**：
    -   顶部导航 -> `<nav>`
    -   侧边栏 -> `<aside>`
    -   文章内容 -> `<article>`
    -   独立区块 -> `<section>`
    -   页眉/页脚 -> `<header>` / `<footer>`
- [ ] **列表优化**：对于列表内容，务必使用 `<ul>`/`<ol>` + `<li>`，而不是一堆 `<div>`。

### 2. 文本与内容 (Text & Content)

- [ ] **标题层级 (Heading Hierarchy)**：
    -   页面必须有且仅有一个 `<h1>`（通常包含核心关键词）。
    -   `<h2>` - `<h6>` 应逻辑清晰，不仅是样式调整，更是内容大纲。
    -   **`<section>` 标签规范**：不要硬套标签。如果一个区块没有标题元素（`<h2>`-`<h6>`），应优先考虑使用 `<div>` 而非 `<section>`。
- [ ] **图片 Alt 属性**：所有 `<img>` 标签必须包含描述性的 `alt` 属性。装饰性图片应设为 `alt=""` 或用 CSS 背景图实现。
- [ ] **链接与交互属性**：
    -   `<a>` 标签应包含有意义的文本（避免 "点击这里"）。
    -   外部链接视情况添加 `rel="nofollow"`。
    -   重要链接添加 `title` 属性。
    -   **避免滥用 ARIA 和 Role 属性**：不要给普通的容器（如 `<div>`、`<section>`、`<nav>`）添加 `aria-label` 或 `role="button"` 等属性来试图提升 SEO。这毫无意义，反而会破坏 HTML 的纯净度并干扰屏幕阅读器的体验。如果元素没有明确的无障碍需求，请不要添加 `aria-label`。交互元素应该直接使用 `<button>` 或 `<a>`。

### 3. CSS 优化 (CSS Optimization)

- [ ] **提取内联样式 (Extract Inline Styles)**：**必须**将 `style="..."` 属性中的内联样式提取到 CSS 类或 `<style>` 块中，保持 HTML 纯净。
- [ ] **CSS 背景图替代 Img (CSS Background)**：对于纯装饰性的图片（如纹理、装饰图标），**推荐**将其从 `<img>` 标签移动到 CSS 的 `background-image` 属性中，以减少 HTML 杂质并提升语义化。但要注意，如果图片包含需要被索引的内容（如商品图、Logo），则必须保留 `<img>` 并添加 `alt`。
- [ ] **视觉隐藏 (Visually Hidden) 禁用**：
    -   **严禁使用 `visually-hidden` 技巧**：不要为了迎合标签的结构规范（比如强行为 `<nav>` 或 `<section>` 塞入一个 `<h2>`），而故意使用 `.visually-hidden` 去隐藏一个其实并不需要在页面上展示的标题。如果设计上没有标题，直接使用没有标题的结构，或者使用 `<div>` 等非强制带标题的标签。
    -   **禁止**使用 `display: none` 或 `visibility: hidden` 隐藏核心内容，这会导致内容被爬虫忽略。
- [ ] **利用伪元素**：对于装饰性图标或修饰符，使用 `::before` 或 `::after`，减少 HTML 标签。
- [ ] **防止降级 (Graceful Degradation)**：确保在 CSS 加载失败或被禁用的情况下，HTML 结构依然能够呈现出清晰的内容层级（Heading 结构清晰，链接可用，图片有 Alt）。

## 常见重构模式 (Refactoring Patterns)

### 模式 A：Section 标题规范

**Before:**
```html
<div class="features">
  <div class="title">Our Features</div>
  <p>Content...</p>
</div>
```

**After:**
```html
<section class="features">
  <h2>Our Features</h2>
  <p>Content...</p>
</section>
```

### 模式 B：提取内联样式

**Before:**
```html
<div style="margin-top: 20px; color: red;">Error Message</div>
```

**After:**
```html
<!-- HTML -->
<div class="error-message">Error Message</div>

<!-- CSS -->
<style>
.error-message {
  margin-top: 20px;
  color: red;
}
</style>
```

### 模式 C：去除多余的包装层

**Before:**
```html
<div class="card-wrapper">
  <div class="card-inner">
    <div class="card-content">
      <h3>Title</h3>
      <p>Text</p>
    </div>
  </div>
</div>
```

**After:**
```html
<article class="card">
  <h3>Title</h3>
  <p>Text</p>
</article>
```

### 模式 B：语义化导航

**Before:**
```html
<div class="nav">
  <div class="nav-item">Home</div>
  <div class="nav-item">About</div>
</div>
```

**After:**

```html

<nav>
    <ul>
        <li><a href="/">Home</a></li>
        <li><a href="/about">About</a></li>
    </ul>
</nav>
```

### 模式 C：图片标题优化

**Before:**
```html
<div class="logo"></div> <!-- 背景图实现 -->
```

**After:**
```html
<h1 class="logo">
  <a href="/">
    <img src="logo.png" alt="Brand Name">
  </a>
</h1>
```

## 使用指南

当用户要求优化页面结构、提升 SEO 或精简代码时，请按以下步骤操作：

1.  **分析现状**：识别当前代码中过深的嵌套、无语义的 `div` 堆砌和 SEO 缺失点。
2.  **制定方案**：提出具体的标签替换和结构扁平化建议。
3.  **实施重构**：
    -   替换标签（如 `div` -> `section`）。
    -   合并样式，移除多余容器。
    -   添加必要的 SEO 属性（`alt`, `title`, ARIA）。
    -   确保视觉效果（UI）不变。
4.  **验证**：确认 HTML 结构更清晰，且未破坏原有布局。
