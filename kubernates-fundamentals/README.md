# Kubernetes Fundamentals

> A ground-up reference: what Kubernetes is, how its pieces fit together, and what every core object actually does.
> **Name:** Mohit Sagar &nbsp;•&nbsp; **Enrollment:** 2024bcs10622
>
> Hands-on companions in this repo: [Pods, ReplicaSets & Deployments](../Pods-Replicasets-Deployments/) · [Services & Networking](../networking-services/) · [Ingress, ConfigMaps & Secrets](../ingress-configmaps-secrets/) · [manifests](../k8s/)

---

## Table of Contents

1. [What Kubernetes Is](#1--what-kubernetes-is)
2. [The Declarative Model](#2--the-declarative-model)
3. [Cluster Architecture](#3--cluster-architecture)
4. [Objects & the Anatomy of a Manifest](#4--objects--the-anatomy-of-a-manifest)
5. [Pods](#5--pods)
6. [Controllers: ReplicaSet, Deployment, StatefulSet, DaemonSet, Job](#6--controllers)
7. [Deployment Strategies](#7--deployment-strategies)
8. [Services & Cluster Networking](#8--services--cluster-networking)
9. [Ingress](#9--ingress)
10. [ConfigMaps & Secrets](#10--configmaps--secrets)
11. [Storage: Volumes, PV, PVC](#11--storage)
12. [Namespaces, Labels & Selectors](#12--namespaces-labels--selectors)
13. [Resources, Requests, Limits & QoS](#13--resources-requests-limits--qos)
14. [Health Probes](#14--health-probes)
15. [Scheduling](#15--scheduling)
16. [Autoscaling](#16--autoscaling)
17. [RBAC & Security](#17--rbac--security)
18. [kubectl Cheat Sheet](#18--kubectl-cheat-sheet)
19. [Troubleshooting Playbook](#19--troubleshooting-playbook)
20. [Glossary](#20--glossary)

---

## 1 · What Kubernetes Is

Kubernetes (K8s — "k", 8 letters, "s") is an **open-source container orchestrator**. You describe the state you want; Kubernetes continuously works to make reality match.

Containers solved *packaging*. They did not solve:

| Problem | What Kubernetes does about it |
|---------|-------------------------------|
| A container dies at 3 a.m. | Restarts it automatically |
| Traffic triples | Scales replicas up (manually or via HPA) |
| A node fails | Reschedules its workloads onto healthy nodes |
| Deploying a new version | Rolling update with automatic rollback on failure |
| "Which IP is the payments service today?" | Stable DNS names and virtual IPs |
| Config and passwords baked into images | ConfigMaps and Secrets, injected at runtime |
| Two services fighting over CPU | Requests, limits and QoS classes |

### What it is *not*

- Not a PaaS — it does not build your source code or provide a database.
- Not a CI/CD system — it is the *target* of your pipeline, not the pipeline.
- Not automatic — you still design health checks, resource requests and rollout strategy. Kubernetes enforces what you declare; it does not invent good defaults for your app.

---

## 2 · The Declarative Model

This is the single most important idea. Everything else follows from it.

**Imperative** — you give instructions, and you own every consequence:

```bash
docker run -d --name web nginx     # container dies -> it stays dead
```

**Declarative** — you state a desired outcome:

```yaml
replicas: 3      # "there should always be 3" -> one dies, another appears
```

### The reconciliation loop

Every controller in Kubernetes runs the same infinite loop:

```
        ┌──────────────────────────────────────┐
        │   read DESIRED state (from etcd)     │
        └───────────────────┬──────────────────┘
                            v
        ┌──────────────────────────────────────┐
        │   observe ACTUAL state (the cluster)  │
        └───────────────────┬──────────────────┘
                            v
                 ┌──────────────────────┐
                 │   do they match?     │
                 └───┬──────────────┬───┘
                 yes │              │ no
                     v              v
                  sleep       take action, then loop
```

Three consequences worth internalising:

1. **Self-healing is free.** Delete a pod owned by a Deployment and a replacement appears in seconds — you did not ask for one; the loop noticed a mismatch.
2. **`kubectl apply` is idempotent.** Run it a hundred times; if desired state is unchanged, nothing happens.
3. **Editing live objects fights the loop.** `kubectl edit` or `kubectl scale` changes desired state directly, so the next `apply` from your file overwrites it. Keep manifests in git and treat the cluster as an output. (This is exactly the drift that produces the `resource … was previously managed with 'kubectl apply'` warning after a `rollout undo`.)

---

## 3 · Cluster Architecture

A cluster = **control plane** (the brain) + **worker nodes** (the muscle).

```
┌──────────────────────── CONTROL PLANE ────────────────────────┐
│                                                                │
│   kube-apiserver  <── the ONLY front door; everything talks    │
│        │               to it, nothing talks around it          │
│        ├── etcd                    key-value store, the single │
│        │                           source of truth             │
│        ├── kube-scheduler          decides WHICH node          │
│        └── kube-controller-manager runs the reconcile loops    │
│            cloud-controller-manager (cloud LBs, volumes)       │
└────────────────────────────┬───────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        v                    v                    v
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│    NODE 1     │    │    NODE 2     │    │    NODE 3     │
│  kubelet      │    │  kubelet      │    │  kubelet      │
│  kube-proxy   │    │  kube-proxy   │    │  kube-proxy   │
│  containerd   │    │  containerd   │    │  containerd   │
│  ┌─────┐┌────┐│    │  ┌─────┐      │    │  ┌─────┐┌────┐│
│  │ Pod ││Pod ││    │  │ Pod │      │    │  │ Pod ││Pod ││
│  └─────┘└────┘│    │  └─────┘      │    │  └─────┘└────┘│
└───────────────┘    └───────────────┘    └───────────────┘
```

### Control plane components

| Component | Responsibility |
|-----------|----------------|
| **kube-apiserver** | REST API, authentication, authorisation, admission control, validation. Every read and write goes through it — including component-to-component traffic. |
| **etcd** | Consistent, distributed key-value store holding all cluster state. Lose etcd without a backup and you lose the cluster. |
| **kube-scheduler** | Watches for Pods with no `nodeName`, picks a node by filtering (which nodes *can* run this?) then scoring (which is *best*?). |
| **kube-controller-manager** | One binary running many controllers: Deployment, ReplicaSet, Node, Job, EndpointSlice, ServiceAccount… |
| **cloud-controller-manager** | Cloud-specific glue: provisions load balancers, attaches disks, manages node lifecycle. Absent on bare clusters — which is why a `LoadBalancer` Service pends forever on minikube. |

### Node components

| Component | Responsibility |
|-----------|----------------|
| **kubelet** | The node agent. Takes PodSpecs from the API server, tells the container runtime to run them, runs probes, reports status back. It manages only containers Kubernetes created. |
| **kube-proxy** | Implements Services — programs iptables/IPVS rules so traffic to a ClusterIP is DNAT'd to a real pod IP. |
| **Container runtime** | containerd or CRI-O (Docker's shim was removed in v1.24). Actually pulls images and runs containers. |

### What happens when you run `kubectl apply -f deployment.yaml`

1. `kubectl` POSTs the manifest to **kube-apiserver**.
2. API server authenticates you, runs **admission webhooks** (this is where a broken `ingress-nginx` webhook causes `context deadline exceeded`), validates the schema, writes to **etcd**.
3. **Deployment controller** sees a new Deployment → creates a **ReplicaSet**.
4. **ReplicaSet controller** sees `replicas: 3` and 0 pods → creates 3 **Pod** objects, each with `nodeName` empty.
5. **Scheduler** sees unscheduled pods → filters and scores nodes → writes `nodeName` on each.
6. The target node's **kubelet** notices pods assigned to it → asks **containerd** to pull images and start containers.
7. kubelet reports `Running`/`Ready` back to the API server → **EndpointSlice controller** adds the pod IPs to the Service → **kube-proxy** programs the routing rules.

Notice that no component ever calls another directly. They all watch the API server and act independently — that is why the system degrades gracefully instead of collapsing.

---

## 4 · Objects & the Anatomy of a Manifest

Every object shares the same four top-level fields:

```yaml
apiVersion: apps/v1        # which API group + version
kind: Deployment           # what type of object
metadata:                  # name, namespace, labels, annotations
  name: web-app
  namespace: default
  labels:
    app: web
spec:                      # DESIRED state  <- you write this
  replicas: 3
  ...
status:                    # ACTUAL state   <- Kubernetes writes this, never you
  readyReplicas: 3
```

**`spec` is yours, `status` is the cluster's.** The gap between them is what every controller exists to close.

Common `apiVersion` values:

| Group | Kinds |
|-------|-------|
| `v1` (core) | Pod, Service, ConfigMap, Secret, Namespace, PersistentVolume(Claim), ServiceAccount |
| `apps/v1` | Deployment, ReplicaSet, StatefulSet, DaemonSet |
| `batch/v1` | Job, CronJob |
| `networking.k8s.io/v1` | Ingress, NetworkPolicy, IngressClass |
| `autoscaling/v2` | HorizontalPodAutoscaler |
| `rbac.authorization.k8s.io/v1` | Role, RoleBinding, ClusterRole, ClusterRoleBinding |

Use `kubectl explain` instead of guessing field names — it reads the live schema of *your* cluster:

```bash
kubectl explain deployment.spec.strategy
kubectl explain pod.spec.containers.livenessProbe --recursive
kubectl api-resources            # every kind, its short name, and whether it is namespaced
```

---

## 5 · Pods

**A Pod is the smallest deployable unit — not a container.** It is one or more containers that share:

- a **network namespace** — one IP, one port space; containers in a Pod reach each other on `localhost`
- **storage volumes**
- a **lifecycle** — scheduled together onto one node, live and die together

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web
  labels:
    app: web
spec:
  containers:
    - name: nginx
      image: nginx:1.27-alpine
      ports:
        - containerPort: 80
      resources:
        requests: { cpu: "50m", memory: "64Mi" }
        limits:   { cpu: "200m", memory: "128Mi" }
```

### Why multiple containers in one Pod?

Only when processes are **tightly coupled** — they must share a network or filesystem and scale as a unit. Standard patterns:

| Pattern | Example |
|---------|---------|
| **Sidecar** | log shipper reading a shared volume; a service-mesh proxy |
| **Ambassador** | a local proxy that fronts an external database |
| **Adapter** | translates the app's metrics format into Prometheus format |
| **Init container** | runs to completion *before* app containers — waits for a DB, runs migrations |

An nginx and a Postgres do **not** belong in one Pod — they scale independently.

### Pod lifecycle phases

| Phase | Meaning |
|-------|---------|
| `Pending` | Accepted, but not all containers running — being scheduled, or pulling images |
| `Running` | Bound to a node, at least one container running |
| `Succeeded` | All containers exited **0** and will not restart |
| `Failed` | All containers terminated, at least one non-zero exit |
| `Unknown` | Node unreachable — the API server lost contact with its kubelet |

`kubectl get pods` shows a friendlier `STATUS` that mixes in container-level reasons:

| STATUS | What it means | Where to look |
|--------|---------------|---------------|
| `ContainerCreating` | Pulling image / mounting volumes | `kubectl describe pod` → Events |
| `ErrImagePull` / `ImagePullBackOff` | Image name wrong, tag missing, or registry auth failed | check the image string, check `imagePullSecrets` |
| `CrashLoopBackOff` | Container keeps exiting; kubelet backs off 10s → 20s → 40s… up to 5 min | `kubectl logs <pod> --previous` |
| `Completed` | Exit 0 with `restartPolicy: Never/OnFailure` | expected for Jobs |
| `OOMKilled` | Exceeded its memory **limit** | raise the limit or fix the leak |
| `Evicted` | Node ran out of resources | set requests; check node pressure |
| `Terminating` (stuck) | Finalizer or ungraceful shutdown | `kubectl describe`; check finalizers |

> `READY 0/1` with `STATUS Running` is **not** an error — the container is up but the readiness probe has not passed, so no Service traffic will reach it yet.

### Restart policy

| `restartPolicy` | Used by |
|---|---|
| `Always` (default) | long-running services — Deployments |
| `OnFailure` | Jobs — retry only on non-zero exit |
| `Never` | one-shot tasks; failures stay visible |

### You rarely create Pods directly

A bare Pod is not rescheduled if its node dies — nothing owns it. In production you always create a **controller** that creates Pods for you. Bare pods are for debugging:

```bash
kubectl run tmp --rm -it --image=busybox:1.36 --restart=Never -- sh
kubectl debug -it <pod> --image=nicolaka/netshoot --target=<container>
```

---

## 6 · Controllers

```
Deployment ──owns──> ReplicaSet ──owns──> Pods
```

### ReplicaSet

Keeps exactly N pods matching a label selector alive. That is all it does — no rollouts, no history, no rollback.

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: backend-rs
spec:
  replicas: 3
  selector:
    matchLabels: { app: backend }     # MUST match template.metadata.labels
  template:
    metadata:
      labels: { app: backend }
    spec:
      containers:
        - name: backend
          image: python:3.11-alpine
```

You almost never write one by hand — Deployments create them.

### Deployment

The workhorse for stateless apps. Adds rollouts, revision history and rollback on top of ReplicaSets.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 4
  revisionHistoryLimit: 10
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1           # at most 1 extra pod above `replicas`
      maxUnavailable: 0     # never drop below `replicas` ready  -> zero downtime
  selector:
    matchLabels: { app: web-app }
  template:
    metadata:
      labels: { app: web-app, version: v1 }
    spec:
      containers:
        - name: web
          image: nginx:1.24-alpine
          readinessProbe:
            httpGet: { path: /, port: 80 }
```

Change anything under `template` → a **new ReplicaSet** is created with a new `pod-template-hash`, and the old one is scaled down. Change `replicas` only → the existing ReplicaSet just resizes; no rollout.

```bash
kubectl rollout status deployment/web-app        # block until complete
kubectl rollout history deployment/web-app       # list revisions
kubectl rollout undo deployment/web-app          # back one revision
kubectl rollout undo deployment/web-app --to-revision=2
kubectl rollout restart deployment/web-app       # recycle all pods, same image
kubectl rollout pause|resume deployment/web-app  # batch several edits into one rollout
```

### StatefulSet

For workloads that need **identity**: databases, queues, anything clustered.

| Deployment | StatefulSet |
|------------|-------------|
| Pods are interchangeable | Pods have **stable identity** |
| Random names: `web-7d4b-x9k2` | Ordinal names: `db-0`, `db-1`, `db-2` |
| Started in parallel | Started **in order**, 0 → 1 → 2 |
| Shared or no storage | Each pod gets its **own** PVC that survives rescheduling |
| No per-pod DNS | `db-0.db-headless.default.svc.cluster.local` |

Needs a **headless Service** (`clusterIP: None`) named in `spec.serviceName` — that is what creates the per-pod DNS records.

### DaemonSet

One pod on **every** node (or every node matching a selector). Node-level agents: log collectors (Fluent Bit), monitoring (node-exporter), CNI plugins, storage drivers. Add a node → a pod appears on it automatically.

### Job & CronJob

| Kind | Purpose |
|------|---------|
| `Job` | Run pods until N complete successfully, then stop. Batch work, migrations. `completions`, `parallelism`, `backoffLimit`. |
| `CronJob` | A Job on a cron schedule: `schedule: "0 2 * * *"`. Keeps `successfulJobsHistoryLimit` old Jobs around for inspection. |

---

## 7 · Deployment Strategies

| Strategy | Mechanism | Downtime | Extra capacity | Rollback speed |
|----------|-----------|:--------:|:--------------:|----------------|
| **Recreate** | kill all old, then start new | **yes** | none | slow (another full restart) |
| **Rolling Update** | replace pod by pod | none | `maxSurge` | fast (`rollout undo`) |
| **Blue-Green** | two full environments, flip a Service selector | none | **2×** | **instant** (flip back) |
| **Canary** | small % to the new version, then ramp | none | small | fast (scale canary to 0) |
| **A/B testing** | route by header/cookie/geo (needs ingress or mesh) | none | small | fast |

**Recreate** — the only choice when two versions cannot coexist: an incompatible schema migration, or a `ReadWriteOnce` volume only one pod can mount.

**Rolling Update** — the default. `maxSurge: 1, maxUnavailable: 0` gives strictly zero downtime at the cost of one extra pod's resources. Correct readiness probes are mandatory: without them Kubernetes calls a pod ready the instant the process starts and will happily route traffic into a still-initialising app.

**Blue-Green** — run `slot: blue` and `slot: green` Deployments simultaneously; the Service selector chooses which is live. The flip is a single `kubectl apply` and it rewrites only kube-proxy rules — no pod restarts, so rollback is just as instant.

**Canary** — both versions carry the same `app` label so one Service selects both; the traffic split is the **replica ratio** (1 canary : 9 stable ≈ 10%). Cheap and needs no extra tooling, but the split is only statistical — kube-proxy balances per *connection*, not per request. For precise percentages or header-based routing you need an ingress controller or a service mesh (Istio, Linkerd).

---

## 8 · Services & Cluster Networking

### The problem

Pods are mortal and their IPs change on every restart. Nothing can hard-code a pod IP. A **Service** is a stable name and virtual IP in front of a changing set of pods.

### How it actually works

```
Service (selector: app=web)
        │
        │  EndpointSlice controller watches pods matching the selector
        v
EndpointSlice: [10.244.0.5:80, 10.244.0.6:80, 10.244.0.7:80]
        │
        │  kube-proxy programs iptables/IPVS rules on every node
        v
traffic to ClusterIP 10.96.0.42:80  ──DNAT──>  a random ready pod
```

The chain to remember when debugging: **selector → endpoints → kube-proxy → traffic.** No endpoints means the selector matches nothing, or the pods are not *Ready*. `kubectl get endpoints <svc>` answers "is this Service wired to anything?" faster than anything else.

### The five types

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: ClusterIP
  selector:
    app: web              # matches pod LABELS, not pod names
  ports:
    - port: 8080          # the port the SERVICE listens on
      targetPort: 80      # the port the CONTAINER listens on
      protocol: TCP
```

| Type | Gets | Reachable from | Use for |
|------|------|----------------|---------|
| **ClusterIP** *(default)* | a virtual IP | inside the cluster only | internal APIs, databases |
| **NodePort** | ClusterIP + a port on every node (30000-32767) | `<anyNodeIP>:<nodePort>` | dev access, or behind an external LB |
| **LoadBalancer** | ClusterIP + NodePort + a cloud LB | the internet | public services on a cloud provider |
| **ExternalName** | nothing — just a DNS CNAME | wherever the CNAME points | aliasing a managed DB or third-party API |
| **Headless** (`clusterIP: None`) | no VIP; DNS returns **pod IPs** | inside the cluster | StatefulSets, client-side load balancing |

Each type builds on the previous: a `LoadBalancer` still has a NodePort and a ClusterIP underneath.

**`<pending>` on a LoadBalancer's EXTERNAL-IP is not a bug** — it is a *request* to a cloud-controller-manager. Without one (minikube, kind, bare metal) nothing answers. Use `minikube tunnel`, or MetalLB on-prem.

### DNS

CoreDNS runs in `kube-system` and gives every Service a name:

```
<service>.<namespace>.svc.cluster.local
```

Because each pod's `/etc/resolv.conf` carries a search path, all of these work from a pod in `default`:

```bash
curl http://web-service:8080                                  # same namespace
curl http://web-service.default:8080                          # explicit namespace
curl http://web-service.default.svc.cluster.local:8080        # FQDN
```

Headless Services also publish **per-pod** records: `db-0.db-headless.default.svc.cluster.local`.

> **Debugging tip that saves hours:** a `curl` exit code tells you which layer broke.
> **`6`** = couldn't resolve host → **DNS problem**, the packet never left the pod.
> **`7`** = couldn't connect → DNS was fine; the network path or the endpoint is broken.

### The four networking rules

1. Every Pod gets its own cluster-wide unique IP.
2. Pods can reach any other pod **without NAT**, on any node.
3. Nodes can reach all pods without NAT.
4. The IP a pod sees itself as is the IP others see it as.

A **CNI plugin** (Calico, Flannel, Cilium, Weave) implements all four. Kubernetes itself does not do networking — it defines the contract.

### NetworkPolicy

By default **every pod can talk to every other pod**. A NetworkPolicy restricts that — but only if your CNI enforces them (Calico and Cilium do; plain Flannel does not).

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-allow-backend-only
spec:
  podSelector:
    matchLabels: { app: database }
  policyTypes: [Ingress]
  ingress:
    - from:
        - podSelector:
            matchLabels: { app: backend }
      ports:
        - protocol: TCP
          port: 5432
```

Policies are **additive and default-deny once applied**: the moment any policy selects a pod, only traffic explicitly allowed gets through.

---

## 9 · Ingress

A Service gives you Layer-4 (TCP) exposure — one Service, one external entry point. Twenty microservices would mean twenty LoadBalancers and twenty cloud bills.

**Ingress** is Layer-7 HTTP routing: one entry point, routed by **host** and **path**, with TLS termination.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  tls:
    - hosts: [app.example.com]
      secretName: app-tls-cert      # a kubernetes.io/tls Secret
  rules:
    - host: app.example.com
      http:
        paths:
          - path: /api
            pathType: Prefix
            backend:
              service:
                name: backend-service
                port: { number: 80 }
          - path: /
            pathType: Prefix
            backend:
              service:
                name: frontend-service
                port: { number: 80 }
```

### The part people miss

**An Ingress object is only a set of rules.** It does nothing until an **ingress controller** — nginx, Traefik, HAProxy, or a cloud ALB controller — is running and watching. No controller = a perfectly valid Ingress that routes nothing, with a permanently blank `ADDRESS` column.

Two more consequences worth knowing:

- Kubernetes does **not** validate that the backend Services exist. An Ingress pointing at a non-existent Service is accepted happily; `kubectl describe ingress` then shows `<error: services "x" not found>` and live requests get **503**.
- `ingress-nginx` installs a **ValidatingWebhookConfiguration**. If the controller pod is unhealthy or was removed while the webhook remains, *every* Ingress create/update fails with `failed calling webhook … context deadline exceeded` — an orphaned webhook blocks the whole cluster.

`pathType` matters: `Prefix` matches path segments, `Exact` matches the whole path, `ImplementationSpecific` defers to the controller.

---

## 10 · ConfigMaps & Secrets

**Never bake configuration into an image.** The same image should run in dev, staging and production with only its injected config differing.

### ConfigMap

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  LOG_LEVEL: "INFO"
  ENVIRONMENT: "production"
  app.properties: |
    timeout=30
    retries=3
```

### Secret

Same shape, but values are base64 in `data` (or plain text in `stringData`, which Kubernetes encodes for you):

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
type: Opaque
stringData:                      # plain text here; encoded on write
  POSTGRES_PASSWORD: "s3cr3t"
```

| Secret `type` | Contents |
|---------------|----------|
| `Opaque` | arbitrary key/value (default) |
| `kubernetes.io/tls` | `tls.crt` + `tls.key` — what an Ingress references |
| `kubernetes.io/dockerconfigjson` | registry credentials for `imagePullSecrets` |
| `kubernetes.io/service-account-token` | API token for a ServiceAccount |

### ⚠️ base64 is encoding, not encryption

```bash
kubectl get secret db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode
# s3cr3t
```

Anyone with `get secret` permission reads every password with one pipe. Real protection:

- **RBAC** — restrict who holds `get`/`list` on `secrets`. The single most effective control.
- **Encryption at rest** — `EncryptionConfiguration` on the API server so etcd stores ciphertext.
- **External stores** — Vault, AWS Secrets Manager, Sealed Secrets, External Secrets Operator.
- **Never commit Secret manifests to git.** A password in git history is a password forever.

### Consuming them

```yaml
spec:
  containers:
    - name: app
      image: myapp:1.0
      env:
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef: { name: app-config, key: LOG_LEVEL }
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:    { name: db-secret, key: POSTGRES_PASSWORD }
      envFrom:                                  # import every key at once
        - configMapRef: { name: app-config }
      volumeMounts:
        - name: config-volume
          mountPath: /etc/config
          readOnly: true
  volumes:
    - name: config-volume
      configMap: { name: app-config }
```

> **Env vars are injected once, at container start.** Editing the ConfigMap does **not** update a running pod — you must `kubectl rollout restart` it. A ConfigMap mounted as a **volume** *does* update in place (within ~60 s), which is why config files beat env vars when you want hot reload. Either way, your app has to re-read the file.

---

## 11 · Storage

A container's filesystem dies with the container. Volumes outlive it.

### Volume types worth knowing

| Type | Lifetime | Use |
|------|----------|-----|
| `emptyDir` | as long as the **Pod** | scratch space, cache, sharing files between containers in a Pod |
| `hostPath` | node's disk | node agents only — ties a pod to one node, a security risk otherwise |
| `configMap` / `secret` | as long as the Pod | inject config files |
| `persistentVolumeClaim` | independent of the Pod | real data |

### PV / PVC / StorageClass

This is the abstraction that keeps app manifests portable across clouds:

```
StorageClass  ──"how to provision"──>  PersistentVolume  (the actual disk)
                                              ^
                                              │ bound to
                                              │
Pod ──mounts──> PersistentVolumeClaim  ──"I need 10Gi, RWO"──┘
```

| Object | Who writes it | Means |
|--------|---------------|-------|
| **PersistentVolume (PV)** | admin, or auto-provisioned | a piece of real storage — an EBS volume, an NFS export |
| **PersistentVolumeClaim (PVC)** | the developer | a *request*: "10Gi, ReadWriteOnce" |
| **StorageClass** | admin | a template for dynamic provisioning — the common case today |

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: standard
  resources:
    requests:
      storage: 10Gi
```

**Access modes:**

| Mode | Meaning |
|------|---------|
| `ReadWriteOnce` (RWO) | mounted read-write by **one node** — most block storage (EBS, GCE PD) |
| `ReadOnlyMany` (ROX) | read-only by many nodes |
| `ReadWriteMany` (RWX) | read-write by many nodes — needs NFS, CephFS, EFS |
| `ReadWriteOncePod` | exactly one **Pod** — the strictest guarantee |

**Reclaim policy** decides what happens when the PVC is deleted: `Delete` (destroys the disk — the default for dynamic provisioning, and a genuine footgun) or `Retain` (keeps the data for manual recovery).

StatefulSets use `volumeClaimTemplates` so each ordinal pod gets its own PVC (`data-db-0`, `data-db-1`) that follows it across reschedules.

---

## 12 · Namespaces, Labels & Selectors

### Namespaces

Virtual clusters inside one physical cluster: scoping for names, RBAC and quotas.

```bash
kubectl get namespaces
kubectl create namespace staging
kubectl get pods -n kube-system
kubectl config set-context --current --namespace=staging   # stop typing -n
```

Built-ins: `default`, `kube-system` (control-plane components), `kube-public`, `kube-node-lease`.

Namespaces are **not a security boundary by themselves** — pods in different namespaces can still reach each other unless a NetworkPolicy says otherwise. And not everything is namespaced: Nodes, PersistentVolumes, ClusterRoles and StorageClasses are cluster-scoped (`kubectl api-resources --namespaced=false`).

### Labels

Key/value pairs used to **select** objects. Labels are how Kubernetes wires itself together — a Service finds pods by label, a ReplicaSet owns pods by label, the scheduler places pods by node label.

```yaml
metadata:
  labels:
    app: web
    tier: frontend
    environment: production
    version: v2
```

```bash
kubectl get pods -l app=web
kubectl get pods -l 'environment in (staging,production)'
kubectl get pods -l app=web,tier!=cache
kubectl get pods --show-labels
kubectl label pod web-1 canary=true          # add on the fly
```

**Labels vs annotations:** labels are for *selection* and are indexed (keep them short); annotations hold arbitrary non-identifying metadata for tools — build IDs, checksums, ingress config. `kubectl.kubernetes.io/last-applied-configuration` is an annotation.

> A Deployment's `spec.selector.matchLabels` is **immutable** after creation, and it must match `spec.template.metadata.labels`. Getting this wrong is one of the most common beginner errors — and you cannot patch your way out; you must delete and recreate.

---

## 13 · Resources, Requests, Limits & QoS

```yaml
resources:
  requests:            # GUARANTEED — used for scheduling decisions
    cpu: "100m"        # 100 millicores = 0.1 core
    memory: "128Mi"
  limits:              # CEILING — enforced at runtime
    cpu: "500m"
    memory: "512Mi"
```

| | Requests | Limits |
|---|---|---|
| **Used by** | the scheduler — is there room on this node? | the kubelet/cgroups at runtime |
| **CPU over-run** | — | **throttled** (slowed, not killed) |
| **Memory over-run** | — | **OOMKilled** — the container is terminated |

CPU is compressible (you get slowed down); memory is not (you get killed). That asymmetry drives most tuning decisions.

### QoS classes

The kubelet assigns each pod a class, which decides who gets evicted first under node pressure:

| Class | Condition | Evicted |
|-------|-----------|---------|
| **Guaranteed** | limits == requests, set for every container | last |
| **Burstable** | requests set, limits higher or absent | second |
| **BestEffort** | nothing set at all | **first** |

**Always set requests.** Without them the scheduler is flying blind — it will happily overcommit a node, and your pod is first in line to be evicted.

Enforce this at the namespace level:

```yaml
apiVersion: v1
kind: ResourceQuota        # hard cap for the whole namespace
metadata: { name: team-quota }
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    pods: "50"
---
apiVersion: v1
kind: LimitRange           # per-container defaults for anything that omits them
metadata: { name: default-limits }
spec:
  limits:
    - type: Container
      default:        { cpu: 500m, memory: 512Mi }
      defaultRequest: { cpu: 100m, memory: 128Mi }
```

---

## 14 · Health Probes

Three probes, three different questions:

| Probe | Question | On failure |
|-------|----------|------------|
| **liveness** | "Is it alive?" | **restart the container** |
| **readiness** | "Can it take traffic *right now*?" | **remove from Service endpoints** (no restart) |
| **startup** | "Has it finished booting?" | restart; **disables the other two until it passes** |

```yaml
livenessProbe:
  httpGet: { path: /healthz, port: 8080 }
  initialDelaySeconds: 10
  periodSeconds: 10
  failureThreshold: 3            # 3 strikes -> restart

readinessProbe:
  httpGet: { path: /ready, port: 8080 }
  periodSeconds: 5

startupProbe:                    # for slow starters (JVM, big migrations)
  httpGet: { path: /healthz, port: 8080 }
  failureThreshold: 30
  periodSeconds: 10              # allows up to 300s to boot
```

Handlers: `httpGet` (2xx/3xx = pass), `tcpSocket` (connection opens = pass), `exec` (exit 0 = pass), `grpc`.

**The distinction that matters:** a readiness failure takes a pod *out of rotation* — the app is fine, just busy or warming up. A liveness failure *kills* it. Pointing a liveness probe at a dependency (your database) is a classic outage amplifier: the DB blips, every pod fails liveness, all of them restart at once, and now you have a thundering herd on top of a DB problem. **Liveness should test only the process itself.**

Readiness probes are also what make zero-downtime rolling updates real. Without one, Kubernetes treats "process started" as "ready" and routes traffic into an app that is still loading.

---

## 15 · Scheduling

The scheduler runs two phases: **filter** (which nodes *can* run this pod?) then **score** (which is *best*?).

| Mechanism | What it does |
|-----------|--------------|
| `nodeSelector` | simplest: run only on nodes with this label |
| **Node affinity** | expressive version — `required…` (hard) or `preferred…` (soft) with weights |
| **Pod affinity / anti-affinity** | place near (or away from) other pods — e.g. spread replicas across zones |
| **Taints & tolerations** | the node *repels* pods; only pods with a matching toleration land there |
| **Topology spread constraints** | even distribution across zones/nodes |
| `priorityClassName` | higher-priority pods can **preempt** (evict) lower-priority ones |

```yaml
# spread replicas across nodes for HA
affinity:
  podAntiAffinity:
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels: { app: web }
          topologyKey: kubernetes.io/hostname
tolerations:
  - key: "gpu"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
```

Taints and tolerations are the inverse of affinity: **affinity is the pod choosing a node; a taint is the node rejecting pods.** Control-plane nodes are tainted by default, which is why your workloads never land on them.

A pod stuck in `Pending` almost always means the filter phase eliminated every node. `kubectl describe pod` spells out why: `0/3 nodes are available: 3 Insufficient cpu`.

---

## 16 · Autoscaling

| Scaler | Adjusts | Trigger |
|--------|---------|---------|
| **HPA** (Horizontal Pod Autoscaler) | number of **pods** | CPU/memory utilisation, or custom metrics |
| **VPA** (Vertical Pod Autoscaler) | requests/limits **per pod** | observed usage |
| **Cluster Autoscaler** | number of **nodes** | pods stuck `Pending` for lack of room |

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata: { name: web-hpa }
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 2
  maxReplicas: 20
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
```

**HPA requires resource `requests` to be set** — "70% utilisation" is 70% *of the request*. With no request there is no denominator and the HPA reports `<unknown>`. It also needs **metrics-server** installed (`minikube addons enable metrics-server`).

Do not run HPA and VPA on the same CPU metric — they will fight each other.

---

## 17 · RBAC & Security

### RBAC

Four objects, one pattern: a **Role** lists permissions; a **Binding** attaches it to a subject.

| Object | Scope |
|--------|-------|
| `Role` | permissions within **one namespace** |
| `ClusterRole` | cluster-wide permissions (or reusable across namespaces) |
| `RoleBinding` | grants a Role (or ClusterRole) to a subject **in one namespace** |
| `ClusterRoleBinding` | grants a ClusterRole cluster-wide |

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: pod-reader
rules:
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: production
  name: read-pods
subjects:
  - kind: ServiceAccount
    name: monitoring-sa
    namespace: production
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

RBAC is **purely additive** — there are no deny rules. A subject can do exactly the union of what its bindings grant, and nothing else.

```bash
kubectl auth can-i delete pods --as=system:serviceaccount:production:monitoring-sa
kubectl auth can-i --list
```

### Pod-level hardening

```yaml
spec:
  serviceAccountName: app-sa
  automountServiceAccountToken: false     # don't hand a token to a pod that has no API to call
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
    - name: app
      securityContext:
        allowPrivilegeEscalation: false
        readOnlyRootFilesystem: true
        capabilities:
          drop: ["ALL"]
```

### A practical checklist

- Run as non-root, drop all capabilities, read-only root filesystem.
- Pin image tags (never `:latest`) and scan images in CI.
- Set requests, limits, and NetworkPolicies as defaults, not afterthoughts.
- Least-privilege RBAC — start from nothing and add.
- Enable encryption at rest for Secrets; keep real secrets in an external store.
- Apply **Pod Security Admission** (`restricted` profile) at the namespace level.
- Back up etcd, and test the restore.

---

## 18 · kubectl Cheat Sheet

```bash
# ---- context & config
kubectl config get-contexts
kubectl config use-context minikube
kubectl config set-context --current --namespace=dev
kubectl cluster-info
kubectl version --short

# ---- look around
kubectl get all
kubectl get pods -o wide                       # + node and pod IP
kubectl get pods --all-namespaces
kubectl get pods --show-labels
kubectl get pods -w                            # stream changes
kubectl get pods --sort-by=.status.startTime
kubectl get pod web -o yaml                    # full object
kubectl get pod web -o jsonpath='{.status.podIP}'

# ---- understand
kubectl describe pod web                       # spec + EVENTS  <- start here
kubectl get events --sort-by=.lastTimestamp
kubectl explain deployment.spec.strategy
kubectl api-resources

# ---- create & change
kubectl apply -f manifest.yaml
kubectl apply -f ./dir/ --recursive
kubectl diff -f manifest.yaml                  # preview before applying
kubectl delete -f manifest.yaml --ignore-not-found
kubectl scale deployment/web --replicas=5
kubectl set image deployment/web nginx=nginx:1.27
kubectl edit deployment web
kubectl patch deployment web -p '{"spec":{"replicas":3}}'

# ---- rollouts
kubectl rollout status deployment/web
kubectl rollout history deployment/web
kubectl rollout undo deployment/web --to-revision=2
kubectl rollout restart deployment/web

# ---- debug
kubectl logs web                               # current container
kubectl logs web -f --tail=100                 # follow
kubectl logs web --previous                    # the crashed instance  <- key for CrashLoopBackOff
kubectl logs -l app=web --all-containers=true  # by label, across pods
kubectl exec -it web -- sh
kubectl debug -it web --image=nicolaka/netshoot --target=app
kubectl port-forward svc/web 8080:80           # works on every driver
kubectl cp web:/var/log/app.log ./app.log
kubectl top nodes && kubectl top pods          # needs metrics-server

# ---- dry runs & generators (great for writing YAML fast)
kubectl create deployment web --image=nginx --dry-run=client -o yaml > deploy.yaml
kubectl expose deployment web --port=80 --dry-run=client -o yaml
kubectl run tmp --rm -it --image=busybox:1.36 --restart=Never -- sh

# ---- node ops
kubectl cordon node-1                          # stop new pods landing
kubectl drain node-1 --ignore-daemonsets       # evict everything, for maintenance
kubectl uncordon node-1
```

---

## 19 · Troubleshooting Playbook

**The universal first move:** `kubectl describe <kind> <name>` and read the **Events** at the bottom. It answers most questions on its own.

| Symptom | Likely cause | Command that confirms it |
|---------|--------------|--------------------------|
| `Pending` forever | no node satisfies requests / taints / affinity | `kubectl describe pod` → `0/3 nodes are available: …` |
| `ImagePullBackOff` | wrong image name/tag, or private registry with no creds | `kubectl describe pod` → Events; check `imagePullSecrets` |
| `CrashLoopBackOff` | app exits on start — bad config, missing env, failing migration | `kubectl logs <pod> --previous` |
| `OOMKilled` | exceeded the memory limit | `kubectl describe pod` → Last State; raise the limit or fix the leak |
| `Running` but `0/1` | readiness probe failing | `kubectl describe pod` → probe Events; curl the path from inside |
| Service returns nothing | selector matches no *ready* pods | **`kubectl get endpoints <svc>`** — empty is the answer |
| DNS name won't resolve | CoreDNS down, or the name is genuinely wrong | `kubectl get pods -n kube-system -l k8s-app=kube-dns`, then `nslookup` from a pod |
| Ingress 404 / 503 | no controller, wrong host header, or backend Service missing | `kubectl describe ingress` → look for `<error: services … not found>` |
| LoadBalancer `<pending>` | no cloud-controller-manager | expected off-cloud — use `minikube tunnel` or MetalLB |
| `context deadline exceeded` on apply | an admission webhook is unreachable | `kubectl get validatingwebhookconfigurations`; check the controller's endpoints |
| Pod stuck `Terminating` | finalizer, or the container ignores SIGTERM | `kubectl describe` → finalizers; `--grace-period=0 --force` as a last resort |

### A repeatable order of attack

```bash
kubectl get pods -o wide                    # 1. what state is it in?
kubectl describe pod <pod>                  # 2. what do the Events say?
kubectl logs <pod> --previous               # 3. what did the app say before it died?
kubectl get endpoints <svc>                 # 4. is the Service wired to anything?
kubectl exec -it <pod> -- sh                # 5. reproduce from inside the cluster
kubectl get events --sort-by=.lastTimestamp # 6. what else happened around that time?
```

**Two rules that prevent most confusion:**

1. **Wait for Ready before you test.** No endpoints means no DNS and no traffic — testing 4 seconds after `apply` produces failures that look like bugs and are only impatience.
2. **Read exit codes.** curl `6` = DNS failure (the request never left the pod); curl `7` = connection failure (DNS was fine, the path is broken). Those are two entirely different investigations.

---

## 20 · Glossary

| Term | Meaning |
|------|---------|
| **Cluster** | control plane + nodes, managed as one unit |
| **Node** | a machine (VM or physical) that runs pods |
| **Pod** | smallest deployable unit — one or more containers sharing network and storage |
| **Controller** | a loop that drives actual state toward desired state |
| **Operator** | a custom controller that encodes domain knowledge (e.g. how to fail over Postgres) |
| **CRD** | CustomResourceDefinition — teaches the API server a new `kind` |
| **Manifest** | the YAML/JSON file describing an object |
| **Label** | key/value used for selection |
| **Annotation** | key/value for non-identifying metadata |
| **Selector** | a label query that binds one object to others |
| **Endpoint / EndpointSlice** | the list of pod IP:ports behind a Service |
| **kubelet** | the agent on each node that actually runs pods |
| **kube-proxy** | programs the routing rules that make Services work |
| **CNI** | the plugin providing pod networking |
| **CRI** | the container runtime interface (containerd, CRI-O) |
| **CSI** | the storage plugin interface |
| **etcd** | the key-value store holding all cluster state |
| **Taint / Toleration** | a node repelling pods / a pod tolerating that repulsion |
| **QoS class** | Guaranteed / Burstable / BestEffort — decides eviction order |
| **Helm** | package manager for Kubernetes; a bundle is a "chart" |
| **Service mesh** | sidecar-proxy layer adding mTLS, retries and fine-grained traffic control |

---

## Where to go next

| Topic | Why it matters |
|-------|----------------|
| **Helm / Kustomize** | templating and environment overlays — raw YAML stops scaling around 20 services |
| **GitOps** (Argo CD, Flux) | git as the single source of truth; the cluster reconciles itself |
| **Observability** | Prometheus + Grafana, Loki, OpenTelemetry |
| **Service mesh** (Istio, Linkerd) | mTLS, retries, real request-level canaries |
| **Operators / CRDs** | package operational knowledge as a controller |
| **Policy** (OPA Gatekeeper, Kyverno) | enforce rules at admission time |
| **Certification** | CKA (admin), CKAD (developer), CKS (security) |

**Official docs:** <https://kubernetes.io/docs/> — the concepts section is genuinely well written, and `kubectl explain` is the fastest way to answer "what fields does this take?"
