#!/usr/bin/env bash
# extract.sh <html-file> — 正文提取：perl 去 script/style/noscript + pup 回退链
set -u
f=${1:?"usage: extract.sh <html-file>"}

clean=$(perl -0777 -pe 's{<(script|style|noscript|nav|header|footer|aside)\b[^>]*>.*?</\1\s*>}{}gis' "$f")

out=''
for sel in 'article' 'main' '[role=main]' 'body'; do
  out=$(printf '%s' "$clean" | pup "$sel text{}" 2>/dev/null | sed '/^[[:space:]]*$/d')
  [ "${#out}" -gt 20 ] && break
done

printf '%s\n' "$out"
