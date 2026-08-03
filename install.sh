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

# 2.5 归档目录不得被当成可用 skill：name 必须带 DEPRECATED 前缀
for f in "$REPO"/docs/archive/*/SKILL.md; do
  [ -e "$f" ] || continue
  if ! awk '/^name:/ {print; exit}' "$f" | grep -q "DEPRECATED"; then
    echo "  FAIL $f 的 frontmatter name 缺 DEPRECATED- 前缀，可能被误加载" >&2
    fail=1
  fi
done

# 2.6 skill 正文引用共享文件时必须走 references/ 相对路径
#     （写“仓库根 CONTEXT.md”在安装后的环境里指不到任何地方）
if grep -rn "仓库根[[:space:]]*\`\?CONTEXT.md" --include=SKILL.md "$REPO" 2>/dev/null | grep -v docs/archive; then
  echo "  FAIL SKILL.md 里出现“仓库根 CONTEXT.md”，应改为 references/glossary.md" >&2
  fail=1
fi

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
