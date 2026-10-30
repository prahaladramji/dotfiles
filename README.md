# dotfiles

This repo holds shared dotfiles for personal and work devices, managed using [chezmoi](https://www.chezmoi.io/user-guide/setup/).

Work-specific configurations live in a separate overlay repository (`~/.local/share/dotfiles-work`) and plug in automatically via drop-in directories (`~/.config/zsh/conf.d/`, `~/.ssh/config.d/`, and optional Neovim plugin detection) so zero work configurations ever touch this repository.

## Setup

### 1. Common Configs (All Machines)

```sh
chezmoi init --apply --verbose git@github.com:prahaladramji/dotfiles.git
```

### 2. Work Overlay (Work Laptop & Cloudtop Only)

```sh
git clone <work-repo-url> ~/.local/share/dotfiles-work
dots apply
```

## Day-to-Day Commands (`dots`)

* `dots sync` — Pull and apply latest changes from both common and work overlay repos
* `dots upgrade` — Refresh external archives (`oh-my-zsh`, Zsh plugins, `nvm`) on demand
* `dots status` — Check `git status` and `chezmoi status` of both repos
* `dots diff` — Show `chezmoi diff` across both common and work overlay sources
* `dots apply` — Run `chezmoi apply` across both common and work overlay sources
* `dots work <args>` — Run any `chezmoi` command against the work overlay source (e.g., `dots work add <file>`)
* `dots cd` / `dots cd work` — Jump to the common or work overlay repo directory
