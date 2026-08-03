---
name: design-implement-olares
description: >-
  Olares / Quasar 系仓库（terminus-cloud、TermiPass、dashboard、AssistHub 等）落地 Figma 设计时的项目特有知识：
  实测的 token 取值与推导规律、Bt*/Terminus* 组件对照、$q.screen 与 platform 的区别、cssAddon 未开的响应式陷阱、
  q-gutter 强制换行、图标前缀、primary 被重定向、以及历次返工换来的翻车清单。与 design-implement **叠加使用**：
  通用流程看那边，本文件只补这套设计系统的具体值和坑。
---

# design-implement-olares

`design-implement` 的 **Olares / Quasar 叠加层**。

通用流程（先词汇表后 Figma、组件选择、图标导出、自查、收尾）在 `design-implement` 里，**不在这里重复**。本文件只写「在这套设计系统里，具体该写什么、哪里会翻车」。

**先读 [references/constraints.md](references/constraints.md)** 的**第四节**（复用优先级）、**第五节**（工具类优先与豁免格式）与**第六节**（UI 可以分文件，逻辑必须共用——本仓库响应式分文件时直接适用）。

**[references/quasar.md](references/quasar.md) 按需查，不必通读**（363 行）。下表是入口：

| 要解决什么 | 读哪节 |
|---|---|
| 页面骨架、QLayout `view` 串怎么拼 | §1 |
| 行列布局、`col-*`、gutter 负 margin | §2（响应式死类看 §2.4，gutter 陷阱看 §2.5）|
| 间距 / 排版工具类的类名怎么推 | §3、§4 |
| 颜色工具类来自哪个文件、`--q-primary` 被指到哪 | §5.1、§5.2 |
| 断点取值、`$q.screen` 与 CSS 为何不一致 | §6（矛盾区间看 §6.2）|
| 图标 set 与前缀 | §7 |
| 某个 `q-*` 组件常用 props | §8（完整 API 查 `dist/api/*.json`）|
| 动手前想先看有哪些坑 | 末节 13 条翻车清单 |

本文件后文引用它时都会给出精确节号，跟着跳即可。

**查"某组件完整 API / 官方怎么说"用 `quasar-skilld` skill**（463 篇官方文档镜像 + 逐版本 API 变更）。⚠️ 它基于 **2.19.3**，而本仓库是 **2.12.0**——标 "new in 2.13" 及以上的 props 在这里**都不存在**，以 `node_modules/quasar/dist/api/*.json` 为准。

分工：**本文件管"项目特有值与坑"，`references/quasar.md` 管"Quasar 落地速查"，`quasar-skilld` 管"官方文档原文"。**

---

## 小修速查（只改一两个值时读这一节就够）

走 `design-routing` 最短路径时，**读到这里即可动手**，不必读 `references/quasar.md`。四条最常撞的：

| | 本仓库实测 |
|---|---|
| **间距** | `xs=4 sm=8 md=12 lg=20 xl=32 xxl=44 xxxl=56 xxxxl=80`（px，9 档，base 8px）。⚠️ `md` 是 **12 不是 16**，Quasar 默认那套在这里不成立 |
| **排版类名** | `text-` + key 原样，**数字紧贴不带连字符**：`text-body1` / `text-subtitle3`。写成 `text-body-1` 是**死类**，不报错、不生效 |
| **响应式工具类** | `row-md` / `justify-md-center` / `q-pa-sm-md` 这类**全部无效**（`cssAddon` 未开）。要断点行为只能用 `col-md-*`、可见性类或 `$q.screen` 条件渲染 |
| **`primary`** | 不是设计稿那个蓝。`--q-primary` 随构建被改（AssistHub=`blue-default`，Space=`orange-default`）。要和同页品牌色控件一致就**直接写语义色名** |

超出「改一两个值」范围（新增区块、动组件结构、改响应式行为）时，回到本文件从下一节读起。

---

## 先确认当前是哪个仓库

这几个仓库共用同一套设计系统，但**文件路径、`primary` 取值、响应式做法都不同**。只看对应那一行，**别照搬隔壁仓库的路径**——拿错不报错，只是找不到文件或写出本仓库不存在的类名。

| 仓库 | 定义源 | `--q-primary` | 响应式做法 |
|---|---|---|---|
| **TermiPass dashboard**（样板，拿不准写法就读它）| `css/ui/quasar.variables.sass`（primitive + `$space-*` + `$headings`）、`css/ui/theme.scss`（语义 `--q-*`，亮/暗成对）| 跟所在构建 | — |
| **terminus-cloud** | `src/packages/lib/styles/theme.scss`、`variables-bg.sass` / `variables-text.sass`、`quasar.variables.sass`、`mobile-font-text.sass`；组件库入口 `src/packages/index.ts` | Space 构建 = `orange-default` | `AdaptiveLayout` + `MainPc`/`MainMobile` 分文件，按 `$q.platform.is.mobile`（**设备**）|
| **AssistHub SPA** | 同 terminus-cloud，但主题入口是 `src/assisthub/css/app.scss` | `blue-default` | 单文件用 `$q.screen`（**视口**）自适应 |
| **均未覆盖时** | — | Quasar 默认 `#1976D2` | — |

