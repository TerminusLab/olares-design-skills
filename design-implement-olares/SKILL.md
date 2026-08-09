---
name: design-implement-olares
description: >-
  Use when implementing or tweaking UI in Olares / Quasar repos (terminus-cloud,
  TermiPass, dashboard, AssistHub, etc.), stacked on design-implement. Covers
  project token values, Bt* components, screen vs platform, cssAddon dead classes,
  and how to look up the full Quasar layout/style surface in node_modules and
  quasar-skilld instead of memorizing skill examples.
---

# design-implement-olares

`design-implement` 的 **Olares / Quasar 叠加层**。

通用流程（先词汇表后 Figma、组件选择、图标导出、自查、收尾）在 `design-implement` 里，**不在这里重复**。本文件只写「在这套设计系统里，具体该写什么、哪里会翻车」。

**先读 [references/constraints.md](references/constraints.md)** 的**第四节**（复用优先级）、**第五节**（工具类优先与豁免格式）与**第六节**（UI 可以分文件，逻辑必须共用——本仓库响应式分文件时直接适用）。

**[references/quasar.md](references/quasar.md) 是落地索引与坑，不是 Quasar 全文。** 按需跳节；布局/样式**全集**在 `node_modules/quasar` + `quasar-skilld`（见「像开发者一样查」）。下表是入口：

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

**查"某组件完整 API / 官方怎么说"用 `quasar-skilld` skill**（463 篇官方文档镜像 + 逐版本 API 变更）。⚠️ skilld 镜像版本可能**新于**项目：先看 `node_modules/quasar/package.json`；标 "new in …" 的 props 必须以项目 `dist/api/*.json` 为准。

分工：**本文件管"项目特有值与坑"，`references/quasar.md` 管"Quasar 落地速查"，`quasar-skilld` 管"官方文档原文"。**

---

## 小修速查（只改一两个值时读这一节就够）

走 `design-routing` 最短路径时，先看下面「本仓库坑」再动手。  
⚠️ **这张坑表 ≠ Quasar 布局全集。** 改取值（lg→md）够用；**布局选型不确定、表里没写到的类/组件/模式 → 必须去权威源查**（见下一节「像开发者一样查」），禁止凭记忆只复用表里那几条例子，也禁止因此退回手写 CSS。

| | 本仓库实测 |
|---|---|
| **间距取值** | `xs=4 sm=8 md=12 lg=20 xl=32 xxl=44 xxxl=56 xxxxl=80`（px，9 档，base 8px）。⚠️ `md` 是 **12 不是 16**，Quasar 默认那套在这里不成立 |
| **间距怎么写** | 按 Quasar 语法整套选用：`q-[p\|m][a\|x\|y\|t\|r\|b\|l]-[档位]`（`q-pa-lg` / `q-py-md` / `q-my-lg` / `q-pt-xxl`…），**按布局选方向，别默认只会 `q-pa-*`**。flex 子项 → `flex-gap-*`。详表见 `references/quasar.md` §3。**禁止**为换档位去 `<style>` 写 `map-get($space-*)`；`max(..., safe-area)` 才进 style + `design-exempt`。`q-*-md` 的 `md`=间距档，不是断点 |
| **排版类名** | `text-` + key 原样，**数字紧贴不带连字符**：`text-body1` / `text-subtitle3`。写成 `text-body-1` 是**死类**，不报错、不生效 |
| **响应式工具类** | `row-md` / `justify-md-center` / `q-pa-sm-md` 这类**全部无效**（`cssAddon` 未开）。要断点行为只能用 `col-md-*`、可见性类或 `$q.screen` 条件渲染 |
| **`primary`** | 不是设计稿那个蓝。`--q-primary` 随构建被改（AssistHub=`blue-default`，Space=`orange-default`）。要和同页品牌色控件一致就**直接写语义色名** |

超出「改一两个值」范围（新增区块、动组件结构、改响应式行为）时，回到本文件从下一节读起。

### 像开发者一样查 Quasar 布局（全集在源里，不在 skill 举例里）

**Skill / 对照表永远不是目录。** Quasar 布局与样式面很大（Flex Grid、Spacing、Visibility、Positioning、Size、Typography、Elevation、QLayout/Drawer/Page…）。你要做的是**按场景去权威源检索并选用**，不是背 skill 里那十几行例子。

#### 查哪里（按这个顺序）

| 层级 | 路径 | 用来干什么 |
|---|---|---|
| 1. 项目取值 / 死类 | 本文件「小修速查」+ `references/quasar.md` §0 入口表 | `md`=几、`cssAddon` 开没开、本仓库翻车点 |
| 2. **已安装版本的类名全集** | 项目 `node_modules/quasar/src/css/core/*.sass`：`flex` `helpers` `size` `positioning` `visibility` `typography` `elevation` `mouse`… | **类是否存在、怎么拼**——以这份为准 |
| 3. 组件 props 全集 | `node_modules/quasar/dist/api/Q*.json` | QLayout / QPage / QSpace / QSeparator… 与**当前版本**一致 |
| 4. 官方概念与模式 | **`quasar-skilld`**：`references/docs/style/`（spacing、typography…）、`references/docs/layout/`（flex grid、QLayout…）；先看 `references/docs/_INDEX.md` | 怎么组合、playground、best practice |
| 5. 项目扩展类 | 如 `src/css/common.scss` 的 `flex-gap-*`、`border-radius-*` | Quasar 没有、项目补的 |

