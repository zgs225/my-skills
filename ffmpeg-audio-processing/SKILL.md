---
name: ffmpeg-audio-processing
description: Use when processing audio files with ffmpeg for metadata modification, format conversion, sample rate conversion, or loudness normalization
---

# FFmpeg Audio Processing

## Overview

Reference guide for common ffmpeg audio processing operations including metadata editing, format conversion, sample rate changes, and loudness normalization.

## Quick Reference

| Task | Key Flag | Example |
|------|----------|---------|
| Read metadata | `ffprobe -i` | `ffprobe -i file.mp3` |
| Set metadata | `-metadata` | `-metadata title="Song"` |
| Copy stream | `-c copy` | No re-encoding |
| Format conversion | `-c:a` | `-c:a aac -b:a 192k` |
| Sample rate | `-ar` | `-ar 44100` |
| Volume/norm | `-af "volume"` | `-af "volume=2.0"` |
| LUFS norm | `-af "loudnorm"` | `loudnorm=I=-14:TP=-1.0` |
| Fade in/out | `-af "afade"` | `afade=t=in:st=0:d=2` |
| Trim audio | `-af "atrim"` | `atrim=0:30,asetpts=PTS-STARTPTS` |

## Metadata Reference

### MP3 (ID3v2.3) - Recommended for Maximum Compatibility

**Important:** When tagging MP3 files, strongly recommend forcing ID3v2.3 version for maximum device and platform compatibility.

```bash
# Add -id3v2_version 3 to force ID3v2.3
ffmpeg -i input.mp3 -c copy -id3v2_version 3 \
  -metadata title="Title" \
  -metadata artist="Artist" \
  output.mp3
```

| Metadata Field | Description | Example |
|----------------|-------------|---------|
| `title` | Song title | `-metadata title="My Song"` |
| `artist` | Artist/performer | `-metadata artist="John Doe"` |
| `album` | Album name | `-metadata album="My Album"` |
| `year` | Year (4 digits) | `-metadata year="2024"` |
| `track` | Track number | `-metadata track="1"` or `"1/12"` |
| `disc` | Disc number | `-metadata disc="1"` or `"1/2"` |
| `genre` | Genre | `-metadata genre="Rock"` |
| `composer` | Composer | `-metadata composer="Beethoven"` |
| `lyricist` | Lyricist | `-metadata lyricist="Lyricist Name"` |
| `conductor` | Conductor | `-metadata conductor="Conductor Name"` |
| `album_artist` | Album artist (use Various Artists for compilations) | `-metadata album_artist="Various Artists"` |
| `grouping` | Grouping/Series | `-metadata grouping="Greatest Hits"` |
| `comment` | Comment | `-metadata comment="My comment"` |
| `isrc` | ISRC code | `-metadata isrc="USRC17607839"` |
| `copyright` | Copyright info | `-metadata copyright="© 2024 Label"` |
| `encoder` | Encoding tool | `-metadata encoder="FFmpeg"` |
| `bpm` | Beats per minute | `-metadata bpm="120"` |
| `key` | Musical key | `-metadata key="C"` or `"Dm"` |
| `mood` | Mood | `-metadata mood="Happy"` |
| `language` | Language (ISO 639-2) | `-metadata language="eng"` |

### M4A/AAC (MP4 Metadata)

| Metadata Field | Description | Example |
|----------------|-------------|---------|
| `title` | Song title | `-metadata title="My Song"` |
| `artist` | Artist | `-metadata artist="John Doe"` |
| `album` | Album name | `-metadata album="My Album"` |
| `year` | Year | `-metadata year="2024"` |
| `track` | Track number (format: track/total) | `-metadata track="1/12"` |
| `disc` | Disc number | `-metadata disc="1/2"` |
| `genre` | Genre | `-metadata genre="Rock"` |
| `composer` | Composer | `-metadata composer="Beethoven"` |
| `album_artist` | Album artist | `-metadata album_artist="Various Artists"` |
| `bpm` | BPM (integer) | `-metadata bpm="120"` |
| `gapless` | Gapless playback flag | `-metadata gapless="1"` |

### FLAC (Vorbis Comments)

