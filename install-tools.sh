#!/usr/bin/env bash
# ============================================================
#  一键安装常用 CLI 工具 + 自动配置 alias
#  jq, ripgrep, fd, zoxide, btop, fish, starship, yazi
#
#  默认: macOS (Homebrew)
#  也支持: Ubuntu/Debian, Fedora, Arch Linux
# ============================================================

set -euo pipefail

# ── 颜色 ─────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
fail()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }
step()  { echo -e "${CYAN}[→]${NC} $1"; }

# ── 检测系统 ─────────────────────────────────────────────────
detect_os() {
    if [[ "$OSTYPE" == darwin* ]]; then
        OS="macos"
    elif command -v apt-get &>/dev/null; then
        OS="debian"
    elif command -v dnf &>/dev/null; then
        OS="fedora"
    elif command -v pacman &>/dev/null; then
        OS="arch"
    else
        fail "不支持的操作系统，请手动安装。"
    fi
    echo "检测到系统: $OS"
}

# ── 确保 Homebrew 已安装 ────────────────────────────────────
ensure_brew() {
    if ! command -v brew &>/dev/null; then
        warn "未检测到 Homebrew，正在安装..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        # Apple Silicon 路径补全
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
        fi
        info "Homebrew 安装完成"
    fi
}

# ── 通用: 检查是否已安装 ────────────────────────────────────
installed() { command -v "$1" &>/dev/null; }

# ── 追加行到文件（去重）───────────────────────────────────────
append_line() {
    local file="$1" line="$2"
    if [[ ! -f "$file" ]]; then
        mkdir -p "$(dirname "$file")"
        echo "$line" >> "$file"
        return 0
    fi
    grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

# ── 备份配置文件 ─────────────────────────────────────────────
BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"
backup_config() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp "$file" "${file}${BACKUP_SUFFIX}"
        warn "已备份 $file → ${file}${BACKUP_SUFFIX}"
    fi
}

# ═══════════════════════════════════════════════════════════════
#  安装各工具
# ═══════════════════════════════════════════════════════════════

# ── Homebrew 统一安装 (macOS 主路径) ─────────────────────────
install_via_brew() {
    local name="$1"
    if installed "$name"; then warn "$name 已存在，跳过"; return 0; fi
    step "brew install $name ..."
    brew install "$name"
    info "$name 安装完成"
}

# ── jq ───────────────────────────────────────────────────────
install_jq() {
    case "$OS" in
        macos)   install_via_brew "jq" ;;
        debian)  sudo apt-get update -qq && sudo apt-get install -y -qq jq ;;
        fedora)  sudo dnf install -y jq ;;
        arch)    sudo pacman -S --noconfirm jq ;;
    esac
}

# ── ripgrep (rg) ─────────────────────────────────────────────
install_ripgrep() {
    if installed rg; then warn "ripgrep 已存在，跳过"; return 0; fi
    case "$OS" in
        macos)   install_via_brew "ripgrep" ;;
        debian)
            step "从 GitHub Release 下载 ripgrep .deb ..."
            RG_VERSION=$(curl -sL https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
            curl -sLO "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep_${RG_VERSION}-1_amd64.deb"
            sudo dpkg -i "ripgrep_${RG_VERSION}-1_amd64.deb"
            rm -f "ripgrep_${RG_VERSION}-1_amd64.deb"
            info "ripgrep 安装完成"
            ;;
        fedora)  sudo dnf install -y ripgrep ;;
        arch)    sudo pacman -S --noconfirm ripgrep ;;
    esac
}

# ── fd ───────────────────────────────────────────────────────
install_fd() {
    if installed fd; then warn "fd 已存在，跳过"; return 0; fi
    case "$OS" in
        macos)   install_via_brew "fd" ;;
        debian)
            sudo apt-get update -qq && sudo apt-get install -y -qq fd-find
            sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
            info "fd 安装完成 (fdfind → fd)"
            ;;
        fedora)  sudo dnf install -y fd-find ;;
        arch)    sudo pacman -S --noconfirm fd ;;
    esac
}

# ── zoxide ───────────────────────────────────────────────────
install_zoxide() {
    if installed zoxide; then warn "zoxide 已存在，跳过"; return 0; fi
    case "$OS" in
        macos)   install_via_brew "zoxide" ;;
        debian)
            curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
            if ! installed zoxide && [[ -f "$HOME/.local/bin/zoxide" ]]; then
                export PATH="$HOME/.local/bin:$PATH"
            fi
            info "zoxide 安装完成"
            ;;
        fedora)  sudo dnf install -y zoxide ;;
        arch)    sudo pacman -S --noconfirm zoxide ;;
    esac
}

