#!/usr/bin/env bash
# 把本仓库的 skill 装到 ~/.claude/skills（Cursor 与 Claude Code 都从这里读）。
# 幂等：重复执行安全，已存在的正确软链会被原样重建。
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SKILLS_DIR:-$HOME/.claude/skills}"

SKILLS=(design-routing design-pipeline design-probe design-implement design-implement-olares design-verify ask-design)

# 共享文件 → 引用它的 skill。ask-design 是纯地图，直接讲 shared/ 本身，不需要软链。
NEEDS_CONSTRAINTS=(design-routing design-pipeline design-probe design-implement design-implement-olares design-verify)
NEEDS_GLOSSARY=(design-routing design-pipeline design-probe design-implement design-implement-olares design-verify)
NEEDS_INVENTORY_SCHEMA=(design-probe design-verify)
NEEDS_SVG_EXPORT=(design-implement)

mkdir -p "$TARGET"

# ---- 仓库内软链：references/<name>.md → 单一定义源 ----

link_shared() {
  local target_rel="$1" name="$2"; shift 2
  for s in "$@"; do
    mkdir -p "$REPO/$s/references"
    ln -sfn "$target_rel" "$REPO/$s/references/$name"
  done
}

link_shared ../../shared/constraints.md       constraints.md       "${NEEDS_CONSTRAINTS[@]}"
link_shared ../../CONTEXT.md                  glossary.md          "${NEEDS_GLOSSARY[@]}"
link_shared ../../shared/inventory-schema.md  inventory-schema.md  "${NEEDS_INVENTORY_SCHEMA[@]}"
link_shared ../../shared/svg-export.md        svg-export.md        "${NEEDS_SVG_EXPORT[@]}"

# ---- 装到 skills 目录 ----

for s in "${SKILLS[@]}"; do
  dest="$TARGET/$s"
  # 已存在同名真实目录（非软链）时不覆盖，避免误删手写内容
  if [ -e "$dest" ] && [ ! -L "$dest" ]; then
    echo "跳过 $s：$dest 是真实目录，不是软链。请先手动处理。" >&2
    continue
  fi
  ln -sfn "$REPO/$s" "$dest"
  echo "已链接 $s"
done

fail=0

# ---- 外部依赖：文案叠加（olares-ux-writing / olares-i18n-audit）----
# Olares 完整落地新增文案时需要；缺则全局安装。不装进本仓库，避免复制文案规范。

echo
echo "外部依赖：文案叠加 skill"

WRITING_SKILLS=(olares-ux-writing olares-i18n-audit)
writing_missing=()

writing_skill_present() {
  local name="$1"
  [ -e "$HOME/.agents/skills/$name/SKILL.md" ] \
    || [ -e "$HOME/.claude/skills/$name/SKILL.md" ] \
    || [ -L "$HOME/.claude/skills/$name" ] \
    || [ -L "$HOME/.agents/skills/$name" ]
}

for ws in "${WRITING_SKILLS[@]}"; do
  if writing_skill_present "$ws"; then
    echo "  ok   ${ws} (global)"
  else
    echo "  miss ${ws}"
    writing_missing+=("$ws")
  fi
done

if [ "${#writing_missing[@]}" -gt 0 ]; then
  echo "  -> installing fnalways/olares-writing-skills globally (--full-depth)..."
  if npx --yes skills add fnalways/olares-writing-skills -g -y --full-depth \
      -a cursor -a claude-code -a universal; then
    for ws in "${WRITING_SKILLS[@]}"; do
      if writing_skill_present "$ws"; then
        echo "  ok   ${ws} (installed)"
      else
        echo "  FAIL ${ws} still missing after install (~/.agents/skills or ~/.claude/skills)" >&2
        fail=1
      fi
    done
  else
    echo "  FAIL npx skills add failed; run manually:" >&2
    echo "       npx skills add fnalways/olares-writing-skills -g -y --full-depth -a cursor -a claude-code -a universal" >&2
    fail=1
  fi
fi

# ---- 自检一：软链可达 ----

echo
echo "自检一：共享文件是否可达"

check_reachable() {
  local name="$1"; shift
  for s in "$@"; do
    if head -1 "$TARGET/$s/references/$name" >/dev/null 2>&1; then
      echo "  ok   $s → $name"
    else
      echo "  FAIL $s → references/$name 读不到" >&2
      fail=1
    fi
  done
}