| Metadata Field | Description | Example |
|----------------|-------------|---------|
| `title` | Song title | `-metadata title="My Song"` |
| `artist` | Artist | `-metadata artist="John Doe"` |
| `album` | Album name | `-metadata album="My Album"` |
| `date` | Date (YYYY-MM-DD) | `-metadata date="2024-01-01"` |
| `tracknumber` | Track number | `-metadata tracknumber="1"` |
| `discnumber` | Disc number | `-metadata discnumber="1"` |
| `genre` | Genre | `-metadata genre="Rock"` |
| `composer` | Composer | `-metadata composer="Beethoven"` |
| `lyricist` | Lyricist | `-metadata lyricist="Lyricist Name"` |
| `conductor` | Conductor | `-metadata conductor="Conductor Name"` |
| `albumartist` | Album artist | `-metadata albumartist="Various Artists"` |
| `grouping` | Grouping/Series | `-metadata grouping="Greatest Hits"` |
| `comment` | Comment | `-metadata comment="My comment"` |
| `isrc` | ISRC code | `-metadata isrc="USRC17607839"` |
| `copyright` | Copyright | `-metadata copyright="© 2024 Label"` |
| `encoder` | Encoding tool | `-metadata encoder="FFmpeg"` |
| `replaygain_track_gain` | ReplayGain track gain | `-metadata replaygain_track_gain="-2.5 dB"` |
| `replaygain_album_gain` | ReplayGain album gain | `-metadata replaygain_album_gain="-1.8 dB"` |

## Basic Operations

### Reading Metadata

**Basic info (all formats):**

```bash
# Quick overview
ffprobe -i audio.mp3

# Show format and stream info
ffprobe -i audio.mp3 -show_format -show_streams
```

**Read metadata only:**

```bash
# MP3/M4A/FLAC - show all metadata tags
ffprobe -i audio.mp3 -show_entries format_tags

# Show specific metadata fields
ffprobe -i audio.mp3 -show_entries format_tags=title,artist,album

# Output as JSON
ffprobe -i audio.mp3 -show_entries format_tags -print_format json

# Output as flat key=value
ffprobe -i audio.mp3 -show_entries format_tags -of default=noprint_wrappers=1
```

**Extract specific metadata value (for scripting):**

```bash
# Get title
ffprobe -i audio.mp3 -show_entries format_tags=title -of default=noprint_wrappers=1:nokey=1 2>/dev/null

# Get artist
ffprobe -i audio.mp3 -show_entries format_tags=artist -of default=noprint_wrappers=1:nokey=1 2>/dev/null

# Get BPM (works if present)
ffprobe -i audio.mp3 -show_entries format_tags=bpm -of default=noprint_wrappers=1:nokey=1 2>/dev/null
```

**Show audio properties:**

```bash
# Codec, sample rate, bitrate
ffprobe -i audio.mp3 -show_entries stream=codec_name,sample_rate,channels,bit_rate -of default=noprint_wrappers=1

# Duration and file size
ffprobe -i audio.mp3 -show_entries format=duration,size -of default=noprint_wrappers=1
```

### Metadata Modification

**MP3 (force ID3v2.3 for maximum compatibility):**

```bash
# Modify MP3 metadata - force ID3v2.3
ffmpeg -i input.mp3 -c copy -id3v2_version 3 \
  -metadata title="My Song" \
  -metadata artist="John Doe" \
  -metadata album="My Album" \
  -metadata year="2024" \
  -metadata genre="Rock" \
  -metadata track="1/12" \
  output.mp3
```

**M4A/AAC:**

```bash
# Modify M4A metadata
ffmpeg -i input.m4a -c copy \
  -metadata title="My Song" \
  -metadata artist="John Doe" \
  -metadata album="My Album" \
  -metadata track="1/12" \
  output.m4a
```

**FLAC:**

```bash
# Modify FLAC metadata
ffmpeg -i input.flac -c copy \
  -metadata title="My Song" \
  -metadata artist="John Doe" \
  -metadata album="My Album" \
  -metadata date="2024-01-01" \
  -metadata tracknumber="1" \
  output.flac
```

### Add Album Art

**MP3 with album art (force ID3v2.3):**

```bash
ffmpeg -i audio.mp3 -i cover.jpg -map 0:a -map 1:v \
  -c:a copy -c:v mjpeg -id3v2_version 3 \
  -metadata title="Song Title" \
  -metadata artist="Artist Name" \
  output.mp3
```

