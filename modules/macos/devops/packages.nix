{ pkgs, ... }:

{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs;  [
    jetbrains.gateway
    jetbrains.idea
    openshift
    minio-client

    docker-compose
    colima
    lima


    argocd

    kubectl
    kubectl-validate
    kubeconform
    kube-linter
    kubernetes-helm
    yamllint
    yq-go
    k9s
  ];

}
