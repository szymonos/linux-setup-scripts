# Kubernetes dev — argo rollouts, cilium, flux, helm, hubble, kustomize, trivy.
{ config, lib, pkgs, ... }:

{
  config = lib.mkIf (builtins.elem "k8s_dev" config.scopes.enabled) {
    home.packages = with pkgs; [
      argo-rollouts
      cilium-cli
      fluxcd
      kubernetes-helm
      hubble
      kustomize
      trivy
    ];
  };
}