**M4A with album art:**

```bash
ffmpeg -i audio.m4a -i cover.jpg -map 0:a -map 1:v \
  -c:a copy -c:v png \
  output.m4a
```

**FLAC with album art:**

```bash
ffmpeg -i audio.flac -i cover.jpg -map 0:a -map 1:v \
  -c:a copy -c:v png \
  output.flac
```

### Remove All Metadata

```bash
# MP3 - remove all metadata
ffmpeg -i input.mp3 -c copy -map_metadata -1 output.mp3

# Or remove specific fields only
ffmpeg -i input.mp3 -c copy \
  -metadata title="" \
  -metadata artist="" \
  output.mp3
```

### Format Conversion

```bash
# WAV to AAC (192kbps)
ffmpeg -i audio.wav -c:a aac -b:a 192k output.aac

# WAV to MP3 (320kbps)
ffmpeg -i audio.wav -c:a libmp3lame -b:a 320k output.mp3

# FLAC to MP3
ffmpeg -i audio.flac -c:a libmp3lame -q:a 2 output.mp3
```

### Sample Rate Conversion

```bash
# 48kHz to 44.1kHz (CD format)
ffmpeg -i input.wav -ar 44100 output.wav

# With high-quality resampling
ffmpeg -i input.wav -af "aresample=resampler=soxr_vhq" -ar 44100 output.wav
```

## Advanced Operations

### LUFS Normalization (Streaming Standard)

```bash
# Single pass (good for most cases)
ffmpeg -i input.wav -af "loudnorm=I=-14:TP=-1.0:LRA=11" \
  -ar 44100 output.wav
```

**Parameters:**
- `I=-14` — Target integrated loudness (-14 LUFS for Spotify, Apple Music, YouTube)
- `TP=-1.0` — True peak ceiling (-1 dBTP)
- `LRA=11` — Loudness range target

### Bit Depth Conversion with Dithering

```bash
# 24-bit to 16-bit (dither filter requires ffmpeg with libsoxr)
ffmpeg -i 24bit.wav \
  -af "aformat=sample_fmts=s16,dither=scale=16:noise_shape=triangular_hp" \
  -acodec pcm_s16le 16bit.wav
```

**Without dither filter (alternative):**
```bash
ffmpeg -i 24bit.wav -af "aformat=sample_fmts=s16" -acodec pcm_s16le 16bit.wav
```

**Dither types:** `shibata` (best for music), `triangular_hp` (standard), `rectangular` (basic)

**Note:** The `dither` filter requires ffmpeg compiled with libsoxr. If you get "Filter not found" error, use the alternative command above.

### Trim and Fade

```bash
# First 30 seconds with fade in/out
ffmpeg -i input.wav \
  -af "atrim=0:30,asetpts=PTS-STARTPTS,afade=t=in:st=0:d=2,afade=t=out:st=27:d=3" \
  output.wav
```

### Multi-Output from Single Source

```bash
ffmpeg -i master.wav \
  -filter_complex "[0:a]loudnorm=I=-14[norm];[0:a]atrim=0:30,asetpts=PTS-STARTPTS[preview]" \
  -map "[norm]" -c:a:0 pcm_s16le spotify-master.wav \
  -map "[preview]" -c:a:1 libmp3lame -b:a 192k preview.mp3
```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Forgetting `-c copy` when only editing metadata | Causes unnecessary re-encoding |
| Using `-ar` without considering bit depth | Use `aformat` filter for bit depth changes |
| Single-pass loudnorm for batch processing | Use two-pass for consistent loudness across tracks |
| Missing `asetpts=PTS-STARTPTS` after `atrim` | Causes timestamp issues |
| Not forcing ID3v2.3 for MP3 | Some devices don't support ID3v2.4 |

## Related Tools

- **ffprobe** — Inspect audio file properties and metadata
  ```bash
  # Full info dump
  ffprobe -i file.mp3

  # Metadata only (JSON)
  ffprobe -i file.mp3 -show_entries format_tags -print_format json

  # Audio properties
  ffprobe -i file.mp3 -show_entries stream=codec_name,sample_rate,channels,bit_rate
  ```
- **MusicBrainz Picard** — Automatic metadata tagging
- **ReplayGain** — Alternative loudness standard
