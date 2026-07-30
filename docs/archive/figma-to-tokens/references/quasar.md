# Quasar 布局 / 样式 / 组件参考（figma-to-tokens 配套）

面向「拿到 Figma 稿，要用 Quasar 把它画出来」的场景。**目的是让你知道"该找什么、去哪查、哪里会翻车"**，不是背清单。

事实来源：Quasar 官方文档（quasar.dev）+ 本地 `node_modules/quasar/src/css/**` 与 `node_modules/quasar/dist/api/*.json`（实测 terminus-cloud，装的是 **quasar 2.12.0**）。

---

## 0. 权威源：先查再写（比记忆可靠）

写任何一个类名 / props 前，能查到就别猜：

| 想确认什么 | 去哪查 |
|---|---|
| 某个工具类是否存在、生成规则 | `node_modules/quasar/src/css/core/*.sass`（flex / typography / visibility / positioning / size / colors / helpers） |
| 间距 / 排版 / 断点 / 调色板的**实际取值** | 项目自己的 `quasar.variables.sass`（覆盖 Quasar 默认），再看 `node_modules/quasar/src/css/variables.sass` |
| 某组件完整 props / slots / events | `node_modules/quasar/dist/api/<QComponent>.json`（离线、与**当前安装版本**严格一致，比在线文档准） |
| 官方文档正文 / 版本 API 变更 / 官方 best practice | **`quasar-skilld` skill**（`~/.claude/skills/quasar-skilld/`，463 篇官方文档镜像 + release/issue/discussion） |
| 响应式 flex/spacing 类是否可用 | `quasar.config.js` → `framework.cssAddon`（默认 **false**，见 §3.4） |

快速查 props：

```bash
python3 -c "import json;d=json.load(open('node_modules/quasar/dist/api/QBtn.json'));print(list(d['props']))"
```

### 和 `quasar-skilld` 的分工（别重复劳动）

| | `quasar-skilld` | 本文件 |
|---|---|---|
| 内容 | 官方文档全量镜像、逐版本 API 变更、通用 best practice | Figma→代码落地视角、**本仓库实测覆盖值**、真实返工点 |
| 适合回答 | "QTable 有哪些 props" "QLayout view 怎么写" "2.17 改了什么" | "这个 12px 该写成什么类" "为什么我的间距不生效" |
| 项目差异 | **不知道**（它是通用文档） | 知道（断点被改、`$spaces` 扩到 9 档、`cssAddon` 没开、图标用 `sym_r_`、`--q-primary` 被重定向） |

⚠️ **版本差**：`quasar-skilld` 基于 **2.19.3**，本仓库装的是 **2.12.0**。它标 "new in 2.17/2.18" 的 props（如 `QTable` 的 `table-row-class-fn`、`QMenu` 的 `no-esc-dismiss`、`QSelect` 的 `disable-tab-select`）**本仓库没有**。凡是"新增"字样的，落地前回 `dist/api/*.json` 核一遍。

> 优先级不变：**项目组件库（`Bt*` 等）> Quasar 组件（`q-*`）> 手写**；**项目语义工具类 > Quasar 工具类 > scoped CSS**。

---

## 1. 布局系统 QLayout（整页骨架）

`QLayout` 托管整个窗口，把 header / footer / 左右 drawer / page 组织成 3×3 矩阵，多页面共用。

```vue
<q-layout view="hHh Lpr fFf">
  <q-header elevated><q-toolbar>…</q-toolbar></q-header>
  <q-drawer v-model="left" side="left" :width="280" bordered>…</q-drawer>
  <q-page-container>
    <router-view />   <!-- 子路由注入点；页面组件根节点用 <q-page> -->
  </q-page-container>
  <q-footer>…</q-footer>
</q-layout>
```

### 1.1 `view` 字符串（11 个字符，大小写敏感）

`xxx xxx xxx` = 3 个 header 行 + 空格 + 3 个中间行 + 空格 + 3 个 footer 行。

