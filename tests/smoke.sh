#!/usr/bin/env bash
# Smoke tests for yt. No network, no real fzf/yt-dlp/mpv: they are stubbed.
# Run: make test   (or: bash tests/smoke.sh)

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

export HOME="$TMP/home" XDG_CACHE_HOME="$TMP/home/.cache" XDG_STATE_HOME="$TMP/home/.local/state"
export XDG_CONFIG_HOME="$TMP/home/.config" TMPDIR="$TMP"
export STUB_LOG="$TMP/ytdlp.log" FZF_ARGS_OUT="$TMP/fzf.args" FZF_STDIN_OUT="$TMP/fzf.stdin"
mkdir -p "$HOME" "$TMP/bin"
: > "$STUB_LOG"

# ── stubs ────────────────────────────────────────────────────────────────────
cat > "$TMP/bin/yt-dlp" <<'STUB'
#!/usr/bin/env bash
echo "$*" >> "$STUB_LOG"
[ "$1" = "--version" ] && { echo "2099.01.01"; exit 0; }
cookies_out=""; prev=""
for a in "$@"; do [ "$prev" = "--cookies" ] && cookies_out=$a; prev=$a; done
case "$*" in
  *--cookies-from-browser*)
    printf '# Netscape HTTP Cookie File\n.youtube.com\tTRUE\t/\tTRUE\t0\tLOGIN_INFO\tabc\n#HttpOnly_.youtube.com\tTRUE\t/\tTRUE\t0\tSAPISID\tzzz\n.evil.example\tTRUE\t/\tTRUE\t0\tSECRET\tleak\n.google.com\tTRUE\t/\tTRUE\t0\tSID\tq\n' > "$cookies_out" ;;
esac
case "$*" in
  *ytsearch1:youtube*) echo "aaaaaaaaaaa" ;;
  *ytsearch*)
    printf 'srch0000001\tHello wörld 日本語タイトル\tChan A\t10:00\thttps://www.youtube.com/watch?v=srch0000001\t1200\tNA\n' ;;
  *youtube.com*)
    printf 'vidAAAAAAA1\tA one\tChan A\t10:00\thttps://www.youtube.com/watch?v=vidAAAAAAA1\t1500000\tNA\n'
    printf 'vidAAAAAAA2\tA two\tChan A\t11:00\thttps://www.youtube.com/watch?v=vidAAAAAAA2\t900\tNA\n'
    printf 'vidAAAAAAA3\tA three\tChan A\tNA\thttps://www.youtube.com/watch?v=vidAAAAAAA3\tNA\tis_live\n'
    printf 'vidBBBBBBB1\tB one\tChan B\t5:00\thttps://www.youtube.com/watch?v=vidBBBBBBB1\t42\tNA\n'
    printf 'shortSSSSS1\tA short\tChan C\t0:30\thttps://www.youtube.com/shorts/shortSSSSS1\t5\tNA\n'
    printf 'vidAAAAAAA1\tA one (dup)\tChan A\t10:00\thttps://www.youtube.com/watch?v=vidAAAAAAA1\t1500000\tNA\n'
    printf 'noch0000001\tNo channel\t\t1:00\thttps://www.youtube.com/watch?v=noch0000001\t7\tNA\n' ;;
esac
STUB
cat > "$TMP/bin/fzf" <<'STUB'
#!/usr/bin/env bash
[ "$1" = "--version" ] && { echo "0.60.0 (stub)"; exit 0; }
printf '%s\n' "$@" > "$FZF_ARGS_OUT"
cat > "$FZF_STDIN_OUT"
STUB
printf '#!/usr/bin/env bash\necho "mpv 0.38 stub"\n' > "$TMP/bin/mpv"
chmod +x "$TMP/bin/"*
export PATH="$TMP/bin:$PATH"

# ── tiny test framework ──────────────────────────────────────────────────────
PASS=0; FAIL=0
ok()   { PASS=$((PASS + 1)); printf '  ok   %s\n' "$1"; }
bad()  { FAIL=$((FAIL + 1)); printf '  FAIL %s\n' "$1"; [ -n "${2:-}" ] && printf '       %s\n' "$2"; }
eq()   { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1" "expected [$3] got [$2]"; fi; }
has()  { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1" "missing [$3] in [$2]" ;; esac; }
hasnt(){ case "$2" in *"$3"*) bad "$1" "unexpected [$3] in [$2]" ;; *) ok "$1" ;; esac; }

# shellcheck source=../bin/yt
source "$ROOT/bin/yt"
export YT_BROWSER="firefox:/nonexistent"      # force a deterministic cookie source
export YT_LANG="en"                           # force deterministic locale strings for tests
init light

