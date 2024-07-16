{
  description = "Nix Template";

  nixConfig = {
    extra-substituters = [
      "https://programmerino.cachix.org"
    ];
    extra-trusted-public-keys = [
      "programmerino.cachix.org-1:v8UWI2QVhEnoU71CDRNS/K1CcW3yzrQxJc604UiijjA="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        lib,
        ...
      }: let
        pkgs = import inputs.nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (lib.getName pkg) [
            ];
        };
        extensions =
          (with pkgs.vscode-extensions; [
            jnoortheen.nix-ide
          ])
          ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
            {
              name = "cloudcode";
              publisher = "GoogleCloudTools";
              version = "2.13.0";
              sha256 = "sha256-zfhRt+dLBONn8yGMWwtR0njh8wwQHCGIS2M5U73M1WI=";
            }
          ];
        vscode = pkgs.vscode-with-extensions.override {
          vscode = pkgs.openvscode-server // {
            executableName = "openvscode-server";
          };
          vscodeExtensions = extensions;
        };
      in rec {
        packages.default = pkgs.hello;
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [nil alejandra git] ++ packages.default.buildInputs ++ packages.default.nativeBuildInputs ++ packages.default.propagatedBuildInputs;
          shellHook = ''
            alias code="${vscode}/bin/openvscode-server --user-data-dir $PWD/.vscode-data --server-data-dir $PWD/.vscode-server-data --port 9050 --host 0.0.0.0"
          '';
        };
        formatter = pkgs.alejandra;
      };
    };
}
