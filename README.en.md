# OpenMD for Linux (unofficial build)

Prebuilt Linux x86_64 packages for [OpenMD](https://github.com/MuLiuSaMa/OpenMD) — a fast, clean, distraction-free Markdown reader built with Tauri 2 + React.

> **Original author**: [MuLiuSaMa](https://github.com/MuLiuSaMa) · **Upstream**: <https://github.com/MuLiuSaMa/OpenMD>
> This is an **unofficial** Linux build. All credit for the application belongs to the original author. Licensed under GPL-3.0.

## Why this repo

Upstream ships `OpenMD_1.0.4_Windows_x86_64.exe` only. There is no Linux artifact and no Linux file-association registration. This repo provides:

- `OpenMD_1.0.4_amd64.deb` — Debian/Ubuntu package
- `OpenMD_1.0.4_amd64.AppImage` — distro-agnostic, no root needed
- desktop entry + MIME mapping so double-clicking `.md` opens OpenMD
- a reproducible build log (`BUILD.md`) and the single one-line source patch we needed

## Install

```bash
# Debian / Ubuntu
sudo apt install ./OpenMD_1.0.4_amd64.deb

# or AppImage
chmod +x OpenMD_1.0.4_amd64.AppImage && ./OpenMD_1.0.4_amd64.AppImage notes.md

# make .md open with OpenMD by default
./scripts/install.sh            # deb already installed
./scripts/install.sh --appimage # for the AppImage flavour
```

Verify:

```bash
xdg-mime query default text/markdown   # -> OpenMD.desktop
gio open notes.md                      # opens in OpenMD
```

## What works

Rendered preview / source view, TOC with scroll sync, tabs, theme switch, font size, instant editing, recent files, and single-instance file forwarding (opening a second file reuses the running window).

## Build it yourself

See [BUILD.md](BUILD.md). Short version:

```bash
sudo apt install build-essential libssl-dev libgtk-3-dev libwebkit2gtk-4.1-dev \
     libjavascriptcoregtk-4.1-dev libsoup-3.0-dev libayatana-appindicator3-dev \
     librsvg2-dev libxdo-dev pkg-config
curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal
npm install && npx vite build
npx tauri build
```

One patch is required: `npm install` resolves `@tauri-apps/plugin-clipboard-manager` to 2.5.0 while `Cargo.lock` pins the Rust crate at 2.4.1, and Tauri aborts on the mismatch. See `patches/0001-pin-clipboard-plugin-to-2.4.1.patch`.

## Notes / limitations

- Tray icon needs the AppIndicator extension on GNOME.
- The app sends a one-time `{version, os}` ping to `nexbox.cn/api/statistics` on first launch (upstream behaviour, untouched).
- Upstream's auto-updater targets GitCode releases and has no Linux channel; upgrade from this repo instead.
- `libfuse2` (`libfuse2t64` on 24.04) is required by the AppImage on some systems.

## License & credits

GPL-3.0, same as upstream. See [LICENSE](LICENSE) and [CREDITS.md](CREDITS.md). Corresponding source: upstream tree + the single patch, documented in [CHANGES.md](CHANGES.md).
