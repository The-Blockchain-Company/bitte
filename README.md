# Bitte

Bitte is designed to run Nomad tasks large-scale on AWS.

## Overview

The current stack consists of:

- [Hashicorp Consul](https://www.consul.io)
- [Hashicorp Vault](https://www.vaultproject.io/)
- [Hashicorp Nomad](https://www.nomadproject.io/)
- [Grafana](https://grafana.com/)
- [Promtail](https://grafana.com/docs/loki/latest/clients/promtail/)
- [VictoriaMetrics](https://victoriametrics.com/)
- [HAProxy](https://www.haproxy.org/)

Provisioning and deployment is done with Nix and Hashicorp Terraform.
The Terraform configuration consists of JSON generated by Nix.

The project is structured into clusters, modules, profiles, and jobs.

Cluster instances import profiles, that configure modules. Once the cluster is
deployed, Nomad jobs can be scheduled.

Each cluster contains 3 core nodes that run server instances of Consul & Vault &
Nomad. Alongside the core nodes, you can specify auto-scaling groups spread
across regions and availability zones that in turn host the client instances and
actually run the Nomad jobs.

The Terraform configuration can be found under modules/terraform and each file
specifies a Terraform workspace.

To help manage this complexity, we also provide the
[bitte-cli](https://github.com/The-Blockchain-Company/bitte-cli) tool. Please note that
this is still under heavy development and the CLI options may break in newer
versions.

We haven't fully automated deployments yet, there are some manual steps
involved, mostly due to inherent complexity and security:

- Create NS entries pointing to the generated route53 zone.
- Generate or choose a KMS key.
- Ensure you have the necessary permissions for your IAM user.

## Usage

### Nix

First you'll need to have [Nix](https://nixos.org/) installed.
We're using an experimental feature called `flakes` which increases speed of
development and deployment drastically, but still requires a bit of preparation.

To enable flake support, add the following line to `~/.config/nix/nix.conf`:

    experimental-features = nix-command flakes

If you don't use `nixUnstable` or `nixFlakes` system-wide yet, you can simply
invoke `nix-shell --run 'nix develop'` to get all required dependencies in
scope.

### Terraform

#### Prerequisites

Set your cluster name in the `BITTE_CLUSTER` environment variable. It's also
convenient to set the `AWS_PROFILE` and have proper default values for the
region. Let's assume we want to work on the `atala-testnet`. Then we need to
have these settings:

    cat ~/.aws/config
    [profile atala-testnet]
    region = eu-central-1

    cat ~/.aws/credentials
    [atala-testnet]
    aws_access_key_id=XXXXXXXXXXXXXXXXXXXX
    aws_secret_access_key=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX

    export BITTE_CLUSTER=atala-testnet
    export AWS_PROFILE="$BITTE_CLUSTER"

To create new deployment from scratch, run the following commands:

    bitte terraform network
    bitte terraform core
    bitte terraform consul
    bitte terraform clients

### Rebuild

This is the equivalent to `nixos-rebuild`. In the `core` workspace it will only
rebuild the core instances. In the `clients` workspace it will include the
instances in all auto-scaling groups.

The `--dirty` flag is used for rebuilds that use the current directory as base,
and doesn't require committing all files.

    bitte rebuild --dirty
    bitte rebuild --dirty --only monitoring

### Debugging

To establish a connection to an instance, you can use `bitte ssh` and pass the
name. This also works in the `core` and `clients` workspaces.

    bitte ssh monitoring
    bitte ssh monitoring -- date

## Consul

It's responsible for simple distributed KV storage, service discovery, and
service mesh communication. In particular we use Consul Connect to facilitate
inter-job communication in Nomad, Consul DNS for discovery, and Consul KV for
Vault.

## Nomad

A workload orchestrator that makes sure our jobs run as efficiently as possible.

### Jobs

Nomad jobs should be stored in the jobs directory.

### Administration

## Vault

Secure, store and tightly control access to tokens, passwords, certificates,
encryption keys for protecting secrets and other sensitive data.

secrets:

/etc/ssl/certs/ca.pem

    cfssl gencert -initca | cfssljson -bare ca

    /etc/ssl/certs/cert.pem

/etc/ssl/certs/cert-key.pem

      cfssl gencert \
        -ca ca.pem \
        -ca-key ca-key.pem \
        -config "${caConfigJson}" \
        -profile bootstrap \
        cert.config

/etc/ssl/certs/full.pem

/etc/consul.d/secrets.json

    {
        "acl": {
            "tokens": {
                "master": "uuid"
            }
        },
        "encrypt": "consul keygen"
    }

/etc/consul.d/tokens.json

    {
      "acl": {
        "tokens": {
          "default": "consul generated",
          "agent": "consul generated"
        }
      }
    }

/etc/nomad.d/consul-token.json

    {
      "consul": {
        "token": "consul generated"
      }
    }

/etc/nomad.d/secrets.json

    {
      "encrypt": "nomad operator keygen"
    }
