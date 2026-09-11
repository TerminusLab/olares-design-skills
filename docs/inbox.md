# 经验回流暂存区

链路跑完后新学到的东西先落这里，攒够了再决定往哪个 skill 沉淀。

**这个文件存在的理由**：每次踩坑当场改 SKILL.md，改法多半是「在最相关的那节末尾加一段」——十次之后文件肿到 300 行，而且相似的经验散在三处互相矛盾。先攒着，回看时能看出哪些是同一类问题，再一次性写进正确的位置。

---

## 怎么记

一条一段，写清四件事：**现象、根因、正确做法、该归到哪**。

不用纠结格式，但**根因必须写**——只记"XX 不生效"半年后没人知道为什么。

```markdown
### 2026-08-03 · q-gutter 在定高滚动列里把卡片折到第二列

- **现象**：弹窗 body 用 `q-gutter-md` 做垂直间距，第三张卡片跑到第二列去了，与第一张并排。
- **根因**：`q-gutter-*` 的实现是「容器加 `flex-wrap:wrap` + 子元素负 margin」，定高滚动容器里 wrap 会真的换列。
- **正确做法**：纵向堆叠用 `column` + 固定 `gap`（值对齐 `$space`）+ `no-wrap`，不要用 `q-gutter-*`。
- **归到**：`design-implement-olares`（Quasar 特有陷阱）。
```

---

## 沉淀规则

**什么时候回看**——满足任一条就停下来整理，不要无限期攒：

- 「待沉淀」里累计 **≥ 5 条**；
- **同一个坑撞到第二次**（这比条数更优先——重复发生意味着 skill 里确实缺了一条，再攒下去就是第三次）；
- 收尾报告里写下的「因缺 X 而降级」同一原因出现两次以上。

**谁触发**：下一次读到本文件的任务（写入新条目时）顺手看一眼条数，够了就在**当前任务收尾时一并沉淀**，不另开任务。沉淀是几分钟的事，拖到下次就不会发生了。

回看时按下表判断归属：

| 经验的性质 | 沉淀到 |
|---|---|
| 对所有项目都成立的硬规矩 | `shared/constraints.md` |
| 通用落地流程的改进 | `design-implement` |
| 只在 Olares / Quasar 系成立的具体值与坑 | `design-implement-olares` |
| 探测方法、盘点格式 | `design-probe` / `shared/inventory-schema.md` |
| 验收判据、扫描范围 | `design-verify` |
| 触发条件、档位判断 | `design-routing` |
| 阶段划分、交接产物 | `design-pipeline` |
| 一句话说不清、且改变了整体结构的决策 | `docs/adr/` 新开一条 ADR |

沉淀完**把条目从本文件删掉**。inbox 里留着已沉淀的条目，下次回看时会分不清哪些还没处理。

---

## 三条判断

**不是所有经验都值得沉淀。** 沉淀之前问三句：

1. **会重复出现吗？** 一次性的环境问题（某次 npm 装坏了）不要写进 skill。
2. **已经有地方写了吗？** 若已有相近条目，**改那一条让它更准**，而不是新加一条——同一件事有两处说法就是下一次矛盾的起点。
3. **是"值"还是"规矩"？** 具体取值（某个 token 的 hex）属于目标仓库的盘点文档，不属于 skill；skill 里放的是规矩和推导规律。

---

## 待沉淀

### 2026-08-18 · TermiPass 是多入口 monorepo，`$primary` 按 app 各自覆盖，BEX 是黄色

- **现象**：给 BEX 翻译页做删除确认弹窗，要给确认按钮配色。`design-implement-olares` 的仓库对照表里 TermiPass 那行 `--q-primary` 只写了「跟所在构建」，照字面读会以为没被覆盖、是 Quasar 默认 `#1976D2` 的蓝。实际翻 `src/css/*/variables.scss` 才发现每个 app 入口各覆盖一份：LarePass / Vault / Files = `$yellow-6`（黄），dashboard = `$light-blue-6`，market / desktop = `$blue-default-light`，controlHub = `$blue-6`，studio = 裸 `#1976d2`。**BEX 的 sidepanel 与 options 页走 LarePass 构建，`primary` 是黄的。**
- **根因**：对照表把 terminus-cloud / AssistHub 的取值写死了（`orange-default` / `blue-default`），唯独 TermiPass 写成「跟所在构建」这种需要自己再查一步的说法，但没给查哪里。而 TermiPass 恰恰是入口最多的那个仓库——同一套代码在 11 个 `src/css/<app>/variables.scss` 下 `primary` 是 5 种不同颜色，比另外两个仓库更容易撞。
- **正确做法**：把「查 `src/css/<app>/variables.scss` 定位当前入口的 `$primary`」写成 TermiPass 那一行的动作，并补一句「BEX = LarePass 构建 = `$yellow-6`」。既有的「别默认 `primary` 是设计稿那个蓝、要品牌色就直接写语义色名」这条结论不变，只是补上怎么查。
- **归到**：`design-implement-olares` 仓库对照表 TermiPass 行（**改那一行，不要新加一节**——`primary` 陷阱在该文件里已有 §B 和小修速查两处说法，再加第三处就是矛盾的起点）。

