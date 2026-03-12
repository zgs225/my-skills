# My Skills

A collection of custom skills for AI coding assistants. Skills are reference guides that extend AI capabilities with proven techniques, patterns, and tools.

Compatible with: **Claude Code**, **Cursor**, **OpenCode**, and other AI assistants that support skill-based workflows.

## Skills

### audiobookshelf-metadata-sync

Sync audiobookshelf server metadata to local audio files.

- API authentication and batch sync
- Metadata mapping (MP3, M4A, FLAC)
- Path prefix translation for Docker/NAS

### ffmpeg-audio-processing

Process audio files with ffmpeg.

- Metadata read/write for MP3, M4A, FLAC
- Format conversion and normalization
- Album art embedding, trimming, fade effects

## Usage

### Claude Code

```bash
cp -r <skill-name> ~/.claude/skills/
```

### Cursor

Settings → Features → Custom Instructions, then reference: `@<skill-name>/SKILL.md`

### OpenCode

```bash
cp -r <skill-name> ~/.opencode/skills/
```

Skills are auto-discovered when relevant tasks are encountered.

## License

MIT
