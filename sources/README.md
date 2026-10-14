# 项目来源

`projects.json` 固定四个自有项目的提交与 NAR 哈希；各 `.lock` 保存迁移前
NixOS 配置实际使用的依赖图（已解析 follows），包括单独更新过的子依赖。
`dates.json` 提供这些锁定时间戳对应的 Flake 日期元数据。

`lib/locked-flake.nix` 使用 Nixpkgs 的固定哈希 fetcher，再用带哈希的
`builtins.path` 恢复与 `fetchTree` 一致的源码上下文。这样可以在 NUR 受限
评估中复用原始配方，同时保持已有缓存的输出路径。

更新项目时同步根提交、依赖锁与日期信息。对于有上游缓存的包，先检查输出
路径及其缓存索引；不要自动将所有项目的 nixpkgs 都改成宿主的版本。
