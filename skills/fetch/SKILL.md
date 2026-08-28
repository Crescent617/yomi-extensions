---
name: fetch
description: 抓取 URL 全文落盘并提取正文，带 1 小时本地缓存。Use when 读网页/链接正文、下载页面/PDF/图片、或用户发来链接要看内容。
---

# fetch

低自由，照抄命令（`scripts/` 在本 skill 目录下）：

```bash
<baseDir>/scripts/fetch.sh "<url>"              # 1h 内命中缓存直接用
<baseDir>/scripts/fetch.sh "<url>" --refresh    # 强制重抓（新闻/监控类）
```

完成判据：输出尾部 `FULL: <path>` = 成功，全文在 path，预览不够就 read/grep path；
`STALE COPY` 开头 = 抓取失败沿用旧副本，引用注明；`FETCH FAILED` = 无副本，换源或如实报告。
内容需溯源/进交付物：把 FULL 文件复制进工作区，缓存目录不保证长期存在。

## 定点提取（只要局部时）

```bash
pup 'article text{}' < f.html        # 正文文本
pup 'a[href] attr{href}' < f.html    # 所有链接
pup 'table' < f.html                 # 表格 HTML
```

已有 html 要全文：`scripts/extract.sh f.html`（perl 去 script/style + article→main→body 回退链）。
要表格/标题层级结构：`command -v pandoc && pandoc -f html -t gfm f.html`，没有则让用户装。
GBK 乱码：`iconv -f GB18030 -t UTF-8`。

## 信号（如实报告）

- 提取结果极短 + 原文件大 + 多 script → SPA 页，curl 拿不到正文，换源
- HTTP 403/404 → curl 直接报错码进 `FETCH FAILED`，反爬/源挂如实报

## 走别的通道

飞书 → lark；文献/论文 → lit-search、paper-digest；JSON API → `curl -s | jq`；本地文件 → read。
