---
name: audiobookshelf-metadata-sync
version: 1.0.0
description: Use when synchronizing audiobookshelf server metadata to local audio files, or when library item metadata and embedded file metadata are inconsistent
---

# Audiobookshelf Metadata Sync

## Overview

Reference guide for synchronizing metadata between audiobookshelf server and local audio files. When audiobookshelf server metadata (manually verified as correct) differs from embedded audio file metadata, use this skill to update files to match the server.

**Core principle:** audiobookshelf server metadata is the source of truth. Update local files to match, avoiding duplicate modifications unless explicitly required.

## Quick Reference

| Task | API Endpoint / Command | Notes |
|------|------------------------|-------|
| Login | `POST /api/login` | Get API token |
| Get all libraries | `GET /api/libraries` | List libraries |
| Get library items | `GET /api/libraries/{id}/items` | List all items in library |
| Get item details | `GET /api/items/{itemId}` | Full item with media metadata |
| Update item media | `PATCH /api/items/{itemId}/media` | Update server metadata |
| Embed metadata | `ffmpeg -i in.m4a -c copy -metadata key="value" out.m4a` | Write to file |
| Batch update | `POST /api/items/batch-update` | Update multiple items |

## When to Use

- audiobookshelf server metadata and local file metadata are inconsistent
- Need to sync server metadata to local audio files
- Files were imported/matched but embedded metadata wasn't updated
- Preparing files for backup or export with correct metadata
- Need to verify metadata consistency across library

## When NOT to Use

- When you want to use local file metadata as source of truth
- When only server-side changes are needed (no file modification)
- When working with podcasts that should preserve original episode metadata

## Authentication

### Get API Token

**Option 1: Login endpoint**
```bash
curl -X POST "http://your-audiobookshelf-server/api/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"your-username","password":"your-password"}'
```

Response:
```json
{
  "user": {
    "token": "eyJhbGciOiJIiJ9.eyJ1c2VyIjoiNDEyODc4fQ.ZraBFohS4Tg39NszY...",
    "id": "user-id"
  },
  "serverSettings": {...}
}
```

**Option 2: From web UI**
1. Open browser developer tools
2. Go to audiobookshelf web UI
3. Find any API request in Network tab
4. Copy `Authorization: Bearer <token>` header

### Use API Token

```bash
# In header (recommended)
curl -X GET "http://your-audiobookshelf-server/api/libraries" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Or as query parameter for GET requests
curl -X GET "http://your-audiobookshelf-server/api/libraries?token=YOUR_TOKEN"
```

## API Workflow

### Step 1: Get All Libraries

```bash
curl -X GET "http://your-audiobookshelf-server/api/libraries" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Response:
```json
{
  "libraries": [
    {
      "id": "lib-id-1",
      "name": "Audiobooks",
      "mediaType": "book",
      "folders": [{"id": "folder-id", "fullPath": "/path/to/audiobooks"}]
    }
  ]
}
```

### Step 2: Get Library Items

```bash
curl -X GET "http://your-audiobookshelf-server/api/libraries/lib-id-1/items" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

Response:
```json
{
  "results": [
    {
      "id": "item-id-1",
      "libraryId": "lib-id-1",
      "path": "/path/to/audiobooks/Book Title",
      "mediaType": "book",
      "media": {
        "metadata": {
          "title": "Book Title",
          "authorName": "Author Name",
          "seriesName": "Series Name",
          "publishedYear": "2024",
          "genres": ["Fiction", "Adventure"],
          "asin": "B00XXX",
          "isbn": "978-xxx"
        },
        "audioFiles": [
          {
            "index": 0,
            "ino": "file-ino",
            "metadata": {
              "filename": "chapter01.m4a",
              "path": "/path/to/audiobooks/Book Title/chapter01.m4a"
            },
            "duration": 1234.56,
            "bitRate": 128000,
            "format": "mp4",
            "metaTags": {
              "title": "Chapter 1",
              "artist": "Author Name"
            }
          }
        ]
      }
    }
  ]
}
```

