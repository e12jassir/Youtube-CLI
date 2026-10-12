# yt

A fast YouTube client for your terminal. Browse your own feed, search, and play
with mpv — without leaving the keyboard.

**fzf** for the interface · **yt-dlp** for data · **mpv** for playback · thumbnails in Kitty/Ghostty (or Chafa).

<!-- Add a 15 s GIF here (vhs / asciinema): it is the single best thing for adoption. -->

## Why it feels fast

- **Stale-while-revalidate.** Your feed appears instantly from cache while a refresh runs behind it.
- **Cookies read once**, not on every call (6 h by default). Only Google/YouTube cookies are kept, with `600` permissions.
- **Thumbnails pre-fetched in parallel**, light 16:9 images (~10 KB).
- **Direct playback.** mpv drives yt-dlp, so playback starts sooner and seeking works; it falls back to the old pipe on errors.
- **Nothing blocks the UI.** Play, save, copy and download run detached; the list stays open.

## Install

```sh
git clone https://github.com/e12jassir/ytx-cli && cd ytx-cli
./install.sh        # or: make install      (PREFIX=~/.local by default)
yt --doctor         # verifies everything below
```

| Needs | Notes |
|---|---|
| bash ≥ 4 | macOS: `brew install bash` |
| fzf ≥ 0.44 | |
| yt-dlp (recent) | keep it updated: `yt-dlp -U` |
| **a JavaScript runtime** | since yt-dlp 2025.11 YouTube needs Deno (recommended), Node, Bun or QuickJS |
| mpv, curl, python3 | |
| optional | kitty/Ghostty or `chafa` (thumbnails), `wl-copy`/`xclip`/`pbcopy`, `notify-send` |

## Use

```sh
yt                 # home view (for you if you are signed in, else history/search)
yt lofi hip hop    # search
yt --view subs     # foryou | subs | later | history | search
```

| Key | Action | Key | Action |
|---|---|---|---|
| `enter` | play (window) | `^w` | save / unsave |
| `^p` | mini picture-in-picture | `^y` | copy `youtu.be` link |
| `^f` | fullscreen | `^d` | download |
| `^a` | audio only | `^o` | open in browser |
| `^s` | search YouTube with what you typed | `^r` | reload this view |
| `alt-1…4` | for you · subscriptions · saved · history | `^/` | toggle preview |

Signed in? `yt` reads the session from Zen, Firefox, LibreWolf, Brave, Chromium or Chrome.
Not signed in? Search, history and saved videos still work. (YouTube retired its Trending page in 2025, so there is no guest feed.)

## Configuration

`~/.config/yt/config` — plain `KEY=value`, never executed. See [`config.example`](config.example).
Environment variables override the file. UI language follows `$LANG` (`es`/`en`).

## Privacy

Cookies are read locally from your browser, filtered to Google/YouTube domains, stored in
`~/.cache/yt_terminal/cookies.txt` (`600`) and passed to yt-dlp as private copies.
`yt --forget-cookies` deletes them; `YT_COOKIES=off` disables the feature.

## Development

```sh
make test   # stub-based smoke tests, no network needed
make lint   # shellcheck + py_compile
```

MIT licensed.
