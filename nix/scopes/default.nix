# Defines the scopes.enabled option used by all scope modules.
# Each scope module checks membership in this list via lib.mkIf.
{ lib, ... }:

{
  options.scopes = {
    enabled = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of enabled scope names (e.g. [ \"shell\" \"k8s_base\" \"pwsh\" ])";
    };

    isStandalone = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this is a standalone environment (macOS/Coder) needing extra base packages";
    };
  };
}