# ── btop ─────────────────────────────────────────────────────
install_btop() {
    if installed btop; then warn "btop 已存在，跳过"; return 0; fi
    case "$OS" in
        macos)   install_via_brew "btop" ;;
        debian)
            if apt-cache show btop &>/dev/null 2>&1; then
                sudo apt-get update -qq && sudo apt-get install -y -qq btop
            else
                step "从 GitHub Release 下载 btop ..."
                BTOP_VERSION=$(curl -sL https://api.github.com/repos/aristocratos/btop/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
                curl -sLO "https://github.com/aristocratos/btop/releases/download/v${BTOP_VERSION}/btop-${BTOP_VERSION}-x86_64-linux-musl.tbz"
                tar xf "btop-${BTOP_VERSION}-x86_64-linux-musl.tbz"
                (cd "btop-${BTOP_VERSION}-x86_64-linux-musl" && sudo make install)
                rm -rf "btop-${BTOP_VERSION}-x86_64-linux-musl.tbz" "btop-${BTOP_VERSION}-x86_64-linux-musl"
            fi
            info "btop 安装完成"
            ;;
        fedora)  sudo dnf install -y btop ;;
        arch)    sudo pacman -S --noconfirm btop ;;
    esac
}

# ── fish ─────────────────────────────────────────────────────
install_fish() {
    if installed fish; then warn "fish 已存在，跳过"; return 0; fi
    case "$OS" in
        macos)   install_via_brew "fish" ;;
        debian)  sudo apt-get update -qq && sudo apt-get install -y -qq fish ;;
        fedora)  sudo dnf install -y fish ;;
        arch)    sudo pacman -S --noconfirm fish ;;
    esac
}

# ── starship ─────────────────────────────────────────────────
install_starship() {
    if installed starship; then warn "starship 已存在，跳过"; return 0; fi
    step "安装 starship ..."
    case "$OS" in
        macos)   brew install starship ;;
        debian|fedora|arch)
            curl -sS https://starship.rs/install.sh | sh -s -- -y
            ;;
    esac
    info "starship 安装完成"
}

# ── yazi ─────────────────────────────────────────────────────
install_yazi() {
    if installed yazi; then warn "yazi 已存在，跳过"; return 0; fi
    step "安装 yazi ..."
    case "$OS" in
        macos)   brew install yazi ;;
        debian)
            curl -fsSL https://raw.githubusercontent.com/sxyazi/yazi/main/install.sh | bash
            ;;
        fedora)
            sudo dnf copr enable atim/yazi -y && sudo dnf install -y yazi
            ;;
        arch)    sudo pacman -S --noconfirm yazi ;;
    esac
    info "yazi 安装完成"
}

# ═══════════════════════════════════════════════════════════════
#  配置 shell
# ═══════════════════════════════════════════════════════════════

# ── 配置 zsh (macOS 默认 shell) ─────────────────────────────
configure_zsh() {
    step "配置 zsh ..."
    local rc="$HOME/.zshrc"
    backup_config "$rc"

    # macOS brew 补全 PATH
    if [[ "$OS" == "macos" ]] && [[ -d /opt/homebrew/bin ]]; then
        append_line "$rc" 'eval "$(/opt/homebrew/bin/brew shellenv)"'
    fi

    # alias
    append_line "$rc" "alias ls='ls --color=auto'"
    append_line "$rc" "alias ll='ls -alF'"
    append_line "$rc" "alias la='ls -A'"
    append_line "$rc" "alias l='ls -CF'"
    append_line "$rc" "alias grep='grep --color=auto'"

    # zoxide
    if installed zoxide; then
        append_line "$rc" 'eval "$(zoxide init zsh)"'
    fi

    # starship
    if installed starship; then
        append_line "$rc" 'eval "$(starship init zsh)"'
    fi

    info "zsh 配置完成"
}

# ── 配置 bash (Linux 默认 shell) ────────────────────────────
configure_bash() {
    step "配置 bash ..."
    local rc="$HOME/.bashrc"
    backup_config "$rc"

    # alias
    append_line "$rc" "alias ls='ls --color=auto'"
    append_line "$rc" "alias ll='ls -alF'"
    append_line "$rc" "alias la='ls -A'"
    append_line "$rc" "alias l='ls -CF'"
    append_line "$rc" "alias grep='grep --color=auto'"

    # zoxide
    if installed zoxide; then
        append_line "$rc" 'eval "$(zoxide init bash)"'
    fi

    # starship
    if installed starship; then
        append_line "$rc" 'eval "$(starship init bash)"'
    fi

    info "bash 配置完成"
}