### 2026-08-18 · `BtDialog` 的 `okStyle` 传 token 名是无效 CSS，静默回退

- **现象**：照存量写法给确认弹窗的确认按钮配色，`okStyle: { background: 'yellow-default' }`（`ItemList.vue` 里就是这么写的），按钮颜色不对但不报错。
- **根因**：`okStyle` 在 `dialog/src/DialogFooter.vue` 里是直接绑到 `:style` 上的，`background: 'yellow-default'` 不是合法 CSS 值，浏览器丢弃该声明，于是回退到 `.but-creat` 的默认 `$yellow-6`。**恰好也是黄色，所以看起来"生效了"**——换成 `red-default` 才会暴露。写对的那种（`MarketSourceItem.vue`）用的是 `useColor('blue-default').color`，拿到的是 `getPaletteColor` 解析出的真 hex，且 `useColor` 内部有 `watchEffect` 跟随暗色。
- **正确做法**：`okStyle` 必须传真实颜色值，走 `useColor('<token>').color`；不要传 token 名，也不要写 hex。
- **归到**：`design-implement-olares`「常用组件先搜这些」那节——该节现在只说了「别停在 Quasar 原生够用，项目里有 `BtDialog`」，但没说 `BtDialog` 自己有个会静默失败的 API。属于「找到了正确组件之后仍然会踩的坑」。

---

## 已沉淀（备查，可删）

### 2026-08-07 · 五条收进正文

- 卡点 2 菜单 → `shared/constraints.md` + `design-probe`
- Greenfield / 阶段 3 自检 / 演示边界 → `design-pipeline` + `CONTEXT.md`
- 空画布路由 → `design-routing` + `ask-design`
- 动效规格 → `shared/constraints.md` 第三节；verify 轻检 → `design-verify`

### 2026-08-09 · `map-get($space-*)` 写进 style 被当成合规

- **现象**：ReplyDialog footer 小修时 agent 反复在 `<style>` 里改 `padding: map-get($space-lg)` / `gap: map-get($space-md)`，用户指出应优先用 `q-pa-*` / 工具类。
- **根因**：① `design-verify` 只扫裸 hex/px，token 版 map-get 静默通过；② skill 强调「用 token」多于「挂工具类」，`design-implement-olares` 甚至把「scoped 固定 gap 对齐 $space」写成避坑正解，强化了捷径；③ `ask-design` 是地图，小修路径没把「改 class 不改 style」写成硬步骤。
- **正确做法**：间距默认模板 `q-p*` / `flex-gap-*`；仅 `max(token, safe-area)` 等组合进 style + `design-exempt`。
- **该归到哪**：已沉淀进 `shared/constraints.md` §5、`design-implement-olares` 小修速查/§C/正反例、`design-routing` 小修步骤、`design-verify` 静态扫、`ask-design`「已知漏洞」——本条可归档。

### 2026-08-09 · 举一反三：布局面不只间距，AI 要自主用整套 Quasar 工具类

- **现象**：用户追问除 `q-pa-*` 外的 `q-my-*` 等，以及 flex/尺寸等布局类 AI 能否自主用。
- **根因**：参考文档（`quasar.md`）其实已有 §2–§7，但小修路径只强化了间距，agent 不会主动「CSS→类」映射；验收原先也不拦 `display:flex`。
- **正确做法**：小修路径挂「自主布局」对照表；verify 拦无豁免的 flex/100%宽高/text-align；gutter 正解改为 `flex-gap-*`。
- **该归到哪**：已写入 `design-implement-olares`「自主布局」、`quasar.md` §2.5/§7、`design-verify`、`design-routing`、`constraints`、`ask-design`。

