{
  base = [ "https://mirror.tuna.tsinghua.edu.cn/nix-channels/store" "https://cache.nixos.org/" ];
  caches = {
    niri = {
      url = "https://niri-computer-use.cachix.org";
      key = "niri-computer-use.cachix.org-1:K5LGfljid+PkRn02OLbwsmngqBCoLkbDi9hRMCnsOTg=";
    };
    codex = {
      url = "https://codex-desktop-linux.cachix.org";
      key = "codex-desktop-linux.cachix.org-1:nX/xy6AdK9hQE24A8ALGjkCKj2ObFmcnemiL5Cid4nk=";
    };
    speech = {
      url = "https://fcitx5-vinput.cachix.org";
      key = "fcitx5-vinput.cachix.org-1:XpX3AA6+dDIX4qJhb1QM7sbTwX6/qSlGvW8Z5NK6XdU=";
    };
    kernel = {
      url = "https://attic.xuyh0120.win/lantian";
      key = "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc=";
    };
    nur = {
      url = "s3://nix-cache?endpoint=6ed1b3dcdc0ddb8c496ad7de884c55cc.r2.cloudflarestorage.com&region=auto&profile=r2-cache";
      key = "r2-fonts-1:WlP+O4M04sA1u8qsLINKBmzg2YUHWJGQQRi3dbqDJaA=";
    };
  };
  groups = {
    nur = [ "nur" ];
    computer-use = [ "niri" "codex" ];
    speech = [ "speech" ];
    kernel = [ "kernel" ];
    system = [ "nur" "niri" "codex" "speech" "kernel" ];
  };
  packages = {
    cloudflare-cli = [ ];
    dbx = [ ];
    honk = [ ];
    try = [ ];
    vscode = [ ];
    vtype-linux = [ ];
    wxc = [ ];
    dms-xhup = [ ];
    edunet = [ ];
    codex-desktop = [ "computer-use" ];
    codex-computer-use = [ "computer-use" ];
    codex-computer-use-niri = [ "computer-use" ];
    niri-patched = [ "computer-use" ];
    gxfp5130-fprintd = [ ];
    gxfp5130-libfprint = [ ];
    gxfp5130-tools = [ ];
  };
}