# ── 配置 fish ────────────────────────────────────────────────
configure_fish() {
    if ! installed fish; then return 0; fi
    step "配置 fish ..."

    local fish_dir="$HOME/.config/fish"
    local conf="$fish_dir/config.fish"
    backup_config "$conf"
    mkdir -p "$fish_dir"

    # macOS brew PATH for fish
    if [[ "$OS" == "macos" ]] && [[ -d /opt/homebrew/bin ]]; then
        append_line "$conf" 'fish_add_path --path /opt/homebrew/bin'
    fi

    # abbr (fish 的 alias 替代)
    append_line "$conf" "abbr -a ll 'ls -alF'"
    append_line "$conf" "abbr -a la 'ls -A'"
    append_line "$conf" "abbr -a l 'ls -CF'"

    # zoxide (官方 fish 写法)
    if installed zoxide; then
        append_line "$conf" 'zoxide init fish | source'
    fi

    # starship (官方 fish 写法)
    if installed starship; then
        append_line "$conf" 'starship init fish | source'
    fi

    # yazi wrapper: 退出后 cd 到最后浏览的目录
    if installed yazi; then
        if ! grep -q "function y" "$conf" 2>/dev/null; then
            cat >> "$conf" << 'YAZI_EOF'

# yazi: 退出后 cd 到最后浏览的目录
function y
    set tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end
YAZI_EOF
        fi
    fi

    # ~/.local/bin to PATH (zoxide 等可能装到这里)
    append_line "$conf" 'fish_add_path --path ~/.local/bin 2>/dev/null'

    info "fish 配置完成"
}

# ── starship.toml（极简配置）─────────────────────────────────
configure_starship() {
    if ! installed starship; then return 0; fi

    local conf="$HOME/.config/starship.toml"
    if [[ -f "$conf" ]]; then
        warn "starship.toml 已存在，跳过配置"
        return 0
    fi

    step "创建 starship 配置 ..."
    mkdir -p "$(dirname "$conf")"
    cat > "$conf" << 'EOF'
# ── Starship 极简配置 ──

[character]
success_symbol = "[→](bold green)"
error_symbol = "[→](bold red)"

[directory]
style = "bold cyan"
truncation_length = 3
truncate_to_repo = true

[git_branch]
symbol = " "
style = "bold purple"

[git_status]
style = "bold red"

[python]
symbol = " "
[rust]
symbol = " "
[nodejs]
symbol = " "
[go]
symbol = " "

[cmd_duration]
min_time = 3_000
format = "took [$duration](bold yellow) "
EOF
    info "starship 配置完成 → ~/.config/starship.toml"
}

# ═══════════════════════════════════════════════════════════════
#  主流程
# ═══════════════════════════════════════════════════════════════
main() {
    echo "=========================================="
    echo "  CLI 工具一键安装 + 配置脚本"
    echo "  jq · ripgrep · fd · zoxide · btop"
    echo "  fish · starship · yazi"
    echo "=========================================="
    echo ""

    detect_os

    # macOS 需要 Homebrew
    if [[ "$OS" == "macos" ]]; then
        ensure_brew
    fi

    echo ""

    # ── 安装 ──
    install_jq
    install_ripgrep
    install_fd
    install_zoxide
    install_btop
    install_fish
    install_starship
    install_yazi

    echo ""
    echo "──────────── 配置 shell ─────────────"
    echo ""

    # macOS 默认 zsh，Linux 默认 bash，fish 额外配置
    if [[ "$OS" == "macos" ]]; then
        configure_zsh
    else
        configure_bash
    fi
    configure_fish
    configure_starship

    echo ""
    echo "=========================================="
    info "全部安装配置完成！"
    echo ""
    echo "后续操作："
    if [[ "$OS" == "macos" ]]; then
        echo "  1. 安装 Nerd Font（Starship 图标需要）"
        echo "     → https://www.nerdfonts.com/font-downloads"
        echo "     推荐在 iTerm2 / Terminal 中设置字体"
        echo ""
        echo "  2. 将 fish 设为默认 shell（可选）："
        echo "     chsh -s \$(which fish)"
        echo ""
        echo "  3. 重新打开终端使配置生效"
        echo ""
        echo "配置文件位置："
        echo "  zsh      → ~/.zshrc"
        echo "  fish     → ~/.config/fish/config.fish"
        echo "  starship → ~/.config/starship.toml"
    else
        echo "  1. 安装 Nerd Font（Starship 图标需要）"
        echo "     → https://www.nerdfonts.com/font-downloads"
        echo ""
        echo "  2. 将 fish 设为默认 shell（可选）："
        echo "     chsh -s \$(which fish)"
        echo ""
        echo "  3. 重新打开终端使配置生效"
        echo ""
        echo "配置文件位置："
        echo "  bash     → ~/.bashrc"
        echo "  fish     → ~/.config/fish/config.fish"
        echo "  starship → ~/.config/starship.toml"
    fi
    echo "=========================================="
}

main "$@"
