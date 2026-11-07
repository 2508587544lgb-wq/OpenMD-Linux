# 构建记录（可复现）

本仓库的二进制是用下面这套步骤和版本编出来的。命令按顺序执行即可复现。

## 环境

| 项 | 值 |
|---|---|
| 发行版 | Ubuntu 24.04.5 LTS（`noble`） |
| 内核 / 架构 | x86_64 |
| Rust | `rustc 1.99.1 (58cf8f9c3 2026-10-13)` / `cargo 1.99.1` |
| Node | `v24.22.2` |
| npm | 随 Node 24（`npm install`，不是 pnpm） |
| WebKitGTK | `libwebkit2gtk-4.1-dev 2.52.6-0ubuntu0.24.04.1` |
| Tauri CLI | `@tauri-apps/cli` 2.x（随项目 devDependencies） |
| Tauri crate | `tauri 2.12.1`（见上游 `src-tauri/Cargo.lock`） |
| 构建时间 | 2026-11-08 00:41（deb）/ 01:0x（AppImage，见 `SHA256SUMS` 时间戳） |

## 1. 系统依赖

```bash
sudo apt update
sudo apt install -y build-essential pkg-config curl wget file libssl-dev \
  libgtk-3-dev libwebkit2gtk-4.1-dev libjavascriptcoregtk-4.1-dev \
  libsoup-3.0-dev libayatana-appindicator3-dev librsvg2-dev libxdo-dev \
  xdg-utils
```

`libxdo-dev` 是 `tauri-plugin-opener` 的依赖；`libayatana-appindicator3-dev` 是 `tray-icon` 特性要的。

## 2. Rust 工具链

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal
source "$HOME/.cargo/env"
rustup default stable   # 1.99.1
```

> 国内网络建议给 rustup / cargo 挂代理（`export https_proxy=http://127.0.0.1:7890`），否则 `static.rust-lang.org` 直连大约 150 KB/s，装完 200 s 起步。

## 3. 取源码

```bash
curl -L -o openmd.tar.gz \
  https://codeload.github.com/MuLiuSaMa/OpenMD/tar.gz/refs/heads/main
# sha256: c34cc68139811982c3cab834b88fe63c7e00a7d17f6c082ff13ab0236498dd93
mkdir OpenMD && tar xzf openmd.tar.gz -C OpenMD --strip-components=1
cd OpenMD
```

## 4. 打补丁（必须）

```bash
patch -p1 < ../patches/0001-pin-clipboard-plugin-to-2.4.1.patch
```

不打会直接构建失败：

```
Found version mismatched Tauri packages. Make sure the NPM package and Rust crate versions
are on the same major/minor releases:
tauri-plugin-clipboard-manager (v2.4.1) : @tauri-apps/plugin-clipboard-manager (v2.5.0)
```

## 5. 前端依赖 + 构建

```bash
npm install --no-audit --no-fund      # 451 个包
npx tsc -p tsconfig.json || true      # 上游 tsconfig 有一处 TS5096（allowImportingTsExtensions），可忽略
npx vite build                        # 产出 dist/
```

## 6. 打包

上游把 `beforeBuildCommand` 写成 `pnpm dev` / `pnpm build`。本机没有 pnpm，且前端已在第 5 步构建完成，所以用一个覆盖配置跳过这一步：

```bash
cat > /tmp/tauri-override.json <<'EOF'
{ "build": { "beforeBuildCommand": "" }, "bundle": { "targets": ["deb"] } }
EOF

export PATH="$HOME/.cargo/bin:$PATH"
npx tauri build --config /tmp/tauri-override.json                 # deb
npx tauri build --config /tmp/tauri-override.json --bundles appimage   # AppImage
```

产物：

- `src-tauri/target/release/bundle/deb/OpenMD_1.0.4_amd64.deb`
- `src-tauri/target/release/bundle/appimage/OpenMD_1.0.4_amd64.AppImage`

（如果你机器上有 pnpm，可以完全按上游来：`pnpm install && pnpm tauri build`。）

## 7. 验证

```bash
# 1) 能起窗口
openmd /tmp/x.md &
xwininfo -root -tree | grep OpenMD        # → "x.md - OpenMD"

# 2) 单实例转发
gio open /tmp/y.md                        # 窗口标题变成 y.md，进程数仍是 1

# 3) 默认打开方式
xdg-mime query default text/markdown      # → OpenMD.desktop
```

本仓库的产物以上三条均已实测通过。

## 备注：deb 的依赖字段

上游 `tauri.conf.json` 里写的 `depends` 包含 `libc6 (>= 2.39)`；Ubuntu 24.04 是 2.39，满足。在更老的发行版（22.04，glibc 2.35）上安装会因这个下限被拒——用 AppImage 代替。

## 本机构建产物校验和（2026-11-08）

我在这台机器上编出来、并实际安装 + 打开文件验证过的那两份：

```
f4d7e3a8be323858be353ff101060aca2200148bf11981715294679fd1053745  OpenMD_1.0.4_amd64.deb        (21,504,876 B)
4bc4b4411e22fba4b5911c30912e9127deb79cd55c81d1e882d3f811334bcf3a  OpenMD_1.0.4_amd64.AppImage   (102,435,320 B)
```

CI（`.github/workflows/build-linux.yml`）从同一份源码重新构建，产出字节不同（deb 21,504,998 B / AppImage 100,551,160 B），**Release 上挂的是 CI 那份**，校验和见 Release 的 `SHA256SUMS` 资产。两者源码完全一致，仅编译环境与时间戳不同。
