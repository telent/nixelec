let
  pkgs = (import <nixpkgs>) {};
  nixos =
    (pkgs.pkgsCross.aarch64-multiplatform.nixos ./configuration.nix);
in nixos.config.system
