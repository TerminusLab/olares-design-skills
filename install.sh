#!/usr/bin/env bash
# 把本仓库的 skill 装到 ~/.claude/skills（Cursor 与 Claude Code 都从这里读）。
# 幂等：重复执行安全，已存在的正确软链会被原样重建。
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${SKILLS_DIR:-$HOME/.claude/skills}"
SKILLS=(design-routing design-pipeline design-probe design-implement design-implement-olares design-verify ask-design)
# 需要引用共享约束的 skill（ask-design 是纯地图，不需要）
NEEDS_CONSTRAINTS=(design-routing design-pipeline design-probe design-implement design-implement-olares design-verify)

mkdir -p "$TARGET"

for s in "${NEEDS_CONSTRAINTS[@]}"; do
  # 仓库内：references/constraints.md → shared/constraints.md（单一定义源）
  mkdir -p "$REPO/$s/references"
  ln -sfn ../../shared/constraints.md "$REPO/$s/references/constraints.md"
done

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

echo
echo "自检：每个 skill 的 constraints.md 是否可达"
fail=0
for s in "${NEEDS_CONSTRAINTS[@]}"; do
  if head -1 "$TARGET/$s/references/constraints.md" >/dev/null 2>&1; then
    echo "  ok   $s"
  else
    echo "  FAIL $s → references/constraints.md 读不到" >&2
    fail=1
  fi
done

exit $fail
