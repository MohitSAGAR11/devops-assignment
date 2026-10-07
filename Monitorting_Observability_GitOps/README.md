# Monitoring, Observability, and GitOps

This assignment demonstrates how to monitor a Kubernetes application, explain the three pillars of observability, and deploy declarative Kubernetes configuration through a GitOps workflow.

## Deliverables

- Monitoring demo: application health, logs, CPU, memory, and alert rule
- Observability documentation: metrics, logs, and traces
- GitOps demo: Argo CD `Application` manifest
- Screenshot checklist for the completed lab

## Repository structure

```text
Monitorting_Observability_GitOps/
├── README.md
├── monitoring/
│   ├── namespace.yaml
│   ├── app.yaml
│   └── alert-rule.yaml
└── gitops/
    └── application.yaml
```

---

## Task 1 — Monitoring demo

Monitoring answers: **Is the application healthy right now, and are its resources within safe limits?**

### Prerequisites

- A running Kubernetes cluster
- `kubectl` configured for that cluster
- Metrics Server for CPU and memory metrics

For Minikube, enable Metrics Server:

```bash
minikube addons enable metrics-server
kubectl top nodes
```

### Deploy the sample application

```bash
cd monitoring
kubectl apply -f namespace.yaml
kubectl apply -f app.yaml
kubectl get all -n monitoring-demo
```

The Deployment runs two Nginx replicas. Each container has CPU and memory requests/limits plus readiness and liveness probes at `/`.

### Check application health

```bash
kubectl get pods -n monitoring-demo
kubectl describe pod -n monitoring-demo <pod-name>
kubectl get endpoints -n monitoring-demo monitoring-demo
```

Expected: both Pods show `1/1 Running`, and the Service has endpoints. A failed readiness probe removes a Pod from the Service endpoints; a failed liveness probe restarts its container.

### Check application logs

```bash
kubectl logs -n monitoring-demo deployment/monitoring-demo
kubectl logs -n monitoring-demo deployment/monitoring-demo --follow
```

Logs record application activity and are the first place to look for request errors or startup failures.

### Check CPU and memory utilization

```bash
kubectl top pods -n monitoring-demo
kubectl top nodes
```

`kubectl top` shows current CPU and memory usage. Compare usage with the values in `resources.requests` and `resources.limits` in `monitoring/app.yaml`.

### Generate traffic

Run this in a separate terminal for a short test:

```bash
kubectl run load-generator -n monitoring-demo --image=busybox:1.36 --restart=Never -- \
  /bin/sh -c 'while true; do wget -q -O- http://monitoring-demo; done'
```

Watch the application while traffic is generated:

```bash
kubectl top pods -n monitoring-demo --containers
kubectl get pods -n monitoring-demo -w
```

Stop the test when finished:

```bash
kubectl delete pod -n monitoring-demo load-generator --ignore-not-found
```

### Alerts

`monitoring/alert-rule.yaml` is a `PrometheusRule` for clusters using Prometheus Operator (for example, kube-prometheus-stack). It creates an alert when Pod CPU usage stays above 80% of its CPU limit for five minutes.

Install it only after Prometheus Operator is available:

```bash
kubectl apply -f alert-rule.yaml
kubectl get prometheusrule -n monitoring-demo
```

---

## Task 2 — Observability

Observability helps explain **why** a system is behaving a certain way by using evidence emitted from the system.

| Pillar | Meaning | Example question | Common tools |
| --- | --- | --- | --- |
| Metrics | Numeric measurements sampled over time | Is CPU usage increasing? | Prometheus, Grafana, Metrics Server, Datadog |
| Logs | Timestamped event records | Why did this request fail? | Loki, Elasticsearch/OpenSearch, Fluent Bit, CloudWatch Logs |
| Traces | A request's path across services | Which service made checkout slow? | Jaeger, Tempo, Zipkin, OpenTelemetry |

### Why observability is required

Modern applications have many containers and services. A `Running` Pod does not guarantee a working application. Metrics reveal trends and saturation, logs provide detailed error context, and traces identify the slow or failing component in a multi-service request.

### Kubernetes observability

In Kubernetes, observe at several levels:

- **Cluster:** node health, capacity, and control-plane events
- **Workload:** Deployment replica count, Pod status, restarts, and resource consumption
- **Container:** stdout/stderr logs, CPU/memory usage, and probe results
- **Network:** Service endpoints, DNS resolution, latency, and error rate

Useful commands:

```bash
kubectl get events --sort-by=.lastTimestamp
kubectl describe pod -n monitoring-demo <pod-name>
kubectl logs -n monitoring-demo <pod-name>
kubectl top pods -n monitoring-demo
```

---

## Task 3 — GitOps demo

GitOps uses a Git repository as the source of truth for declarative infrastructure and application configuration.

### Core concepts

- **Git as the source of truth:** the approved state is stored and reviewed in Git.
- **Declarative configuration:** manifests describe the desired end state, not manual steps.
- **Continuous reconciliation:** a GitOps controller compares the cluster with Git and corrects drift.
- **Auditability:** commits and pull requests show who changed what and why.

### GitOps workflow

```text
Developer changes Kubernetes YAML
          |
          v
Pull request and review
          |
          v
Merge to main
          |
          v
Argo CD detects the Git change
          |
          v
Argo CD synchronizes the cluster to match Git
```

### Argo CD application

1. Install Argo CD in your cluster.
2. Edit `gitops/application.yaml` and replace `YOUR_GITHUB_USERNAME/YOUR_REPOSITORY` with the repository that contains this folder.
3. Apply the application definition:

```bash
kubectl apply -f gitops/application.yaml
kubectl get applications -n argocd
```

Argo CD watches the `monitoring/` path. With automated sync enabled, a change committed to Git is reconciled into the cluster automatically.

> Do not store cloud keys, passwords, or tokens in Git. Use Kubernetes Secrets with a secure secret-management process such as External Secrets, Sealed Secrets, or a cloud secret manager.

---

## Screenshot checklist

Capture and add screenshots after completing the live demo:

1. `kubectl get pods -n monitoring-demo` — healthy Pods
2. `kubectl top pods -n monitoring-demo` — CPU and memory usage
3. `kubectl logs -n monitoring-demo deployment/monitoring-demo` — application logs
4. Prometheus/Grafana — CPU metric or fired alert
5. Argo CD UI or `kubectl get applications -n argocd` — GitOps application status

## Cleanup

```bash
kubectl delete -f monitoring/alert-rule.yaml --ignore-not-found
kubectl delete -f monitoring/app.yaml --ignore-not-found
kubectl delete -f monitoring/namespace.yaml --ignore-not-found
kubectl delete -f gitops/application.yaml --ignore-not-found
```
