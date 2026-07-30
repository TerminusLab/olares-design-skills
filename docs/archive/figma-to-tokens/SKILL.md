---
name: figma-to-tokens
description: >-
  按项目自有的 design-token 变量体系 + 组件库,把 Figma 设计忠实落地为代码(布局/间距/结构/颜色/图标/响应式)。
  当用户说"implement this figma / restyle to match figma / 按 figma 改 UI / 应用变量清单 / apply the variable list",
  或给出 figma.com/design 链接并要求还原/改样式时使用。核心是:所有视觉值强制映射到项目 token,
  优先复用现成组件,只改 UI 不碰业务逻辑。
---

# figma-to-tokens

把 Figma 设计**忠实落地成代码**,并强制对齐到**目标项目自己的 design-token 变量体系**与**组件库**。
适用于任何用「分层 token(primitive → 语义 CSS 变量 → 工具类)+ 组件库」的前端项目(本仓库是 Quasar/Vue)。

产出目标不是"另起一套样式",而是"用项目已有的词汇把设计画出来"。

## 配套参考(Quasar 项目**动手前先读**)

- **`references/quasar.md`(本 skill 目录内)**——Figma 落地视角的 Quasar 速查:QLayout `view` 串、flex grid、
  gutter 负 margin 坑、间距/排版/颜色工具类的生成规律、断点(**CSS 与 `$q.screen` 是两套、本仓库互相矛盾**)、
  QIcon 前缀、组件对照表、13 条实测翻车清单,以及**本仓库对 Quasar 默认值的覆盖**(`$spaces` 9 档、
  `$headings` 多了 `subtitle3`/`body3`、`cssAddon` 未开、`--q-primary` 被重定向)。
- **`quasar-skilld` skill**(若已安装)——463 篇 Quasar 官方文档镜像 + 逐版本 API 变更 + 官方 best practice。
  查"某组件完整 API / 官方怎么说"用它。⚠️ 它基于 2.19.3,标"new in 2.17/2.18"的 props 在旧版本项目里不存在,
  以项目 `node_modules/quasar/dist/api/*.json` 为准。

分工:**本文件管"怎么落地 + 项目特有值",`quasar-skilld` 管"官方文档原文"。**

---

## 0. 硬约束(最高优先级,任何步骤都不得违反)

- **A. 分文件时 UI 分、逻辑共用**
  PC/Mobile 分成两个文件时,**只有 template + 样式**分开;所有业务逻辑(数据获取、状态、事件语义、校验、计算)
  必须抽到**共享 composable(`use*.ts`)/ store**,两个 SFC 引用同一份。
  **禁止**把同一段逻辑在 PC/Mobile 各写一遍。发现逻辑内联在旧组件里 → 先抽成 composable 再分文件。

- **B. 改 UI 不动业务逻辑**
  默认只改:模板结构、样式/token、图标/资源、响应式。
  **不碰**:API 调用、store、路由、数据流、事件处理的语义、以及既有工程约定(如 `ASSISTHUB_EMBEDDED`、无 BFF)。
  确有必要改逻辑 → **停下来**,说明改哪、为什么、影响面,**等用户确认**,不擅自改。

- **C. 保留既有能力,别在重写中丢掉**
  - 双模式/多形态分支(如 `v-if="!embedded"` standalone/embedded)必须保留。
  - 文案走 i18n(如 vue-i18n `t('...')`),figma 里的文字**只当参考**,落地抽 key,**不硬编码**。
  - 保留 loading / empty / error 等非理想态(figma 通常只画有数据态,别删)。
  - 保留可聚焦/键盘可达/对比度(a11y),保留现有过渡动效。

- **D. token 迁移先加后删**
  把旧的私有 token 换成项目 token 时,**先加新、待所有消费者迁移完再删旧定义**,
  避免未迁移组件因删了旧变量而瞬间崩。

- **E. 匹配不到就停下问**
  某个视觉值找不到"足够接近"的项目 token 时,**不要静默硬编码 hex/px**,停下来向用户确认(见第 3 步)。

---

## 1. 先解析目标项目的设计体系(必须早于读 figma)

目的:建立"可用词汇表",后面所有 figma 值都往这套词汇上映射。

