# nur-packages

基于 [nix-community/nur-packages-template](https://github.com/nix-community/nur-packages-template)
创建，模板版本固定为 [`b885a769`](https://github.com/nix-community/nur-packages-template/tree/b885a769f27b0d6dfa815c4497c3694a7412904f)。

![Build and populate cache](https://github.com/lihaoze123/nur-packages/actions/workflows/build.yml/badge.svg)

lihaoze123 的独立 NUR 软件包仓库。软件包配方集中维护，安装由 `nix profile`
管理。标准软件直接使用 `nixpkgs`；此处维护自定义包及定制版本。

| 包 | 内容 |
| --- | --- |
| `cloudflare-cli` | Cloudflare 官方 `cf` / `cloudflare` CLI，使用 npm 发布包 |
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

## 缓存

缓存地址和公钥集中维护在 `lib/cache-config.nix`，由主机 Nix 配置直接启用。
下载使用普通 `nix build`、`nix profile` 或系统构建命令，无需额外的安装器或缓存选择包装。
长期使用的软件应声明在 NixOS / Home Manager 配置中，`nix profile` 仅用于临时试用。

私有 NUR 缓存为 `https://cache.chumeng.xyz/nur`。在已配置只读凭据的 NixOS 主机上，
可直接声明：

```nix
nix.settings = {
  extra-substituters = [ "https://cache.chumeng.xyz/nur" ];
  extra-trusted-public-keys = [ "nur:dJh05Op2+iv3GCHoaF2+1FfQtqcUZzf/4v/ZTaLHomY=" ];
  netrc-file = "/run/agenix/attic-netrc";
};
```

`netrc-file` 应指向主机密钥管理工具生成的 root 可读文件；不要将明文 token 写进
Nix 配置或 Nix store。公开项目缓存也由主机按需声明，NUR 包自身不改写客户端配置。
签名私钥由 Attic 服务端管理，上传使用单独的 token。

CI 对三个渠道执行求值检查；实际构建和上传的是 `flake.lock` 对应的
`ci-pinned.nix.buildOutputs`。源码 IFD 实现后检查完整 Flake。CI 不会缓存非自由包作为独立构建目标。

GitHub Secret `ATTIC_TOKEN` 只允许读取、上传 `nur` 缓存，无管理或删除权限。
`scripts/cache-attic.sh` 使用临时 token 文件上传闭包，结束后清理；公开缓存公钥
由 `lib/cache-config.nix` 维护。旧对象存储上传链路已移除。

## NUR、Flake 和 overlay

`default.nix` 符合传统 NUR 接口，维护本地配方及缓存工具，所有依赖取自调用者的 `pkgs`。
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
GitHub Actions 在三个 nixpkgs 分支上检查传统 NUR 受限求值，另对锁定版本
构建 `buildOutputs` 并上传私有 Attic。每日 03:17 UTC 定时运行，Dependabot 每周检查 Actions 和 Nix 更新。
项目公开 Cachix 缓存用于相关构建的下载；进入 NUR 公共索引后，
将 `NUR_REGISTERED` 设为 `true`，成功的 push 工作流会通知 NUR 更新。
回归脚本在 `tests/vtype-linux/`，仅在相关代码发生变化时运行。

本仓库的软件包配方、文档与测试采用 MIT 许可证；VType 补丁沿用上游
GPL-3.0 许可证。打包的软件自身许可证见各包的 `meta.license`。
