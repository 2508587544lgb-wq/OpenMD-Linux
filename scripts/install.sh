#!/usr/bin/env bash
# OpenMD for Linux —— 安装 / 注册 / 设为默认
# 用法：
#   ./install.sh              已装好 deb 的情况下，只做 desktop + MIME 注册
#   ./install.sh --deb        用 apt 安装同目录的 deb，再注册
#   ./install.sh --appimage   把同目录 AppImage 装到 ~/.local/bin，再注册
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$HERE")"
APPS="$HOME/.local/share/applications"
MIME_DIR=/usr/share/mime/packages

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
die() { printf '\033[1;31m错误:\033[0m %s\n' "$*" >&2; exit 1; }

MODE="${1:-}"

case "$MODE" in
  --deb)
    DEB=$(ls "$ROOT"/dist/OpenMD_*_amd64.deb 2>/dev/null | head -1)
    [ -n "$DEB" ] || die "dist/ 里找不到 deb"
    say "安装 $DEB"
    sudo apt install -y "$DEB"
    ;;
  --appimage)
    APP=$(ls "$ROOT"/dist/OpenMD_*_amd64.AppImage 2>/dev/null | head -1)
    [ -n "$APP" ] || die "dist/ 里找不到 AppImage"
    say "安装 AppImage 到 ~/.local/bin/openmd"
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$APP" "$HOME/.local/bin/openmd"
    case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo "提醒：$HOME/.local/bin 不在 PATH 里" ;; esac
    ;;
  "") ;;
  *) die "未知参数：$MODE（可用：--deb / --appimage / 空）" ;;
esac

command -v openmd >/dev/null || die "没找到 openmd 可执行文件，先装 deb 或用 --appimage"

say "注册桌面入口（含 MimeType 与 %f）"
mkdir -p "$APPS"
install -m 644 "$ROOT/packaging/OpenMD.desktop" "$APPS/OpenMD.desktop"

say "补充 .mdown / .mkd / .mdx → text/markdown"
sudo install -m 644 "$ROOT/packaging/openmd-markdown.xml" "$MIME_DIR/openmd-markdown.xml"
sudo update-mime-database /usr/share/mime

say "刷新桌面数据库"
update-desktop-database "$APPS" >/dev/null 2>&1 || true

say "设为默认打开方式"
xdg-mime default OpenMD.desktop text/markdown
xdg-mime default OpenMD.desktop text/x-markdown

printf '\n完成。验证：\n'
printf '  xdg-mime query default text/markdown   # 应输出 OpenMD.desktop\n'
printf '  gio open 某个文件.md                    # 应打开 OpenMD\n'