### 2026-08-09 · Skill 举例 ≠ Quasar 全集；要像开发者一样查源

- **现象**：用户要求 AI 灵活使用 Quasar 全部布局能力，不能只靠 skill 里举的几个 class。
- **根因**：小修路径曾写「不必读 quasar.md」，对照表又被当成白名单；权威源（`core/*.sass`、`dist/api`、`quasar-skilld` 的 style/layout）写在 §0 但未绑进强制流程。
- **正确做法**：明确「举例不是目录」；强制查证顺序 + rg/Read 命令；skilld `style/`+`layout/` 为概念全文，安装版 `core/*.sass` 为类名真源。
- **该归到哪**：已改 `design-implement-olares`（重写查证节）、`quasar.md` §0、`design-routing`、`ask-design`、`constraints`。

### 2026-08-09 · ask-design 族收敛：约束框架无关、地图索引化、查证进主干

- **现象**：多轮补丁后 ask-design / constraints 堆了 Quasar 类名表与重复漏洞段，共享约束被某一框架绑死。
- **根因**：举一反三时把框架细节写进 `shared/constraints`；ask-design 从地图变成第二份操作手册。
- **正确做法**：constraints §5 只保留框架无关原则；Quasar 查证只在 `design-implement-olares`；ask-design 改回索引型地图；routing 底线指向 verify 新扫描项。
- **该归到哪**：本次已改正文（ask-design / constraints / routing / verify·olares description / README）。

### 2026-09-07 · 落地前没读仓库已有盘点，自己重推词汇表 → 漏掉只有盘点才知道的陷阱

- **现象**：TermiPass BEX 设计落地（7 个 commit / 49 文件）时 agent 自己从 `quasar.variables.sass` / `variables-bg.sass` / `theme.scss` 重新推了间距、排版、颜色，**没打开仓库里已经存在的 `docs/design-system-inventory.md`**。结果漏掉盘点里明写的一条：「`blue-6` 亮暗同值 #3377FF，暗色模式不跟随；新代码一律用 `blue-default`」。整体重写的 `TranslateIndex.vue` 里因此留下 4 处 `text-blue-6`，旁边还有 2 处 `text-grey-4`（Quasar primitive #e0e0e0，无亮暗配对 —— 暗色下 disabled 项比 enabled 项更亮，层级反转）。
- **根因**：① `design-implement-olares` 的「像开发者一样查」把权威源指向 `node_modules/quasar/src/css/core/*` 与项目 theme 文件，**没有把「先查仓库已有盘点」写成第 0 层**；② 「某个 class 看起来能用、实际不跟随主题」这类陷阱**只存在于盘点的 ⚠️ 段落里**，从源文件按规律推导推不出来 —— 源文件只告诉你 `$grey-4` 存在，不告诉你它不该用。
- **正确做法**：落地前第一步读 `docs/design-system-inventory.md`（并核对元信息里的 `盘点范围` 与源文件是否已变）；源文件只在盘点缺项、或盘点已过期时才去推。
- **该归到哪**：`design-implement-olares` 查证顺序补「第 0 层：仓库已有盘点」；`design-routing` 小修路径里的「词汇表」明确指盘点文件而不是源文件。

### 2026-09-07 · 整体重写存量文件时，文件里原有的写法就成了新代码

- **现象**：`TranslateIndex.vue` 被整体重写（`Write` 覆盖），文件里存量的 `text-blue-6`、`text-grey-4`、以及与模板上 `text-subtitle3` / `text-overline` **完全重复**的 scoped `font-size` / `line-height` 被原样搬了过去。当时的自我判断是「这些是存量写法，不在本次改动范围」。
- **根因**：「只改增量、不动存量」这条**本是文案规则**（避免越权改既有翻译），被误用到样式上。而 `design-verify` 只扫 diff 的新增行 —— 整体重写恰恰会把存量行也变成新增行，本该扫得更严，实际却因为「这是存量写法」被自我豁免掉了。
- **正确做法**：判据是「这一行在本次 diff 里是不是新增的」，不是「这段代码以前有没有」。整体重写一个文件 = 整个文件按新代码验收。文案的「不动存量」与样式的「不动存量」是两件事，不能互相借用。
- **该归到哪**：`design-verify` 静态层补一句说明；`shared/constraints.md` 第五节豁免部分点明「存量写法不构成豁免理由」。
