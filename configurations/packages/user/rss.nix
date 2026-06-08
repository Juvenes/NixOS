{ pkgs, ... }:

let
    # qs-rss: shared RSS picker for hyprlock + quickshell.
    # - `pick --n N --format json|line` → N articles from the cached selection
    # - `line <i>`     → Pango-marked single line for hyprlock labels
    # - `dismiss <id>` → write to ~/.local/state/quickshell/rss-dismissed.txt
    # - `refresh`      → force re-fetch all feeds
    #
    # The "selection" is recomputed every 15 minutes so the three hyprlock
    # labels (and the reader popup) stay consistent across simultaneous calls.
    qs-rss = pkgs.writers.writePython3Bin "qs-rss" {
        libraries = [ pkgs.python313Packages.feedparser ];
        # Inline scripts won't satisfy PEP8 spacing; skip the noisy checks.
        flakeIgnore = [
            "E302"  # expected 2 blank lines
            "E305"  # expected 2 blank lines after function
            "E221"  # multiple spaces before operator (we align = on shorts)
            "E231"  # missing whitespace after ','
            "E272"  # multiple spaces before keyword (we align `or` chains)
            "E401"  # multiple imports on one line
            "E501"  # line too long
            "W391"  # blank line at end of file
        ];
    } ''
        import argparse, html, json, os, random, sys, time
        from pathlib import Path

        import feedparser

        XDG_CONFIG = Path(os.environ.get("XDG_CONFIG_HOME") or (Path.home() / ".config"))
        XDG_STATE  = Path(os.environ.get("XDG_STATE_HOME")  or (Path.home() / ".local/state"))
        XDG_CACHE  = Path(os.environ.get("XDG_CACHE_HOME")  or (Path.home() / ".cache"))

        FEEDS_FILE     = XDG_CONFIG / "quickshell" / "rss-feeds.txt"
        STATE_DIR      = XDG_STATE  / "quickshell"
        CACHE_DIR      = XDG_CACHE  / "quickshell"
        DISMISSED_FILE = STATE_DIR  / "rss-dismissed.txt"
        CACHE_FILE     = CACHE_DIR  / "rss-articles.json"
        SELECTION_FILE = CACHE_DIR  / "rss-selection.json"

        CACHE_TTL     = 900   # 15 min — when to refetch feeds
        SELECTION_TTL = 900   # 15 min — when to reroll which N are shown

        def load_feeds():
            if not FEEDS_FILE.exists():
                return []
            out = []
            for line in FEEDS_FILE.read_text().splitlines():
                line = line.strip()
                if line and not line.startswith("#"):
                    out.append(line)
            return out

        def load_dismissed():
            if not DISMISSED_FILE.exists():
                return set()
            return set(DISMISSED_FILE.read_text().splitlines())

        def dismiss(aid):
            STATE_DIR.mkdir(parents=True, exist_ok=True)
            with DISMISSED_FILE.open("a") as f:
                f.write(aid + "\n")

        def fetch_articles(force=False):
            CACHE_DIR.mkdir(parents=True, exist_ok=True)
            if not force and CACHE_FILE.exists():
                if time.time() - CACHE_FILE.stat().st_mtime < CACHE_TTL:
                    try:
                        return json.loads(CACHE_FILE.read_text())
                    except Exception:
                        pass
            out = []
            for url in load_feeds():
                try:
                    f = feedparser.parse(url)
                    src = (f.feed.get("title") or "?").strip()
                    for e in f.entries[:15]:
                        eid = e.get("id") or e.get("link") or ""
                        if not eid:
                            continue
                        out.append({
                            "id": eid,
                            "title": (e.get("title") or "(untitled)").strip(),
                            "link": e.get("link", ""),
                            "source": src,
                        })
                except Exception as exc:
                    print(f"feed {url}: {exc}", file=sys.stderr)
            CACHE_FILE.write_text(json.dumps(out))
            return out

        def pick(n):
            dismissed = load_dismissed()
            arts = [a for a in fetch_articles() if a["id"] not in dismissed]
            random.shuffle(arts)
            # Spread across sources first to avoid 3-from-HN
            seen_src = set()
            spread = []
            for a in arts:
                if a["source"] not in seen_src:
                    spread.append(a)
                    seen_src.add(a["source"])
                if len(spread) >= n:
                    break
            for a in arts:
                if len(spread) >= n:
                    break
                if a not in spread:
                    spread.append(a)
            return spread[:n]

        def current_selection(n):
            if SELECTION_FILE.exists():
                age = time.time() - SELECTION_FILE.stat().st_mtime
                if age < SELECTION_TTL:
                    try:
                        sel = json.loads(SELECTION_FILE.read_text())
                        if len(sel) >= n:
                            return sel[:n]
                    except Exception:
                        pass
            CACHE_DIR.mkdir(parents=True, exist_ok=True)
            sel = pick(max(n, 5))
            SELECTION_FILE.write_text(json.dumps(sel))
            return sel[:n]

        def main():
            p = argparse.ArgumentParser(prog="qs-rss")
            sub = p.add_subparsers(dest="cmd", required=True)

            p_pick = sub.add_parser("pick", help="emit N articles")
            p_pick.add_argument("--n", type=int, default=5)
            p_pick.add_argument("--format", choices=["json", "line"], default="json")

            p_line = sub.add_parser("line", help="single Pango line; arg = index")
            p_line.add_argument("index", type=int, nargs="?", default=0)

            p_dismiss = sub.add_parser("dismiss")
            p_dismiss.add_argument("id")

            sub.add_parser("refresh", help="force refetch feeds + reroll selection")

            args = p.parse_args()

            if args.cmd == "dismiss":
                dismiss(args.id)
            elif args.cmd == "refresh":
                fetch_articles(force=True)
                # Drop the selection so next call rerolls.
                if SELECTION_FILE.exists():
                    SELECTION_FILE.unlink()
            elif args.cmd == "line":
                sel = current_selection(max(args.index + 1, 3))
                if args.index < len(sel):
                    a = sel[args.index]
                    src   = html.escape(a["source"][:18])
                    title = html.escape(a["title"][:90])
                    print(f"<span foreground='#89b4fa'>{src}</span>  {title}")
                else:
                    print("(no article)")
            elif args.cmd == "pick":
                sel = current_selection(args.n)
                if args.format == "json":
                    print(json.dumps(sel))
                else:
                    for a in sel:
                        print(f"{a['source'][:20]}: {a['title']}")

        if __name__ == "__main__":
            main()
    '';
in {
    home.packages = [ qs-rss ];

    # Default feed list. Edit to taste — one URL per line, # for comments.
    xdg.configFile."quickshell/rss-feeds.txt".text = ''
        # NixOS
        https://discourse.nixos.org/c/announcements/8.rss
        https://discourse.nixos.org/latest.rss
        # Linux / desktop
        https://www.phoronix.com/rss.php
        # Security / pentest
        https://www.bleepingcomputer.com/feed/
        https://feeds.feedburner.com/TheHackersNews
        # General tech
        https://news.ycombinator.com/rss
        https://lobste.rs/rss
        https://arstechnica.com/feed/
    '';
}
