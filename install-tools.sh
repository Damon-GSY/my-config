#!/usr/bin/env bash
# ============================================================
#  一键安装常用 CLI 工具
#  jq, ripgrep, fd, zoxide, btop, fish, starship, yazi
#  支持 Ubuntu/Debian 和 macOS (Homebrew)
# ============================================================

set -euo pipefail

# ── 颜色 ─────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()  { echo -e "${GREEN}[✓]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
fail()  { echo -e "${RED}[✗]${NC} $1"; exit 1; }

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
        # Apple Silicon 路径补全
        if [[ -f /opt/homebrew/bin/brew ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
        info "Homebrew 安装完成"
    fi
}

# ── 安装函数 ─────────────────────────────────────────────────

install_via_apt() {
    local name="$1"
    if command -v "$name" &>/dev/null; then
        warn "$name 已存在，跳过"
        return 0
    fi
    echo "正在安装 $name ..."
    sudo apt-get update -qq
    sudo apt-get install -y -qq "$name" 2>/dev/null
    info "$name 安装完成"
}

install_via_brew() {
    local name="$1"
    if command -v "$name" &>/dev/null; then
        warn "$name 已存在，跳过"
        return 0
    fi
    echo "正在安装 $name ..."
    brew install "$name"
    info "$name 安装完成"
}

# ── jq ───────────────────────────────────────────────────────
install_jq() {
    case "$OS" in
        debian)  install_via_apt "jq" ;;
        macos)   install_via_brew "jq" ;;
        fedora)  sudo dnf install -y jq ;;
        arch)    sudo pacman -S --noconfirm jq ;;
    esac
}

# ── ripgrep (rg) ─────────────────────────────────────────────
install_ripgrep() {
    if command -v rg &>/dev/null; then
        warn "ripgrep 已存在，跳过"
        return 0
    fi
    case "$OS" in
        macos)   install_via_brew "ripgrep" ;;
        debian)
            # Debian 源的 rg 版本较旧，优先用 cargo 安装最新版
            if command -v cargo &>/dev/null; then
                echo "正在通过 cargo 安装 ripgrep ..."
                cargo install ripgrep
            else
                install_via_apt "ripgrep"
            fi
            ;;
        fedora)  sudo dnf install -y ripgrep ;;
        arch)    sudo pacman -S --noconfirm ripgrep ;;
    esac
    info "ripgrep 安装完成"
}

# ── fd ───────────────────────────────────────────────────────
install_fd() {
    if command -v fd &>/dev/null; then
        warn "fd 已存在，跳过"
        return 0
    fi
    case "$OS" in
        macos)   install_via_brew "fd" ;;
        debian)
            if command -v cargo &>/dev/null; then
                echo "正在通过 cargo 安装 fd ..."
                cargo install fd-find
            else
                install_via_apt "fd-find"
            fi
            ;;
        fedora)  sudo dnf install -y fd-find ;;
        arch)    sudo pacman -S --noconfirm fd ;;
    esac
    info "fd 安装完成"
}

# ── zoxide ───────────────────────────────────────────────────
install_zoxide() {
    if command -v zoxide &>/dev/null; then
        warn "zoxide 已存在，跳过"
        return 0
    fi
    case "$OS" in
        macos)   install_via_brew "zoxide" ;;
        debian)
            if command -v cargo &>/dev/null; then
                echo "正在通过 cargo 安装 zoxide ..."
                cargo install zoxide
            else
                echo "正在通过官方脚本安装 zoxide ..."
                curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
            fi
            ;;
        fedora)  sudo dnf install -y zoxide ;;
        arch)    sudo pacman -S --noconfirm zoxide ;;
    esac
    info "zoxide 安装完成"
}

# ── btop ─────────────────────────────────────────────────────
install_btop() {
    if command -v btop &>/dev/null; then
        warn "btop 已存在，跳过"
        return 0
    fi
    case "$OS" in
        macos)   install_via_brew "btop" ;;
        debian)  install_via_apt "btop" ;;
        fedora)  sudo dnf install -y btop ;;
        arch)    sudo pacman -S --noconfirm btop ;;
    esac
    info "btop 安装完成"
}

# ── fish ─────────────────────────────────────────────────────
install_fish() {
    if command -v fish &>/dev/null; then
        warn "fish 已存在，跳过"
        return 0
    fi
    case "$OS" in
        macos)   install_via_brew "fish" ;;
        debian)
            # Ubuntu 24.04+ 直接有 fish，旧版需加 PPA
            sudo apt-get update -qq
            if apt-cache show fish 2>/dev/null | grep -q "Package:"; then
                sudo apt-get install -y -qq fish
            else
                echo "正在添加 fish PPA ..."
                sudo apt-add-repository -y ppa:fish-shell/release-3
                sudo apt-get update -qq
                sudo apt-get install -y -qq fish
            fi
            ;;
        fedora)  sudo dnf install -y fish ;;
        arch)    sudo pacman -S --noconfirm fish ;;
    esac
    info "fish 安装完成"
}

# ── starship ─────────────────────────────────────────────────
install_starship() {
    if command -v starship &>/dev/null; then
        warn "starship 已存在，跳过"
        return 0
    fi
    echo "正在通过官方脚本安装 starship ..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    info "starship 安装完成"
}

# ── yazi ─────────────────────────────────────────────────────
install_yazi() {
    if command -v yazi &>/dev/null; then
        warn "yazi 已存在，跳过"
        return 0
    fi
    case "$OS" in
        macos)   install_via_brew "yazi" ;;
        debian)
            echo "正在通过官方脚本安装 yazi ..."
            curl -fsSL https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-musl.zip \
                -o /tmp/yazi.zip
            unzip -qo /tmp/yazi.zip -d /tmp/yazi
            sudo mv /tmp/yazi/yazi-* /usr/local/bin/yazi
            sudo chmod +x /usr/local/bin/yazi
            rm -rf /tmp/yazi /tmp/yazi.zip
            ;;
        fedora)  sudo dnf install -y yazi ;;
        arch)    sudo pacman -S --noconfirm yazi ;;
    esac
    info "yazi 安装完成"
}

# ── 主流程 ───────────────────────────────────────────────────
main() {
    echo "=========================================="
    echo "  CLI 工具一键安装脚本"
    echo "  jq · ripgrep · fd · zoxide · btop"
    echo "  fish · starship · yazi"
    echo "=========================================="
    echo ""

    detect_os
    ensure_brew
    echo ""

    install_jq
    install_ripgrep
    install_fd
    install_zoxide
    install_btop
    install_fish
    install_starship
    install_yazi

    echo ""
    echo "=========================================="
    info "全部安装完成！"
    echo ""
    echo "后续配置提示："
    echo "  1. 将 fish 设为默认 shell: chsh -s \$(which fish)"
    echo "  2. 在 fish config 中添加: eval \"\$(zoxide init fish)\""
    echo "  3. 在 fish config 中添加: starship init fish | source"
    echo "=========================================="
}

main "$@"
