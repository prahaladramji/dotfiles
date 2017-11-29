# Configuration files for my current setup
Install stow and use stow to manage symlinks or copy files manually.

### Basic usage
```
git clone git@github.com:prahaladramji/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow <config-folder-name>
```

### Stow from a different folder to a different target
`stow -d /path/to/dotfiles -t /path/to/target <config-folder-name>`

### In order to restow
`stow -R <config-folder-name>`
