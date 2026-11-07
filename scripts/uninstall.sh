#!/usr/bin/env bash
# 卸载 OpenMD for Linux 的全部痕迹（含本仓库补的注册项）
set -euo pipefail

say() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }

if dpkg -s open-md >/dev/null 2>&1; then
  say "卸载 open-md"
  sudo apt remove -y open-md
fi

if [ -f "$HOME/.local/bin/openmd" ] && command -v openmd >/dev/null 2>&1; then
  if [ "$(command -v openmd)" = "$HOME/.local/bin/openmd" ]; then
    say "删除 ~/.local/bin/openmd（AppImage 版）"
    rm -f "$HOME/.local/bin/openmd"
  fi
fi

say "移除桌面入口"
rm -f "$HOME/.local/share/applications/OpenMD.desktop"
update-desktop-database "$HOME/.local/share/applications" >/dev/null 2>&1 || true

say "移除 MIME 补充"
if [ -f /usr/share/mime/packages/openmd-markdown.xml ]; then
  sudo rm -f /usr/share/mime/packages/openmd-markdown.xml
  sudo update-mime-database /usr/share/mime
fi

say "把 text/markdown 还给系统默认（如果它还在指向已删除的 OpenMD）"
if [ "$(xdg-mime query default text/markdown 2>/dev/null)" = "OpenMD.desktop" ]; then
  FALLBACK=$(xdg-mime query default text/x-markdown 2>/dev/null || true)
  for c in org.gnome.TextEditor.desktop gedit.desktop code.desktop; do
    if [ -f "/usr/share/applications/$c" ] || [ -f "$HOME/.local/share/applications/$c" ]; then
      xdg-mime default "$c" text/markdown text/x-markdown
      say "text/markdown 现在默认 $c"
      break
    fi
  done
fi

printf '\n完成。\n'