扫描并记录下列四类,产出一份内部索引:

1. **Token 分层**(通常在 `styles/` / `css/` 目录):
   - primitive 调色板(如 `$grey-*` / `$orange-*`)——**底层,一般不直接用**。
   - 语义层 CSS 变量(如 `--q-background-1` / `--q-ink-1` / `--q-orange-default`),**注意 light/dark 两套**(如 `body` 与 `body.body--dark`)。
   - 工具类(如 `.bg-background-1` / `.text-ink-2`)。
   - 间距尺度(如 `$space-*`,8px 基准)与 Quasar `q-pa/q-ma/gutter`。
   - 排版尺度(如 `$headings`:subtitle1/2/3、body1/2/3、caption、overline…)。
   - 断点(如 `$breakpoint-*`)。
   - 移动端字号(如 `mobile-font-text.sass`)。
2. **组件库**:扫描组件库导出(如 `src/packages/*` 的 `index.ts`),列出可复用组件(如 `Bt*` / `Terminus*`)及其 props。
3. **图标/资源约定**:图标是走 icon 字体名(如 material-symbols)还是 `assets/*.svg`;是否有暗色变体命名约定(如 `xxx_dark.svg` / `xxx-dark.svg`)。
4. **可选的变量清单文件**:用户若提供(如 `Variables List.txt`),读它对齐命名/取值,但**以项目实际 styles 目录为准**。

> 本仓库参考(terminus-cloud):
> - token:`src/packages/lib/styles/theme.scss`(语义 `--q-*` light/dark)、`variables-bg.sass`/`variables-text.sass`(`.bg-*`/`.text-*`)、`quasar.variables.sass`(primitive + `$space-*` + `$headings`)、`mobile-font-text.sass`。
> - 组件库:`src/packages/index.ts`(`BtButton`/`BtSwitch`/`BtMenu`/`BtScrollArea`/`BtDialog`/`TerminusAvatar`/`useColor`/`BtTheme`…)。
> - 图标:`q-icon name="..."`(material-symbols-rounded)+ `src/assets/*.svg`(含 `_dark` 变体)。
> - 响应式:Space 原生页用 `AdaptiveLayout`(按 `$q.platform.is.mobile` 分 `MainPc`/`MainMobile`);AssistHub 用单文件 `$q.screen`。

---

## 2. 读 Figma 设计

- **优先 Figma MCP**(可用时):`get_design_context`(布局+参考代码+hint)、`get_screenshot`(视觉真值)、变量定义、
  `download_assets`/`export_nodes`(导出图标/图片)、`get_motion_context`(动效)。
- **无 MCP 则回退**:让用户提供 **截图 + 变量文件**,按截图还原、按变量文件映射 token。
- **多链接输入**:支持一次给多个 figma 链接,每个标注对应视口(如 PC / 移动),fileKey 可不同。
  解析 URL:`figma.com/design/:fileKey/...?node-id=:nodeId`,nodeId 里的 `-` 换成 `:`。
- MCP 返回的参考代码是 **reference,不是最终代码**:结构/意图可信,但要改写成项目的技术栈、组件与 token。

---

## 3. 落地实现(布局/间距/结构/颜色)

### 3.1 组件复用优先级(自上而下)
1. 项目组件库现成组件(如 `src/packages` 的 `Bt*` / `Terminus*`);
2. 框架原生组件(如 Quasar `q-*`);
3. 都没有才手写。手写时样式仍走 token。

**先搜再写(强制前置检查)——动手写/套样式做任何常见控件(dialog / switch / toggle / menu / drawer / tabs / tooltip…)之前,必须先搜一遍:**
- ① 项目组件库导出:`rg` 控件关键词看 `src/packages/*` 的 `index.ts`(如 `BtDialog` / `BtSwitch` / `BtMenu`);
- ② **同源姊妹仓库**(如本项目的 TermiPass):它常已有对齐了设计系统的封装,能直接用或移植过来。
- **别停在"框架原生够用"就动手**:`q-toggle` / `q-dialog` 看着够用,但项目/姊妹仓库里往往已有 `BtSwitch` / `BtDialog`(视觉、主题色、宽度约定都对好了)。用 `q-toggle` 自己套药丸样式、用 `q-dialog` 自己调宽度 = 返工;应先复用 `BtSwitch` / `BtDialog`。
- 搜不到才降到"原生 + style wrapper",再不行才手写。**这一步没做就是本次"先手写 switch/dialog 又被要求换成 Bt* "返工的根因。**

