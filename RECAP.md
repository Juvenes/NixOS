# Recap

Post-rebuild setup steps + every shortcut the system now knows about.

## Run order on the laptop

```sh
nixtest                # ephemeral; verifies it boots, no commitment
nixbuild               # makes it the active generation
loginctl terminate-user $USER   # or: log out from Hyprland menu
```

The logout step matters — Hyprland only re-registers the new `global,
quickshell:*` keybinds after a fresh session. Hyprpaper, cliphist watchers
and the Quickshell systemd unit also start cleanly only on re-login.

If you'd rather not log out: `hyprctl reload` picks up the new keybindings,
but the cliphist `wl-paste --watch` execs in `hyprland/default.nix` only fire
on Hyprland startup — so D5 will have an empty history until next login.

## One-time things to do after first rebuild

- **RSS feeds** — defaults live in the Nix-managed
  `~/.config/quickshell/rss-feeds.txt` (a read-only symlink into the store).
  To add/remove feeds, edit the list in `configurations/packages/user/rss.nix`
  under `xdg.configFile."quickshell/rss-feeds.txt".text` and rebuild.
- **First RSS fetch** is cold-network — the very first `qs-rss` call (hyprlock
  label or `$mod+M`) takes a few seconds while `feedparser` pulls every URL.
  Subsequent calls hit the 15-min cache.
- **Hostname change** — was `roole-nixos-laptop`, now `nixos-work`. The
  rebuild aliases (`nixbuild`, `nixtest`, `update`) all use `--flake
  ~/.dotfiles` and pick up the new `nixosConfigurations.nixos-work` key
  automatically. If you have any external configs referencing the old name
  (Tailscale name, monitoring, SSH `Host` aliases), update those.
- **Nix shells list** — hardcoded in
  `configurations/packages/user/quickshell/configs/bar/NixShells.qml` under
  the `shells:` array. Edit + rebuild to add languages/tools.
- **Wofi is still installed** as a fallback, but no key binds to it. Safe to
  drop from `packages/user/default.nix` once you trust the new launcher.
- **`wlogout` is still installed** but no key binds to it — same situation.
  PowerMenu replaces it.
- **Fingerprint at lock** — `fprintd` is enabled (work hardware) but the
  hyprlock fingerprint block is commented out in the upstream example. If
  you want a fingerprint scan inside hyprlock, add an `auth = { fingerprint
  = { enabled = true; ... }; }` block to `hyprlock.nix`.
- **Reset RSS dismissals** — to re-surface every article you've dismissed:
  `rm ~/.local/state/quickshell/rss-dismissed.txt`.
- **Reset the launcher's icon cache** — if app icons render as blanks: the
  `IconImage` source URL is `image://icon/<name>` and resolves against the
  GTK/Stylix icon theme; verify a theme is active (`gsettings get
  org.gnome.desktop.interface icon-theme`).

## Quickshell popups — open via hotkey or click

| Popup | Hotkey | Click trigger | Internal keys |
|--|--|--|--|
| **Launcher** (O3) | `$mod+Space` or `$mod+R` | rocket pill (left of bar) | type → filter, **Enter** runs first match, **Esc** close |
| **Quick note** (D6) | `$mod+N` | — | **Ctrl+Enter** saves to `~/notes/scratch.md`, **Esc** cancels |
| **Clipboard** (D5) | `$mod+V` | — | type → filter, **Enter** copies first match, **Esc** close |
| **Nix shells** | `$mod+X` | — | click any tile → kitty `nix-shell -p …`, **Esc** close |
| **Power menu** (D4) | `$mod+P` | power pill (far right) | click button or **Esc** |
| **Audio mixer** (D2) | — | volume label (right of bar) | click sliders, click mute toggle, **Esc** close |
| **Network picker** (D3) | — | network label (right of bar) | click to connect, "Rescan" button, **Esc** close |
| **RSS reader** | `$mod+M` | — | **left-click** opens in Firefox + dismisses, **right-click** dismisses only, **r** rerolls, **Esc** close |
| **OSD** (D7) | (auto) | — | shows on volume / brightness change, fades after 1.5s |

## Hyprland keybindings — Apps & system

| Bind | Action |
|--|--|
| `$mod, Return` | kitty |
| `$mod, T` | kitty |
| `$mod, A` | firefox |
| `$mod, B` | firefox private window |
| `$mod+SHIFT, B` | firefox |
| `$mod, U` | vesktop |
| `$mod, L` | hyprlock (manual lock) |
| `$mod, Escape` | **exit Hyprland session** |
| `$mod+SHIFT, S` | screenshot region → clipboard (`grim+slurp+wl-copy`) |
| `Print` | screenshot full → clipboard |
| `ALT, twosuperior` | replay-save |

## Hyprland keybindings — Quickshell popups

All routed through `GlobalShortcut`s declared in `shell.qml`.

| Bind | Popup |
|--|--|
| `$mod, Space` | Launcher |
| `$mod, R` | Launcher (alias) |
| `$mod, N` | Quick note |
| `$mod, V` | Clipboard history |
| `$mod, X` | Nix shells |
| `$mod, P` | Power menu |
| `$mod, M` | RSS reader |

## Workspaces (Belgian layout — top-row digits)

