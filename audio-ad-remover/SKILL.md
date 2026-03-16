---
name: audio-ad-remover
version: 0.2.0
description: 识别并移除音频文件片头广告的技能。当用户需要处理播客、有声书等音频文件的片头广告时使用此技能。工作流程分三步：1) 运行 extract_transcript.sh 提取前 N 秒音频的带时间戳文本；2) LLM 分析文本内容判断广告结束位置；3) 调用 trim_audio_ad.sh 备份并裁剪音频。
---

# Audio Ad Remover

## 概述

本技能用于自动识别并移除音频文件（如播客、访谈等）的片头广告部分。

**工作流程（三步）：**

1. **提取语音识别数据** - 运行 `scripts/extract_transcript.sh` 截取音频前 N 秒，使用 whisper.cpp 进行语音识别，输出带时间戳的结构化 JSON 数据
2. **LLM 判断广告边界** - 分析 JSON 中的文本内容，基于语义理解判断广告结束的时间点
3. **执行裁剪** - 调用 `scripts/trim_audio_ad.sh` 备份原文件并从广告结束点裁剪音频

## 触发条件

当用户需要处理音频文件的片头广告时，应使用此技能。典型场景包括：
- 用户提到"移除片头广告"、"剪掉开头广告"、"清理音频开头"
- 用户有播客、访谈录音等需要清理片头赞助广告
- 用户提到 whisper.cpp 或 ffmpeg 处理音频广告

## 配置参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `--duration` | 60 | 分析的广告时长上限（秒） |
| `--model` | base | whisper 模型路径（或设置 `WHISPER_MODEL` 环境变量） |
| `--language` | zh | 音频语言 (zh/en/ja 等) |
| `--keep-backup` | true | 是否保留备份文件 |

## 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `WHISPER_CLI` | whisper-cli | whisper.cpp 可执行文件路径 |
| `WHISPER_MODEL` | ggml-base.bin | whisper 模型文件路径 |

## 广告关键词检测

LLM 在判断广告边界时应关注以下内容：

**中文关键词：**
- 微信、公众号、赞助、广告、课程、添加、收听、关注、付费、众筹

**英文关键词：**
- sponsor, ad, advertisement, commercial, premium course, subscribe

**广告特征：**
- 片头出现推广性质的内容
- 引导用户添加联系方式或关注公众号
- 宣传付费课程或会员服务

## 使用方法

### Step 1: 提取语音识别数据

```bash
# 设置环境变量（可选）
export WHISPER_CLI="/path/to/whisper-cli"
export WHISPER_MODEL="/path/to/ggml-base.bin"

# 基本用法
./scripts/extract_transcript.sh <audio_file.m4a> --language zh --duration 60

# 使用不同模型
./scripts/extract_transcript.sh <audio_file.m4a> --model /path/to/ggml-small.bin
```

### Step 2: LLM 分析并确定广告结束时间

LLM 收到 JSON 输出后，应：
1. 阅读所有文本片段
2. 识别包含广告内容的片段
3. 确定广告结束的时间点（秒）
4. 输出裁剪指令

### Step 3: 执行裁剪

```bash
# LLM 调用裁剪脚本
./scripts/trim_audio_ad.sh <audio_file.m4a> <ad_end_time> --keep-backup true
```

## 支持的文件格式

- MP3 (.mp3)
- M4A/AAC (.m4a)
- WAV (.wav)
- FLAC (.flac)

## 注意事项

1. **备份文件**：`scripts/trim_audio_ad.sh` 会自动创建备份文件（.backup.时间戳），确认处理无误后可手动删除
2. **广告时长**：如果广告超过默认 60 秒，可在 step 1 使用 `--duration` 增加分析时长
3. **语言设置**：指定正确的语言可提高识别准确率
4. **裁剪精度**：使用 `-c copy` 在关键帧处裁剪，可能有±0.5 秒误差

## scripts/

### scripts/extract_transcript.sh

输入：音频文件路径
输出：JSON 格式的结构化数据

```json
{
  "audio_file": "podcast.m4a",
  "analysis_duration": 60,
  "segments": [
    {"start": 0.00, "end": 4.32, "text": "想收听更多精品付费课程 添加微信"},
    {"start": 4.32, "end": 10.28, "text": "XXX 添加微信公众号 XXX"},
    {"start": 10.28, "end": 15.00, "text": "正式开始今天的节目内容"}
  ]
}
```

### scripts/trim_audio_ad.sh

输入：音频文件路径 + 广告结束时间（秒）
输出：裁剪后的音频文件（覆盖原文件），备份文件保留

## LLM 判断广告边界的指导原则

1. **寻找第一个非广告片段**：广告通常是连续的几个片段，当出现与节目正片相关的内容时，广告结束
2. **关注转折词**："好，我们开始"、"今天我们来聊"等通常标志着广告结束
3. **忽略片头自我介绍**：有些播客的片头介绍不算广告，需根据用户意图判断
4. **多个广告关键词连续出现**：如果多个片段都包含广告关键词，取最后一个广告片段的结束时间

## 版本记录

- **v0.2.0** (2026-03-16)：架构重构为三步骤流程（脚本提取 → LLM 分析 → 脚本裁剪），支持环境变量配置路径
- **v0.1.0** (2026-03-13)：初始版本，基础广告检测和移除功能