**样式与 figma 不符时,优先"基于框架原生组件覆盖样式",不要从零重写组件。**
- 用到的组件(如按钮)在 figma 里样式与框架默认(如 Quasar `q-button`)不一致时:**保留原生组件的行为/无障碍/API**,只覆盖视觉。
- 覆盖方式:用一个**样式包裹组件**把原生组件裹起来,样式集中写在 wrapper 里,而不是到处散落深选择器 / `!important`。例如:

```vue
<QButtonStyleWrapper>
  <q-button>{{ label }}</q-button>
</QButtonStyleWrapper>
```

  wrapper 内用 `:deep()` 定向覆盖原生组件的类,覆盖值仍走 token(见 3.2)。
- 好处:行为/键盘可达/props 全部沿用原生组件(不丢 a11y、不重造轮子),视觉集中可控、可复用;同类组件复用同一个 wrapper。
- 若项目组件库已有对应的封装(如 `BtButton`),优先用它;没有再用「原生组件 + style wrapper」。

### 3.2 强制 token 映射
- **颜色** → 语义 `--q-*` / `.bg-*` / `.text-*`(不要直接用 `$grey-6` 这种 primitive)。
- **间距** → `$space-*` / `q-pa*`/`q-ma*`,不硬编码 px。
- **字号/行高** → `$headings` 里的排版类,不硬编码。
- **light/dark 成对**:每个 token 的亮/暗值一等公民,**绝不只取 light 值硬编码**;用了语义变量就自动跟随主题。
- 找不到足够接近的 token → 按约束 E **停下问**,别硬编码。

### 3.2.1 工具类优先:能用框架工具类就别写自定义类/CSS(举一反三)

**默认心态:先找框架/项目已有的工具类,找不到才写 scoped CSS,写之前再问一遍"真没有吗"。** 不是只有颜色/字号要用工具类——**布局、flex、间距、对齐、显隐**统统优先工具类,别一上来就造一堆 `.xxx__title` / `.xxx__actions` 的 BEM 类再在 `<style>` 里手写 `display:flex`。

- **布局/flex**(Quasar `core/flex.sass`):`row` / `column`(自带 `flex-wrap:wrap`)、`flex-center`(= items+justify center)、`items-center` / `justify-center` / `justify-between`、`col` / `col-auto` / `col-grow` / `col-shrink`、`text-center`。
- **间距**:`q-pa*` / `q-ma*`(含方向 `q-pt/pb/pl/pr/px/py`、`q-mt/...`)、`q-gutter-*` / `q-col-gutter-*`(flex 子元素间距,含换行)、以及 **`-none` 档**(如 `q-ma-none` 复位 `h1..h6`/`p` 的浏览器默认 margin)。**档位取项目 `$spaces` 的 key**(本仓库 base 8:`xs4 sm8 md12 lg20 xl32 xxl44 xxxl56 xxxxl80` + `none`)。
- **排版/颜色**:见 §A/§B(`text-subtitle1`、`text-ink-1` …)。

**只有下列情形才保留 scoped 自定义类(其余一律工具类):**
1. 固定像素尺寸且无对应工具类(如插画 `width/height: 240px`);
2. **主题相关的资源切换**(如亮/暗两张图靠 `body.body--dark` 选择器切换 `display`);
3. 值在项目 token/工具类里**没有匹配项**(如描述文案 `12/16` 在 `$headings` 无对应、`max-width: 320px`)——保留并**加注释说明为何保留**。

> 落地自检(每写一条 `<style>` 规则前问自己):这条 `display:flex` / `margin` / `gap` / `font-size` / `color`,**框架或项目有没有现成工具类?** 有 → 挂类;没有 → 再写,并注释原因。custom class 数量应趋近于 0。