- header 行 `l/h` `h/H` `r/h` ｜ 中间行 `l/L` `p` `r/R` ｜ footer 行 `l/f` `f/F` `r/f`
- **大写 = fixed**（`H` 固定头、`L` 固定左抽屉、`R` 固定右抽屉、`F` 固定脚）。
- 左右两列的字母决定"抽屉是否越过 header/footer"：`hhr lpr ffr` = 右抽屉在 header/page/footer 右侧；`hHh Lpr fFf` = 左抽屉通高、头脚固定。
- **即使不用 footer / 右抽屉，9 个位置也必须写全。**
- QDrawer 设成 `overlay` 时强制 fixed，无视 `l/L`。

本仓库实测：`src/layouts/main/MainLayout.vue` 用 `view="lHh Lpr lFf"`。

### 1.2 硬性约束

- **QLayout 及 QHeader / QFooter / QDrawer / QPageContainer 上不能用 `margin`**（位置由 layout 接管，会直接错位）；留白用 `padding` / `q-pa-*`。
- **Containerized layout（嵌在页面里的局部 layout）必须显式给 `height` / `min-height`**，否则不工作；此时抽屉 `breakpoint` 比的是容器宽度，不是窗口宽度。
- 页面根节点用 `<q-page>`（`padding` prop 自动加上与 layout 匹配的内边距）。

### 1.3 配套组件

| 组件 | 用途 | 关键 props / 坑 |
|---|---|---|
| `QHeader` / `QFooter` | 顶栏 / 底栏 | `reveal`（滚动收起/露出）`bordered` `elevated` `height-hint`（SSR 先占高避免跳动） |
| `QDrawer` | 侧栏 | `side` `width` `breakpoint`（窄于它自动转 overlay）`overlay` `mini` `mini-to-overlay` `show-if-above` `behavior` |
| `QPageContainer` / `QPage` | 内容区 | QPage 必须在 QPageContainer 内 |
| `QPageSticky` | 页面内固定元素（FAB） | `position` `offset` `expand` |
| `QPageScroller` | 回到顶部 | 常配 QPageSticky |
| `QScrollArea` | 自定义滚动条区域 | **必须显式给高度**，否则塌成 0；`thumb-style` / `bar-style` 定制 |
| `QToolbar` / `QToolbarTitle` / `QSpace` | 栏内布局 | `QSpace` = 弹性占位，比手写 `margin-left:auto` 好 |

移动端：侧栏走 overlay drawer 或底部 sheet；底部固定操作栏留 `env(safe-area-inset-bottom)`。

---

## 2. Flex Grid（`row` / `column` / `col-*`）

布局主力，**优先用它，别手写 `display:flex`**。

### 2.1 父容器（必须先声明方向，子类才生效）

`row`（横）｜`column`（纵）｜`flex`；加 `inline` 变 inline-flex；加 `reverse` 反向。

**默认 `flex-wrap: wrap`**（三者都是）。不想换行必须显式 `no-wrap`；`reverse-wrap` 反向换行。

对齐：

- 主轴 `justify-start|end|center|between|around|evenly`
- 交叉轴 `items-start|end|center|baseline|stretch`
- 多行 `content-start|end|center|between|around|stretch`
- 便捷 `flex-center`（= `items-center` + `justify-center`）

### 2.2 子元素

- `col-0..12` 栅格宽度；`offset-0..12` 左偏移。
- `col` 吃掉剩余空间（可缩）｜`col-auto` 只占内容所需 ｜`col-grow` 至少内容宽、有空间就长 ｜`col-shrink` 至多内容宽、不够就缩。
- 自身对齐 `self-start|end|center|baseline|stretch`；顺序 `order-first|last|none`。
- 一行不限 12 点，超过自动换行——这正是"窄屏堆叠、宽屏并排"的实现方式。

### 2.3 响应式栅格（**默认就有**）

`col-<bp>-<n>` / `offset-<bp>-<n>` / `col-<bp>-auto`，bp ∈ `xs sm md lg xl`，移动优先：

```html
<div class="row">
  <div class="col-xs-12 col-sm-6 col-md-4">…</div>
</div>
```

生成源：`core/flex.sass` 末尾 `@each $name,$size in $sizes` —— 所以**只有 `col-*` / `offset-*` 有响应式版本**。

### 2.4 其余响应式 flex/spacing 类需要 `cssAddon: true`（本仓库**没开**）