### Step 3: Get Specific Item Details

```bash
curl -X GET "http://your-audiobookshelf-server/api/items/item-id-1" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Step 4: Extract Metadata for File Sync

Key metadata fields to sync to audio files:

**Book/Podcast Metadata:**
- `title` — Book or podcast title
- `authorName` — Author or podcast author
- `narratorName` — Narrator (for audiobooks)
- `seriesName` — Series name
- `seriesSequence` — Series sequence number
- `genres` — Genres/categories
- `publishedYear` — Publication year
- `publisher` — Publisher name
- `description` — Book/podcast description
- `isbn` / `asin` — Identifiers
- `language` — Language code
- `explicit` — Explicit content flag

**Audio File Metadata (embedded tags):**
- `title` — Chapter/episode title
- `artist` — Usually author/narrator
- `album` — Book/podcast title
- `albumArtist` — Author (useful for compilations)
- `genre` — Genre
- `year` — Publication year
- `track` — Track number (e.g., "1/12")
- `disc` — Disc number (for multi-part)
- `comment` — Description or notes
- `cover` — Embedded album art

## Sync Process

### Single File Sync with ffmpeg

```bash
# Read current metadata
ffprobe -i "chapter01.m4a" -show_entries format_tags -of default=noprint_wrappers=1

# Update file metadata (replace values from audiobookshelf)
ffmpeg -i "chapter01.m4a" -c copy \
  -metadata title="Chapter 1" \
  -metadata artist="Author Name" \
  -metadata album="Book Title" \
  -metadata album_artist="Author Name" \
  -metadata genre="Fiction" \
  -metadata year="2024" \
  -metadata track="1/12" \
  -metadata comment="Description here" \
  "chapter01_synced.m4a"

# Replace original (after verification)
mv "chapter01_synced.m4a" "chapter01.m4a"
```

### Batch Sync Script Pattern

```bash
#!/bin/bash
# Sync metadata from audiobookshelf to local files

SERVER="http://your-audiobookshelf-server"
TOKEN="your-api-token"
LIBRARY_ID="lib-id"

# Get all items
items=$(curl -s "$SERVER/api/libraries/$LIBRARY_ID/items" \
  -H "Authorization: Bearer $TOKEN")

# Process each item
echo "$items" | jq -c '.results[]' | while read -r item; do
  item_id=$(echo "$item" | jq -r '.id')

  # Get full item details
  full_item=$(curl -s "$SERVER/api/items/$item_id" \
    -H "Authorization: Bearer $TOKEN")

  # Extract metadata
  title=$(echo "$full_item" | jq -r '.media.metadata.title')
  author=$(echo "$full_item" | jq -r '.media.metadata.authorName')
  genre=$(echo "$full_item" | jq -r '.media.metadata.genres[0] // ""')
  year=$(echo "$full_item" | jq -r '.media.metadata.publishedYear')

  # Process each audio file
  echo "$full_item" | jq -c '.media.audioFiles[]' | while read -r audio_file; do
    file_path=$(echo "$audio_file" | jq -r '.metadata.path')
    file_duration=$(echo "$audio_file" | jq -r '.duration')

    if [ -f "$file_path" ]; then
      echo "Processing: $file_path"
      # ffmpeg command to update metadata
      # ...
    fi
  done