#### 怎么查（动手命令，别凭印象）

```bash
# 类名是否存在 / 有哪些变体（在项目根）
rg -n "\\.(row|column|flex-center|full-width|q-pa-|gt-sm)" node_modules/quasar/src/css/core/

# 某组件 props
python3 -c "import json;print(list(json.load(open('node_modules/quasar/dist/api/QLayout.json'))['props']))"

# 官方文档索引（skilld）
rg -n "Flex|Spacing|Layout" ~/.claude/skills/quasar-skilld/references/docs/_INDEX.md
```

不确定就 **Read / rg 上述文件**，读完再写模板 class。版本以 `node_modules/quasar/package.json` 为准；`quasar-skilld` 镜像可能更新，标 "new in …" 的 props 必须回 `dist/api` 核对。

#### 选型流程（灵活，不是背表）

1. 拆意图：方向？对齐？栅格？内外边距？显隐？整页骨架？滚动容器？
2. 到对应权威源找**一整族**工具类/组件（例如要间距就读 `style/spacing` + `core` 里生成规则，不要只想起 `q-pa-lg`）。
3. 对照项目坑：`cssAddon`、定高列禁用 `q-gutter`、`$spaces` 取值、项目 `flex-gap-*`。
4. 同页已有写法优先对齐；仍无对应 → scoped + `design-exempt`。

下面是**起步直觉**（帮助把 CSS 念头拐到检索词），**不是白名单、不是上限**：

| 念头 | 去哪搜（关键词 / 文件） |
|---|---|
| flex 行列对齐 | `core/flex.sass`；skilld `layout/grid/*` |
| padding/margin | `q-[p\|m]…`；skilld `style/spacing.md` |
| 宽高占满 | `core/size.sass`：`full-width` `fit`… |
| 定位贴边 | `core/positioning.sass` |
| 断点显隐 | `core/visibility.sass`；**别用**未开 cssAddon 的 `row-md` |
| 子项间距 | 项目 `flex-gap-*` 或 skilld `layout/grid/gutter.md`（知坑再用） |
| 顶栏/侧栏/页面 | skilld `layout/*` + `dist/api/QLayout.json` 等 |
| 字号颜色 | `text-*` + 项目语义色；skilld `style/typography` |

**禁止合理化**：「skill 表里没有就手写 CSS」「先写 flex 以后再换类」「只复用会话里见过的那几个 class」。

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

## C. 间距：Figma `space-*` → `q-pa*` / `flex-gap-*`（1:1，base 8px）

`xs=4 · sm=8 · md=12 · lg=20 · xl=32 · xxl=44 · xxxl=56 · xxxxl=80`（px）

**默认落点是模板工具类**，不是 `$space-*` 变量。按布局从整套里挑，不要只会 `q-pa-*`：

| 场景 | 类 |
|---|---|
| 容器四边内边距 | `q-pa-lg` |
| 只要上下 / 左右内边距 | `q-py-md` / `q-px-lg` |
| 单边（顶栏下推、底栏上推） | `q-pt-xxl` / `q-pb-lg` |
| 块与块外间距、标题复位 | `q-mt-lg` / `q-my-md` / `q-ma-none` |
| 轴组合 | `q-px-lg q-py-md` |
| flex 子项间距（且不要 wrap） | `flex-gap-sm`…`flex-gap-xl`（`src/css/common.scss`） |

语法与选型细节：`references/quasar.md` §3。  
Figma `space-md` → 类名档位 `md`（**不是断点**）。  
`$space-*` / `map-get` **只留给**工具类表达不了的组合，并 `design-exempt`。

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

纵向堆叠用 `column` + `no-wrap` + **`flex-gap-*`（优先挂模板）**。没有对应 `flex-gap` 档位时才 scoped `gap` + `design-exempt`。  
不要用「避开会 wrap → 就写 `map-get($space-*)`」这条捷径替代已有工具类。

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
  <div v-if="$slots.actions" class="row flex-center flex-gap-md q-mt-lg"><slot name="actions"/></div>
</div>
```

（注意 `q-ma-none` 用来复位 `h1..h6` / `p` 的浏览器默认 margin。横向按钮行也优先 `flex-gap-*`，避免习惯性写回 `q-gutter-*`。）

**第三个翻车点：用 `map-get($space-*)` 改 footer 留白，以为「用了 token」就合规。**

```vue
<!-- ❌ 验收扫 px 会放过，但仍绕过工具类 -->
<div class="ah-reply__footer row items-center">…</div>
<style scoped>
.ah-reply__footer {
  padding: map-get($space-lg, y) map-get($space-lg, x);
  gap: map-get($space-md, x);
}
</style>
```

```vue
<!-- ✅ PC 公共档挂工具类；移动端分叉才进覆盖（或 :class 条件） -->
<div class="ah-reply__footer row items-center justify-end no-wrap q-pa-lg flex-gap-md">…</div>
```
