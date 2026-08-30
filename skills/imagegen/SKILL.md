---
name: imagegen
description: 本地 AI 生图（ComfyUI + SD1.5 + 像素风 LoRA，RTX 2070）。生成游戏 sprite/图标/背景时使用；需要提示词工程 + 后处理（裁剪/缩放/去底）。
---

# 本地图像生成

## 组件
- ComfyUI 服务：`~/tools/ComfyUI/run.sh`（后台启动，监听 127.0.0.1:8188，含 NixOS 库路径修复）
- 生成脚本：`~/tools/ComfyUI/gen.py`
- 模型：SD1.5 fp16（checkpoints/）+ PixelArtRedmond LoRA（loras/，默认自动加载）

## 用法

```bash
# 启动服务（先检查是否已在跑：curl -s 127.0.0.1:8188/system_stats）
~/tools/ComfyUI/run.sh &

# 出图
cd ~/tools/ComfyUI && ./venv/bin/python gen.py "pixel art game sprite, <主体>, single object, centered, solid black background" /path/out.png --seed 42
```

参数：`--neg`（负面词）、`--seed`（-1 随机，复现风格时固定）、`--size 512x512`、`--steps 25`、`--no-lora`（非像素风时）。

## 经验（prompt 调优中）
- **单资产 sprite** 必须写 `single character/object, centered, solid black background`，否则出场景图
- 地府调色板关键词：`dark underworld, vermillion red, ghostly green, gold accents, moody`——不写会跑偏成明亮配色
- 批量生产同一资产家族：固定 seed 前缀 + 同一组风格关键词
- 512x512 出图后用最近邻缩放到目标尺寸（保持像素感），透明底需后处理（rembg 或脚本去纯色底）

## 注意
- 显存 8GB：只跑 SD1.5，别加载 SDXL/FLUX
- 服务常驻占 ~2GB 显存；不用时可杀掉
