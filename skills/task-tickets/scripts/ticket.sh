#!/usr/bin/env bash
# ticket.sh — yomi 工单生命周期工具。格式契约见 ../SKILL.md「规范」节，
# 本脚本负责强制执行它：id 铸造、slug、时间戳、frontmatter 形状、状态机。
#
# 用法：
#   ticket.sh new  --dir <工作区> --title <标题> [--prefix yt] [--body <正文>]
#                  （--body 缺省且 stdin 非 tty 时从 stdin 读）
#   ticket.sh set  <文件> <pending|claimed|done|blocked> [--by <session_id>]
#                  [--note <备注>] [--result <结果摘要>]

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

mint_id() { # $1=prefix $2=dir
  local prefix="$1" dir="$2" id i
  for i in $(seq 10); do
    id="$prefix-$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom | head -c 5)"
    compgen -G "$dir/$id-*.md" > /dev/null || { printf '%s' "$id"; return 0; }
  done
  fail "cannot mint unique id after 10 tries"
}

yaml_quote() { # 双引号标量，转义 \ 和 "
  printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

cmd_new() {
  local dir="" title="" prefix="tk" body=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --dir) dir="$2"; shift 2 ;;
      --title) title="$2"; shift 2 ;;
      --prefix) prefix="$2"; shift 2 ;;
      --body) body="$2"; shift 2 ;;
      *) fail "new: unknown arg '$1'" ;;
    esac
  done
  [ -n "$dir" ] || fail "new: --dir required"
  [ -n "$title" ] || fail "new: --title required"
  [ -n "$body" ] || [ -t 0 ] || body="$(cat)"

  local board="$dir/.yomi/tickets"
  mkdir -p "$board"
  local id slug file
  id="$(mint_id "$prefix" "$board")"
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

current_status() { # $1=file
  sed -n 's/^status: //p' "$1" | head -1
}

upsert_owner() { # $1=file $2=owner
  if grep -q '^owner_session_id:' "$1"; then
    sed -i '' -E "s/^owner_session_id: .*/owner_session_id: \"$2\"/" "$1"
  else
    sed -i '' -E "/^status: /a\\
owner_session_id: \"$2\"" "$1"
  fi
}

cmd_set() {
  local file="${1:-}" next="${2:-}"
  [ -n "$file" ] && [ -n "$next" ] || fail "set: <file> <status> required"
  shift 2
  local by="" note="" result=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --by) by="$2"; shift 2 ;;
      --note) note="$2"; shift 2 ;;
      --result) result="$2"; shift 2 ;;
      *) fail "set: unknown arg '$1'" ;;
    esac
  done
  [ -f "$file" ] || fail "set: no such file: $file"
  case "$next" in pending|claimed|done|blocked) ;; *) fail "set: bad status '$next'" ;; esac

  local cur
  cur="$(current_status "$file")"
  [ -n "$cur" ] || fail "set: no status line in $file"

  # 状态机：pending->claimed|done|blocked；claimed->done|blocked|pending；
  # blocked->claimed（复工）；done 不流转（要重做请新建工单）。
  case "$cur->$next" in
    "pending->claimed"|"claimed->done"|"claimed->blocked"|"blocked->claimed"|"claimed->pending") ;;
    "pending->"*) fail "set: $cur->$next 非法——先 claim（claimed）再完结" ;;
    *) fail "set: $cur->$next 非法流转" ;;
  esac

  [ "$next" = "claimed" ] && [ -z "$by" ] && fail "set: claimed 需要 --by <session_id>"

  sed -i '' -E "s/^status: .*/status: $next/" "$file"
  case "$next" in
    claimed) upsert_owner "$file" "$by" ;;
    pending) sed -i '' -E '/^owner_session_id:/d' "$file" ;;
  esac

  if [ "$next" = "done" ]; then
    if [ -n "$result" ] && ! grep -q '^## Result' "$file"; then
      printf '\n## Result\n\n%s\n' "$result" >> "$file"
    elif ! grep -q '^## Result' "$file"; then
      echo "ticket.sh: warning: done without Result section" >&2
    fi
  fi
  [ -n "$note" ] && printf '\n> [%s] %s\n' "$(date '+%Y-%m-%d')" "$note" >> "$file"

  printf '%s: %s -> %s\n' "$file" "$cur" "$next"
}

case "${1:-}" in
  new) shift; cmd_new "$@" ;;
  set) shift; cmd_set "$@" ;;
  *) fail "usage: ticket.sh new|set ..." ;;
esac
