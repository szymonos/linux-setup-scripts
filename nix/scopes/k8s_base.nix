# Kubernetes base — kubectl, kubelogin, k9s, kubecolor, kubectx/kubens.
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (builtins.elem "k8s_base" config.scopes.enabled) {
    home.packages = with pkgs; [
      kubectl
      kubelogin
      k9s
      kubecolor
      kubectx
    ];
  };
}
