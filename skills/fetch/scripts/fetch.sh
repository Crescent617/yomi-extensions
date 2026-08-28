#!/usr/bin/env bash
# fetch.sh <url> [--refresh] — 抓取 URL：1h 缓存 → 类型分发 → 预览 + FULL 路径
set -u
url=${1:?"usage: fetch.sh <url> [--refresh]"}
[ "${2:-}" = "--refresh" ] && refresh=1 || refresh=0

dir=${FETCH_CACHE_DIR:-$HOME/.cache/yomi-web}
mkdir -p "$dir"
find "$dir" -type f -mtime +7 -delete 2>/dev/null   # 自清理：删 7 天前条目

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
  tmp=$raw.new.$$   # PID 唯一临时名，并发同 URL 不撕裂
  if curl -sfL --max-time 60 --retry 2 \
       -A "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36" \
       -o "$tmp" "$url" && [ -s "$tmp" ]; then
    mv "$tmp" "$raw"; rm -f "$raw.txt"   # rename 原子，后到者整体覆盖
  else
    rm -f "$tmp"
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
    if ! command -v pandoc >/dev/null 2>&1; then
      echo "需要 pandoc 提取 HTML：brew install pandoc / apt install pandoc"; exit 1
    fi
    if [ ! -f "$raw.txt" ]; then
      perl -0777 -pe 's{<(script|style|noscript|nav|header|footer|aside)\b[^>]*>.*?</\1\s*>}{}gis' "$raw" \
        | pandoc -f html -t gfm-raw_html --wrap=none > "$raw.txt.$$" 2>/dev/null
      [ -s "$raw.txt.$$" ] || { rm -f "$raw.txt.$$"; echo "EXTRACT FAILED: $raw"; exit 1; }
      mv "$raw.txt.$$" "$raw.txt"
    fi
    head -c 6000 "$raw.txt"
    echo; echo "FULL: $raw.txt (extracted) | raw: $raw ($(fsize "$raw") bytes)" ;;
  *)
    head -c 6000 "$raw"
    echo; echo "FULL: $raw ($(fsize "$raw") bytes, $mime)" ;;
esac
