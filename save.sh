#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO"

save_one() {
  local rel="$1"
  local src="$HOME/$rel"
  local dest="$REPO/home/$rel"

  if [[ ! -e "$src" ]]; then
    printf 'skip (missing): %s\n' "$src"
    return 0
  fi

  if [[ "$rel" == ".config/foot/foot.ini" ]]; then
    dest="$dest.template"
    mkdir -p "$(dirname "$dest")"
    sed "s|$HOME|@HOME@|g" "$src" >"$dest"
  elif [[ -d "$src" ]]; then
    mkdir -p "$dest"
    cp -a "$src/." "$dest/"
    find "$dest" -name .git -type d -prune -exec rm -rf {} + 2>/dev/null || true
  else
    mkdir -p "$(dirname "$dest")"
    cp -p "$src" "$dest"
  fi
  printf 'saved %s\n' "$rel"
}

if [[ $# -gt 0 ]]; then
  for path in "$@"; do
    abs="$(realpath -m "$path")"
    if [[ "$abs" != "$HOME/"* ]]; then
      printf 'outside $HOME, refused: %s\n' "$path" >&2
      exit 1
    fi
    save_one "${abs#"$HOME"/}"
  done
else
  while IFS= read -r repo_rel; do
    rel="${repo_rel#home/}"
    rel="${rel%.template}"
    save_one "$rel"
  done < <(git ls-files home)
fi

git add -A home
printf '\nStaged changes. Review with: git -C %s status\n' "$REPO"
