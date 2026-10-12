# yt-cli

A minimalist, high-performance terminal YouTube client with an interactive omnibar search, channel-interleaved algorithmic recommendations, GPU-accelerated thumbnail previews, and instant mpv playback.

---

## Features

- **Interactive Omnibar Search**: Type any query directly into the main prompt (`youtube › `) and press Enter to search instantly, or navigate feeds without clutter.
- **Personal Recommendation Algorithm**: Reads session cookies from modern browsers (Zen, Firefox, LibreWolf, Brave, Chromium, Chrome) to load your authentic 100-item YouTube feed.
- **Channel De-Clustering (Interleaving)**: Automatically alternates creators in your recommendations feed to prevent algorithmic echo chambers.
- **Graceful Guest Fallback**: If no browser session or cookies are detected, automatically switches to global trending and unrestricted direct search.
- **GPU-Accelerated Kitty Previews**: Pixel-perfect thumbnail previews drawn via Kitty `icat` memory transfer mode with dynamic preview pane geometry and Chafa ANSI fallback.
- **Modal Control Bindings**:
  - `Enter`: Fullscreen video playback via `mpv` (Wayland/GPU hardware accelerated).
  - `Ctrl + a`: Background audio-only mode.
  - `Ctrl + y`: Copy short URL (`youtu.be/<id>`) to clipboard via `wl-copy` or `xclip`.
  - `Ctrl + d`: Download video to `~/Videos` in the background.
  - `Ctrl + o`: Open in your default browser.
  - `Ctrl + r`: Force reload feed cache.

---

## Dependencies

Make sure the following tools are available on your system:

| Dependency | Purpose | Arch Linux Package |
|---|---|---|
| `fzf` | Interactive fuzzy finder & omnibar UI | `fzf` |
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

You can also search directly without opening the interactive menu:

```bash
yt "rust programming language"
```

### Cookie Configuration

`yt-cli` automatically scans known browser profiles for active sessions. If you use a non-standard browser profile, you can explicitly set the `YT_BROWSER` environment variable:

```bash
export YT_BROWSER="firefox:~/.config/zen/Profiles/myprofile"
```

---

## Architecture

```
yt (omnibox fzf) ───► yt-dlp (flat playlist metadata) ───► python3 (interleaving)
        │
        ├───► yt-thumb-preview ───► Kitty ICAT / Chafa
        └───► mpv (GPU video / audio)
```

---

## License

MIT © [Esteban David Marrugo Jassir](https://github.com/e12jassir)
