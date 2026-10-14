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

## NUR、Flake 和 overlay

`default.nix` 符合 NUR 接口，所有依赖取自调用者的 `pkgs`：

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

- `default.nix`：软件包以及 `lib`、`nixosModules`、`overlays` 入口。
- `flake.nix`：按系统生成 `legacyPackages`，筛选 derivation 后生成 `packages`。
- `ci.nix`：模板提供的构建与缓存输出筛选。
- `lib/`、`nixos-modules/`、`overlays/` 和 `overlay.nix`：模板的扩展入口。
- `.github/workflows/build.yml`、`.github/dependabot.yml`：模板的 CI 与依赖维护配置。

适配项：当前包只支持 x86_64 Linux；Flake 允许 VS Code 的非自由许可证；
nixpkgs 沿用迁移前的锁定版本；overlay 使用独立命名空间，避免覆盖 nixpkgs 中的
`try`、`vscode` 等同名包。模板示例包已由六个实际包替代。

## 维护

更新包时修改版本、源码修订和哈希，再对该包求值、构建及检查。
`flake.lock` 固定 nixpkgs，保持运行依赖可复现；需要更新时执行 `nix flake update nixpkgs`。
沿用模板的 `ci.nix`，分别导出 `buildPkgs`、`cachePkgs`、`buildOutputs`、
`cacheOutputs`；过滤 broken、非自由及 `preferLocalBuild` 软件包。
GitHub Actions 检查 Flake 与 NUR 受限求值，并在三个 nixpkgs 分支上构建
`cacheOutputs`。每日 03:17 UTC 定时运行，Dependabot 每周检查 Actions 和 Nix 更新。
设置仓库变量 `CACHIX_NAME` 和对应 secret 后启用 Cachix 上传；进入 NUR 公共索引后，
将 `NUR_REGISTERED` 设为 `true`，成功的 push 工作流会通知 NUR 更新。
回归脚本在 `tests/vtype-linux/`，仅在相关代码发生变化时运行。

本仓库的软件包配方、文档与测试采用 MIT 许可证；VType 补丁沿用上游
GPL-3.0 许可证。打包的软件自身许可证见各包的 `meta.license`。