`row-md`、`justify-md-center`、`items-lg-end`、`no-wrap-sm`、`q-gutter-md-sm`、`q-pa-sm-md`、`flex-md-block` 这一整类，只有 `quasar.config.js` → `framework: { cssAddon: true }` 时才由 `css/flex-addon.sass` 生成。

> **本仓库未配置 → 上面这些全是死类，写了不报错但完全不生效。** 需要响应式时：用 `col-<bp>-*`、可见性类（§6）、或 `$q.screen` 条件渲染。换项目务必重新确认。

### 2.5 Gutter：`q-gutter-*` vs `q-col-gutter-*`（高频翻车点）

| | `q-gutter-{size}` | `q-col-gutter-{size}` |
|---|---|---|
| 用于 | 子元素**没有** `col-*` 宽度 | 子元素**有** `col-*` 宽度 |
| 实现 | 父负 margin + 子正 **margin** | 父负 margin + 子正 **padding** |
| 子元素能否直接加 background/border | 能 | **不能**（padding 被占用，要再套一层） |

方向变体 `-x-` / `-y-`；档位取项目 `$flex-gutter` 的 key（本仓库 `none xs sm md lg xl xxl xxxl xxxxl`）。

**三个必须记住的副作用：**

1. **两者都给父元素加负 margin** → 父元素上**不要**再写 background / margin / border，会露馅。正确做法：外面再包一层容器，样式写容器上，容器加 `overflow-auto` 或 `row`。
2. **`q-gutter-*` 语境下容器是 wrap 的**：在**定高 + 可滚动的纵向堆叠容器**（弹窗/抽屉 body）里用它做垂直间距，子项会被折到第二列、与前面的元素并排重叠、看起来像"消失了"。
   → 纵向堆叠改用 `column` + `no-wrap` + 固定 `gap`（值对齐 `$space-*`）。
   → 改完用浏览器/CDP 量相邻子项的 `top` / `left`，确认真的是上下堆叠。
3. `q-gutter-*` 适合"本来就允许换行的一排 chip / 按钮"，不适合"必须单列的定高滚动区"。

---

## 3. 间距 Spacing

语法：`q-[p|m][t|r|b|l|a|x|y]-[none|auto|<size>]`

- 类型 `p` padding / `m` margin
- 方向 `t` `r` `b` `l` `a`(全部) `x`(左右) `y`(上下)
- `auto` 仅对 margin 的 `l` / `r` / `x` 有效（`q-mx-auto` 居中）
- `none` 用来**复位浏览器默认 margin**（`h1..h6` / `p` 自带 margin，`q-ma-none` 干掉它）

档位取项目 `$spaces` 的 key。**Quasar 默认只有 `none xs sm md lg xl`；本仓库扩到 9 档**（base 8px）：

`xs=4 · sm=8 · md=12 · lg=20 · xl=32 · xxl=44 · xxxl=56 · xxxxl=80`

> `$spaces` 每档是 `(x: …, y: …)` 两个值，`q-pa-md` 展开成 `padding: <y> <x>`。本仓库 x=y，其他项目未必。
> Figma 的 `space-md=12` 直接对应 `md`，不要硬编码 `12px`。

---

## 4. 排版 Typography

**类名 = `text-` + `$headings` map 的 key 原样。** key 怎么写类名就怎么拼，不擅自加连字符。

- Quasar 默认 key：`h1..h6 subtitle1 subtitle2 body1 body2 caption overline`
- **本仓库扩展了 `subtitle3` / `body3`** → `text-subtitle3` / `text-body3` 可用（项目覆盖了 `$headings`；换项目先确认）
- 由此推出的坑：`text-body-1`（硬塞连字符）不在 key 里，Quasar 不会生成，是**死类**。

其他排版工具类（`core/typography.sass`）：

- 字重 `text-weight-thin|light|regular|medium|bold|bolder`（100/300/400/500/700/900），另有 `text-bold` `text-italic` `text-strike`
- 对齐 `text-left|right|center|justify`
- 大小写 `text-uppercase|lowercase|capitalize`
- 不换行 `text-no-wrap`
- 截断（在 `core/visibility.sass`）`ellipsis` / `ellipsis-2-lines` / `ellipsis-3-lines`

