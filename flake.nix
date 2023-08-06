{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, devenv, ... } @ inputs:
    let
      systems = [ "x86_64-linux" "i686-linux" "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
      forAllSystems = f: builtins.listToAttrs (map (name: { inherit name; value = f name; }) systems);
    in
    {
      packages = forAllSystems
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          with pkgs; {
            default = self.packages.${system}.gitops;
            gitops = buildGoModule rec {
              pname = "gitops";
              version = "0.29.0";

              src = fetchFromGitHub {
                owner = "weaveworks";
                repo = "weave-gitops";
                rev = "v${version}";
                sha256 = "sha256-nXFR+X63yp9IFTeW41ncBt77bCD3QFTs4phJMMLWrxs=";
              };
              vendorHash = "sha256-3CgR9F3Bz4k1MVOufaF/E2GD6+bTOnnUqOXkNO9ZFrc=";

              subPackages = "cmd/gitops";

              CGO_ENABLED = 0;

              ldflags = [
                "-X github.com/weaveworks/weave-gitops/cmd/gitops/version.Branch=main"
                "-X github.com/weaveworks/weave-gitops/cmd/gitops/version.BuildTime=1970-01-01_00:00:00"
                "-X github.com/weaveworks/weave-gitops/cmd/gitops/version.GitCommit=${version}"
                "-X github.com/weaveworks/weave-gitops/cmd/gitops/version.Version=${version}"
                "-X github.com/weaveworks/weave-gitops/pkg/version.FluxVersion=0.41.2"
                "-X github.com/weaveworks/weave-gitops/pkg/run/watch.DevBucketContainerImage=ghcr.io/weaveworks/gitops-bucket-server@sha256:9fa2a68032b9d67197a3d41a46b5029ffdf9a7bc415e4e7e9794faec8bc3b8e4"
                "-X github.com/weaveworks/weave-gitops/pkg/analytics.Tier=oss"
                "-X github.com/weaveworks/weave-gitops/cmd/gitops/beta/run.HelmChartVersion=4.0.21"
              ];
            };
          }
        );

      devShells = forAllSystems
        (system:
          let
            pkgs = nixpkgs.legacyPackages.${system};
          in
          {
            default = devenv.lib.mkShell {
              inherit inputs pkgs;
              modules = [
                {
                  # https://devenv.sh/reference/options/
                  packages = with pkgs; [
                    self.packages.${system}.gitops
                  ];

                  languages.nix.enable = true;
                  pre-commit.hooks = {
                    deadnix.enable = true;
                    nixpkgs-fmt.enable = true;
                    statix.enable = true;
                    actionlint.enable = true;
                    yamllint.enable = true;
                    markdownlint.enable = true;
                  };
                }
              ];
            };
          }
        );
    };
}
