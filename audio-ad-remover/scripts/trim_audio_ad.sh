#!/bin/bash
# trim_audio_ad.sh - 备份原文件并从指定位置裁剪掉广告片段
# 输入：原文件路径，广告结束时间（秒）
# 输出：裁剪后的文件覆盖原文件，备份文件保留

set -e

# 默认参数
KEEP_BACKUP=true

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --keep-backup)
            KEEP_BACKUP="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: trim_audio_ad.sh <audio_file> <ad_end_time> [options]"
            echo "Arguments:"
            echo "  audio_file       Path to the audio file to trim"
            echo "  ad_end_time      Ad end time in seconds (裁剪起始点)"
            echo "Options:"
            echo "  --keep-backup BOOL  Keep backup file (default: true)"
            exit 0
            ;;
        *)
            if [ -z "$INPUT_FILE" ]; then
                INPUT_FILE="$1"
            elif [ -z "$AD_END_TIME" ]; then
                AD_END_TIME="$1"
            fi
            shift
            ;;
    esac
done

if [ -z "$INPUT_FILE" ] || [ -z "$AD_END_TIME" ]; then
    echo "Error: Missing arguments. Usage: trim_audio_ad.sh <audio_file> <ad_end_time>"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File not found: $INPUT_FILE"
    exit 1
fi

# 验证裁剪时间
if ! [[ "$AD_END_TIME" =~ ^[0-9]+\.?[0-9]*$ ]]; then
    echo "Error: Invalid ad_end_time: $AD_END_TIME (must be a positive number)"
    exit 1
fi

# 获取原文件时长
duration=$(ffprobe -i "$INPUT_FILE" -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 2>/dev/null)

# 如果裁剪时间为 0，跳过裁剪
if [ "$AD_END_TIME" = "0" ] || [ "$AD_END_TIME" = "0.0" ]; then
    echo "Ad end time is 0, skipping trim."
    exit 0
fi

# 检查裁剪时间是否合理
if (( $(echo "$AD_END_TIME >= $duration" | bc -l) )); then
    echo "Error: Ad end time ($AD_END_TIME) is greater than or equal to audio duration ($duration)"
    exit 1
fi

echo "=== Trimming Audio Ad ==="
echo "Input file: $INPUT_FILE"
echo "Original duration: $duration seconds"
echo "Ad end time: $AD_END_TIME seconds"
echo "New duration will be: $(echo "$duration - $AD_END_TIME" | bc) seconds"

# Step 1: 备份原文件
backup_file="${INPUT_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
cp "$INPUT_FILE" "$backup_file"
echo "Backup created: $backup_file"

# Step 2: 裁剪音频
# -ss 放在 -i 之前进行快速 seek
# -c copy 避免重新编码，但只能在关键帧处裁剪，可能有±0.5 秒误差
# 临时文件使用与原文件相同的扩展名，以便 ffmpeg 识别格式
extension="${INPUT_FILE##*.}"
temp_file="${INPUT_FILE}.trimmed.${extension}"
ffmpeg -ss "$AD_END_TIME" -i "$INPUT_FILE" -c copy -y "$temp_file" 2>/dev/null

if [ -f "$temp_file" ] && [ -s "$temp_file" ]; then
    # 验证裁剪后的文件
    new_duration=$(ffprobe -i "$temp_file" -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 2>/dev/null)
    echo "Trimmed duration: $new_duration seconds"

    # 移动裁剪后的文件覆盖原文件
    mv "$temp_file" "$INPUT_FILE"
    echo "Success! Removed $AD_END_TIME seconds of ad content."
else
    echo "Error: Failed to trim audio. Restoring backup..."
    cp "$backup_file" "$INPUT_FILE"
    rm -f "$temp_file"
    exit 1
fi

# Step 3: 清理备份（如果不需要保留）
if [ "$KEEP_BACKUP" = "false" ]; then
    rm -f "$backup_file"
    echo "Backup removed."
else
    echo "Backup file: $backup_file"
fi

echo ""
echo "=== Done ==="
