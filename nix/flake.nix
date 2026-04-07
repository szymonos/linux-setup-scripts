{
  description = "Cross-platform dev environment - scope-based package set";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
  };

  outputs = { nixpkgs, ... }:
    let
      cfg = import ./config.nix;
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      mkEnv = system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          # always include base packages
          basePkgs = import ./scopes/base.nix { inherit pkgs; };

          # include init packages when no system-wide curl/jq
          initPkgs = if cfg.isInit or false
            then import ./scopes/base_init.nix { inherit pkgs; }
            else [ ];

          # include packages from enabled scopes
          scopePkgs = builtins.concatMap (scope:
            let file = ./scopes/${scope}.nix;
            in if builtins.pathExists file
              then import file { inherit pkgs; }
              else [ ]
          ) (cfg.scopes or [ ]);

        in pkgs.buildEnv {
          name = "dev-env";
          paths = basePkgs ++ initPkgs ++ scopePkgs;
        };
    in
    {
      packages = nixpkgs.lib.genAttrs supportedSystems (system: {
        default = mkEnv system;
      });
    };
}