样板代码在 `packages/app/src/apps/dashboard/**`。

两个常用到的全局事实：

- **已注册的 Quasar 插件**：`Notify` `Dialog` `Loading` `Cookies` `Meta`。没列在这里的（如 `BottomSheet`）**直接调用会报错**，需先改 `quasar.config.js`。
- **`MainLayout.vue` 的 `view="lHh Lpr lFf"`**：头部不固定、侧边栏在 header 下方。动到页面框架前先确认这串，否则自己算的吸顶偏移会对不上。

---

## A. 排版：Figma `Text/XXX` → 工具类

**类名 = `text-` + `$headings` map 里的 key 原样（小写）。**

key 是 `h1..h6 / subtitle1 subtitle2 subtitle3 / body1 body2 body3 / caption / overline`——**数字直接贴在词后，不含连字符**。

所以 `Text/Body1` → `text-body1`，`Text/Subtitle3` → `text-subtitle3`。

**由此推出的坑**：`text-body-1` 不在 key 里，Quasar 不会生成，是**死类**——不报错、纯粹不生效。

实测取值（size/line/weight）：`text-h6` 16/24/700 · `text-subtitle3` 12/16/500 · `text-body1` 16/24/400 · `text-body2` 14/20/400。

## B. 颜色：Figma 语义色 → 语义变量

**token 名（`theme.scss` 里 `--q-<name>` 的 `<name>`）是什么就原样用。**

模板挂 `text-<name>` / `bg-<name>` 或组件 `color="<name>"`；`<style lang="scss">` 里用 scss 变量 `$<name>`，**不要**硬编码 `var(--q-ink-2)` 或 hex。

颜色 token 名本身带连字符（`ink-1`、`orange-default`、`background-2`），所以类名也带：`text-ink-2`、`bg-background-2`。

亮 / 暗自动跟随，无需写 dark 分支——`theme.scss` 已成对定义。

### ⚠️ `primary` 陷阱

**`--q-primary` 随 app 构建被覆盖成不同值**——取值见上面的仓库对照表。

所以**别默认 `color="primary"` 就是设计稿那个蓝**。要和同页其他品牌色控件（如开关）一致时，**直接用同一个语义色名**（如 `color="blue-default"`），否则按钮和开关撞不上色。

落地前先查当前构建的主题入口看 `--q-primary` 被指到了哪里（具体文件路径见 `references/quasar.md` §5.2）。

## C. 间距：Figma `space-*` → `$space-*` / `q-pa*`（1:1，base 8px）

`xs=4 · sm=8 · md=12 · lg=20 · xl=32 · xxl=44 · xxxl=56 · xxxxl=80`（px）

padding / margin 用 `q-pa-md`、`q-px-sm`、`q-mt-lg`；flex 间距用 `flex-gap-sm`、`flex-gap-x-md`。

Figma 的 `space-md=12` 直接对应 `md`，**不要硬编码 `12px`**。

## D. 投影

Figma 的「下拉、弹窗投影」= `0 4px 10px rgba(0,0,0,0.2)`，Quasar `.q-menu` 默认已带。

---

## 工具类的两个来源，分清再查

同样是 `text-*` / `bg-*`，可能来自两处：**Quasar 调色板里没有的语义名（`background-hover`、`ink-*`、`separator`…）→ 查项目 `src/packages/lib/styles/`；通用排版 / 间距 / 定位显隐 → 查 `node_modules/quasar/src/css/core/*`。**

项目自定义的那一类是**逐条手写声明**的，存在与否以文件为准，不能按命名规律推断；两处都可能被项目二次覆盖。具体到哪个文件声明了什么，见 `references/quasar.md` §5.1（颜色两种来源）与 §0（权威源）。

**图标是另一回事**：`q-icon name="..."` 的取值来自图标字体集，装在 `@quasar/extras/<set>/`。查某个 name 是否存在看当前启用的 set（`quasar.config` 的 `extras` / `iconSet`），不是 `quasar/src/css`。**前缀以项目现有 `q-icon name=` 写法为准**（如 Material Symbols Rounded 用 `sym_r_<name>`），别照 Figma 图层名抄——写错前缀 = 图标不显示或显示错图。

---

## 常用组件先搜这些

写 dialog / switch / menu / scroll / avatar 之前，先搜 `src/packages/index.ts`：`BtButton` / `BtSwitch` / `BtMenu` / `BtScrollArea` / `BtDialog` / `TerminusAvatar` / `useColor` / `BtTheme`…

