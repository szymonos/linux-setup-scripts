# Kubernetes ext - local cluster tools
# bins: minikube k3d kind
{ pkgs }: with pkgs; [
  minikube
  k3d
  kind
]