check_reachable constraints.md      "${NEEDS_CONSTRAINTS[@]}"
check_reachable glossary.md         "${NEEDS_GLOSSARY[@]}"
check_reachable inventory-schema.md "${NEEDS_INVENTORY_SCHEMA[@]}"
check_reachable svg-export.md       "${NEEDS_SVG_EXPORT[@]}"

# ---- 自检二：内容层一致性 ----
# 软链可达 ≠ 说法一致。下面这些是实际发生过的漂移，检查成本远低于半年后踩坑。

echo
echo "自检二：内容一致性"

# 2.1 每个 skill 都有 frontmatter 的 name，且与目录名一致
for s in "${SKILLS[@]}"; do
  declared="$(awk '/^name:[[:space:]]*/ {sub(/^name:[[:space:]]*/,""); print; exit}' "$REPO/$s/SKILL.md" 2>/dev/null || true)"
  if [ -z "$declared" ]; then
    echo "  FAIL $s → SKILL.md 缺 frontmatter 的 name" >&2
    fail=1
  elif [ "$declared" != "$s" ]; then
    echo "  FAIL $s → frontmatter name 是 '$declared'，与目录名不一致" >&2
    fail=1
  fi
done

# 2.2 constraints.md 的引用列表必须涵盖所有 NEEDS_CONSTRAINTS
#     （曾漏掉 design-routing：软链建了，文档没提，等于没人知道要读）
for s in "${NEEDS_CONSTRAINTS[@]}"; do
  if ! grep -q "$s" "$REPO/shared/constraints.md"; then
    echo "  FAIL shared/constraints.md 的引用列表没提到 $s" >&2
    fail=1
  fi
done

# 2.3 不该再出现写死的 skill 计数
#     （"五个 skill" 一旦增删就是错的，正确写法是不写数字）
if grep -rn "[五六七八]个[[:space:]]*skill" --include=*.md "$REPO" 2>/dev/null | grep -v docs/archive; then
  echo "  FAIL 出现写死的 skill 计数，改成不写数字的表述" >&2
  fail=1
fi

# 2.4 阶段编号统一为 1–7，不该残留重构前的"阶段 0"
if grep -rn "阶段[[:space:]]*0" --include=*.md "$REPO" 2>/dev/null | grep -v docs/archive; then
  echo "  FAIL 残留“阶段 0”，现行编号是 1–7" >&2
  fail=1
fi

# 2.4b 卡点数量已从三改四（新增「模块清盘」），不该再有「三个卡点」残留
#      这类数字散在多个 skill 的开头摘要里，改一处必漏其他处。
if grep -rn "三个卡点" --include=*.md "$REPO" 2>/dev/null | grep -v docs/archive; then
  echo "  FAIL 残留“三个卡点”，现行是四个（含模块清盘）" >&2
  fail=1
fi

# 2.4c 长页面档的三个入口必须同时知道它存在
#      只在 pipeline 里定义一个新档位而入口不转发，结果是这个档永远不会被走到。
for s in design-pipeline design-routing design-implement; do
  if ! grep -q "长页面" "$REPO/$s/SKILL.md"; then
    echo "  FAIL $s/SKILL.md 没提长页面档，该档位的入口会断" >&2
    fail=1
  fi
done

# 2.4d 长页面阈值已从 5 降为 4，不得残留旧阈值
#      阈值同时写在 constraints、pipeline、routing、implement、CONTEXT、ask-design 六处，
#      改一处必漏其他，而且两个阈值共存时不会报错，只会让判据自相矛盾。
if grep -rn "section \*\*≥ 5\|section ≥ 5\|够不够 5 个 section" --include=*.md "$REPO" 2>/dev/null | grep -v docs/archive; then
  echo "  FAIL 残留长页面旧阈值‘section ≥ 5’，现行是 ≥ 4" >&2
  fail=1
fi

# 2.4e 阶段 3.5 必须包含物料就绪度自检与三路分流
#      清盘若只拆模块而不查缺件，缺文案 / 缺导出图 / 缺移动稿会拖到 5b 才暴露，
#      那时已经写了一半，补文案意味着重排布局。
if ! grep -q "物料就绪度自检" "$REPO/design-pipeline/SKILL.md"; then
  echo "  FAIL design-pipeline 阶段 3.5 缺少物料就绪度自检，清盘会退化成只拆模块" >&2
  fail=1
