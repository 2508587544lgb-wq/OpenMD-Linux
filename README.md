# OpenMD for Linux（非官方构建）

[OpenMD](https://github.com/MuLiuSaMa/OpenMD) 是一款「为阅读而生的 Markdown 阅读器」：无边框窗口、沉浸阅读、渲染预览 / 源码双视图、左侧目录与滚动同步、多标签页、即时编辑。上游只提供 Windows 安装包，**这个仓库提供的是 Linux（x86_64）版本**，包含编译产物、安装脚本和完整的构建步骤。

> **原作者 / Original author**：[MuLiuSaMa](https://github.com/MuLiuSaMa) · 上游仓库：<https://github.com/MuLiuSaMa/OpenMD>
> 本项目不是上游官方发布，仅为 Linux 平台的非官方构建与打包。源码版权归原作者所有，按 **GPL-3.0** 分发。

---

## 一、这是什么

| | |
|---|---|
| 上游项目 | `MuLiuSaMa/OpenMD` —— 简洁、美观、高效的 Markdown 查看器 |
| 上游版本 | **v1.0.4**（`package.json` version = 1.0.4） |
| 本项目产物 | `OpenMD_1.0.4_amd64.deb`、`OpenMD_1.0.4_amd64.AppImage` |
| 技术栈 | Tauri 2（Rust 后端）+ React 19 / Vite 前端 + markdown-it 渲染链 |
| 构建环境 | Ubuntu 24.04.5 LTS / x86_64 / Rust 1.99.1 / Node 24.22.2 / webkit2gtk-4.1 (2.52.6) |
| 许可 | GPL-3.0（见 [LICENSE](LICENSE)） |

上游仓库自带的 prebuilt 只有 `OpenMD_1.0.4_Windows_x86_64.exe`，Linux 需要自行从源码编译。本仓库把这一步做完，并把「双击 `.md` 用 OpenMD 打开」这件上游在 Linux 上没做的事补上。

## 二、装

### 方式 A：deb（推荐，Debian / Ubuntu / Mint / Deepin）

```bash
sudo apt install ./OpenMD_1.0.4_amd64.deb
```

装完即得：

- `/usr/bin/openmd`
- 应用菜单里的 **OpenMD** 图标
- 本仓库额外补的 MIME 关联（见下）

### 方式 B：AppImage（任意发行版，免 root）

```bash
chmod +x OpenMD_1.0.4_amd64.AppImage
./OpenMD_1.0.4_amd64.AppImage 文档.md
```

部分系统需要 `libfuse2`（Ubuntu 24.04：`sudo apt install libfuse2t64`）。想给 AppImage 配双击关联，用仓库里的 `scripts/install.sh --appimage`。

### 设为 `.md` 的默认打开方式

> `scripts/install.sh` 会用 `sudo` 写 `/usr/share/mime/packages/`，所以会向你要一次密码；不想给 root 就照下面的「手动等价命令」只做用户级部分（`.mdown/.mkd/.mdx` 的补充会失效，`.md/.markdown` 仍然生效）。

deb 包本身不带 MIME 关联（上游的「文件关联」功能是 Windows 实现）。`scripts/install.sh` 会做三件事：

1. 复制 `packaging/OpenMD.desktop`（`Exec=openmd %f`，`MimeType=text/markdown;text/x-markdown`）到 `~/.local/share/applications/`
2. 安装 `packaging/openmd-markdown.xml`，把 `.mdown` / `.mkd` / `.mdx` 补充归入 `text/markdown`（系统默认只认 `.md` / `.markdown` / `.mkd`，`.mdown` 会落到 `text/plain`、`.mdx` 甚至被误判成 Genesis ROM 镜像）
3. `xdg-mime default OpenMD.desktop text/markdown text/x-markdown`

手动等价命令：

```bash
cp packaging/OpenMD.desktop ~/.local/share/applications/
sudo cp packaging/openmd-markdown.xml /usr/share/mime/packages/
sudo update-mime-database /usr/share/mime
update-desktop-database ~/.local/share/applications
xdg-mime default OpenMD.desktop text/markdown text/x-markdown
```

验证：

```bash
$ xdg-mime query filetype 笔记.md
text/markdown
$ xdg-mime query default text/markdown
OpenMD.desktop
$ gio open 笔记.md          # 等价于文件管理器里双击
```

## 三、装上之后能干什么

- 双击 `.md` / `.markdown` / `.mdown` / `.mkd` / `.mdx` 直接进 OpenMD
- **单实例转发**：已开着窗口时再双击另一个文件，不会开第二个进程，文件直接塞进当前窗口
- 渲染预览 / 源码双视图，目录导航与滚动同步
- 多标签页（中键关闭）、字号调节、亮暗主题、铺满模式
- 即时编辑（可视化编 MarkDown）
- 最近打开列表

## 四、自己编译

完整步骤见 [BUILD.md](BUILD.md)。大致是：

```bash
sudo apt install build-essential pkg-config libssl-dev libgtk-3-dev \
  libwebkit2gtk-4.1-dev libjavascriptcoregtk-4.1-dev libsoup-3.0-dev \
  libayatana-appindicator3-dev librsvg2-dev libxdo-dev
curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal
npm install
npx tauri build
```

**有一个必须打的补丁**：`npm install` 会装到 `@tauri-apps/plugin-clipboard-manager@2.5.0`，而上游 `Cargo.lock` 钉的是 `2.4.1`，Tauri CLI 的版本一致性检查会直接拒绝构建（`Found version mismatched Tauri packages`）。本仓库用 [patches/0001](patches/0001-pin-clipboard-plugin-to-2.4.1.patch) 把它钉回 2.4.1。这是**唯一**对上游源码的改动，且只影响依赖版本，不改任何业务逻辑。

## 五、校验

```bash
sha256sum -c SHA256SUMS
```

当前产物：

| 文件 | 大小 | SHA-256 |
|---|---|---|
| `OpenMD_1.0.4_amd64.deb` | 21,504,876 B | `f4d7e3a8be323858be353ff101060aca2200148bf11981715294679fd1053745` |
| `OpenMD_1.0.4_amd64.AppImage` | 102,435,320 B | `4bc4b4411e22fba4b5911c30912e9127deb79cd55c81d1e882d3f811334bcf3a` |

> AppImage 约 97.7 MiB，超过 GitHub 单文件 100 MB 的仓库上限，所以它**放在 Release 资产里**（`v1.0.4-linux`），不在 git 树中；deb 已随仓库提交。

每个产物的来源、编译命令、环境版本都写在 [BUILD.md](BUILD.md)，可逐条复现。CI 也会在打 tag 时自动重编并挂到 Release（见 `.github/workflows/build-linux.yml`）。

## 六、已知限制

- **托盘图标**：应用带 tray-icon；GNOME 默认不显示托盘，需要装 [AppIndicator 扩展](https://extensions.gnome.org/extension/615/appindicator-support/)。没有托盘不影响主窗口使用。
- **文件关联**：只在装了本仓库的 desktop + MIME 配置后生效；纯 `apt install` deb 不会自动抢默认程序。
- **Wayland**：在 GNOME Wayland 会话下走 XWayland 运行（Tauri 默认），无边框窗口的拖动/贴边行为可能与 X11 略有差异。
- **首次启动联网**：应用会向上游作者的 `https://nexbox.cn/api/statistics` 发一次 `{version, os}`，然后写本地标记不再发送（见 `src-tauri/src/stats.rs`）。这是上游行为，本仓库未改动。
- **自动更新**：上游的更新器指向 GitCode Release，Linux 产物不在那条通道里，所以本构建不会自动更新——升级请来本仓库拉新版本。

## 七、卸载

```bash
sudo apt remove open-md
rm -f ~/.local/share/applications/OpenMD.desktop
sudo rm -f /usr/share/mime/packages/openmd-markdown.xml
sudo update-mime-database /usr/share/mime
```

或 `scripts/uninstall.sh`。

## 八、致谢与许可

- **原作者**：[MuLiuSaMa](https://github.com/MuLiuSaMa) —— 设计并实现了 OpenMD 的全部功能。本仓库只是把它搬到 Linux 上编译打包，**没有原作者的代码就没有这个产物**。
- 上游仓库：<https://github.com/MuLiuSaMa/OpenMD>（镜像：[Gitee](https://gitee.com/muliuawa/OpenMD)、[GitCode](https://gitcode.com/MuLiuSaMa/OpenMD)；官网：<https://openmd.nexbox.cn>）
- 上游采用 **GPL-3.0**；本仓库的构建脚本与文档同样以 GPL-3.0 发布，二进制按 GPL-3.0 分发。对应源码见 [CHANGES.md](CHANGES.md) 的「对应源码」一节。
- 上游 README 中致谢的内联组件与依赖，其版权归各自作者所有。