**验证工具类真实存在**(别凭记忆):flex/定位/显隐 → `node_modules/<framework>/src/css/core/*`;间距/排版档位 → 项目 `quasar.variables.sass` 的 `$spaces` / `$headings`;语义色 → 项目 `variables-{bg,text}.sass`;拿不准就 `rg "q-ma-none|col-grow|flex-center"` 看仓库里有没有人在用。**常用类的完整清单与生成规律见 `references/quasar.md` §2/§3/§4/§7。**

**响应式类有个大坑:`row-md` / `justify-md-center` / `q-pa-sm-md` 这类 breakpoint 版本只有开了 `framework.cssAddon` 才生成(本仓库**没开**,写了不报错、完全不生效);而 `col-md-*` / `offset-md-*` 是默认就有的。动手前先看 `quasar.config.js`。**

**工具类陷阱 · `q-gutter-*` 会强制 `flex-wrap: wrap`(定高滚动列容器里会翻车)。**
`q-gutter-*` / `q-col-gutter-*` 的实现是「给容器加 `flex-wrap:wrap` + 给子元素加负 margin」。在**定高 + 可滚动的纵向堆叠容器**(如弹窗/抽屉 body)里用它做垂直间距,子项会因为 `wrap` 被折到**第二列**,跟前面的元素**并排重叠、看似"消失"**(本次实测:定高滚动列里第三张卡片折进第二列,与第一张 `top` 相同并排,宽 600 vs 294)。
- 纵向堆叠的间距:用 `column` + **固定 `gap`**(scoped,值对齐 `$space`,如 16px=`$space-lg`)+ `no-wrap`,**不要**用 `q-gutter-*`。
- 改完**用浏览器/CDP 量一下**相邻子项的 `top`/`left`,确认是真的上下堆叠、没被换行排成两列。
- (`q-gutter-*` 适合"本来就允许换行的一排 chip/按钮",不适合"必须单列的定高滚动区"。)

### 3.3 图标 / 资源导出(三档)
1. 能对应 icon 字体名(如 material-symbols)→ 直接用(如 `<q-icon name="chevron_right" />`)。
2. 自定义**单色**图标 → 从 figma 导出 SVG 到 `assets/`,**优先 `currentColor` 内联**(自动跟随主题/文字色,免双份)。
3. **多色**插图 / logo → 导出资源;确实无法用 currentColor 时才产出 `_dark` 变体(遵循项目命名约定)。

**3.3.1 整节点导出 SVG 的两个坑(实测):**

- **祖先画板 chrome 会混进来**。用 `download_assets(defaultFormat:"svg")` 导单个节点时,导出的 SVG 常把**父级画板/画布的背景**也画进去:整块底色 `<rect .. fill="#EDEDED"/>`、巨型画布 rect(坐标像 `M-2148 -342…`)、带 `filter=drop-shadow` 的白卡片、content 白底 rect 等。**必须删掉这些 chrome**,只留真正插画那一层(通常是带 `clip-path` 的那个 `<g>`),让背景透明。删完再**本地栅格化肉眼核对**(如 `qlmanage -t -s 480 -o <dir> x.svg`,暗色图先临时垫个深色 `<rect>` 再截图)。
- **别动结构性 `fill="white"`**。SVG 里的 `<mask id=".." fill="white">` 和 `<clipPath><rect fill="white"/></clipPath>` 里的 white 是**遮罩/裁剪语义**(白=显示),不是可见颜色;做暗色重映射时若把它们一起改黑,遮罩失效、图形残缺。改色前先把这两处**占位保护**,改完再还原。

**3.3.2 暗色变体(灰阶插画)= 有序颜色重映射**,而不是简单 invert(纯 invert 会出死黑纸卡):
- 线稿描边(深灰 `#5C5C5C`)→ 提亮成浅灰(在深底上可读);
- 纸卡/镜片等 `fill="white"` → 深卡片色(如 `#2E2F35`);柔光底块(近白 `#F6F6F6`)→ 极暗低对比色;
- 中灰件(`#ADADAD`)→ 略降的中灰;`fill="black" fill-opacity` 的阴影 → 翻成 `white` 低透明(阴影在暗色下应是浅色);
- 高光 `fill="white" fill-opacity=".8"` 保留为浅色(先于纸卡替换处理,避免被一起改黑);
- **`<mask>/<clipPath>` 的 white 保持不变**(见上)。
- 切换:用 `body.body--dark` 选择器切两张 `<img>` 的 `display`(纯 CSS,无 JS)。

