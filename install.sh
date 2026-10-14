#!/bin/sh
set -e

dir=$(cd "$(dirname "$0")" && pwd)
line="source \"$dir/sheen.zsh-theme\""
rc="${ZDOTDIR:-$HOME}/.zshrc"

if [ "$1" = "--uninstall" ]; then
  [ -f "$rc" ] || { echo "No $rc found."; exit 0; }
  tmp=$(mktemp)
  grep -vF "$line" "$rc" > "$tmp" || true
  cat "$tmp" > "$rc" && rm -f "$tmp"
  echo "Sheen removed from $rc. Open a new tab to finish."
  exit 0
fi

if grep -qF "$line" "$rc" 2>/dev/null; then
  echo "Sheen is already installed in $rc."
  exit 0
fi

printf '\n%s\n' "$line" >> "$rc"
echo "Sheen installed. Open a new tab (or run: exec zsh)."
echo "Icons need a Nerd Font: brew install --cask font-jetbrains-mono-nerd-font"
