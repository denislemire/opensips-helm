# opensips-helm

Helm chart and Docker image for **OpenSIPS 4.0** with **RTPEngine** on Kubernetes.

Generic by design — no site-specific IPs, carriers, or cluster names in chart defaults. Consumer repos (e.g. Flux `HelmRelease` values) supply those.

**Author:** Denis Lemire \<denis@lemire.name\>

## Features

- **OpenSIPS 4.0** built from upstream git (`4.0` branch)
- **RTPEngine** — `distributed` (default, StatefulSet) or `sidecar` (debug)
- **4× RTPEngine** default with **pod anti-affinity** (one pod per node)
- **DNS discovery** of RTPEngine control sockets at OpenSIPS startup
- **Modular config** under `config/fragments/` (assembled into ConfigMap)
- **Phased deployment** — ClusterIP bootstrap without touching an existing Asterisk LoadBalancer VIP

## Deployment phases

| Phase | Service type | VIP | Carrier registration | Asterisk |
|-------|--------------|-----|----------------------|----------|
| **1 — Bootstrap** | ClusterIP | None | Off (avoid double VoIP.ms reg) | Unchanged LB |
| **2 — Cutover** | LoadBalancer + `loadBalancerIP` | e.g. `.60` | On (OpenSIPS only) | ClusterIP |

```bash
# Phase 1 — in-cluster only, safe alongside existing Asterisk
helm install opensips . -n opensips --create-namespace \
  -f examples/phase1-clusterip-distributed.yaml

# Debug — sidecar mode
helm upgrade opensips . -n opensips -f examples/debug-sidecar.yaml

# Phase 2 — ONLY when ready (see examples/phase2-cutover-loadbalancer.yaml)
```

## RTPEngine modes

| `rtpengine.mode` | Use case |
|------------------|----------|
| `distributed` | Production — scaled StatefulSet, independent media tier |
| `sidecar` | Troubleshooting — single pod, `127.0.0.1:2223` |

Default: **distributed**, **replicaCount: 4**, anti-affinity on `kubernetes.io/hostname`.

## Build the OpenSIPS image

Local Docker is optional. Options:

### A. Kaniko Job on your cluster (no local Docker)

After this repo is on GitHub and `zot-regcred` exists in `opensips` namespace:

```bash
kubectl apply -f scripts/kaniko-build-job.yaml
kubectl -n opensips wait job/build-opensips-image --for=condition=complete --timeout=45m
```

Edit `--destination=` in the Job for your registry tag.

### B. Local Docker (when available)

```bash
docker build -f docker/Dockerfile \
  --build-arg OPENSIPS_VERSION="$(tr -d '[:space:]' < VERSION)" \
  -t denislemire/opensips:0.1.0 .
```

### C. CircleCI (planned)

Path-filtered build + dual push (Docker Hub + Zot) — same pattern as `asterisk-docker`. Not wired yet.

## Install

```bash
helm lint .
helm template opensips . -f examples/phase1-clusterip-distributed.yaml

helm install opensips . -n opensips --create-namespace \
  -f examples/phase1-clusterip-distributed.yaml \
  --set opensips.image.repository=denislemire/opensips \
  --set opensips.image.tag=0.1.0
```

## Key values

| Value | Default | Notes |
|-------|---------|-------|
| `opensips.service.type` | `ClusterIP` | Phase 2: `LoadBalancer` |
| `rtpengine.mode` | `distributed` | Debug: `sidecar` |
| `rtpengine.replicaCount` | `4` | Sidecar ignores (always 1) |
| `rtpengine.affinity` | anti-affinity | One RTPEngine pod per node |
| `peers.asterisk.enabled` | `false` | Enable for static trunk to PBX |
| `registration.enabled` | `false` | Enable at cutover only |

## Config layout

```
config/fragments/
  opensips.cfg.tpl    # main — imports opensips.d/*
  modules.cfg.tpl
  rtpengine.cfg.tpl
  routing.cfg.tpl
  peers-asterisk.cfg.tpl
  registration.cfg.tpl
```

Rendered into a ConfigMap; `docker/entrypoint.sh` injects RTPEngine sockets and starts `opensips -F`.

## License

**GPL-2.0-or-later** — same family as [OpenSIPS](https://www.opensips.org/Development/License). The container image compiles OpenSIPS from source; combined works are GPL. See [LICENSE](LICENSE).
