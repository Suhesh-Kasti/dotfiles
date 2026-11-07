# dotfiles

Config snapshot for this machine, managed as plain files under `home/`, which mirrors
`$HOME`. Copy-based (no symlinks), so applications that rewrite their own configs
(KDE especially) cannot break the links.

## Layout

```
home/                 mirrors $HOME exactly
install.sh            copy repo -> $HOME (backs up existing files first)
save.sh               copy $HOME -> repo (sync live edits / add new files)
.gitignore            blocks secrets and machine state
```

## Fresh machine

```bash
git clone <your-repo-url> ~/dotfiles
cd ~/dotfiles
./install.sh
exec zsh
```

`install.sh` copies every file under `home/` into `$HOME`, saving anything it replaces to
`~/.dotfiles-backup-<timestamp>/`. `foot.ini.template` is rendered with your `$HOME`, so
the absolute paths in it work on a different username.

After installing, log in to the tools that need their own state:

```bash
cmd login                 # Command Code (config/skills are tracked, auth.json is not)
herdr update              # install the herdr binary (not tracked)
herdr config check
```

## Saving changes

Edit the live configs as normal, then sync them back into the repo:

```bash
cd ~/dotfiles
./save.sh                          # sync every tracked file
./save.sh ~/.config/foo/bar.conf   # add or refresh a specific file/directory
git add -A
git commit -m "update configs"
git push
```

`save.sh` never deletes anything from the repo; it overwrites tracked files and stages them.

## Push to GitHub (first time)

Create an empty repo on GitHub (no README), then:

```bash
cd ~/dotfiles
git remote add origin git@github.com:<your-user>/dotfiles.git   # or https://...
git branch -M main
git push -u origin main
```

## Tracked

- Shell: `.zshrc`, `.p10k.zsh`, `.bashrc`, `.bash_profile`, `.gitconfig`
- Terminal: `.config/foot/foot.ini` (template), `.config/alacritty`, herdr `config.toml`
- Herdr helpers: `herdr-start`, `herdr-sessions`, `herdr-pentest`, `herdr-snap`
- Editor: `.config/nvim` (NvChad starter base, `lazy-lock.json` included)
- Desktop: KDE `kdeglobals`, `kwinrc`, `kwinrulesrc`, `kglobalshortcutsrc`, `kcminputrc`,
  GTK 3/4 theme files and assets, Kvantum config, `mimeapps.list`
- System: `environment.d/gaming.conf`, `libinput-gestures.conf`
- Apps: fish config, fastfetch config/art, feroxbuster config
- Command Code: `config.json`, `mcp.json`, `trusted-hooks.json`, `skills/`, `taste/`

## Never tracked

`.ssh/`, `.vpn/` (contains VPN credentials), `.aws/`, `.gnupg/`, browser profiles,
Steam, Wine, `.commandcode/auth.json`, `.commandcode/history.jsonl`, `.commandcode/projects/`,
`cache/`, `logs/`, `file-history/`, `plans/`, `telemetry-install-id`, the herdr binary,
and KDE machine state such as `kwinoutputconfig.json` and activity/applet configs.
The `.gitignore` enforces these.
