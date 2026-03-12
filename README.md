# My Skills

A collection of custom skills for AI coding assistants. Skills are reference guides that extend AI capabilities with proven techniques, patterns, and tools.

Compatible with: **Claude Code**, **Cursor**, **OpenCode**, and other AI assistants that support skill-based workflows.

## Skills

### ffmpeg-audio-processing

Reference guide for processing audio files with ffmpeg.

**Features:**
- Read/write metadata for MP3, M4A, FLAC
- Format conversion (WAV, MP3, AAC, FLAC)
- Sample rate and bit depth conversion
- LUFS normalization for streaming platforms
- Album art embedding
- Audio trimming and fade effects

**Location:** `ffmpeg-audio-processing/`

## Usage

### Claude Code

```bash
# Copy skill to Claude Code skills directory
cp -r ffmpeg-audio-processing ~/.claude/skills/
```

### Cursor

1. Open Cursor Settings
2. Navigate to Features → Custom Instructions
3. Add the skill content to your custom instructions, or
4. Reference the skill file: `@ffmpeg-audio-processing/SKILL.md`

### OpenCode

```bash
# Copy skill to OpenCode skills directory
cp -r ffmpeg-audio-processing ~/.opencode/skills/
```

### General Usage

Skills are discovered automatically by AI assistants when relevant tasks are encountered. Simply mention the skill name or describe the task, and the AI will reference the appropriate skill.

## Creating New Skills

Skills follow a Test-Driven Development approach:

1. **RED** - Write failing test scenarios (baseline behavior)
2. **GREEN** - Write minimal skill documentation
3. **REFACTOR** - Close loopholes, add edge cases

### Skill Structure

```
skill-name/
├── SKILL.md          # Main reference document (required)
├── README.md         # Optional: Additional documentation
└── test-files/       # Optional: Test fixtures
```

### SKILL.md Format

```markdown
---
name: skill-name
description: Use when [specific triggering conditions and symptoms]
---

# Skill Name

## Overview
Core principle in 1-2 sentences.

## Quick Reference
| Task | Key Flag | Example |
|------|----------|---------|
| ...  | ...      | ...     |

## When to Use
- Symptom 1
- Symptom 2

## Core Pattern
Code examples and patterns.

## Common Mistakes
| Mistake | Fix |
|---------|-----|
| ...     | ... |
```

### Guidelines

- **Name**: Use letters, numbers, and hyphens only
- **Description**: Start with "Use when...", describe triggering conditions only
- **Content**: One excellent example beats many mediocre ones
- **Language**: English only

## Resources

- [Superpowers Skills Documentation](https://github.com/superpowers/skills)
- [FFmpeg Documentation](https://ffmpeg.org/documentation.html)
- [Cursor Custom Instructions](https://cursor.sh/docs/custom-instructions)
- [OpenCode Documentation](https://opencode.ai/docs)

## License

MIT