`h1..h6` 标签本身被 `$h-tags` 赋了样式，所以标题标签常需 `q-ma-none` 复位。

---

## 5. 颜色

### 5.1 两种来源，分清再用

1. **Quasar 调色板 + 品牌色**（`core/colors.sass` 自动生成）：`text-<color>` / `bg-<color>`，`<color>` 是注册的品牌色（`primary secondary accent dark positive negative info warning`）和调色板色（`red-5`、`grey-8`…）。
2. **项目自定义语义色**（Quasar 调色板里没有的名字，如 `ink-1` `background-hover` `separator` `orange-default`）：必须由项目**逐条手写声明**才存在。本仓库在 `src/packages/lib/styles/variables-bg.sass`（`.bg-<name>`）、`variables-text.sass`（`.text-<name>`）声明，取值在 `theme.scss` 的 `--q-<name>`（light/dark 成对）。

**通则：类名 = 前缀 + 源 token 名原样。** 排版 key 恰好不含连字符（`body1`），颜色名恰好含（`ink-1`），不是两条规则，是同一条。

`<style lang="scss">` 里用 scss 变量（如 `$ink-2` = `setColorVar(ink-2)` = `var(--q-ink-2)`），**不要**硬编码 `var(--q-ink-2)` 或 hex。用了语义变量自动跟随亮/暗，不用写 dark 分支。

### 5.2 `primary` 陷阱（实测返工点）

品牌色最终落在 CSS 变量 `--q-primary` 上，**项目可以在 CSS 层重新指向别的 token**：

- 本仓库 Space 构建：`src/css/app.scss` → `--q-primary: var(--q-orange-default)`
- 本仓库 AssistHub SPA 构建：`src/assisthub/css/app.scss` → `--q-primary: var(--q-blue-default)`
- 都没覆盖时才是 sass `$primary`（Quasar 默认 `#1976D2`）

所以**别默认 `color="primary"` 就是设计稿那个蓝**。要和同页其它品牌色控件（如开关）一致，直接用同一个语义色名（`color="blue-default"`），而不是裸 `primary`。

---

## 6. 断点与可见性（**本仓库有严重不一致，务必读**）

### 6.1 CSS 可见性类（`core/visibility.sass`）

- 只在某档显示：`xs` `sm` `md` `lg` `xl`
- 小于 / 大于：`lt-sm` `lt-md` `lt-lg` `lt-xl` / `gt-xs` `gt-sm` `gt-md` `gt-lg`
- 隐藏：`xs-hide` … `xl-hide`
- 平台：`desktop-only` `mobile-only` `touch-only` `platform-ios-only` `electron-only` `within-iframe-only`…，及对应 `*-hide`
- 方向 `orientation-portrait` / `orientation-landscape`；打印 `print-only` / `print-hide`
- 配 `inline` 用于 inline-block：`<span class="gt-sm inline">`

### 6.2 断点数值：CSS 与 JS 是**两套**

| | xs | sm | md | lg | xl |
|---|---|---|---|---|---|
| Quasar 默认 CSS（`$breakpoint-*`） | ≤599 | 600–1023 | 1024–1439 | 1440–1919 | ≥1920 |
| **本仓库覆盖后的 CSS** | **≤799** | **800–1023** | **1024–1599** | **1600–1919** | ≥1920 |
| JS `$q.screen`（`Screen.js` 默认） | <600 | 600–1023 | 1024–1439 | 1440–1919 | ≥1920 |

> **陷阱：改 sass `$breakpoint-*` 不会改 JS `$q.screen` 阈值**（`Screen.setSizes()` 反过来也不改 CSS）。本仓库两者在 **600–799px** 和 **1440–1599px** 两个区间**互相矛盾**：CSS 认为是 `xs` / `md`，JS 认为是 `sm` / `lg`。
> → 同一个响应式行为**别一半用 CSS 类一半用 `$q.screen`**，选一套贯穿；跨断点显隐要在这两个区间实测。

### 6.3 JS 侧

```vue
<q-list :dense="$q.screen.lt.md">…</q-list>
```

