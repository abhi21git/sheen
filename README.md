<p align="center">
  <img src="assets/icon.png" width="128" alt="Sheen icon">
</p>

<h1 align="center">Sheen</h1>

<p align="center">
  An animated zsh prompt for macOS.<br>
  <sub>A soft light sweeps across your path, the prompt glows while you type, and long tasks finish with a sparkle.</sub>
</p>

<br>

```text
󰉋 ~/Apple/sheen
❯ git push                                  ✦ took 12s ✦ · 󰘬 main ↑1 status [+2 ?1]
```

<br>

## What it does

<table>
  <tr>
    <td width="30%"><b>Shimmer</b></td>
    <td>A sheen of light sweeps across the current path every few seconds.</td>
  </tr>
  <tr>
    <td><b>Glow</b></td>
    <td>The <code>❯</code> flows blue → purple → pink → orange, brightens while you type, and breathes red after an error.</td>
  </tr>
  <tr>
    <td><b>Day and night</b></td>
    <td>Warm peach and gold in the morning, vivid colours by day, calm indigo and teal at night.</td>
  </tr>
  <tr>
    <td><b>Per-project colour</b></td>
    <td>Every repo gets its own tint, so terminal panes are easy to tell apart.</td>
  </tr>
  <tr>
    <td><b>Git on the right</b></td>
    <td>Branch, ahead/behind and <code>+staged !modified ?untracked</code>. Loaded in the background, with a spinner in slow repos and rolling text when something changes.</td>
  </tr>
  <tr>
    <td><b>Long-task finish</b></td>
    <td>Commands over 10 seconds end with a sparkle and the Glass sound, plus a notification if your terminal isn't in front.</td>
  </tr>
  <tr>
    <td><b>Clean scrollback</b></td>
    <td>Earlier prompts collapse to <code>folder ❯ command</code>.</td>
  </tr>
  <tr>
    <td><b>Respects your Mac</b></td>
    <td>Animation stops when Reduce Motion or Low Power Mode is on.</td>
  </tr>
</table>

Needs zsh 5.8 or later and a [Nerd Font](https://www.nerdfonts.com) for the icons. Nothing else to install.

## Install

```bash
git clone git@github.com:abhi21git/sheen.git ~/.sheen && ~/.sheen/install.sh
```

Then open a new tab.

> **Using oh-my-zsh?** Set `ZSH_THEME=""` and use the line above, or copy `sheen.zsh-theme` into `$ZSH_CUSTOM/themes/` and set `ZSH_THEME="sheen"`.

## Options

| Variable | Effect |
|---|---|
| `SHEEN_QUIET=1` | No sound or notification when long tasks finish |

Set it in `~/.zshrc` before the `source` line.

## Update and uninstall

```bash
git -C ~/.sheen pull                                     # update
~/.sheen/install.sh --uninstall && rm -rf ~/.sheen       # uninstall
```

## Notes

- Sheen uses `TRAPUSR1` for background git updates. If your config defines its own `TRAPUSR1`, only one of them will run.
- Load `zsh-syntax-highlighting` after Sheen, as its docs recommend.
