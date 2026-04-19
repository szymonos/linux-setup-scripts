# Kubernetes dev - argo rollouts, cilium, flux, helm, hubble, humio, kustomize, trivy
# bins: rollouts cilium flux helm hubble humioctl kustomize trivy
{ pkgs }: with pkgs; [
  argo-rollouts
  cilium-cli
  fluxcd
  humioctl
  kubernetes-helm
  hubble
  kustomize
  trivy
]
