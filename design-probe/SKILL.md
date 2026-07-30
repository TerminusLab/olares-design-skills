---
name: design-probe
description: >-
  探测一个项目的设计体系并产出盘点快照：代码侧的 design token / 语义变量 / 工具类 / 组件库 / 图标约定 / 断点，
  Figma 侧的变量 / 组件 / 文字与效果样式，以及 Code Connect 映射覆盖率。当用户说"摸清这个项目的设计体系"
  "有哪些 token 和组件能用""扫一下设计系统""建立设计词汇表"，或在落地 Figma 稿前需要先知道可用词汇时使用。
  产出 docs/design-system-inventory.md。
---

# design-probe

**建立词汇表。** 后面所有视觉值都要往这套词汇上映射，所以这一步必须早于读 Figma 稿。

**先读 [references/constraints.md](references/constraints.md)**。术语见本仓库根 `CONTEXT.md`。

---

## 先看有没有现成盘点

目标仓库存在 `docs/design-system-inventory.md` 时，读它的头部元信息：

- **源文件清单里的文件都没变**（比对 mtime 或内容哈希）→ 直接用，别重扫。
- **有变化**，只重扫受影响的部分，并更新元信息。

盘点是快照，不是真理。过期的盘点比没有盘点更危险——它看起来可信。

## 两侧并行扫

代码侧与 Figma 侧互不依赖，同时开始。

---

## 一、代码侧

### 1. Token 分层

通常在 `styles/` / `css/` / `theme/` 目录。要分清三层，**别把 primitive 当语义层用**：

- **primitive 调色板**（`$grey-*`、`$orange-*`）——底层，一般不直接用。
- **语义层变量**（`--q-background-1`、`--color-text-secondary`）——**注意亮 / 暗两套定义**，通常在 `body` 与 `body.dark` 两个选择器下成对出现。
- **工具类**（`.bg-background-1`、`.text-ink-2`）。

还要记：间距尺度、排版尺度、圆角、阴影、断点、移动端字号（常有独立文件）。

### 2. 工具类有两个来源，分别去查

- **项目自定义**：项目样式目录里**逐条手写**的声明。Quasar 调色板里没有的语义名（`background-hover`、`ink-*`、`separator`）只可能来自这里。
- **框架自带**：框架源码的 css 目录（如 `node_modules/quasar/src/css/core/*`）。通用排版、间距、flex、定位、显隐来自这里。

两处都可能被项目二次覆盖，**以项目覆盖为准**。

**别凭记忆判断某个类存在**。搜一下声明处和用量：有声明且高频 = 真实；无声明或极低频 = 多半是写错的死类。

### 3. 组件库

扫组件库的导出入口（如 `src/packages/index.ts`），列出可复用组件与关键 props。

同时记下**姊妹仓库**——同一个团队里对齐了同一设计系统的其他仓库，常有能直接移植的封装。

### 4. 图标与资源约定

图标走字体名还是 SVG 资源？字体的话是哪个 set、**命名前缀是什么**（有的 set 要 `sym_r_` 之类的前缀，写错了图标不显示或显示错图）。

前缀以项目现有写法为准，别照 Figma 图层名抄。

暗色变体有没有命名约定（`xxx_dark.svg` / `xxx-dark.svg`）。

### 5. 响应式惯例

断点定义在哪、取值多少；「设备是移动端」与「视口窄」是两套判断，项目各区域用哪套；PC / 移动是分文件还是单文件自适应。

---

## 二、Figma 侧

需要 `fileKey`。没有就问人要，或从盘点文档里读上次记录的。

1. `get_libraries({ fileKey })` — 看有哪些库已加入、哪些可加入。拿到 `libraryKey` 用于缩小后续搜索范围。
2. `search_design_system` 分别开 `includeVariables` / `includeComponents` / `includeStyles`，用**短词并行多查几次**（`gray`、`background`、`space`、`radius`、`button`、`card`…），别指望一个复合查询命中。
3. 文件里已有成品页面时，**直接读它用了什么**最权威——遍历实例拿组件 key、遍历 `boundVariables` 拿变量，比搜索准得多。

⚠️ `figma.variables.getLocalVariableCollectionsAsync()` **只返回本文件的局部变量**。它返回空**不代表没有变量**——库变量对这个 API 不可见。判断"有没有变量"必须用 `search_design_system`。

---

## 三、Code Connect 覆盖率

搜代码库里的映射文件：`*.figma.ts` / `*.figma.js` / `*.figma.tsx`、含 `@FigmaConnect` 的 `.kt`、含 `FigmaConnect` 的 `.swift`。

统计：有多少组件有映射、哪些常用组件没有。

**覆盖率低不是错误**，如实记下即可（走记账，不是卡点）。它决定后续落地是"查"还是"搜"。

---

## 四、两种空体系 → 卡点 2

- **代码侧扫不到任何设计变量**（像只有几个纯 CSS 文件、零变量声明的项目）：停下来告知"此项目无词汇表"，给建体系的方案供选，别擅自塞一套进去。
- **Figma 侧无可用库**：停下来告知，给方案供选——从代码反向建库 / 引入社区 UI kit / 先手工建。

详见 `references/constraints.md` 卡点 2。

---

## 产出：docs/design-system-inventory.md

写进**目标仓库**（不是 skill 仓库）。

头部必须有元信息，否则无法判断新鲜度：

```markdown
<!-- 生成时间: 2026-07-30T16:00+08:00 -->
<!-- 源文件:
  src/styles/theme.scss
  src/styles/variables.sass
  src/packages/index.ts
  quasar.config.js
-->
<!-- Figma fileKey: ABC123 -->
```

正文用**结构化表格**——`design-verify` 会把 token 那几张表当作合法值集合直接读，格式散了它就用不了：

```markdown
## 颜色

| token | 亮色值 | 暗色值 | 工具类 | 来源 |
|---|---|---|---|---|
| ink-1 | #1a1a1a | #ffffff | .text-ink-1 | src/styles/theme.scss |

## 间距

| token | 值 | 工具类 |
|---|---|---|
| md | 12px | q-pa-md / q-ma-md |

## 排版

| token | 字号/行高/字重 | 工具类 |
|---|---|---|
| body1 | 16/24/400 | .text-body1 |

## 组件库

| 组件 | 用途 | Code Connect |
|---|---|---|
| BtDialog | 弹窗 | ✅ src/components/BtDialog.figma.ts |
| BtSwitch | 开关 | ❌ 缺映射 |

## 图标

set、命名前缀、SVG 资源目录、暗色变体约定

## 断点与响应式惯例

## Figma 侧

库名与 libraryKey、变量命名规律、可用组件
```

最后附一段**推导规律**而不只是清单：工具类名怎么从 token 名推出来（前缀 + token 名原样？还是有别的规则），这样遇到表里没列的 token 也能推对。
