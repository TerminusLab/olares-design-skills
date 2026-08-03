---
name: design-implement
description: >-
  把 Figma 设计忠实落地成代码，并强制对齐到目标项目自己的 design token 体系与组件库。当用户说
  "implement this figma""按 figma 改 UI""还原这个设计""restyle to match figma""应用变量清单"，
  或给出 figma.com/design 链接要求实现/改样式时使用。核心：所有视觉值映射到项目 token、优先复用现成组件、
  只改 UI 不碰业务逻辑。目标项目是 Olares / Quasar 系时，叠加使用 design-implement-olares。
---

# design-implement

把 Figma 稿**忠实落地成代码**，用项目已有的词汇把设计画出来——而不是另起一套样式。

**先读 [references/constraints.md](references/constraints.md)**：三个卡点、不许丢的东西、复用优先级、工具类优先、UI 分文件逻辑共用、多视口、旧消费者回归、收尾报告。本文件只写**流程**，约束都在那里。

术语见 [references/glossary.md](references/glossary.md)。

**目标项目是 Olares / Quasar 系时，同时加载 `design-implement-olares`**——那里有本套设计系统的实测取值、组件对照和翻车清单。

---

## 第 1 步：拿到词汇表（不可跳过）

读目标仓库的 `docs/design-system-inventory.md`。没有盘点、或盘点已过期，先跑 `design-probe`。

目的是建立"可用词汇"，后面每一个视觉值都往这套词汇上映射。

**顺序不可颠倒**：倒过来做——先读 Figma 再找词汇——的结果一定是先按 Figma 的原始值写了一版，再回头逐个换 token，等于做两遍。

⚠️ **只做小修（改间距、换颜色、换图标）也要先走这一步。** 第 3 步的值映射、第 4 步的自查、`design-verify` 的静态层，判据全部来自这里。跳过它等于把"对齐 token"退化成凭记忆写值。改动小的时候可以只取本次要用到的那一类值，见 `design-probe` 的最小可用盘点。

## 第 2 步：读 Figma

委派 `figma-design-to-code`（调 `get_design_context` 前它是必读的）。

**没有设计稿的小修跳过本步**，直接第 1 步 → 第 3 步。这是唯一允许跳过的步骤。

要点：

- `get_design_context` 是主工具，一次调用同时给参考代码、截图和 hint。别用 `get_metadata` / `get_screenshot` 替代它。
- 返回的是 **React + Tailwind 参考代码，不是最终代码**。结构和意图可信，但必须改写成项目的技术栈、组件与 token。
- 按优先级采信 hint：Code Connect 片段 > 组件文档链接 > 设计标注 > 设计 token > 裸 hex / 绝对定位。
- 一次给多个链接时，标注每个链接对应哪个视口，`fileKey` 可以不同。
- 节点 ID 从 URL 取，`-` 换成 `:`。

## 第 3 步：落地

### 组件怎么选

严格按 `references/constraints.md` 第四节的五级优先级，**先搜再写**是强制的。

样式与设计不符时，**优先"框架原生组件 + 样式包裹层"**，不要从零重写组件：保留原生组件的行为、无障碍与 API，只覆盖视觉，样式集中写在 wrapper 里，覆盖值仍走 token。

### 值怎么映射

**通则：类名 = 前缀 + 源 token 名原样。** 不擅自加减连字符。

token 名本身带连字符（`ink-1`、`orange-default`）类名就带（`text-ink-2`）；token 名不带（`body1`）类名就不带（`text-body1`）。这不是两条特例，是同一条规律——差别只来自 token 名本身。硬塞一个连字符写成 `text-body-1`，框架不会生成这个类，它是**死类**，不报错、纯粹不生效。

- **颜色** → 语义层变量 / 工具类，不用 primitive 调色板。
- **间距** → 间距尺度的档位，不硬编码 px。
- **字号 / 行高** → 排版尺度的类，模板挂类优先于在 `<style>` 里写。
- **亮 / 暗成对**：用语义变量即可自动跟随主题，**绝不只取亮色值硬编码**。
- 找不到足够接近的 → 走卡点 2，别静默硬编码。

⚠️ **品牌色 / `primary` 可能随构建被覆盖成不同值。** 同一套代码在不同入口下 `primary` 可能是完全不同的颜色。要和同页其他控件（如开关）保持一致时，**直接用同一个语义色名**，而不是裸 `primary`。用前先确认当前构建的实际取值。

### 图标与资源（三档）

1. 能对应图标字体名 → 直接用。**注意 set 的命名前缀**，以项目现有写法为准。
2. 自定义**单色**图标 → 导出 SVG，**优先 `currentColor` 内联**，自动跟随主题与文字色，免维护两份。
3. **多色**插图 / logo → 导出资源；实在无法用 `currentColor` 时才产出暗色变体。

走到第 3 档（整节点导出 SVG / 做暗色变体）时，**读 [references/svg-export.md](references/svg-export.md)**——祖先画板 chrome 混入、结构性 `fill="white"` 不能动、暗色重映射的顺序，都在那里。能停在第 2 档就不用读。

### 响应式

忠实还原给定视口，用项目断点做优雅降级。缺移动端稿就标注降级，**不臆造**（见 `references/constraints.md` 第七节）。

## 第 4 步：验收前先自查

交给 `design-verify` 之前，自己先过一遍：

1. 排版：字号 / 字重 / 行高
2. 间距 / 对齐 / 圆角 / 描边 / 投影
3. 颜色：特别是**品牌色是否与同页其他控件一致**
4. 图标：名字 / 前缀对不对、**该有的外框或底色方块在不在**
5. **非理想态**：loading / empty / error 也要还原到位——尤其 loading 文案在窄按钮里别换行溢出
6. 自定义 CSS 类的数量：应该趋近于 0，每保留一条都要有 `/* design-exempt: <原因> */`（格式见共享约束第五节，没有这个前缀验收会判失败）

**页面已有现成的参考实现时，以它为准**——读它逐像素对齐，比只看 Figma 准得多。

## 第 5 步：收尾

按 `references/constraints.md` 第十节输出结构化报告。

报告之前，改过被复用组件的话**先做旧消费者回归核对**（第八节）——特别是靠 `:deep()` 依赖你的包裹类名的那些。