| Bind | Action |
|--|--|
| `$mod, &` | workspace 1 |
| `$mod, é` | workspace 2 |
| `$mod, "` | workspace 3 |
| `$mod, '` | workspace 4 |
| `$mod, (` | workspace 5 |
| `$mod, §` | workspace 6 |
| `$mod, è` | workspace 7 |
| `$mod, !` | workspace 8 |
| `$mod, ç` | workspace 9 |
| `$mod, à` | workspace 10 |
| `$mod+SHIFT, <same>` | move window to that workspace |
| `$mod, Tab` | next workspace |
| `$mod+SHIFT, Tab` | previous workspace |

The same set is mirrored on the numpad (`$mod, KP_End` → ws 1, etc.).

## Window movement

| Bind | Action |
|--|--|
| `$mod, ←/→/↑/↓` | move focus |
| `$mod + LMB drag` | move window |
| `$mod + RMB drag` | resize window |

## Multi-monitor swap

| Bind | Action |
|--|--|
| `$mod+CTRL, ←` | HDMI-A-1 primary (left), eDP-1 right |
| `$mod+CTRL, →` | eDP-1 primary (left), HDMI-A-1 right |

## Audio (with OSD)

| Key | Action |
|--|--|
| `XF86AudioRaiseVolume` | +5% sink volume + OSD pop |
| `XF86AudioLowerVolume` | −5% sink volume + OSD pop |
| `XF86AudioMute` | toggle sink mute + OSD pop |
| `XF86AudioMicMute` | toggle mic mute + `notify-send` |
| `CTRL + XF86AudioMute` | same as MicMute (legacy chord) |

Wrappers live in `keybindings.nix` (`pkgs.writeShellScript` derivations)
and call `qs ipc call osd showVolume` after the value change.

## Brightness (with OSD)

| Key | Action |
|--|--|
| `XF86MonBrightnessUp` | +5% backlight + OSD pop |
| `XF86MonBrightnessDown` | −5% backlight + OSD pop |

## Media

| Key | Action |
|--|--|
| `XF86AudioPlay` | playerctl play-pause |
| `XF86AudioPrev` | playerctl previous |
| `XF86AudioNext` | playerctl next |

## Hyprlock screen (when locked)

- Live screen blur (`background.path = screenshot`, 4 passes).
- Big top-right clock, date underneath.
- Three RSS headlines bottom-left, rotated every 5 minutes via `cmd[update:300000] qs-rss line N`. Same selection as the popup until either reaches its 15-min TTL.
- Password field centered (`input-field`). Type → Enter → unlock.

## Where things live

```
flake.nix                                         nixosConfigurations.nixos-work
settings.nix                                      username / desktop / theme
configurations/
  nixos.nix                                       host-specific (hostname, kernel, TLP)
  default.nix                                     cross-host base (locale, kb, DNS)
  desktop-environment/hyprland.nix                wires hyprland + quickshell
  themes/mocha.nix                                Stylix + base16 wiring
  packages/
    system/                                       doas, docker, firewall, pipewire, tailscale, …
    user/
      default.nix                                 sharedModules + media bundle
      rss.nix                                     qs-rss tool + default feeds
      hyprland/
        default.nix                               core hyprland + cliphist watchers
        keybindings.nix                           all binds (see above)
        visual.nix, hyprlock.nix, laptop/         the rest
      quickshell/
        default.nix                               programs.quickshell wrapper
        hyprland.nix                              + hyprland-session.target
        configs/bar/
          shell.qml                               root + GlobalShortcuts + IpcHandlers
          Bar.qml                                 per-monitor top panel
          Launcher.qml                            O3 (DesktopEntries)
          QuickNote.qml                           D6
          Clipboard.qml                           D5 (cliphist)
          NixShells.qml                           nix-shell launcher tiles
          PowerMenu.qml                           D4
          AudioMixer.qml                          D2 (Pipewire)
          NetworkPicker.qml                       D3 (iwd / iwctl)
          Osd.qml                                 D7
          RssReader.qml                           qs-rss popup
```

## qs-rss CLI (for hacking)

```sh
qs-rss pick --n 8 --format json     # what the popup uses
qs-rss line 0                       # what hyprlock labels use; Pango-marked
qs-rss dismiss <article-id>         # mark as read; popup does this on click
qs-rss refresh                      # force refetch + reroll selection
```

State files (delete to reset):

- `~/.cache/quickshell/rss-articles.json`   — feed cache (15 min)
- `~/.cache/quickshell/rss-selection.json`  — current N picks (15 min)
- `~/.local/state/quickshell/rss-dismissed.txt` — dismissed IDs

## Known limitations / things to watch first time

1. **NetworkPicker** can't do first-time secured connections — use `iwctl
   station <iface> connect <SSID>` once on CLI so iwd stores the
   passphrase, then the GUI works.
2. **DesktopEntries icons** depend on Stylix's GTK icon theme being active.
   Blank icons → check `gsettings`/`gtk-icon-theme-name`.
3. **AudioMixer auto-refresh** assumes `ObjectModel.valuesChanged` fires.
   If new playback streams don't show up, close + reopen, or replace the
   `Connections` block with a polling Timer.
4. **`qs` on PATH from Hyprland** — the OSD wrappers in `keybindings.nix`
   call `qs ipc call osd …`. If the OSD never pops, replace `qs` in the
   `writeShellScript` bodies with `${pkgs.quickshell}/bin/qs`.
5. **`qs-rss` first run is slow** — `feedparser` fetches every URL
   sequentially. If hyprlock labels stay empty for 10+ seconds, that's
   fine; subsequent re-locks read from cache instantly.
