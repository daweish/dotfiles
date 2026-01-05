# dotfiles

## Pre-requisites
This repo relies on GNU stow to manage symlinks

## Install the dotfiles
To use simply cd into dotfiles directory and run
`stow --dotfiles $(eza -D)`

*This assumes that you've cloned dotfiles into your home directory

You can restow files with the -R flag and also adopt conflicting files with --adopt
`stow --dotfiles -R --adopt $(eza -D)`