done
```

## Metadata Field Mapping

| audiobookshelf field | ID3v2 (MP3) | MP4 (M4A) | Vorbis (FLAC) |
|---------------------|-------------|-----------|---------------|
| `metadata.title` | `title` | `title` | `title` |
| `metadata.authorName` | `artist` / `albumartist` | `artist` / `albumartist` | `artist` / `albumartist` |
| `metadata.seriesName` | `grouping` | `series` | `series` |
| `metadata.genres` | `genre` | `genre` | `genre` |
| `metadata.publishedYear` | `year` | `year` | `date` |
| `metadata.description` | `comment` | `description` | `comment` |
| `metadata.isbn` | `isbn` | `isbn` | `isbn` |
| `metadata.language` | `language` | `language` | `language` |

## Path Prefix Mapping

**Important:** API paths may differ from local filesystem paths due to Docker volumes, NAS mounts, or different system configurations.

### Common Scenarios

| Scenario | API Path | Local Path |
|----------|----------|------------|
| Docker container | `/books/...` | `/mnt/nas/audiobooks/...` |
| NAS mount | `/audiobooks/...` | `/Volumes/NAS/Media/Books/...` |
| WSL2 | `/mnt/media/books/...` | `D:\Media\Books\...` |
| Different OS | `/data/audiobooks/...` | `/Volumes/Drive/audiobooks/...` |

### Configuration

Define path prefix mappings at the start of your sync script:

```bash
#!/bin/bash

# Path prefix mapping: API path -> Local path
# Add mappings for each library/folder
declare -A PATH_MAPPINGS=(
  ["/books"]="/mnt/nas/audiobooks"
  ["/audiobooks"]="/Volumes/NAS/Media/Books"
  ["/data/media"]="/media"
)
```

### Path Translation Function

```bash
# Translate API path to local path
translate_path() {
  local api_path="$1"
  local local_path=""

  for api_prefix in "${!PATH_MAPPINGS[@]}"; do
    if [[ "$api_path" == "$api_prefix"* ]]; then
      local_prefix="${PATH_MAPPINGS[$api_prefix]}"
      local_path="${api_path/$api_prefix/$local_prefix}"
      echo "$local_path"
      return 0
    fi
  done

  # No mapping found, return original
  echo "$api_path"
  return 1
}

# Usage example:
api_path="/books/Book Title/chapter01.m4a"
local_path=$(translate_path "$api_path")
# Result: /mnt/nas/audiobooks/Book Title/chapter01.m4a
```

### Verify Path Translation

```bash
# Test path translation before processing
verify_paths() {
  echo "Testing path mappings..."
  for api_prefix in "${!PATH_MAPPINGS[@]}"; do
    local_prefix="${PATH_MAPPINGS[$api_prefix]}"
    if [ -d "$local_prefix" ]; then
      echo "OK: $api_prefix -> $local_prefix"
    else
      echo "WARNING: Local path not found: $local_prefix"
    fi
  done
}
```

### Updated Batch Sync with Path Translation

```bash
#!/bin/bash

SERVER="http://your-audiobookshelf-server"
TOKEN="your-api-token"
LIBRARY_ID="lib-id"

# Path mappings
declare -A PATH_MAPPINGS=(
  ["/books"]="/mnt/nas/audiobooks"
)

translate_path() {
  local api_path="$1"
  for api_prefix in "${!PATH_MAPPINGS[@]}"; do
    if [[ "$api_path" == "$api_prefix"* ]]; then
      echo "${api_path/$api_prefix/${PATH_MAPPINGS[$api_prefix]}}"
      return 0
    fi
  done
  echo "$api_path"
  return 1
}

# Get all items
items=$(curl -s "$SERVER/api/libraries/$LIBRARY_ID/items" \
  -H "Authorization: Bearer $TOKEN")

echo "$items" | jq -c '.results[]' | while read -r item; do
  item_id=$(echo "$item" | jq -r '.id')
  full_item=$(curl -s "$SERVER/api/items/$item_id" \
    -H "Authorization: Bearer $TOKEN")

  # Extract metadata
  title=$(echo "$full_item" | jq -r '.media.metadata.title')
  author=$(echo "$full_item" | jq -r '.media.metadata.authorName')

  # Process each audio file
  echo "$full_item" | jq -c '.media.audioFiles[]' | while read -r audio_file; do
    # Get API path
    api_path=$(echo "$audio_file" | jq -r '.metadata.path')

    # Translate to local path
    local_path=$(translate_path "$api_path")

    if [ -f "$local_path" ]; then
      echo "Processing: $title"
      echo "  API path: $api_path"
      echo "  Local path: $local_path"

      # Update metadata with ffmpeg
      ffmpeg -i "$local_path" -c copy \
        -metadata title="$title" \
        -metadata artist="$author" \
        -y "$local_path.tmp" && mv "$local_path.tmp" "$local_path"
    else
      echo "WARNING: File not found at translated path: $local_path"
      echo "  Original API path: $api_path"
    fi
  done