也搜**姊妹仓库 TermiPass**——它常已有对齐设计系统的封装，能直接用或移植。

**别停在"Quasar 原生够用"就动手**：`q-toggle` / `q-dialog` 看着够用，但项目里往往已有 `BtSwitch` / `BtDialog`（视觉、主题色、宽度约定都对好了）。自己套药丸样式、自己调弹窗宽度 = 返工。

---

## 响应式：本仓库有两套惯例，别混

- **Space 原生页**：`AdaptiveLayout` + `MainPc` / `MainMobile` 分文件，按 `$q.platform.is.mobile`（**设备**）。
- **AssistHub**：单文件用 `$q.screen`（**视口**）自适应。

判据：两套设计**差异大**就分文件，**差异小**就自适应。分文件时严守共享约束第六节（逻辑抽共享 composable）。

⚠️ **`$q.screen` 的断点值与 CSS 断点在本仓库是两套且互相矛盾**：

| 区间 | CSS 类认为 | `$q.screen` 认为 |
|---|---|---|
| 600–799px | `xs` | `sm` |
| 1440–1599px | `md` | `lg` |

同一个响应式行为**别一半用 CSS 类一半用 `$q.screen`**，选一套贯穿；跨断点显隐必须在这两个区间实测。成因与查证方法见 `references/quasar.md` §6.2。

移动端字号用 `mobile-font-text.sass` 的尺度，别套桌面号。

---

## 三个反复踩到的坑

### 1. `q-gutter-*` 会强制 `flex-wrap: wrap`

在**定高 + 可滚动的纵向堆叠容器**（弹窗 / 抽屉 body）里用它做垂直间距，子项会被折到**第二列**、与前面的元素并排重叠，看起来像"消失了"。

**本仓库实测：** 定高滚动列里第三张卡片折进第二列，与第一张 `top` 相同并排，宽度 600 vs 294。

纵向堆叠的间距用 `column` + `no-wrap` + **固定 `gap`**（scoped，值对齐 `$space-*`）。改完用浏览器量一下相邻子项的 `top` / `left`，确认是真的上下堆叠。

负 margin 对父元素背景 / 边框的连带影响、以及 `q-gutter-*` 与 `q-col-gutter-*` 的适用区别，见 `references/quasar.md` §2.5。

### 2. 响应式工具类要 `cssAddon` 才有

`row-md` / `justify-md-center` / `q-pa-sm-md` 这类断点版本只有开了 `framework.cssAddon` 才生成，**本仓库没开**——写了不报错、完全不生效。而 `col-md-*` / `offset-md-*` 是默认就有的。

动手前先看 `quasar.config.js`；完整的死类清单与替代方案见 `references/quasar.md` §2.4。

### 3. token 迁移先加后删

把旧的私有 token 换成项目 token 时，**先加新的、等所有消费者迁移完再删旧定义**，避免未迁移的组件因为删了旧变量而瞬间崩。

---

## 正反例（都是真实翻车点）

Figma：`Draft` 选项 = `color: ink-2` + `Text/Body1`。

```scss
/* ❌ 硬编码字号 + 裸 CSS 变量 */
.ah-status-option { font-size: 16px; line-height: 24px; color: var(--q-ink-2); }
```

```vue
<!-- ✅ 模板挂工具类 -->
<div class="text-body1 text-ink-2">Draft</div>
```

```scss
/* ✅ 必须写在 <style> 里时用 scss 变量，字号交给 text-body1 */
.ah-status-option { color: $ink-2; }
```

**第二个翻车点：造 BEM 类 + 在 `<style>` 里手写布局。**

```vue
<!-- ❌ 自定义类 + scoped 里手写 flex / 间距 / 字号 -->
<div class="ah-empty">
  <h3 class="ah-empty__title">{{ title }}</h3>
  <div class="ah-empty__actions"><slot name="actions"/></div>
</div>
<style scoped>
.ah-empty { display:flex; flex-direction:column; align-items:center; padding:32px 16px; }
.ah-empty__title { font-size:16px; line-height:24px; font-weight:500; color:var(--q-ink-1); margin:0; }
.ah-empty__actions { display:flex; gap:12px; margin-top:16px; }
</style>
```

```vue
<!-- ✅ 布局/间距/排版/颜色全走工具类 -->
<div class="column flex-center text-center col-grow q-py-xl q-px-lg">
  <h3 class="text-subtitle1 text-ink-1 q-ma-none">{{ title }}</h3>
  <div v-if="$slots.actions" class="row flex-center q-gutter-md q-mt-lg"><slot name="actions"/></div>
</div>
```

（注意 `q-ma-none` 用来复位 `h1..h6` / `p` 的浏览器默认 margin。）
