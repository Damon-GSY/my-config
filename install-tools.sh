#!/usr/bin/env bash
# ============================================================
#  一键安装常用 CLI 工具 + 自动配置 alias
#  jq, ripgrep, fd, zoxide, btop, fish, starship, yazi
#  支持 Ubuntu/Debian, macOS (Homebrew), Fedora, Arch Linux
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
    if [[ "$OSTYPE" == "darwin"* ]]; then
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

# ── macOS 前置检查 ──────────────────────────────────────────
ensure_brew() {
    if [[ "$OS" == "macos" ]] && ! command -v brew &>/dev/null; then
        warn "未检测到 Homebrew，正在安装..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        info "Homebrew 安装完成"
    fi
}

# ── 通用: 检查是否已安装 ────────────────────────────────────
installed() { command -v "$1" &>/dev/null; }

# ── 确认是否首次运行 (避免重复写配置) ──────────────────────
CONFIG_BACKUP_SUFFIX=".bak.$(date +%Y%m%d%H%M%S)"

backup_config() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp "$file" "${file}${CONFIG_BACKUP_SUFFIX}"
        warn "已备份 $file → ${file}${CONFIG_BACKUP_SUFFIX}"
    fi
}

# ═══════════════════════════════════════════════════════════════
#  安装各工具
# ═══════════════════════════════════════════════════════════════

# ── jq ───────────────────────────────────────────────────────
install_jq() {
    if installed jq; then warn "jq 已存在，跳过"; return 0; fi
    step "安装 jq ..."
    case "$OS" in
        debian)  sudo apt-get update -qq && sudo apt-get install -y -qq jq ;;
        macos)   brew install jq ;;
        fedora)  sudo dnf install -y jq ;;
        arch)    sudo pacman -S --noconfirm jq ;;
    esac
    info "jq 安装完成"
}

# ── ripgrep (rg) ─────────────────────────────────────────────
install_ripgrep() {
    if installed rg; then warn "ripgrep 已存在，跳过"; return 0; fi
    step "安装 ripgrep ..."
    case "$OS" in
        macos)   brew install ripgrep ;;
        debian)
            # 官方推荐从 GitHub release 下载 .deb（版本更新）
            step "从 GitHub Release 下载 ripgrep .deb ..."
            RG_VERSION=$(curl -sL https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep -oP '"tag_name":\s*"v\K[^"]+')
            curl -sLO "https://github.com/BurntSushi/ripgrep/releases/download/${RG_VERSION}/ripgrep_${RG_VERSION}-1_amd64.deb"
            sudo dpkg -i "ripgrep_${RG_VERSION}-1_amd64.deb"
            rm -f "ripgrep_${RG_VERSION}-1_amd64.deb"
            ;;
        fedora)  sudo dnf install -y ripgrep ;;
        arch)    sudo pacman -S --noconfirm ripgrep ;;
    esac
    info "ripgrep 安装完成"
}

# ── fd ───────────────────────────────────────────────────────
install_fd() {
    if installed fd; then warn "fd 已存在，跳过"; return 0; fi
    step "安装 fd ..."
    case "$OS" in
        macos)   brew install fd ;;
        debian)
            # Debian/Ubuntu 包名是 fdfind，安装后创建 fd → fdfind 的符号链接
            sudo apt-get update -qq && sudo apt-get install -y -qq fd-find
            sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
            info "创建符号链接: fdfind → fd"
            ;;
        fedora)  sudo dnf install -y fd-find ;;
        arch)    sudo pacman -S --noconfirm fd ;;
    esac
    info "fd 安装完成"
}

# ── zoxide ───────────────────────────────────────────────────
install_zoxide() {
    if installed zoxide; then warn "zoxide 已存在，跳过"; return 0; fi
    step "安装 zoxide ..."
    case "$OS" in
        macos)   brew install zoxide ;;
        debian)
            # Debian/Ubuntu 无官方 apt 包，使用官方安装脚本
            curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
            ;;
        fedora)  sudo dnf install -y zoxide ;;
        arch)    sudo pacman -S --noconfirm zoxide ;;
    esac
    # 确保 zoxide 在 PATH 中
    if ! installed zoxide && [[ -f "$HOME/.local/bin/zoxide" ]]; then
        export PATH="$HOME/.local/bin:$PATH"
    fi
    info "zoxide 安装完成"
}

# ── btop ─────────────────────────────────────────────────────
install_btop() {
    if installed btop; then warn "btop 已存在，跳过"; return 0; fi
    step "安装 btop ..."
    case "$OS" in
        macos)   brew install btop ;;
        debian)
            # Ubuntu 24.04+ 有 btop 包，旧版从 release 下载编译
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
            ;;
        fedora)  sudo dnf install -y btop ;;
        arch)    sudo pacman -S --noconfirm btop ;;
    esac
    info "btop 安装完成"
}