echo "yt-fmt"
RAW="$("$TMP/bin/yt-dlp" https://www.youtube.com/)"
OUT="$(printf '%s\n' "$RAW" | "$ROOT/bin/yt-fmt" --width 80 --hide-shorts --interleave --no-color)"
IDS="$(printf '%s\n' "$OUT" | cut -f1 | tr '\n' ' ')"
eq "interleaves by channel, dedupes, hides shorts" "$IDS" "vidAAAAAAA1 vidBBBBBBB1 noch0000001 vidAAAAAAA2 vidAAAAAAA3 "
BAD="$(printf '%s\n' "$OUT" | awk -F'\t' 'NF != 7 || $1=="" || $2=="" || $3=="" || $4=="" || $5=="" || $6=="" {print}')"
eq "every row has 7 non-empty fields" "$BAD" ""
has "live badge" "$(printf '%s\n' "$OUT" | grep vidAAAAAAA3 | cut -f7)" "LIVE"
has "views are humanised" "$(printf '%s\n' "$OUT" | grep vidAAAAAAA1 | cut -f6)" "1.5M"
eq "missing channel becomes -" "$(printf '%s\n' "$OUT" | grep noch0000001 | cut -f4)" "-"
W="$(printf 'srch0000001\tHello wörld 日本語タイトル 日本語タイトル 日本語タイトル 日本語タイトル\tChan A\t10:00\thttps://x\t1\tNA\n' \
    | "$ROOT/bin/yt-fmt" --width 60 --no-color | cut -f7)"
eq "display width never exceeds the budget (CJK aware)" "$(python3 - "$W" <<'PY'
import sys, unicodedata
s = sys.argv[1]
w = sum(0 if unicodedata.category(c) in ("Mn","Me","Cf") else 2 if unicodedata.east_asian_width(c) in "WF" else 1 for c in s)
print("ok" if w <= 60 else "too wide: %d" % w)
PY
)" "ok"
NC="$(printf '%s\n' "$RAW" | NO_COLOR=1 "$ROOT/bin/yt-fmt" | cut -f7 | head -n 1)"
hasnt "NO_COLOR removes ANSI" "$NC" $'\033'
printf 'idid00000\tT\tC\t1:00\thttps://x\t1\tNA\textra\n' | "$ROOT/bin/yt-fmt" --stored >/dev/null && ok "stored rows accepted"

echo "config"
mkdir -p "$XDG_CONFIG_HOME/yt"
cat > "$XDG_CONFIG_HOME/yt/config" <<CFG
# comment
YT_FEED_SIZE=5        # inline comment
YT_SEARCH_SIZE="7"
YT_BROWSER_CMD="\${BROWSER:-fallbackbrowser}"
YT_DOWNLOAD_DIR=~/dl
YT_EVIL=\$(touch $TMP/pwned1)
notyt=\$(touch $TMP/pwned2)
YT_QUALITY=notanumber
CFG
unset YT_FEED_SIZE YT_SEARCH_SIZE YT_BROWSER_CMD YT_DOWNLOAD_DIR YT_EVIL YT_QUALITY BROWSER
init light
eq "inline comment stripped" "$YT_FEED_SIZE" "5"
eq "quoted value" "$YT_SEARCH_SIZE" "7"
eq "\${BROWSER:-x} supported" "$YT_BROWSER_CMD" "fallbackbrowser"
eq "tilde expands" "$YT_DOWNLOAD_DIR" "$HOME/dl"
eq "bad number falls back to default" "$YT_QUALITY" "1080"
[ ! -e "$TMP/pwned1" ] && [ ! -e "$TMP/pwned2" ] && ok "config is data, never executed" || bad "config executed code"
eq "env beats config file" "$( ( YT_FEED_SIZE=9; init light; echo "$YT_FEED_SIZE" ) )" "9"
rm -f "$XDG_CONFIG_HOME/yt/config"; unset YT_FEED_SIZE YT_SEARCH_SIZE YT_BROWSER_CMD YT_DOWNLOAD_DIR YT_QUALITY; init light

echo "cookies"
prepare_cookies
JAR="$CACHE_DIR/cookies.txt"
[ -s "$JAR" ] && ok "jar created" || bad "jar missing"
hasnt "foreign-domain cookies are dropped" "$(cat "$JAR")" "evil.example"
has "HttpOnly youtube cookie kept" "$(cat "$JAR")" "#HttpOnly_.youtube.com"
has "google cookie kept" "$(cat "$JAR")" ".google.com"
eq "jar permissions are 600" "$(stat -c %a "$JAR" 2>/dev/null || stat -f %Lp "$JAR")" "600"
eq "yt-dlp gets a private copy" "$([ "${COOKIE_ARGS[1]}" != "$JAR" ] && [ -s "${COOKIE_ARGS[1]}" ] && echo yes)" "yes"
BEFORE=$(grep -c cookies-from-browser "$STUB_LOG"); prepare_cookies; prepare_cookies
eq "browser DB is read once per TTL" "$(grep -c cookies-from-browser "$STUB_LOG")" "$BEFORE"

