# My Config

Personal configuration files managed by [chezmoi](https://www.chezmoi.io/).

## Quick Start

```bash
# Install chezmoi
brew install chezmoi           # macOS
sh -c "$(curl -fsLS get.chezmoi.io)"  # Linux

# Apply configs
chezmoi init Damon-GSY/my-config --apply
```

## What's Managed

- **nvim** — LazyVim config (`~/.config/nvim/`)
- **tmux** — tmux + TPM plugins (`~/.config/tmux/`)
- **lsd** — lsd config (`~/.config/lsd/`)
- **karabiner** — Karabiner-Elements (macOS only)

## Tools

Install script runs automatically on first apply (`run_once_install-tools.sh`):
- fish, starship, yazi, ripgrep, fd, zoxide, jq, btop, eza

## Structure

```
├── dot_config/          → ~/.config/
│   ├── nvim/
│   ├── tmux/
│   ├── lsd/
│   └── karabiner/       (macOS only)
├── .chezmoiignore       # OS-specific exclusions
├── .chezmoiscripts/     # Run-once scripts
└── README.md
```