### 3.4 响应式
- 忠实还原给定视口;用项目断点(如 `$q.screen` / `$breakpoint-*`)做**优雅降级**。
- **不凭空造移动端**:只有桌面 figma 时,标注"移动端需专属 figma 节点",不臆造。

### 3.5 PC / 移动端分文件(有两套 figma 时)
- **识别当前区域惯例并沿用**:
  - 类似 Space 原生页的区域 → `AdaptiveLayout` + `Pc/Mobile` 分文件(按 `$q.platform.is.mobile`)。
  - 类似 AssistHub 的区域 → 单文件 `$q.screen` 自适应。
  - 判据:两套设计**差异大**就分文件,**差异小**就自适应。
  - 分文件时严守约束 A(逻辑抽共享 composable)。
- **移动端必查 checklist**:
  1. 点击热区 ≥ 44px、间距加大;
  2. 不依赖 hover,改 pressed/active 反馈;
  3. 侧栏 → overlay drawer / 底部 sheet;下拉菜单 → 全屏选择器;
  4. 底部固定操作栏预留 `env(safe-area-inset-*)`;
  5. 分清 `$q.platform.is.mobile`(设备)与 `$q.screen`(视口),按区域惯例选;
  6. 字号/行高沿用移动端尺度(如 `mobile-font-text.sass`),不套桌面号;
  7. 图片/背景按移动端尺寸导出,避免加载超大图。

---

## 4. 验证(有 dev server + 浏览器就**必须**做,不是可选)

- 有**运行中的 dev server + 浏览器工具**时,**必须**导航到对应页面 → 截图 → 与 figma **逐块并排对比 → 迭代到接近**才算完,别改完就交(用户一句"差别很大"/"ui 很难看"基本都是漏了这步)。
  - 用**已在运行**的 dev server,不要盲目再起一个;注意区分被改的形态(如 embedded / standalone / PC / 移动),每个被改形态都要核对。
- **逐块核对清单**(每个改动块都过一遍,别只看整体像不像):
  1. 排版:字号 / 字重 / 行高;
  2. 间距 / 对齐 / 圆角 / 描边 / 投影;
  3. 颜色:含**品牌色是否与同页其它控件一致**(见 §B primary 陷阱);
  4. 图标:名 / 前缀是否对、**是否带该有的外框/底色方块**(见 §3.3 / §5 收尾回归);
  5. **非理想态**:loading / empty / error 也要还原到位——尤其 loading 文案在窄按钮里**别换行/溢出**("正在收集日志"撑爆小按钮就是本次返工),必要时 `no-wrap` + 缩短文案 / 只留图标。
- **有现成参考实现时以它为准**:figma 之外若页面已有真实实现(如 Space 的同款页),**读它逐像素对齐**比只看 figma 更准(本次登录页"差别很大"就是没先去对现成实现)。
- 没有 dev server / 浏览器:跳过,并**明确提示用户人工核对**。

---

## 5. 收尾报告(必须输出)

**报告前先做一次「旧消费者回归核对」(改了被复用的组件时必做):**
重构 / 抽取 / 换壳一个被别处复用的组件后(如把手写弹窗换成 `BtDialog`、抽共享富文本组件、重写某个按钮),`rg` 出**所有旧消费者**——**特别是靠 `:deep(.wrapper .q-btn)` 这类依赖你的包裹类名/DOM 结构的外部样式**——逐个回到旧消费者的页面/形态截图核对,确认没把既有视觉或能力弄回退。
- **删任何包裹层 `<div class="...">` / 类名前,先确认没有别处选择器依赖它**(本次"olares-cli 图标外框没了"就是重写按钮时删掉了外部 `:deep()` 依赖的 `.ah-cli-pairing` 包裹层)。呼应约束 C(保留能力)/ D(先加后删)。
- 抽共享组件时,回到**每一个**旧消费者(如同时被创建页 + 详情页用的富文本框)核对都没回退,而不是只看新加的那处。