# ── fish ─────────────────────────────────────────────────────
install_fish() {
    if installed fish; then warn "fish 已存在，跳过"; return 0; fi
    step "安装 fish ..."
    case "$OS" in
        macos)   brew install fish ;;
        debian)
            sudo apt-get update -qq && sudo apt-get install -y -qq fish
            ;;
        fedora)  sudo dnf install -y fish ;;
        arch)    sudo pacman -S --noconfirm fish ;;
    esac
    info "fish 安装完成"
}

# ── starship ─────────────────────────────────────────────────
install_starship() {
    if installed starship; then warn "starship 已存在，跳过"; return 0; fi
    step "安装 starship ..."
    case "$OS" in
        macos)
            brew install starship
            ;;
        debian|fedora|arch)
            # 官方推荐安装脚本，全平台通用
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
            # 使用 yazi 官方安装脚本
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

# 追加行到文件（如果不存在）
append_line() {
    local file="$1" line="$2"
    if [[ ! -f "$file" ]]; then
        mkdir -p "$(dirname "$file")"
        echo "$line" >> "$file"
        return 0
    fi
    grep -qxF "$line" "$file" 2>/dev/null || echo "$line" >> "$file"
}

# ── 配置 bash ────────────────────────────────────────────────
configure_bash() {
    step "配置 bash ..."
    local rc="$HOME/.bashrc"
    backup_config "$rc"

    # alias
    append_line "$rc" "alias ls='ls --color=auto'"
    append_line "$rc" "alias ll='ls -alF'"
    append_line "$rc" "alias la='ls -A'"
    append_line "$rc" "alias l='ls -CF'"

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

    # alias (fish 用 function 实现缩写)
    append_line "$conf" "abbr -a ll 'ls -alF'"
    append_line "$conf" "abbr -a la 'ls -A'"
    append_line "$conf" "abbr -a l 'ls -CF'"

    # zoxide
    if installed zoxide; then
        append_line "$conf" 'zoxide init fish | source'
    fi

    # starship (官方推荐 fish 写法)
    if installed starship; then
        append_line "$conf" 'starship init fish | source'
    fi

    # yazi wrapper (可选：退出后 cd 到 yazi 最后浏览的目录)
    if installed yazi; then
        if ! grep -q "yazi" "$conf" 2>/dev/null; then
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

    # 添加 ~/.local/bin 到 PATH (zoxide install script 可能装到这里)
    append_line "$conf" 'fish_add_path --path ~/.local/bin 2>/dev/null'

    info "fish 配置完成"
}

# ── 配置 starship.toml（极简配置）────────────────────────────
configure_starship() {
    if ! installed starship; then return 0; fi

    local starship_conf="$HOME/.config/starship.toml"
    if [[ -f "$starship_conf" ]]; then
        warn "starship.toml 已存在，跳过配置"
        return 0
    fi

    step "创建 starship 配置 ..."
    mkdir -p "$(dirname "$starship_conf")"
    cat > "$starship_conf" << 'STARSHIP_EOF'
# Starship 配置 - 极简实用风格

# 用 → 替代默认的 ❯ 字符（兼容性更好）
[character]
success_symbol = "[→](bold green)"
error_symbol = "[→](bold red)"

# 目录
[directory]
style = "bold cyan"
truncation_length = 3
truncate_to_repo = true

# Git
[git_branch]
symbol = " "
style = "bold purple"

[git_status]
style = "bold red"

# 语言
[python]
symbol = " "
[rust]
symbol = " "
[nodejs]
symbol = " "
[go]
symbol = " "

# 命令耗时（超过 3 秒才显示）
[cmd_duration]
min_time = 3_000
format = "took [$duration](bold yellow) "
STARSHIP_EOF
    info "starship 配置完成 → ~/.config/starship.toml"
}

# ── 提示 Nerd Font ──────────────────────────────────────────
check_nerd_font() {
    if ! installed starship; then return 0; fi
    echo ""
    warn "Starship 需要 Nerd Font 才能正确显示图标"
    echo "  推荐安装: FiraCode Nerd Font 或 JetBrainsMono Nerd Font"
    echo "  下载地址: https://www.nerdfonts.com/font-downloads"
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
    ensure_brew
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
    echo "──────────── 配置 ─────────────"
    echo ""

    # ── 配置 ──
    configure_bash
    configure_fish
    configure_starship
    check_nerd_font

    echo ""
    echo "=========================================="
    info "全部安装配置完成！"
    echo ""
    echo "后续操作："
    echo "  1. 安装 Nerd Font（Starship 图标显示需要）"
    echo "     → https://www.nerdfonts.com/font-downloads"
    echo ""
    echo "  2. 将 fish 设为默认 shell（可选）："
    echo "     chsh -s \$(which fish)"
    echo ""
    echo "  3. 重新打开终端使配置生效"
    echo ""
    echo "配置文件位置："
    echo "  Bash   → ~/.bashrc"
    echo "  Fish   → ~/.config/fish/config.fish"
    echo "  Starship → ~/.config/starship.toml"
    echo "=========================================="
}

main "$@"
