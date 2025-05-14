# Kubernetes Cluster Setup with KIND + Local Docker Registry

[![Stars](https://img.shields.io/github/stars/iflan7744/kind_cluster?style=social)](https://github.com/iflan7744/kind_cluster/stargazers)
[![Shell Lint](https://img.shields.io/badge/shellcheck-passing-brightgreen)](https://github.com/koalaman/shellcheck)
![kind_cluster](https://github.com/user-attachments/assets/ae468c9d-0699-4a21-9c27-f5e8238f6b7e)
![](https://github.com/iflan7744/kind_cluster#:~:text=42%20minutes%20ago-,kind_cluster.png,-Add%20files%20via)



This project ships a **one‑click script** that spins up / tears down an isolated Kubernetes **Kind** cluster **and** a co‑located **Docker registry** (`kind-registry`) so you can push images at `localhost:5000/...` without leaving your laptop. Perfect for:

* Local development & iterative testing
* CI pipelines that need ephemeral clusters
* Reproducing production issues in a hermetic lab

---

## Prerequisites

| Tool                                  | Minimum Version | Purpose                                           |
| ------------------------------------- | --------------- | ------------------------------------------------- |
| **Docker Desktop**                    | 24.x            | Runs both the registry *and* the Kind nodes       |
| **[Kind](https://kind.sigs.k8s.io/)** | v0.23+          | Launches Kubernetes-in‑Docker clusters            |
| **kubectl**                           | 1.29+           | (Optional) Interact with the cluster once it’s up |

Make sure Docker is running before you call the script—`kind-create.sh` checks this for you.

---

## Getting Started

```bash
# 1. Clone & enter the repo
$ git clone https://github.com/iflan7744/kind_cluster.git
$ cd kind_cluster
$ chmod +x kind-create.sh

# 2. Create your first cluster → myfirstcluster
$ ./kind-create.sh create myfirstcluster
```

<details>
<summary>What happens under the hood?</summary>

1. **Local registry**: If not already present, a `registry:2` container called **kind-registry** is started on port **5000** and attached to the “kind” Docker network.
2. **Kind cluster**: A three‑node (control‑plane + 2 workers) cluster is created from `kind-config.yaml`.
3. **Containerd mirror**: The cluster’s container runtime is auto‑patched so any pull for `localhost:5000` is transparently redirected to `kind-registry:5000`.

</details>

### Build ‑› Push ‑› Deploy cycle

```bash
# Build a local image …
$ docker build -t localhost:5000/demo:dev .

# …push it to the registry
$ docker push localhost:5000/demo:dev

# …and use the tag in Kubernetes
$ kubectl --context kind-myfirstcluster run demo \
    --image=localhost:5000/demo:dev --restart=Never
```

### Destroy everything

```bash
$ ./kind-create.sh destroy myfirstcluster
```

If **no other Kind clusters remain**, the script also tears down the registry container so your Docker environment stays clean.

---

## Repository Layout

```text
.
├── kind-create.sh      # Main automation script (create / destroy)
├── kind-config.yaml    # Cluster topology + containerd mirror patch
└── README.md           # You’re reading it 🙂
```

---

## FAQ

| Question                                           | Answer                                                                                                                          |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| **Can I expose the registry on a different port?** | Edit `REGISTRY_PORT` near the top of `kind-create.sh`.                                                                          |
| **Does it support TLS + auth?**                    | The default registry is plaintext (dev‑only). For production‑style TLS/basic‑auth, follow the comments inside `kind-create.sh`. |
| **How do I inspect the cluster?**                  | `kubectl cluster-info --context kind-<name>` or `kubectl get nodes -o wide`.                                                    |

---

## Roadmap

* Automatic registry bootstrap
* Optional self‑signed TLS
* Helm chart for common add‑ons (Ingress‑NGINX, Cert‑Manager)

PRs & issues welcome!

---

## License

MIT © 2025 Iflan
