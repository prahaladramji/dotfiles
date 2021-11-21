# My configuration files

This repository contains all my local configruation files that I share between various machines that I use.

## Quick Start

This repos uses [stow](https://github.com/aspiers/stow) to manage symlinks in the home folder.

1. Install `stow` from your os specific package manager.
2. Clone this repo to your `$HOME` directory
   ```bash
   git clone https://github.com/prahaladramji/dotfiles.git ~/dotfiles
   ```
3. Link the required configurations
   ```bash
   stow zsh
   ```
