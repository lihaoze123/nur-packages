# nur-packages

基于 [nix-community/nur-packages-template](https://github.com/nix-community/nur-packages-template)
创建，模板版本固定为 [`b885a769`](https://github.com/nix-community/nur-packages-template/tree/b885a769f27b0d6dfa815c4497c3694a7412904f)。

![Build and populate cache](https://github.com/lihaoze123/nur-packages/actions/workflows/build.yml/badge.svg)

lihaoze123 的独立 NUR 软件包仓库。软件包配方集中维护，安装由 `nix profile`
管理。标准软件直接使用 `nixpkgs`；此处维护自定义包及定制版本。

| 包 | 内容 |
| --- | --- |
| `dbx` | DBX 官方预编译 AppImage，包含 NixOS 启动环境、菜单入口和图标 |
| `vtype-linux` | 微信拼音 Fcitx5 插件，含小鹤双拼、云延迟修补和固定运行时 |
| `wxc` | 微信输入法设备关联与剪贴板客户端，使用官方预编译包 |
| `honk` | 带原生 API 和内嵌 doona 的固定预编译版本 |
| `try` | tobi/try，修复 NixOS Ruby shebang |
| `vscode` | VS Code，包含原有六个扩展 |
| `dms-xhup` | DMS 小鹤音形插件 |
| `edunet` | 校园网 ePortal CLI |
| `codex-desktop`、`codex-computer-use`、`codex-computer-use-niri`、`niri-patched` | niri 上的 Codex Computer Use，保留已有缓存所用的版本与依赖 |
| `gxfp5130-fprintd`、`gxfp5130-libfprint`、`gxfp5130-tools` | GXFP5130 ChicagoHS 指纹支持 |
| `nur-install`、`nur-with-caches` | 按需选择项目缓存的安装与命令入口 |

目前 Flake 输出支持 `x86_64-linux`。`vscode` 包含非自由软件；Flake 入口已允许，
通过传统 NUR 入口使用时由调用者设置 `config.allowUnfree`。

## 安装与更新

直接从 GitHub 安装：

```sh
nix profile install github:lihaoze123/nur-packages#dbx
nix profile install github:lihaoze123/nur-packages#vtype-linux
nix profile upgrade dbx
nix profile remove dbx
```

本地开发：

```sh
nix profile install .#dbx
nix fmt
nix flake check --no-build
nix build .#dbx
```

DBX 的构建仅解包官方二进制并生成 Nix 启动环境，不编译 DBX 源码。
VType 从源码构建插件和 Android 宿主程序；引擎、词库、设备身份另存于用户目录，
安装和更新 Nix 包不会自动初始化、关联设备或重启输入法。
VType 的初始化与运行说明见 [pkgs/vtype-linux/README.md](pkgs/vtype-linux/README.md)。

## 按需使用缓存

默认 Nix 配置只查询官方缓存和清华镜像。缓存的信任列表与查询列表分开维护：
`trusted-substituters` 和公钥允许使用指定缓存，不会主动查询它们。
项目缓存只在相关命令内启用；Nix 没有按单个 derivation 自动选择缓存的机制。

```sh
# 自动选择这个包适用的公开项目缓存
nix run github:lihaoze123/nur-packages#install -- codex-desktop

# 在配置了私有 R2 凭据的个人设备上，同时使用 NUR 缓存
nix run github:lihaoze123/nur-packages#install -- --private dbx edunet

# 对已安装的包升级，缓存只用于此命令
nix run github:lihaoze123/nur-packages#with-caches -- nur nix profile upgrade dbx

# 查看将使用的缓存，不执行构建
nix run github:lihaoze123/nur-packages#with-caches -- computer-use --print-config
```

缓存组：`computer-use`（Niri 和 Codex）、`speech`（VoCoType）、`kernel`
（CachyOS）、`nur`（现有私有 R2）、`system`（系统构建所需的这些缓存）。
可用逗号组合，例如 `nur,computer-use`。普通 `nix profile` 命令不会自动加上它们。

NUR 缓存复用已有私有 R2 桶和签名密钥。仓库公开，缓存仍需要个人设备的 R2
凭据。CI 对三个渠道执行求值检查；实际构建、签名、上传的是 `flake.lock`
对应的 `ci-pinned.nix.buildOutputs`，包含原模板因 `preferLocalBuild` 排除的
本仓库封装。`cache-r2.sh` 先上传 NAR 数据，再上传签名索引，最后校验本批文件。
CI 不会自动公开私有桶、清理旧对象或缓存非自由包作为独立构建目标。

凭据仅存于 GitHub Secrets：`R2_CACHE_CREDENTIALS`、`NIX_CACHE_SIGNING_KEY`；
地址存于仓库变量 `R2_CACHE_STORE`。

## NUR、Flake 和 overlay

`default.nix` 符合传统 NUR 接口，维护六个本地配方及缓存工具，所有依赖取自调用者的 `pkgs`。
已有独立 Flake 的四个项目通过 `flake.nix` 的 `packages`/`legacyPackages` 聚合，
并在 Flake 中提供对应 NixOS 模块；它们保持上游自己的配方和依赖锁，不加入
传统 NUR 的查询集合，以避免查询阶段的远程源码 IFD。

```nix
import ./default.nix { inherit pkgs; }
```

NixOS 或 Home Manager 可通过 Flake 输入使用：

```nix
inputs.nur-packages.url = "github:lihaoze123/nur-packages";
inputs.nur-packages.inputs.nixpkgs.follows = "nixpkgs";

# 在模块内
environment.systemPackages = [
  inputs.nur-packages.packages.${pkgs.stdenv.hostPlatform.system}.dbx
];
```

Overlay 将软件包放在 `pkgs.nur-lihaoze123` 中，不覆盖 nixpkgs 同名包。

这是可直接使用的 NUR 格式仓库。进入 NUR 公共索引需要另向
[nix-community/NUR](https://github.com/nix-community/NUR#how-to-add-your-own-repository)
提交仓库登记；登记前也可以直接使用上述 Flake 安装命令。

## 模板结构

- `default.nix`：本地配方以及模板预留的 `lib`、`nixosModules`、`overlays` 入口。
- `flake.nix`：聚合已有项目、生成按系统的软件包集合，并提供上游模块。
- `ci.nix`：模板提供的构建与缓存输出筛选。
- `lib/`、`nixos-modules/`、`overlays/` 和 `overlay.nix`：模板的扩展入口。
- `.github/workflows/build.yml`、`.github/dependabot.yml`：模板的 CI 与依赖维护配置。

适配项：当前包只支持 x86_64 Linux；Flake 允许 VS Code 的非自由许可证；
nixpkgs 沿用迁移前的锁定版本；overlay 使用独立命名空间，避免覆盖 nixpkgs 中的
`try`、`vscode` 等同名包。模板示例包已由实际软件包替代。

## 维护

更新包时修改版本、源码修订和哈希，再对该包求值、构建及检查。
`flake.lock` 固定 nixpkgs，保持运行依赖可复现；需要更新时执行 `nix flake update nixpkgs`。
沿用模板的 `ci.nix`，分别导出 `buildPkgs`、`cachePkgs`、`buildOutputs`、
`cacheOutputs`；过滤 broken、非自由及 `preferLocalBuild` 软件包。
GitHub Actions 在三个 nixpkgs 分支上检查 Flake 与 NUR 受限求值，另对锁定版本
构建 `buildOutputs` 并上传 R2。每日 03:17 UTC 定时运行，Dependabot 每周检查 Actions 和 Nix 更新。
项目公开 Cachix 缓存用于相关构建的下载；进入 NUR 公共索引后，
将 `NUR_REGISTERED` 设为 `true`，成功的 push 工作流会通知 NUR 更新。
回归脚本在 `tests/vtype-linux/`，仅在相关代码发生变化时运行。

本仓库的软件包配方、文档与测试采用 MIT 许可证；VType 补丁沿用上游
GPL-3.0 许可证。打包的软件自身许可证见各包的 `meta.license`。
