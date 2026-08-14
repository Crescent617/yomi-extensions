#!/usr/bin/env bash
# ticket.sh — yomi 工单建单工具。格式契约见 ../SKILL.md，
# 本脚本负责建单时强制执行它：id 铸造、slug、时间戳、frontmatter 形状。
# 状态流转不走脚本——直接编辑工单文件，规则见 SKILL.md「状态流转」节。
#
# 用法：
#   ticket.sh new --title <标题> [--dir <工作区，默认 cwd>] [--body <正文>]
#                 （--body 缺省且 stdin 非 tty 时从 stdin 读）

set -euo pipefail

fail() { echo "ticket.sh: $*" >&2; exit 2; }

slugify() {
  local s
  s="$(printf '%s' "$1" | tr 'A-Z' 'a-z' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g' | cut -c1-40)"
  printf '%s' "${s:-task}"
}

now_rfc3339() {
  date '+%Y-%m-%dT%H:%M:%S%z' | sed -E 's/([+-][0-9]{2})([0-9]{2})$/\1:\2/'
}

mint_id() { # $1=dir
  local dir="$1" id i
  for i in $(seq 10); do
    id="$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 7)"
    compgen -G "$dir/$id-*.md" > /dev/null || { printf '%s' "$id"; return 0; }
  done
  fail "cannot mint unique id after 10 tries"
}

yaml_quote() { # 双引号标量，转义 \ 和 "
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

cmd_new() {
  local dir="$PWD" title="" body=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --dir) dir="$2"; shift 2 ;;
      --title) title="$2"; shift 2 ;;
      --body) body="$2"; shift 2 ;;
      *) fail "new: unknown arg '$1'" ;;
    esac
  done
  [ -n "$title" ] || fail "new: --title required"
  [ -n "$body" ] || [ -t 0 ] || body="$(cat)"

  local board="$dir/.yomi/tickets"
  mkdir -p "$board"
  local id slug file
  id="$(mint_id "$board")"
  slug="$(slugify "$title")"
  file="$board/$id-$slug.md"

  {
    printf -- '---\n'
    printf 'title: "%s"\n' "$(yaml_quote "$title")"
    printf 'status: pending\n'
    printf 'created_at: %s\n' "$(now_rfc3339)"
    printf -- '---\n\n'
    [ -n "$body" ] && printf '%s\n' "$body"
  } > "$file"

  printf '%s\n' "$file"
}

case "${1:-}" in
  new) shift; cmd_new "$@" ;;
  *) fail "usage: ticket.sh new --title <标题> [--dir <工作区>] [--body <正文>]" ;;
esac
