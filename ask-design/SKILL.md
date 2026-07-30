---
name: ask-design
description: 设计到开发这套 skill 的地图——有哪些、各管什么、怎么串起来。想不起来该用哪个时问它。
disable-model-invocation: true
---

# ask-design

你不会记得每个 skill，所以问。

日常**不需要**用到这份地图——`design-routing` 会自动分发。这里是给你想看全貌、或者怀疑路由走错了的时候用的。

## 主干：需求 → 页面能跑

```
需求 → 探测词汇表 → Figma 真图层 → 【卡点：定稿确认】→ 落地 → 验收 → 收尾报告
```

由 **`design-pipeline`** 编排。它自己不写 Figma API 细节，在每个阶段委派出去。

终点是「页面能跑 + 验收通过 + 收尾报告」，**不 commit、不开 PR**——那些交给 `code-review`、`split-to-prs`。

## 三档进入方式

不是所有活儿都要走全链路：

- **新建**（做一个不存在的页面）→ 全链路。
- **改造**（既有页面重做视觉）→ 跳过需求澄清，从探测进。
- **小修**（改间距、换图标）→ 只走 `design-implement` + `design-verify` 静态层，不进编排。

## 五个执行 skill

- **`design-probe`** — 建立**词汇表**。扫代码侧的 token / 组件库 / 图标约定，扫 Figma 侧的变量 / 组件 / 样式，扫 Code Connect 覆盖率。产出目标仓库的 `docs/design-system-inventory.md`。它是**快照不是真理**，源文件变了就过期。

  链路里所有"映射到 token"的动作都依赖它，所以它必须早于读 Figma 稿。**探测发现项目根本没有 token 体系、或 Figma 侧没有设计系统库，都会停下来问你**——链路不假装自己完整。

- **`design-implement`** — 把 Figma 稿落地成代码，通用手册。核心是三件事：复用优先于新写、所有值映射到词汇表、只改 UI 不碰业务逻辑。

- **`design-implement-olares`** — 上一个的**叠加层**，不是替代。Olares / Quasar 系仓库才用：实测的 token 取值、`Bt*` 组件对照、`$q.screen` 与 platform 的区别、`cssAddon` 未开的陷阱、`q-gutter` 强制换行、图标前缀、`primary` 被重定向，以及历次返工换来的翻车清单。查 Quasar 官方 API 用 `quasar-skilld`。

- **`design-verify`** — 判定"对不对"，不是"像不像"。两层：静态扫本次改动文件的硬编码字面量（零误报），CDP 扫本次改动元素子树的 computed style（抓「写的是 token 但渲染成别的值」）。都只看本次改动范围，不扫整页——**宁可漏报，不可被第三方噪音淹没**。

- **`design-routing`** — 自动分发器，模型自己会调用。任何涉及视觉的请求都先落到它，由它判档位、选路径、挂底线。它存在的理由是：**大改你会记得走流程，小修你不会**。

## 约束住在哪

**`shared/constraints.md`** 是唯一定义源，五个 skill 各用一条软链引用（`references/constraints.md`）。

要改约束就改那一个文件，全部生效。**不要**在某个 skill 里另写一份——那正是半年后两个 skill 说法不一致的起点。

术语（链路 / 词汇表 / 盘点 / 桥 / 卡点 / 记账 / 降级 / 档位）见仓库根 `CONTEXT.md`。

## 三个卡点

除这三处一律自主推进，不为了"确认一下"打断你：

1. **设计定稿确认**——不确认就写代码，等于把一个错的设计完美实现一遍。通过之后**必须重新拉一次 Figma 当前状态**，因为设计师可能已经直接改了图层。
2. **词汇表匹配不到**——包括"这个项目压根没有 token 体系"。
3. **要动业务逻辑**。

**验收失败不是卡点**，agent 自己迭代；但超过 3 轮就停下汇报，不无限磨。

## 和官方 Figma skill 的分工

官方插件带了约 2600 行，把「代码 → Figma」写得很细（`figma-generate-design` / `figma-use`）。我们**不重写**那部分，只在正确时机按名字委派。

补的是官方薄的那一侧——`figma-design-to-code` 只有 61 行，"复用项目已有组件和 token"只有一句话。词汇表探测、验收闭环、i18n / 非理想态 / a11y 保护、收尾报告，都在这边。

## 通用设计 skill 怎么配合

`polish` / `layout` / `colorize` / `animate` / `typeset` / `critique` 那一批视觉判断力很强，但**不知道你有 token 体系**。

`design-routing` 会给它们加护栏：用之前先把词汇表交给它，用之后跑一次静态校验。不必因此放弃它们。

## 经验怎么回流

收尾报告里会附「建议写回 skill 的条目」，注明该放哪个文件哪一节。

**agent 不会自己改 skill 文件**——它会把一次性的偶发问题写成永久约束，半年后没人读得完。采不采纳你说了算。
