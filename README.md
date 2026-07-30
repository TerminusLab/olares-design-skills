# olares-design-skills

设计到开发链路的 skill 集合。装进 `~/.claude/skills` 后 Cursor 与 Claude Code 都能用。

## 安装

```bash
./install.sh
```

幂等，重复跑安全。脚本会建软链并自检 `references/constraints.md` 是否可达。

## 七个 skill

| skill | 什么时候触发 |
|---|---|
| `design-routing` | **自动**。任何涉及 UI / 样式 / 组件 / 页面 / 设计的请求都先落到它，由它判档位、选路径、挂底线 |
| `design-pipeline` | 从一句需求做一个新页面 / 功能，走全链路 |
| `design-probe` | 摸清一个项目有哪些 token、组件、Figma 变量可用 |
| `design-implement` | 已有 Figma 稿，要实现成代码 |
| `design-implement-olares` | 同上，且项目是 Olares / Quasar 系——与上一个**叠加**使用 |
| `design-verify` | 检查落地对不对：硬编码、实际渲染值与词汇表是否一致 |
| `ask-design` | **手动**。想不起来全貌时问它要一张地图 |

日常**不需要自己挑 skill**——`design-routing` 会分发。它存在的理由是：大改你会记得走流程，小修（改个间距、换个颜色）你不会，而小修恰恰最容易绕过 token 约束。

它也给 `polish` / `colorize` / `typeset` 那批通用设计 skill 加护栏：用之前先把词汇表交给它们，用之后跑一次静态校验。

## 链路长什么样

```
需求 → 探测词汇表 → Figma 真图层 → 【卡点：定稿确认】→ 落地 → 验收 → 收尾报告
```

三档进入方式：**新建**走全链路；**改造**跳过需求澄清；**小修**只走落地 + 静态校验。

终点是「页面能跑 + 验收通过 + 收尾报告」，**不碰 git**。

## 仓库结构

```
CONTEXT.md                  链路自身的术语表（glossary）
docs/adr/                   架构决策记录
shared/constraints.md       共享硬约束，唯一定义源
<skill>/SKILL.md            各 skill
<skill>/references/         constraints.md 是指向 shared/ 的软链
install.sh
```

**要改约束，改 `shared/constraints.md`**，五个 skill 同时生效。不要在单个 skill 里另写一份。

## 与官方 Figma skill 的分工

Figma 官方插件带了约 2600 行 skill，把「代码 → Figma」写得很细。本仓库**不重写** Figma API 细节，只在正确时机按名字委派过去，并补上官方薄弱的那一侧（`figma-design-to-code` 只有 61 行）：项目词汇表探测、验收闭环、i18n / 非理想态 / a11y 保护、收尾报告。