`$q.screen.name`（'xs'…）/ `.lt.*` / `.gt.*` / `.xs`…；组件外 `import { Screen } from 'quasar'`。
另有 `$q.platform.is.mobile`（**设备**，不是视口）——分清它和 `$q.screen`（视口），按所在区域既有惯例选。
官方建议：**能用 CSS 可见性类就别用 JS**（少重渲染）；需要"根本不渲染"时才用 JS。

---

## 7. 其他常用工具类（写 scoped CSS 前先扫一眼）

| 分类 | 类名 |
|---|---|
| 尺寸 | `fit`(100%×100%) `full-width` `full-height` `window-width` `window-height` `block` `inline-block` |
| 定位 | `relative-position` `absolute` `fixed` + `-top/-right/-bottom/-left/-center/-full/-top-left`… `float-left/right` `vertical-top/middle/bottom` |
| 层级 | `z-top`（普通组件之上、弹层之下）`z-max`（最高） |
| 滚动 | `scroll` `no-scroll` `overflow-auto` `overflow-hidden` `overflow-hidden-y` `hide-scrollbar` |
| 边框 | `rounded-borders` `border-radius-inherit` `no-border` `no-border-radius` `no-box-shadow` `no-outline` |
| 阴影 | `shadow-1..24` / `shadow-up-1..24` / `no-shadow`（`core/elevation.sass`）；下拉/弹窗默认 `0 4px 10px rgba(0,0,0,.2)`（`.q-menu` 自带） |
| 鼠标 | `non-selectable` `no-pointer-events` `all-pointer-events` `cursor-pointer` `cursor-not-allowed` `cursor-inherit` `cursor-none` |
| 状态 | `disabled` `hidden`（不占位）`invisible`（占位）`transparent` `dimmed` `light-dimmed` |
| 复位 | `no-margin` `no-padding` |
| 变换 | `rotate-45/90/…/315` `flip-horizontal` `flip-vertical` |
| 间隔 | `on-left`(margin-right:12px) `on-right`(margin-left:12px) |

**自检**：每写一条 `<style>` 规则前问——这条 `display:flex` / `margin` / `gap` / `font-size` / `color`，上面有没有现成的？有就挂类。scoped 自定义类只保留三种情况：固定像素尺寸无对应工具类、主题相关的资源切换、项目 token 里确实没有的值（并注释原因）。

---

## 8. 暗色模式

- `$q.dark.set(true|false|'auto')`；`auto` 跟随 `prefers-color-scheme` 且动态生效。**SSR 下别用 `auto`**（服务端先渲染 light，客户端再同步会闪）。
- body 上挂 `body--light` / `body--dark`，用它写差异样式；覆盖暗色页底色用 `body.body--dark { background: … }`。
- 所有带 `dark` prop 的 Quasar 组件会自动置 true，**不用手写 `:dark="…"`**。
- 用项目语义色变量（`theme.scss` 已定义 light/dark 两套）就无需写 dark 分支。**只有主题相关的切图**（两张不同插画）才需要 `body.body--dark` 切 `display`。

---

## 9. 图标 QIcon

`<q-icon name="…" size="20px" color="ink-2" />`。`name` 的**前缀决定用哪个图标集**（源：`node_modules/quasar/src/components/icon/QIcon.js`）：

| 前缀 | 含义 |
|---|---|
| 无前缀 | 当前 `iconSet`（默认 material-icons，ligature 名如 `chevron_right`） |
| `o_` / `r_` / `s_` | Material **Icons** outlined / round / sharp |
| **`sym_o_` / `sym_r_` / `sym_s_`** | Material **Symbols** outlined / rounded / sharp |
| `mdi-` `fa-…` `ion-` `eva-` `ti-` `la-` `bi-` `bt-` `icon-` | 对应第三方图标库 |
| `img:<path>` | 直接渲染一张图片（可用于 `assets/*.svg`） |
| `svguse:<file>#<id>` | 引用 SVG sprite 里的 symbol（可继承 `currentColor`） |

对应图标集必须在 `quasar.config.js` → `extras` 引入才有字体。本仓库 `extras: ['roboto-font','material-icons','material-symbols-rounded']`，实际用法几乎全是 **`sym_r_*`**（如 `sym_r_check_circle`）——**写错前缀 = 图标不显示或显示错图**。落地前 `rg 'q-icon'` 看现存写法，别照 Figma 图层名直接抄。