done
```

## File-Level Deduplication

To avoid duplicate modifications:

1. **Track processed files:**
   ```bash
   # Use a marker file or extended attributes
   xattr -w user.audiobookshelf.synced "true" file.m4a

   # Check before processing
   xattr -l file.m4a | grep -q "user.audiobookshelf.synced"
   ```

2. **Compare metadata before writing:**
   ```bash
   # Get current title
   current_title=$(ffprobe -i file.m4a -show_entries format_tags=title \
     -of default=noprint_wrappers=1:nokey=1 2>/dev/null)

   # Only update if different
   if [ "$current_title" != "$target_title" ]; then
     # Update metadata
   fi
   ```

3. **Use checksums:**
   ```bash
   # Store hash after sync
   md5sum file.m4a >> .audiobookshelf-sync-cache

   # Skip if file unchanged
   ```

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Forgetting `-c copy` | Causes unnecessary re-encoding, quality loss |
| Not backing up before batch sync | Always backup or create temp files first |
| Using wrong metadata field names | MP4 uses `album_artist`, FLAC uses `albumartist` |
| Not forcing ID3v2.3 for MP3 | Add `-id3v2_version 3` for compatibility |
| Syncing all files when one changed | Track per-file sync status |
| Overwriting manually-corrected files | Verify server metadata is source of truth |
| Assuming API paths match local paths | Always configure path prefix mappings |
| Using hardcoded paths | Use path translation function with mappings |

## Error Handling

### Path Translation Failures

```bash
# When translated path still doesn't exist
if [ ! -f "$local_path" ]; then
  echo "ERROR: Cannot locate file"
  echo "  API path: $api_path"
  echo "  Translated: $local_path"

  # Option 1: Try to find by filename
  filename=$(basename "$api_path")
  found=$(find /local/search/paths -name "$filename" 2>/dev/null | head -1)
  if [ -n "$found" ]; then
    echo "  Found by filename: $found"
    local_path="$found"
  fi

  # Option 2: Log for manual review
  echo "$api_path|$local_path" >> .sync-path-errors
fi
```

### Authentication Errors
```bash
# Check if token expired
curl -I "http://server/api/libraries" \
  -H "Authorization: Bearer $TOKEN"

# If 401, re-login
```

### File Not Found
```bash
# Server path may differ from actual filesystem
# Verify file exists before processing
if [ ! -f "$file_path" ]; then
  echo "File not found: $file_path"
  # Option: scan filesystem to find matching file
fi
```

### Metadata Write Failures
```bash
# Some formats are read-only
# Check file permissions
ls -la file.m4a

# For MP4, may need to rewrite file (not in-place edit)
ffmpeg -i in.m4a -c copy -metadata title="New" temp.m4a && mv temp.m4a in.m4a
```

## Related Tools

- **ffprobe/ffmpeg** — Read/write audio file metadata
- **AtomicParsley** — MP4/M4A metadata tool
- **id3v2/libid3tag** — MP3 metadata tool
- **metaflac** — FLAC metadata tool
- **MusicBrainz Picard** — Auto-tagging with fingerprinting

## API Discovery

Since official API docs are outdated:

1. **Browser DevTools:**
   - Open audiobookshelf web UI
   - Perform actions (edit metadata, scan library)
   - Watch Network tab for API calls

2. **Server logs:**
   - Check audiobookshelf server logs
   - Shows all API requests

3. **Source code:**
   - GitHub: advply/audiobookshelf
   - Check `server/controllers/` for API routes

4. **Community resources:**
   - https://github.com/advply/audiobookshelf/discussions
   - https://reddit.com/r/audiobookshelf

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2026-03-12 | Initial release: API reference, metadata mapping, path prefix translation, deduplication |
