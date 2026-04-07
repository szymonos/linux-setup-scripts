# Kubernetes ext — local cluster tools.
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (builtins.elem "k8s_ext" config.scopes.enabled) {
    home.packages = with pkgs; [
      minikube
      k3d
      kind
    ];
  };
}
