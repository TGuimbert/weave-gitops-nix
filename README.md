# weave-gitops-nix

This is a simple flake to build the `gitops` binary from the
[weave-gitops](https://github.com/weaveworks/weave-gitops) repository.

## How to use

A minimal flake to use this package in a dev shell environment with `nix develop`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    weave-gitops-nix.url = "github:TGuimbert/weave-gitops-nix";
  };

  outputs = { self, nixpkgs, weave-gitops-nix }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      gitops = weave-gitops-nix.packages.${system}.gitops;
    in
    {
      devShell.${system} = pkgs.mkShell {
        packages = [
          gitops
        ];
      };
    };
}
```
