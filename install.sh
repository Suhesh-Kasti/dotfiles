#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$REPO/home"
[[ -d "$SRC" ]] || { printf 'missing %s\n' "$SRC" >&2; exit 1; }

BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
count=0

while IFS= read -r -d '' file; do
  rel="${file#"$SRC"/}"
  live_rel="${rel%.template}"
  out="$HOME/$live_rel"
  mkdir -p "$(dirname "$out")"

  if [[ -e "$out" || -L "$out" ]]; then
    mkdir -p "$BACKUP/$(dirname "$live_rel")"
    cp -a "$out" "$BACKUP/$live_rel"
  fi

  if [[ "$file" == *.template ]]; then
    sed "s|@HOME@|$HOME|g" "$file" >"$out"
  else
    cp -p "$file" "$out"
  fi
  count=$((count + 1))
done < <(find "$SRC" -type f -print0)

printf 'Installed %d files into %s\n' "$count" "$HOME"
[[ -d "$BACKUP" ]] && printf 'Existing files backed up to %s\n' "$BACKUP"
printf 'Reload your shell with: exec zsh\n'
