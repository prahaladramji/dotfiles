# dotfiles

This repo holds shared dotfiles and cross-platform package manifests for personal and work devices, managed using [chezmoi](https://www.chezmoi.io/user-guide/setup/).

Work-specific configurations and packages live in a separate overlay repository (`~/.local/share/dotfiles-work`) and plug in automatically via drop-in directories (`~/.config/zsh/conf.d/`, `~/.ssh/config.d/`, and optional Neovim plugin detection) so zero work configurations ever touch this repository.

## Setup

### 1. Common Configs & Packages (All Machines)

On **Linux** (laptop/workstation = Sway + Waybar + SwayNC + Kanshi; `virtual` = i3 + Polybar + Dunst; `synology-nas` = headless CLI only):

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin init --apply --verbose https://github.com/prahaladramji/dotfiles.git
```

On **macOS** (after installing Homebrew, `brew install chezmoi 1password 1password-cli`):

```sh
chezmoi init --apply --verbose git@github.com:prahaladramji/dotfiles.git
```

Applying automatically installs OS/profile packages from `.chezmoidata/packages.yaml` (`brew bundle` on macOS; `dpkg-query`-guarded `apt-get`, 1Password `.deb`, and pinned Neovim on non-NAS Linux), Hack Nerd Font (`.chezmoiexternal.toml.tmpl`), VS Code settings/extensions, and desktop theme settings. Re-running `chezmoi init`/`apply` is a near-no-op when nothing has changed.

### 2. Work Overlay (Work Devices Only)

```sh
git clone <work-repo-url> ~/.local/share/dotfiles-work
dots apply
```

## Day-to-Day Commands (`dots`)

* `dots sync` — Pull and apply latest changes from both common and work overlay repos
* `dots upgrade` — Refresh external archives (`oh-my-zsh`, Zsh plugins, `nvm`, Hack Nerd Font) on demand
* `dots status` — Check `git status` and `chezmoi status` of both repos
* `dots diff` — Show `chezmoi diff` across both common and work overlay sources
* `dots apply` — Run `chezmoi apply` across both common and work overlay sources
* `dots work <args>` — Run any `chezmoi` command against the work overlay source (e.g., `dots work add <file>`)
* `dots cd` / `dots cd work` — Jump to the common or work overlay repo directory