echo "feeds & cache"
: > "$STUB_LOG"
A="$(emit_view foryou auto | cut -f1 | head -n 1)"
eq "first row of the feed" "$A" "vidAAAAAAA1"
N1=$(grep -c 'youtube.com/' "$STUB_LOG")
emit_view foryou auto >/dev/null
eq "fresh cache: no second network call" "$(grep -c 'youtube.com/' "$STUB_LOG")" "$N1"
emit_view foryou refresh >/dev/null
eq "refresh forces a call" "$(grep -c 'youtube.com/' "$STUB_LOG")" "$((N1 + 1))"
[ "$(emit_view foryou cached | wc -l)" -gt 0 ] && ok "cached mode serves stale data" || bad "cached mode empty"
S="$(emit_view search auto "rust lang" | cut -f1 | head -n 1)"
eq "search results" "$S" "srch0000001"
touch -d '2 hours ago' "$(view_cache_file foryou)" 2>/dev/null || touch -t 200001010000 "$(view_cache_file foryou)"
needs_sync foryou "" && ok "stale cache triggers background sync" || bad "stale cache not detected"

echo "views & saved list"
E="$(emit_view later cached | cut -f1)"
eq "empty saved list shows a placeholder row" "$E" "none"
toggle_later vidBBBBBBB1 "B one" "Chan B" "5:00" "https://www.youtube.com/watch?v=vidBBBBBBB1"
eq "toggle adds" "$(cut -f1 "$WATCHLATER_FILE")" "vidBBBBBBB1"
has "saved items are starred in lists" "$(emit_view foryou cached | grep vidBBBBBBB1 | cut -f7)" "★"
toggle_later vidBBBBBBB1 x x x x
eq "toggle removes (exact id match)" "$(wc -l < "$WATCHLATER_FILE" | tr -d ' ')" "0"
printf '\033[90m 1:00 \033[0m T\tOld title\tOld chan\t1:00\toldid000001\thttps://www.youtube.com/watch?v=oldid000001\n' > "$WATCHLATER_FILE"
migrate_watchlater
eq "old watch-later format migrates" "$(cut -f1,2 "$WATCHLATER_FILE")" "$(printf 'oldid000001\tOld title')"
record_history vidAAAAAAA2 "A two" "Chan A" "11:00" "https://www.youtube.com/watch?v=vidAAAAAAA2"
eq "history shows newest first" "$(emit_view history cached | cut -f1 | head -n 1)" "vidAAAAAAA2"

echo "actions"
eq "ids are validated" "$(valid_id 'x; rm -rf /' && echo bad || echo ok)" "ok"
eq "URLs never start with a dash" "$(canonical_url abcdefghijk '-oevil')" "https://www.youtube.com/watch?v=abcdefghijk"
do_action copy 'not valid!' ; ok "invalid ids are ignored by actions"

echo "ui wiring (fzf stub records its arguments)"
rm -f "$CACHE_DIR"/feed_*.tsv
( browse foryou ) >/dev/null 2>&1
ARGS="$(cat "$FZF_ARGS_OUT")"
has "fzf: only the display column is searchable" "$ARGS" "--with-nth=7"
has "fzf: enter plays without leaving the list" "$ARGS" "enter:execute-silent("
has "fzf: stale-while-revalidate bind on start" "$ARGS" "start:change-prompt("
has "fzf: ctrl-r reloads the current view" "$ARGS" "reload-sync("
has "fzf: ctrl-s searches with {q}" "$ARGS" "search {q})"
has "fzf: tabs alt-1..4" "$ARGS" "alt-4:"
has "fzf: preview wired to helper" "$ARGS" "yt-thumb-preview {1} {3} {4} {5} {6}"
has "fzf: ghost text on fzf >= 0.58" "$ARGS" "--ghost="
has "no cache yet: list starts with a syncing row" "$(cat "$FZF_STDIN_OUT")" "syncing"
emit_view foryou refresh >/dev/null
( browse foryou ) >/dev/null 2>&1
hasnt "fresh cache: no start-sync bind" "$(cat "$FZF_ARGS_OUT")" "start:change-prompt("
eq "fresh cache: first row comes from cache" "$(cut -f1 "$FZF_STDIN_OUT" | head -n 1)" "vidAAAAAAA1"

echo "preview"
PV="$(FZF_PREVIEW_COLUMNS=50 FZF_PREVIEW_LINES=30 YT_PREVIEW=none NO_COLOR=1 "$ROOT/bin/yt-thumb-preview" vidAAAAAAA1 "A one" "Chan A" "10:00" "1.5M" 2>&1)"
has "preview prints title" "$PV" "A one"
has "preview prints channel and views" "$PV" "Chan A  ·  10:00  ·  1.5M views"
has "preview prints short url" "$PV" "youtu.be/vidAAAAAAA1"
eq "preview ignores placeholder rows" "$("$ROOT/bin/yt-thumb-preview" none x 2>&1)" ""

echo "cli"
eq "--version" "$(bash "$ROOT/bin/yt" --version)" "yt $VERSION"
DOC="$(bash "$ROOT/bin/yt" --doctor 2>&1)"; RC=$?
has "doctor lists fzf" "$DOC" "fzf"
has "doctor checks the JS runtime" "$DOC" "js runtime"
eq "doctor passes with all deps present" "$RC" "0"
has "usage mentions search" "$(bash "$ROOT/bin/yt" --help)" "search YouTube"

echo
printf '%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
