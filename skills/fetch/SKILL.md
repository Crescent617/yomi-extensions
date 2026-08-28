---
name: fetch
description: 抓取 URL 全文落盘并提取正文，带 1 小时本地缓存。Use when 读网页/链接正文、下载页面/PDF/图片、或用户发来链接要看内容。
metadata: { "requires": { "bins": ["pandoc"] } }
---

# fetch

低自由，照抄命令（`scripts/` 在本 skill 目录下）：

```bash
<baseDir>/scripts/fetch.sh "<url>"              # 1h 内命中缓存直接用
<baseDir>/scripts/fetch.sh "<url>" --refresh    # 强制重抓（新闻/监控类）
```

完成判据：输出尾部 `FULL: <path>` = 成功，全文在 path，预览不够就 read/grep path；
`STALE COPY` 开头 = 抓取失败沿用旧副本，引用注明；`FETCH FAILED` = 无副本，换源或如实报告；
报缺 pandoc / `EXTRACT FAILED` = 提取失败，按提示装 pandoc 或换源。
内容需溯源/进交付物：把 FULL 文件复制进工作区——缓存 7 天自动清理。

已有 html 要转全文：管线照抄 `scripts/fetch.sh` 的 text/html 分支。
GBK 乱码：`iconv -f GB18030 -t UTF-8 f.html > f.u8.html`。
