---
name: ask-design
description: >-
  Use when you need a map of the design-to-code skills (which skill does what, how
  they chain, which path for 新建/改造/小修), or suspect routing went to the wrong
  skill. Manual only — day-to-day UI work is auto-routed by design-routing.
disable-model-invocation: true
---

# ask-design

设计到开发这套 skill 的**地图**。日常改 UI 走 `design-routing` 自动分发；只有想看全貌、或怀疑走错档位时才打开这里。

## 主干

```
需求 → 探测词汇表 → Figma 真图层 → 【卡点：定稿确认】→ 落地 → 验收 → 收尾报告
```

编排者：`design-pipeline`。终点是「能跑 + 验收通过 + 收尾报告」——**不 commit / 不开 PR**。

**Figma 链接 ≠ 有稿。** 空画布或「先设计再开发」→ pipeline 生成图层，不要直接 `design-implement`。

## 谁干什么

| skill | 职责 |
|---|---|
| `design-routing` | **自动分发**：判档位、挂底线、小修短路径 |
| `design-pipeline` | 新建 / 改造 / 长页面编排与卡点 |
| `design-probe` | 建词汇表 → `docs/design-system-inventory.md`（快照，会过期） |
| `design-implement` | Figma → 代码（通用） |
| `design-implement-olares` | 上者叠加：Olares/Quasar 坑 + **像开发者一样查**框架全集 |
| `design-verify` | 对不对：静态层 + 可选 CDP；含伪合规 / 可工具类化布局 |
| `quasar-skilld` | Quasar 官方文档镜像（`style/` `layout/`…）；类名真源仍是项目 `node_modules/quasar` |

## 三档（+ 长页面叠层）

| 档位 | 何时 | 怎么走 |
|---|---|---|
| 新建 | 没有可落地稿 | pipeline 全链路 |
| 改造 | 既有页重做视觉 | pipeline 从探测进 |
| 小修 | 改间距/色/字号/图标等，无新稿 | 词汇表 → 工具类落地 → `design-verify` 静态层（见 routing） |
| 长页面 | 并列 section≥4 或结构重复模块 | pipeline 3.5 清盘 → 5a 骨架 → 5b 逐模块；**禁止**一次 `design-implement` 整页 |

## 四条底线（任何路径）

细节与卡点正文在 [`shared/constraints.md`](../shared/constraints.md)，这里只索引：

1. **工具类优先**——token/变量写进 `<style>` ≠ 合规；有等价 class 必须挂模板。
2. **视觉值 ∈ 词汇表**——没有盘点先 `design-probe`；匹配不到 → 卡点 2。
3. **框架全集要查，不要背举例**——Olares/Quasar：`design-implement-olares`「像开发者一样查」（`core/*.sass` + `dist/api` + `quasar-skilld`）。skill 举例不是目录。
4. **改完静态验收**——`design-verify` 第一层；豁免必须 `design-exempt:`。

四个**卡点**（停下来问人）：定稿确认 · 词汇表匹配不到 · 要动业务逻辑 · 长页面模块清盘。验收失败不是卡点（自迭代，最多 3 轮）。

## 共享定义源

| 文件 | 内容 |
|---|---|
| `shared/constraints.md` | 卡点 / 复用 / 工具类优先 / 失控预算 / 收尾（**框架无关**） |
| `CONTEXT.md`（各 skill 里叫 `glossary.md`） | 链路术语 |
| `shared/inventory-schema.md` | 盘点格式（probe 写、verify 读） |
| `shared/svg-export.md` | SVG / 暗色变体 |
| `docs/inbox.md` | 经验暂存；**默认不直接改 SKILL 正文** |

各 skill `references/` 是软链。改真身，勿复制一份。

## 和外部 skill 的边界

- **Figma 官方**：代码→Figma 很厚；我们补探测 / 验收 / i18n / 非理想态 / 收尾，按名委派不重写。
- **`polish` / `colorize` / `typeset` / …**：有判断力、不懂你的 token → routing 加护栏（先词汇表，后 verify）。
- **`quasar-skilld`**：官方全文；版本可能新于项目 → props 以 `dist/api` 为准。

## 经验回流

收尾里的「建议写回 skill」→ [`docs/inbox.md`](../docs/inbox.md)。人确认后再改正文，避免每次在节尾堆一段把文件撑爆。
