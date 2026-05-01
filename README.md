# My Config

Personal configuration files managed by [chezmoi](https://www.chezmoi.io/).

## Quick Start

```bash
# Install chezmoi
brew install chezmoi           # macOS
sh -c "$(curl -fsLS get.chezmoi.io)"  # Linux

# First-time setup (clone repo + apply)
chezmoi init Damon-GSY/my-config --apply

# Install TPM plugins (after entering tmux)
prefix + I
```

## Tools

| Tool | Description |
|------|-------------|
| yazi | Terminal file manager |
| fd | Find replacement |
| fish + starship | Shell + prompt |
| bat | Cat replacement |
| eza | Ls replacement |
| zoxide | Cd replacement |
| ripgrep | Grep replacement |
| tmux | Terminal multiplexer |
| jq | JSON processor |
| ghossty | GitHub CLI theme |
| btop | System monitor |
| chezmoi | Dotfiles manager |
| uv | Python package manager |
| fzf | Fuzzy finder |

Tools are auto-installed by `.chezmoiscripts/run_once_install-tools.sh` on first apply.

## What's Managed

| Config | Path | Notes |
|--------|------|-------|
| nvim | `~/.config/nvim/` | LazyVim |
| tmux | `~/.config/tmux/` | TPM plugins installed at runtime |
| lsd | `~/.config/lsd/` | |
| karabiner | `~/.config/karabiner/` | macOS only |

## Daily Workflow

### Sync config changes between machines

**Option A: Edit target file directly** (changes take effect immediately)

```bash
# 1. Edit (tmux/nvim/etc picks up changes right away)
vim ~/.config/tmux/tmux.conf

# 2. Sync back to chezmoi source
chezmoi re-add ~/.config/tmux/tmux.conf

# 3. Push to remote
chezmoi cd && git add -A && git commit -m "update tmux" && git push
```

**Option B: Edit in source directory** (need extra apply step)

```bash
# 1. Edit source
chezmoi cd
vim dot_config/tmux/tmux.conf

# 2. Apply to target + push
chezmoi apply
git add -A && git commit -m "update tmux" && git push
```

### Pull updates on another machine

```bash
chezmoi update   # git pull + apply, one step
```

### Add a new config file

```bash
chezmoi add ~/.config/starship.toml
chezmoi cd && git add -A && git commit -m "add starship" && git push
```

### Check status

| Command | Description |
|---------|-------------|
| `chezmoi managed` | List all managed files |
| `chezmoi diff` | Show uncommitted changes |
| `chezmoi apply` | Apply source to target |
| `chezmoi update` | Pull remote + apply |
| `chezmoi cd` | Enter source directory |
| `chezmoi re-add <path>` | Sync target change back to source |
| `chezmoi add <path>` | Start managing a new file |

## Structure

```
├── dot_config/          → ~/.config/
│   ├── nvim/
│   ├── tmux/
│   ├── lsd/
│   └── karabiner/       (macOS only)
├── .chezmoiignore       # OS-specific exclusions
├── .chezmoiscripts/     # Run-once install scripts
└── README.md
```
