# yt-cli

A minimalist, high-performance terminal YouTube client with an interactive omnibar search, channel-interleaved algorithmic recommendations, GPU-accelerated thumbnail previews, and instant mpv playback.

---

## Features

- **Interactive Omnibar Search**: Type any query directly into the main prompt and press Enter to search instantly, or navigate feeds without clutter.
- **Personal Recommendation Algorithm**: Reads session cookies from modern browsers (Zen, Firefox, LibreWolf, Brave, Chromium, Chrome) to load your authentic YouTube feed.
- **Channel De-Clustering (Interleaving)**: Automatically alternates creators in your recommendations feed to prevent algorithmic echo chambers.
- **Graceful Guest Fallback**: If no browser session is detected, automatically switches to global trending and unrestricted direct search.
- **GPU-Accelerated Kitty Previews**: Pixel-perfect thumbnail previews drawn via Kitty `icat` with dynamic geometry and Chafa ANSI fallback.
- **Watch Later**: Press `Ctrl+w` on any video to save or remove it from your watch-later list. Accessible from the main menu.
- **Cache Age Display**: The main menu shows how old each feed's cache is (`4m`, `sin cache`, `ahora`) so you always know if you're seeing fresh data.
- **Animated Spinner**: Braille spinner animation during network fetches — clean, non-blocking.
- **Signal Safety**: `trap` on `EXIT`, `INT`, and `TERM` ensures the spinner and Kitty image are always cleaned up, even on Ctrl+C.
- **Configurable**: All defaults can be overridden via `~/.config/yt/config`.
- **Multi-Mode Playback**: Seamless support for windowed mode, floating Picture-in-Picture (PiP), and fullscreen.
- **Robust Authenticated Pipeline**: Pipes authenticated video streams directly from `yt-dlp` to `mpv` stdin, completely bypassing YouTube CDN 403 Forbidden errors and bot checks.
- **IPC Render Synchronization**: Terminal spinner runs smoothly until `mpv` actually draws the first video frame, firing desktop notifications accurately on playback start.
- **Modal Control Bindings**:
  - `Enter`: Playback using default mode configured in `~/.config/yt/config` (`window` by default).
  - `Ctrl + p`: Picture-in-Picture (PiP) floating window pinned on top.
  - `Ctrl + f`: Fullscreen playback via `mpv`.
  - `Ctrl + a`: Background audio-only stream.
  - `Ctrl + y`: Copy short URL (`youtu.be/<id>`) to clipboard.
  - `Ctrl + w`: Toggle watch later (save / remove).
  - `Ctrl + d`: Download video to `~/Videos` in the background.
  - `Ctrl + o`: Open in your default browser.
  - `Ctrl + r`: Force reload feed cache.

---

## Dependencies

| Dependency | Purpose | Arch Linux Package |
|---|---|---|
| `fzf` ≥ 0.36 | Interactive fuzzy finder & omnibar UI | `fzf` |
| `yt-dlp` | Metadata extractor and stream resolver | `yt-dlp` |
| `mpv` | Hardware-accelerated media player | `mpv` |
| `curl` | Fast CDN thumbnail fetching | `curl` |
| `python3` | Algorithmic creator interleaving | `python` |
| `kitty` *(optional)* | Native GPU image rendering | `kitty` |
| `chafa` *(optional)* | Terminal image fallback for non-Kitty terminals | `chafa` |
| `wl-copy` / `xclip` *(optional)* | Clipboard synchronization | `wl-clipboard` / `xclip` |

---

## Installation

### Via Git & Makefile

```bash
git clone git@github.com:e12jassir/yt-cli.git
cd yt-cli
make install
```

Or run the installer directly:

```bash
./install.sh
```

Ensure `~/.local/bin` is in your `$PATH`.

---

## Usage

Simply launch:

```bash
yt
```

### Direct Search via CLI Arguments

```bash
yt "rust programming language"
```

### Cookie Configuration

`yt-cli` automatically scans known browser profiles for active sessions. To use a specific profile:

```bash
export YT_BROWSER="firefox:~/.config/zen/Profiles/myprofile"
```

---

## Configuration

Create `~/.config/yt/config` to override any default:

```bash
# Feed & search sizes
YT_FEED_SIZE=100        # items fetched from your personal feed
YT_SEARCH_SIZE=40       # results per search query

# Cache
YT_CACHE_TTL=900        # seconds before a cached feed is considered stale (default: 15 min)

# Playback
YT_AUDIO_VOLUME=75      # volume for background audio mode (0–100)
YT_DEFAULT_MODE=window  # default playback mode on Enter: "window", "pip", or "fs"

# Browser
YT_BROWSER_CMD=zen      # browser to open videos with Ctrl+o
```

---

## State Files

All state is stored under XDG Base Dirs:

| File | Purpose |
|---|---|
| `~/.local/state/yt/history.tsv` | Playback history (deduped by video ID) |
| `~/.local/state/yt/watchlater.tsv` | Watch later list |
| `~/.cache/yt_terminal/` | Feed cache (TSV) and thumbnails (JPG) |

---

## Architecture

```
yt (omnibox fzf) ───► yt-dlp (flat playlist metadata) ───► python3 (interleaving)
        │
        ├───► yt-thumb-preview ───► Kitty ICAT / Chafa
        └───► mpv (detached — video / audio)
```

---

## License

MIT © [Esteban David Marrugo Jassir](https://github.com/e12jassir)
