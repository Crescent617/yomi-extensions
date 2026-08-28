#!/usr/bin/env bash
# fetch.sh <url> [--refresh] — 抓取 URL：1h 缓存 → 类型分发 → 预览 + FULL 路径
set -u
url=${1:?"usage: fetch.sh <url> [--refresh]"}
[ "${2:-}" = "--refresh" ] && refresh=1 || refresh=0

dir=${FETCH_CACHE_DIR:-$HOME/.cache/yomi-web}
mkdir -p "$dir"

md5q()  { command -v md5 >/dev/null 2>&1 && md5 -q || md5sum | cut -d' ' -f1; }
mtime() { stat -f %m "$1" 2>/dev/null || stat -c %Y "$1"; }
fsize() { stat -f %z "$1" 2>/dev/null || stat -c %s "$1"; }
fmime() { file -bI "$1" 2>/dev/null || file --mime-type -b "$1"; }

key=$(printf '%s' "$url" | md5q | cut -c1-10)
slug=$(printf '%s' "${url%%\?*}" | sed 's|.*/||' | tr -cd '[:alnum:]._-' | cut -c1-40)
[ -n "$slug" ] || slug=index
raw=$dir/$key-$slug

fresh=0
if [ "$refresh" = 0 ] && [ -f "$raw" ]; then
  [ $(( $(date +%s) - $(mtime "$raw") )) -lt 3600 ] && fresh=1
fi

stale=0
if [ "$fresh" = 0 ]; then
  if curl -sfL --max-time 60 --retry 2 \
       -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36" \
       -o "$raw.new" "$url" && [ -s "$raw.new" ]; then
    mv "$raw.new" "$raw"; rm -f "$raw.txt"
  else
    rm -f "$raw.new"
    [ -f "$raw" ] && stale=1 || { echo "FETCH FAILED: $url"; exit 1; }
  fi
fi

[ "$stale" = 1 ] && echo "STALE COPY (refetch failed)"

mime=$(fmime "$raw" | cut -d';' -f1)
case "$mime" in
  image/*)
    echo "IMAGE: $raw — 用 read 工具看图"; exit 0 ;;
  application/pdf)
    echo "PDF: $raw ($(fsize "$raw") bytes)"
    if command -v pdftotext >/dev/null 2>&1; then
      pdftotext -layout "$raw" "$raw.txt" && head -c 6000 "$raw.txt"
      echo; echo "FULL: $raw.txt"
    else
      echo "提取文本需 pdftotext：brew install poppler / apt install poppler-utils"
    fi
    exit 0 ;;
  text/html*)
    [ -f "$raw.txt" ] || "$(dirname "$0")/extract.sh" "$raw" > "$raw.txt"
    head -c 6000 "$raw.txt"
    echo; echo "FULL: $raw.txt (extracted) | raw: $raw ($(fsize "$raw") bytes)" ;;
  *)
    head -c 6000 "$raw"
    echo; echo "FULL: $raw ($(fsize "$raw") bytes, $mime)" ;;
esac
