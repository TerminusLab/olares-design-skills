# olares-design-skills

设计到开发链路的 skill 集合。装进 `~/.claude/skills` 后 Cursor 与 Claude Code 都能用。

## 安装

```bash
./install.sh
```

幂等，重复跑安全。脚本会建软链，并做两层自检：共享文件是否可达，以及**内容是否一致**（frontmatter 名与目录名、引用列表完整性、阶段编号、引用路径写法、归档防误加载）。后者是因为软链可达不等于说法一致——文档与实际不符不会报错，只会在半年后让人踩坑。

## skill 清单

| skill | 什么时候触发 |
|---|---|
| `design-routing` | **自动**。任何涉及 UI / 样式 / 组件 / 页面 / 设计的请求都先落到它，由它判档位、选路径、挂底线 |
| `design-pipeline` | 从一句需求做一个新页面 / 功能，走全链路 |
| `design-probe` | 摸清一个项目有哪些 token、组件、Figma 变量可用 |
| `design-implement` | 已有 Figma 稿，要实现成代码 |
| `design-implement-olares` | Olares / Quasar 叠加：项目坑 + **查框架全集的方法**（不是举例目录） |
| `design-verify` | 对不对：hex/px、伪合规 style、可工具类化布局；可选 CDP |
| `ask-design` | **手动**地图：谁干什么、哪条底线、去哪查 |

日常**不需要自己挑 skill**——`design-routing` 会分发。小修最容易绕过工具类约束，所以短路径仍强制：词汇表 → class → verify。

Olares/Quasar：布局/样式**全集**在项目 `node_modules/quasar` 与 `quasar-skilld`（`style/` `layout/`），skill 只给坑与查证流程。

`polish` / `colorize` / `typeset` 等通用设计 skill：先词汇表、后 verify。

## 链路长什么样

```
需求 → 探测词汇表 → Figma 真图层 → 【卡点：定稿确认】→ 落地 → 验收 → 收尾报告
```

三档进入方式：**新建**走全链路；**改造**跳过需求澄清；**小修**只走落地 + 静态校验。

终点是「页面能跑 + 验收通过 + 收尾报告」，**不碰 git**。

## 仓库结构

```
CONTEXT.md                    链路自身的术语表（各 skill 里叫 glossary.md）
shared/constraints.md         卡点 / 记账 / 复用优先级 / 失控预算 / 收尾报告 / 依赖降级
shared/inventory-schema.md    盘点文档的格式契约（probe 写、verify 读）
shared/svg-export.md          SVG 导出与暗色变体（只在真要导出时读）
docs/adr/                     架构决策记录
docs/inbox.md                 经验回流暂存区
docs/archive/                 拆分前的旧版，已废弃、不安装
<skill>/SKILL.md              各 skill
<skill>/references/           指向 shared/ 与 CONTEXT.md 的软链
install.sh
```

`shared/` 下的每一份都是**唯一定义源**，各 skill 通过 `references/` 下的软链引用。要改就改 `shared/` 里那一份，所有引用它的 skill 同时生效（纯地图类的 `ask-design` 除外，它直接讲 `shared/` 本身）。不要在单个 skill 里另写一份。

**新增共享文件后要回 `install.sh` 里加软链**，否则它在安装后的环境里不存在。

## 与官方 Figma skill 的分工

Figma 官方插件带了约 2600 行 skill，把「代码 → Figma」写得很细。本仓库**不重写** Figma API 细节，只在正确时机按名字委派过去，并补上官方薄弱的那一侧（`figma-design-to-code` 只有 61 行）：项目词汇表探测、验收闭环、i18n / 非理想态 / a11y 保护、收尾报告。
