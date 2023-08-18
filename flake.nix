{
  description = "rexit development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # Tools

    flake-parts.url = "github:hercules-ci/flake-parts";

    flake-root.url = "github:srid/flake-root";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gitignore = {
      url = "github:hercules-ci/gitignore.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ flake-parts, gitignore, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "aarch64-darwin" "x86_64-linux" "aarch64-linux" ];

      imports = [
        inputs.flake-root.flakeModule
        inputs.treefmt-nix.flakeModule
      ];

      perSystem = { pkgs, lib, config, self', ... }:
        let
          pname = "rexit";
          version = "1.2.0";

          inherit (pkgs.stdenv) isDarwin;
          inherit (gitignore.lib) gitignoreSource;
        in
        {
          treefmt = {
            inherit (config.flake-root) projectRootFile;
            flakeCheck = false;

            programs = {
              nixpkgs-fmt.enable = true;
            };
          };

          devShells.default = pkgs.mkShell {
            name = pname;

            nativeBuildInputs = with pkgs; [
              libiconv
              rustc
            ] ++ lib.optionals isDarwin (with pkgs.darwin.apple_sdk.frameworks; [
              CoreFoundation
              CoreServices
              Security
            ]);

            packages = with pkgs; [
              cargo
            ];

            inputsFrom = [
              config.flake-root.devShell
              config.treefmt.build.devShell
            ];

            TREEFMT_CONFIG_FILE = config.treefmt.build.configFile;
          };
        };
    };
}