给用户一份结构化清单:
1. **未能映射到 token 的值**(按约束 E 停下问过的、或临时保留的),等人工定夺;
2. **新写(而非复用)的组件**及原因;
3. **新导出的资源**(路径 + 是否含暗色变体);
4. **PC/移动端**:哪些区块分文件、哪些自适应、哪些因缺移动端 figma 而降级;
5. **触碰业务逻辑的请求**(按约束 B 需要用户确认的点)。

---

## 使用要点速记

- 顺序不可颠倒:**先解析项目体系(第 1 步)→ 再读 figma(第 2 步)**。Quasar 项目动手前先读 `references/quasar.md`(尤其断点两套值、`cssAddon`、gutter 坑、图标前缀)。
- 复用优先(**写 dialog/switch/menu 等控件前,先搜项目组件库 + 姊妹仓库如 TermiPass 有没有 `Bt*`,别停在"原生够用"**)、token 强制、light/dark 成对、匹配不到就问。
- **工具类优先**:布局/flex/间距/对齐/排版/颜色一律先找框架工具类(`column`/`row`/`flex-center`/`col-grow`/`q-pa*`/`q-ma*`/`q-gutter*`/`-none`/`text-*`),`<style>` 自定义类趋近于 0;只为「固定尺寸 / 主题切图 / 无 token 值」保留(并注释)。**注意 `q-gutter-*` 会强制 `flex-wrap`,定高滚动的纵向列改用 `column`+固定 gap+`no-wrap`。**
- `primary`/品牌色随构建不同(SPA=blue-default / Space=orange-default),用前先确认当前 `--q-primary`,要和开关等同页控件一致就用同一个语义色名。
- 只改 UI,逻辑要动先确认;分文件 UI 分逻辑共用;迁移先加后删;**重构被复用组件后回归核对所有旧消费者(尤其 `:deep()` 依赖包裹类名的)。**
- 别丢:i18n、非理想态、a11y、动效、双模式分支。
- **有 dev server+浏览器就必须逐块和 figma 并排核对再交**(排版/间距/颜色/圆角/图标/**非理想态**),有现成实现以它为准。
- 导出插画:删祖先画板 chrome、护住 `<mask>/<clipPath>` 的 white、暗色靠有序重映射 + `body--dark` 切图,导完本地栅格化核对。

---

## 附:Olares/Quasar 设计系统 token 映射速查(实测 dashboard / terminus-cloud / TermiPass)

> 参考实现以 **TermiPass dashboard**(`packages/app/src/apps/dashboard/**`)为准,它是这套约定用得最规范的样板。
> 定义源:`css/ui/quasar.variables.sass`(primitive + `$space-*` + `$headings`)、`css/ui/theme.scss`(语义 `--q-*`,light/dark 两套)。

> **重点是理解推导规律,不是背某几个 token。** 下面给的是"怎么从任意 Figma token 推出正确写法"的通则,表格只是演示。遇到没列出的 token,按同样规律推 + 用「自查」验证即可。

### A. 排版:Figma `Text/XXX` → 工具类

**通则:类名 = `text-` + `$headings` map 里的 key 原样(小写)。** key 怎么写,类名就怎么拼,不擅自加/减连字符。

- `$headings` 的 key 是 `h1..h6 / subtitle1 subtitle2 subtitle3 / body1 body2 body3 / caption / overline` —— **数字直接贴在词后,本身不含连字符**。
- 所以 `Text/Body1` → key `body1` → 类 `text-body1`;`Text/Subtitle3` → `text-subtitle3`;`Text/H6` → `text-h6`。
- **由此推出的坑**:`text-body-1`(硬塞连字符)不在 key 里,Quasar 不会生成,是**死类**。凡是不确定,回到"key 是什么,类就是 `text-` + key"这条规律,再自查。
- 模板里**优先挂类**,不要手写 `font-size/line-height/font-weight`;`<style>` 里确需时才 `@include` 对应尺度。

演示(size/line/weight):`text-h6` 16/24/700 · `text-subtitle3` 12/16/500 · `text-body1` 16/24/400 · `text-body2` 14/20/400。

### B. 颜色:Figma 语义色 → 语义变量

**通则:token 名(`theme.scss` 里 `--q-<name>` 的 `<name>`)是什么,就原样用。** 模板挂 `text-<name>` / `bg-<name>` 或组件 `color="<name>"`;`<style>` 里用 scss 变量 `$<name>`。

- 颜色 token 名本身**带连字符**(如 `ink-1`、`orange-default`、`background-2`),所以类名也带:`text-ink-2`、`bg-background-2`、`color="orange-default"`。
- 这跟 A 段"排版不带连字符"**不是两条特例,而是同一条规律**:类名永远 = 前缀 + 源 token 名原样。排版 key 恰好无连字符(`body1`),颜色名恰好有(`ink-1`),差别只来自 token 名本身。
- `<style lang="scss">` 用 `$ink-2`(= `setColorVar(ink-2)` = `var(--q-ink-2)`),**不要**硬编码 `var(--q-ink-2)` 或 hex。
- 亮/暗自动跟随:用语义变量即可,无需写 dark 分支(`theme.scss` 已成对定义)。
- **`primary` / 品牌色可能随 app 构建被覆盖成不同值,落地前先确认当前构建的 `--q-primary`。** 同一套代码在不同入口里 `$primary` / `--q-primary` 被覆盖成不同颜色(本项目:AssistHub **SPA=`blue-default`**、Space **嵌入=`orange-default`**;都没覆盖时才是 Quasar 默认 `#1976D2`)。所以**别默认 `color="primary"` 就是设计稿那个蓝**——先查当前构建的主题入口(`quasar.variables`/`theme.scss`/`app.scss`)看 `$primary` 实际被设成什么。要和同页其它品牌色控件(如开关)保持一致时,**直接用同一个语义色名**(如 `color="blue-default"`)而不是裸 `primary`,否则按钮与开关撞不上色(本次返工点)。

### 工具类有两个来源,分清再用(关键,别只盯一处)

同样是 `text-*` / `bg-*`,可能来自两处;要举一反三,就得知道各自去哪读:

1. **项目自定义**(`src/packages/lib/styles/`):语义色工具类是**逐条手写声明**的,存在与否以这些文件为准。
   - `variables-bg.sass` → `.bg-<name>`(如 `.bg-background-hover`、`.bg-background-selected`、`.bg-separator`,均 `setColorVar(...) !important`)。
   - `variables-text.sass` → `.text-<name>`(同理,如 `.text-ink-2`)。
   - `theme.scss` → 每个 `--q-<name>` 的 light/dark 取值;`quasar.variables.sass` → primitive 调色板 + `$space-*` + `$headings`。
   - 特点:这些是**扩展出来的语义类**(`background-hover`/`ink-1`/`separator` 等 Quasar 调色板里没有的名字),所以必须项目自己声明才有。
2. **Quasar 自带**(无需项目声明就有的),源 SCSS 可直接读:`node_modules/quasar/src/css/`
   - `core/typography.sass` → `text-h1..h6 / text-subtitle1/2 / text-body1/2 / text-caption / text-overline`(以及 `text-weight-*`);
   - `core/flex.sass` + `variables.sass`(`$space-*`)→ 间距 `q-pa/pt/pb/pl/pr/px/py-*`、`q-ma-*`、`q-gutter-*`、`q-col-gutter-*`;
   - `core/colors.sass` → 调色板色 `text-<brandColor>` / `bg-<brandColor>`(仅 Quasar 注册的品牌色,如 `primary`);
   - `core/positioning.sass`、`core/visibility.sass`、`core/size.sass`、`flex-addon.sass` → 定位/显隐/尺寸/flex helper;
   - `variables.sass` → Quasar 默认的 `$headings`、`$space-*`、`$sizes`(项目常在自己的 `quasar.variables.sass` 里覆盖)。

> 一句话:**Quasar 调色板里没有的语义名(background-hover、ink-*、separator…)→ 找项目 `styles/` 的声明;通用排版/间距/品牌色/定位显隐 → `quasar/src/css/core/*`。** 两处都可能被项目二次覆盖。

**图标是另一回事,别和上面混:** `q-icon name="..."` 的取值来自图标字体集,装在 **`@quasar/extras/<set>/`**(如 `material-symbols-rounded`、`themify`、`fontawesome-v6`、`mdi-v7`…)。要查某个 `name` 是否存在、或找暗色/风格变体,去看当前启用的那个 set(见 `quasar.config` 的 `extras`/`iconSet`),而不是 `quasar/src/css`。**落地前还要确认该 set 的命名前缀约定**——有的项目图标名带前缀(如 Material Symbols Rounded 用 `sym_r_<name>`),写错前缀 = 图标不显示或显示错图(本次"草稿图标不对"返工);前缀与具体 `name` 怎么写,以项目现有 `q-icon name=` 用法为准(`rg 'q-icon' 看现存写法`),别照 figma 图层名直接抄。

### 自查(推不准时用,别猜)

- 排版名:`quasar.variables.sass` 的 `$headings` map key(或 Quasar 文档)。
- 颜色/背景工具类:先搜项目 `src/packages/lib/styles/variables-{bg,text}.sass` 有没有那一条 `.bg-<name>`/`.text-<name>`;语义值看 `theme.scss` 的 `--q-*`。
- 拿不准某个类是否真实存在:`rg "\.bg-background-hover|bg-background-hover"` 看声明处 + 用量(有声明/高频=真实,无声明/极低频=写错的死类)。

### C. 间距:Figma `space-*` → `$space-*` / `q-pa*` / `flex-gap-*`(1:1 对应,base=8px)

`xs=4 · sm=8 · md=12 · lg=20 · xl=32 · xxl=44 · xxxl=56 · xxxxl=80`(px)

- padding/margin:`q-pa-md`、`q-px-sm`、`q-mt-lg`……;flex 间距:`flex-gap-sm`、`flex-gap-x-md`。
- Figma 的 `space-md=12` 直接对应 `md`,不要硬编码 `12px`。

### D. 投影:Figma「下拉、弹窗投影」→ `0 4px 10px rgba(0,0,0,0.2)`(Quasar `.q-menu` 默认已带)。

### E. 正反例(就是本次翻车点)

Figma:`Draft` 选项 = `color: ink-2` + `Text/Body1`。

```scss
/* ❌ 错误:硬编码字号 + 裸 CSS 变量 */
.ah-status-option { font-size: 16px; line-height: 24px; color: var(--q-ink-2); }
```

```vue
<!-- ✅ 正确:模板挂工具类 -->
<div class="text-body1 text-ink-2">Draft</div>
```

```scss
/* ✅ 正确:必须写在 <style> 里时,用 scss 变量,字号交给 text-body1 类 */
.ah-status-option { color: $ink-2; }
```

**翻车点二(同一批次又犯):造 BEM 类 + 在 `<style>` 里手写布局/间距。** 空态组件一上来写了 `.ah-empty__title/__desc/__actions` 再手写 `display:flex`、`gap`、`margin`、`font-size`——全是框架工具类能替代的(见 §3.2.1)。

```vue
<!-- ❌ 错误:自定义类 + scoped 里手写 flex/间距/字号 -->
<div class="ah-empty">
  <h3 class="ah-empty__title">{{ title }}</h3>
  <div class="ah-empty__actions"><slot name="actions"/></div>
</div>
<style scoped>
.ah-empty { display:flex; flex-direction:column; align-items:center; justify-content:center; padding:32px 16px; }
.ah-empty__title { font-size:16px; line-height:24px; font-weight:500; color:var(--q-ink-1); margin:0; }
.ah-empty__actions { display:flex; gap:12px; margin-top:16px; }
</style>
```

```vue
<!-- ✅ 正确:布局/间距/排版/颜色全走工具类,scoped 只留没有工具类的(固定尺寸/主题切图/无 token 值) -->
<div class="column flex-center text-center col-grow q-py-xl q-px-lg">
  <h3 class="text-subtitle1 text-ink-1 q-ma-none">{{ title }}</h3>
  <div v-if="$slots.actions" class="row flex-center q-gutter-md q-mt-lg"><slot name="actions"/></div>
</div>
```