fi
for kw in "自己解决" "物料清单" "带建议再问\|带上自己的建议"; do
  if ! grep -q "$kw" "$REPO/design-pipeline/SKILL.md"; then
    echo "  FAIL design-pipeline 阶段 3.5 分流三档不完整，缺“$kw”一类" >&2
    fail=1
  fi
done
if ! grep -q "物料就绪门槛" "$REPO/design-pipeline/SKILL.md"; then
  echo "  FAIL design-pipeline 缺物料就绪门槛，5a 会拿占位数据定 props 接口" >&2
  fail=1
fi

# 2.4f 文案叠加：入口 skill 必须知道闸门（只增量 / 不改存量；模糊须确认；小修也可挂）
#      只写在 constraints 而 routing/implement/verify 不提 = 永远走不到。
for s in design-routing design-implement-olares design-verify design-pipeline ask-design; do
  if ! grep -q "文案叠加" "$REPO/$s/SKILL.md"; then
    echo "  FAIL $s/SKILL.md 没提文案叠加，Olares 新增文案闸门会断" >&2
    fail=1
  fi
done
if ! grep -q "文案叠加" "$REPO/CONTEXT.md"; then
  echo "  FAIL CONTEXT.md 缺「文案叠加」术语" >&2
  fail=1
fi

# 2.5 归档目录不得被当成可用 skill：name 必须带 DEPRECATED 前缀
for f in "$REPO"/docs/archive/*/SKILL.md; do
  [ -e "$f" ] || continue
  if ! awk '/^name:/ {print; exit}' "$f" | grep -q "DEPRECATED"; then
    echo "  FAIL $f 的 frontmatter name 缺 DEPRECATED- 前缀，可能被误加载" >&2
    fail=1
  fi
done

# 2.6 正文里提到的 .md 路径必须真实存在
#     上一版只匹配“仓库根 CONTEXT.md”这一种已知错误写法，换个说法就漏网。
#     现在改成把引用抽出来逐个验证，不依赖预先知道错在哪。
#     两类不算引用，要排除：
#       a) 目标仓库（而非本仓库）里的产物；
#       b) 共享文件的软链名：它们在各 skill 的 references/ 下才存在，
#          而 ask-design（地图）与 shared/ 内部是在“谈论”它们，不建软链。
SHARED_NAMES="constraints.md glossary.md inventory-schema.md svg-export.md"

skip_ref() {
  local r="$1" base
  base="$(basename "$r")"
  case "$r" in
    docs/design-system-inventory.md|docs/inbox.md|*run-record*) return 0 ;;
    *.sass|*.scss|*.json|*.js) return 0 ;;
    */SKILL.md|SKILL.md) return 0 ;;
  esac
  # 共享文件名（含 references/ 前缀的写法）已由自检一验证可达，不重复检
  for n in $SHARED_NAMES; do
    [ "$base" = "$n" ] && return 0
  done
  return 1
}

bad_refs=""
check_refs() {
  local file="$1" label="$2" basedir="$3" refs ref
  refs="$(grep -oE '\(([A-Za-z0-9_./-]+\.md)\)|`([A-Za-z0-9_./-]+\.md)`' "$file" 2>/dev/null | tr -d '()`' | sort -u || true)"
  for ref in $refs; do
    skip_ref "$ref" && continue
    if [ ! -e "$basedir/$ref" ] && [ ! -e "$REPO/$ref" ]; then
      echo "  FAIL $label 引用了不存在的 $ref" >&2
      bad_refs="x$bad_refs"
    fi
  done
}

for s in "${SKILLS[@]}"; do
  check_refs "$REPO/$s/SKILL.md" "$s/SKILL.md" "$REPO/$s"
done

# 2.7 共享文件之间的互引也要能解析
for f in "$REPO"/shared/*.md; do
  check_refs "$f" "shared/$(basename "$f")" "$REPO/shared"
done

[ -n "$bad_refs" ] && fail=1

if [ "$fail" -eq 0 ]; then
  echo "  ok   全部一致"
fi

echo
if [ "$fail" -eq 0 ]; then
  echo "安装完成，自检通过。"
else
  echo "安装完成，但自检有失败项，请修复后重跑。" >&2
fi

exit $fail
