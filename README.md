# ✨ Sheen

An animated zsh prompt for macOS. A soft light sweeps across your path, the `❯` flows through the Apple Intelligence colours, and long tasks finish with a sparkle.

```
󰉋 ~/Apple/sheen
❯ _                          ✦ took 12s ✦ · 󰘬 main status [+1]
```

## Features

- **Shimmer**: a sheen of light sweeps across the current path every few seconds
- **Glow**: `❯` flows blue → purple → pink → orange, brightens while you type, and breathes red after an error
- **Day/night palette**: warm at dawn, Apple Intelligence by day, calm indigo at night
- **Per-project colour**: every repo gets its own tint, so panes are easy to tell apart
- **Git on the right**: branch, ahead/behind, `+staged !modified ?untracked`, loaded async with a spinner in slow repos and rolling text when it changes
- **Long-task finish**: commands over 10s end with a sparkle, the Glass sound, and a notification if your terminal isn't in front
- **Transient prompt**: earlier prompts collapse to `folder ❯ command`
- **Respects your Mac**: animation stops with Reduce Motion or Low Power Mode on

No dependencies beyond zsh 5.8+ and a [Nerd Font](https://www.nerdfonts.com) for the icons.

## Install

```bash
git clone git@github.com:abhi21git/sheen.git ~/.sheen && ~/.sheen/install.sh
```

Then open a new tab.

**oh-my-zsh:** either set `ZSH_THEME=""` and use the line above, or copy `sheen.zsh-theme` into `$ZSH_CUSTOM/themes/` and set `ZSH_THEME="sheen"`.

## Options

| Variable | Effect |
|---|---|
| `SHEEN_QUIET=1` | No sound or notification when long tasks finish |

Set it in `~/.zshrc` before the `source` line.

## Update

```bash
git -C ~/.sheen pull
```

## Uninstall

```bash
~/.sheen/install.sh --uninstall && rm -rf ~/.sheen
```

## Notes

- Sheen uses `TRAPUSR1` for async git updates. If your config defines its own `TRAPUSR1`, one of them will win.
- Load `zsh-syntax-highlighting` after Sheen, as its docs recommend.