Figma 图标落地三档：① 能对上图标集名 → 直接 `q-icon`；② 自定义单色 → 导 SVG，优先 `currentColor` 内联 / `svguse:`（自动跟随主题，免双份）；③ 多色插图 → 导资源，实在不能 currentColor 才做 `_dark` 变体。

---

## 10. 组件速查（Figma 元素 → Quasar 组件）

**先搜项目组件库和姊妹仓库有没有封装（`BtButton` / `BtDialog` / `BtSwitch` / `BtMenu` / `BtScrollArea` / `TerminusAvatar`…），再用原生 `q-*`。** 别停在"`q-toggle` 看着够用"就动手——项目封装通常已经把视觉、主题色、宽度约定对好了，自己套样式 = 返工。

下表 props 摘自本仓库 `dist/api/*.json`（2.12.0）；**完整 API 查 JSON，文档正文查 `quasar-skilld`**。

| Figma 里画的 | 组件 | 高频 props | 坑 |
|---|---|---|---|
| 按钮 | `QBtn` | `flat outline unelevated rounded round dense square push` `label icon icon-right` `color text-color` `no-caps no-wrap` `padding size` `loading disable` `stretch stack align` | **默认 label 全大写**，原样显示必须 `no-caps`；`loading` 文案在窄按钮里容易换行溢出，配 `no-wrap` / 缩短文案 |
| 输入框 | `QInput` | `outlined filled borderless standout` `dense` `label stack-label hint prefix suffix` `rules lazy-rules reactive-rules` `error error-message` `hide-bottom-space` `clearable autogrow maxlength debounce` `mask` | 不加 `hide-bottom-space` 时下方永远预留报错行高度，间距会和 Figma 对不上 |
| 下拉选择 | `QSelect` | 同 QInput 一套 + `options option-value option-label` `emit-value map-options` `multiple use-chips use-input` `menu-anchor menu-self popup-content-class` | 想让 v-model 是原始值而非对象 → `emit-value` + `map-options` |
| 开关 | `QToggle` | `label left-label` `color keep-color` `dense size` `checked-icon` `true-value false-value` | 项目多半有 `BtSwitch`，优先用 |
| 复选 / 单选 | `QCheckbox` `QRadio` `QOptionGroup` | `color dense label val` | |
| 弹窗 | `QDialog` | `persistent maximized full-width full-height` `position`('top'/'bottom'/…) `seamless` `no-backdrop-dismiss no-esc-dismiss` `transition-show/hide` | 项目多半有 `BtDialog`（宽度/视觉已对齐）；`position` 可直接做移动端底部 sheet；自定义弹窗组件用 `useDialogPluginComponent` |
| 下拉菜单 / 气泡 | `QMenu` | `anchor self offset` `fit cover` `auto-close persistent` `max-height max-width` `context-menu` | `anchor`/`self` 是 `"top left"` 两词格式；默认已带弹窗阴影 |
| 提示 | `QTooltip` | `anchor self offset delay hide-delay max-width` | |
| 卡片 | `QCard` + `QCardSection` + `QCardActions` | `flat bordered square` | Figma 卡片一般 = `flat bordered` 再自己给圆角/阴影 |
| 列表 | `QList` + `QItem` + `QItemSection` + `QItemLabel` | QList `bordered dense separator padding`；QItem `clickable active dense to href inset-level` | 左图标/右操作用 `QItemSection avatar` / `side` |
| 表格 | `QTable` | `rows columns row-key`（**2.x 是 `rows` 不是 `data`**）`flat bordered dense square separator` `pagination rows-per-page-options` `loading` `grid`(卡片态) `selection` `virtual-scroll` | 样式定制走 `table-class` / `body-cell-*` slot |
| 标签页 | `QTabs` + `QTab` + `QTabPanels` | `no-caps dense inline-label` `active-color indicator-color narrow-indicator switch-indicator` `align` | 同样**默认大写**，要 `no-caps`；`QRouteTab` **不要**配 `v-model` |
| 折叠面板 | `QExpansionItem` | `label caption icon expand-icon` `default-opened group popup` `header-class dense` | `group` 实现手风琴 |
| 分隔线 | `QSeparator` | `vertical inset spaced size color` | 比手写 1px div 好 |
| 弹性占位 | `QSpace` | 无 props | 顶栏两端对齐的标准做法 |
| 徽标 / 标签 | `QBadge` `QChip` | Badge `floating outline rounded transparent align`；Chip `outline square removable clickable selected icon icon-remove dense size` | |
| 头像 / 图片 | `QAvatar` `QImg` | QImg `src ratio fit position placeholder-src loading no-spinner img-class` | `ratio` 防加载抖动 |
| 加载态 | `QSpinner*` `QSkeleton` `QInnerLoading` `QLinearProgress` `QCircularProgress` | Skeleton `type animation square bordered width height`；InnerLoading `showing label size color` | Figma 通常不画 loading/empty/error，**别删既有的非理想态** |
| 空态 / 提示条 | `QBanner` | `inline-actions dense rounded` | |
| 分栏 | `QSplitter` | `model-value horizontal unit limits before-class after-class` | |
| 步骤条 | `QStepper` + `QStep` | | |
| 表单 | `QForm` | `greedy no-error-focus` + `@submit` `.validate()` `.resetValidation()` | 校验规则写在各字段 `rules` |
| 上传 | `QUploader` | `url method field-name headers accept max-file-size multiple auto-upload factory` | 直传 S3 等场景常改用自定义 `factory` |

