# 与上游的差异

上游：<https://github.com/MuLiuSaMa/OpenMD>（v1.0.4）。本仓库只做「让它在 Linux 上能编、能装、能双击打开」，**不改任何业务逻辑、不改任何界面**。

## 1. 源码改动：1 处，1 行

`package.json`：

```diff
-    "@tauri-apps/plugin-clipboard-manager": "^2.4.1",
+    "@tauri-apps/plugin-clipboard-manager": "2.4.1",
```

原因：`^2.4.1` 会解析到 `2.5.0`，而 `src-tauri/Cargo.lock` 里 Rust 侧钉的是 `tauri-plugin-clipboard-manager 2.4.1`。Tauri CLI 的版本一致性检查把「npm 2.5.0 vs crate 2.4.1」判为跨 minor 不匹配，直接终止构建。钉死到 2.4.1 即通过。

补丁文件：[`patches/0001-pin-clipboard-plugin-to-2.4.1.patch`](patches/0001-pin-clipboard-plugin-to-2.4.1.patch)

## 2. 构建配置：1 处，仅本地覆盖

上游 `src-tauri/tauri.conf.json` 的 `beforeBuildCommand` 是 `pnpm build`。构建机上没有 pnpm，前端已用 `vite build` 单独产出，故用 `--config` 临时覆盖为空命令：

```json
{ "build": { "beforeBuildCommand": "" } }
```

仓库里**没有**提交这份覆盖配置，`tauri.conf.json` 保持上游原样。

## 3. 打包新增（不改源码）

| 文件 | 作用 | 上游是否提供 |
|---|---|---|
| `packaging/OpenMD.desktop` | 带 `MimeType=text/markdown;text/x-markdown` 与 `Exec=openmd %f` 的桌面入口 | 否（上游 deb 里的 desktop 无 MimeType，也不带 `%f`） |
| `packaging/openmd-markdown.xml` | 把 `.mdown` / `.mkd` / `.mdx` 归入 `text/markdown` | 否 |
| `scripts/install.sh` | 装 deb/AppImage + 注册 desktop + 注册 MIME + 设默认 | 否 |
| `scripts/uninstall.sh` | 反向清理 | 否 |

上游的「文件关联」是在 Windows 侧实现的（`src-tauri/src/file_assoc.rs` + 安装器选项），Linux 侧没有任何注册逻辑——这是补这些文件的原因。

## 4. 二进制层面的差异

无。deb / AppImage 里的可执行文件就是上游 v1.0.4 源码 + 上面第 1 条版本钉死编出来的，未做 patch、未改启动参数、未动联网行为（包括上游那次性的 `nexbox.cn/api/statistics` 启动统计）。

## 5. 对应源码（GPL-3.0 合规）

分发的二进制对应以下源码，可完整重建：

| 项 | 值 |
|---|---|
| 上游仓库 | <https://github.com/MuLiuSaMa/OpenMD> |
| 分支 / 版本 | `main` @ 2026-10-24 快照，`package.json` version = **1.0.4** |
| 源码压缩包 | `https://codeload.github.com/MuLiuSaMa/OpenMD/tar.gz/refs/heads/main` |
| 压缩包 SHA-256 | `c34cc68139811982c3cab834b88fe63c7e00a7d17f6c082ff13ab0236498dd93` |
| 本仓库改动 | 仅 `patches/0001-pin-clipboard-plugin-to-2.4.1.patch`（1 行） |
| 重建步骤 | [BUILD.md](BUILD.md) |

即：`上游源码 + patches/0001` = 本仓库二进制的完整对应源码。
