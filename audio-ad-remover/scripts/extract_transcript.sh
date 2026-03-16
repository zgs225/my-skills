#!/bin/bash
# extract_transcript.sh - 提取音频前 N 秒的语音识别文本和时间戳
# 输出：JSON 格式的带时间戳的文本片段，供 LLM 分析广告边界

set -e

# 工具路径：支持环境变量覆盖，默认使用常见路径
WHISPER_CLI="${WHISPER_CLI:-whisper-cli}"
WHISPER_MODEL="${WHISPER_MODEL:-ggml-base.bin}"

# 默认参数
ANALYSIS_DURATION=60
LANGUAGE="zh"
OUTPUT_FORMAT="json"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --duration)
            ANALYSIS_DURATION="$2"
            shift 2
            ;;
        --model)
            WHISPER_MODEL="$2"
            shift 2
            ;;
        --language)
            LANGUAGE="$2"
            shift 2
            ;;
        --output-format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: extract_transcript.sh <audio_file> [options]"
            echo "Options:"
            echo "  --duration N       Analyze first N seconds (default: 60)"
            echo "  --model PATH       Whisper model path (or set WHISPER_MODEL env)"
            echo "  --language CODE    Audio language (default: zh)"
            echo "  --output-format    json|csv (default: json)"
            echo ""
            echo "Environment Variables:"
            echo "  WHISPER_CLI        Path to whisper-cli (default: whisper-cli)"
            echo "  WHISPER_MODEL      Path to model file (default: ggml-base.bin)"
            exit 0
            ;;
        *)
            INPUT_FILE="$1"
            shift
            ;;
    esac
done

if [ -z "$INPUT_FILE" ]; then
    echo "Error: No input file specified"
    exit 1
fi

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File not found: $INPUT_FILE"
    exit 1
fi

# 获取文件时长
duration=$(ffprobe -i "$INPUT_FILE" -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 2>/dev/null)
echo "# Audio duration: $duration seconds"
echo "# Analyzing first $ANALYSIS_DURATION seconds"

# Step 1: 截取分析片段 (重采样到 16kHz mono)
analysis_segment="/tmp/ad_analysis_$$.wav"
ffmpeg -i "$INPUT_FILE" -t "$ANALYSIS_DURATION" -ar 16000 -ac 1 -y "$analysis_segment" 2>/dev/null

# Step 2: 运行 whisper.cpp
whisper_output="/tmp/whisper_output_$$"
"$WHISPER_CLI" \
    -m "$WHISPER_MODEL" \
    -f "$analysis_segment" \
    --output-csv \
    --language "$LANGUAGE" \
    --output-file "$whisper_output" 2>/dev/null

# Step 3: 输出结果
if [ "$OUTPUT_FORMAT" = "json" ]; then
    # 转换为 JSON 格式
    echo "{"
    echo "  \"audio_file\": \"$INPUT_FILE\","
    echo "  \"analysis_duration\": $ANALYSIS_DURATION,"
    echo "  \"segments\": ["

    first=true
    while IFS=',' read -r start end text; do
        # 跳过标题行
        if [ "$start" = "start" ]; then
            continue
        fi

        # 去掉文本中的引号并转义 JSON 特殊字符
        text=$(echo "$text" | tr -d '"' | sed 's/\\/\\\\/g')

        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi

        # 将毫秒转换为秒
        start_sec=$(awk "BEGIN {printf \"%.2f\", $start / 1000}")
        end_sec=$(awk "BEGIN {printf \"%.2f\", $end / 1000}")

        printf '    {"start": %s, "end": %s, "text": "%s"}' "$start_sec" "$end_sec" "$text"
    done < "${whisper_output}.csv"

    echo ""
    echo "  ]"
    echo "}"
else
    # CSV 格式直接输出
    cat "${whisper_output}.csv"
fi

# 清理临时文件
rm -f "$analysis_segment"
rm -f "$whisper_output" "${whisper_output}.csv" "${whisper_output}.txt"
