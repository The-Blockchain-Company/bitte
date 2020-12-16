{ pkgs }:
with pkgs;
mkShellNoCC {
  # TF_LOG = "TRACE";

  LOG_LEVEL = "debug";

  buildInputs = [
    awscli
    bitte.cli
    cfssl
    consul
    consul-template
    dnsutils
    ipcalc
    jq
    nixFlakes
    nixfmt
    nixos-rebuild
    nomad
    openssl
    python38Packages.pyhcl
    sops
    # ssm-session-manager-plugin
    terraform-with-plugins
    vault-bin
  ];
}