**样式与 Figma 不符时**：优先"原生组件 + 样式包裹组件（wrapper）用 `:deep()` 定向覆盖"，保留原生的行为 / a11y / props，别从零重写组件；覆盖值仍走 token。

---

## 11. 插件与 `$q` 对象

`quasar.config.js` → `framework.plugins` 注册后才可用（本仓库：`Notify` `Dialog` `Loading` `Cookies` `Meta`）。

```js
const $q = useQuasar()
$q.notify({ message: '…', type: 'positive', position: 'top' })
$q.dialog({ title: '…', message: '…', cancel: true }).onOk(() => {})
$q.loading.show(); $q.loading.hide()
$q.dark.set('auto')      // $q.dark.isActive
$q.screen.lt.md          // 视口
$q.platform.is.mobile    // 设备
```

组件外：`import { Notify, Dialog, Loading, Dark, Screen, Platform } from 'quasar'`。

---

## 12. Quasar 特有的翻车清单（提交前逐条自查）

1. **`q-gutter-*` 在定高滚动纵向列里会把子项折到第二列** → 改 `column` + `no-wrap` + 固定 gap；改完量 `top`/`left` 确认。
2. **gutter 父元素加了 background / border** → 负 margin 露馅，改为外包一层容器。
3. **`row-md` / `q-pa-sm-md` / `justify-md-center` 是死类**（除非 `cssAddon: true`）；`col-md-*` 才默认可用。
4. **`text-body-1` 这种硬塞连字符的类名不存在** → 类名 = `text-` + `$headings` key 原样。
5. **`QBtn` / `QTab` 默认大写** → 忘了 `no-caps` 就和设计稿对不上。
6. **CSS 断点 ≠ `$q.screen` 断点**（本仓库 600–799 / 1440–1599 两段互相矛盾）→ 一套贯穿，跨区间实测。
7. **QLayout 系列上写了 `margin`** → 布局错位，改 `padding`。
8. **`QScrollArea` / containerized QLayout 没给高度** → 塌成 0。
9. **`q-icon` 前缀写错**（本仓库该用 `sym_r_*`）→ 不显示或显示错图。
10. **`color="primary"` 不等于设计稿的蓝**（`--q-primary` 被各构建重定向）→ 用同一个语义色名。
11. **`QInput` 未加 `hide-bottom-space`** → 底部多出一行报错预留高度，间距对不上。
12. **删了包裹层 `<div class="…">`** → 别处 `:deep(.wrapper .q-btn)` 的外部样式失效（先 `rg` 确认没人依赖再删）。
13. **照抄 `quasar-skilld` 里标"new in 2.17/2.18"的 props** → 本仓库 2.12.0 没有，回 `dist/api/*.json` 核。
