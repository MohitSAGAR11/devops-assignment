# Session 14 — Kubernetes Troubleshooting

**Name:** Mohit Sagar &nbsp;•&nbsp; **Enrollment:** 2024bcs10622
**Cluster:** minikube v1.35.1 (Docker driver, WSL2)

---

### 1 · kubectl get — pods, services, nodes, all
![kubectl get](1.png)

### 2 · kubectl describe — pod details and events
![kubectl describe](2.png)

### 3 · kubectl logs — logs, follow, previous, per-container
![kubectl logs](3.png)

### 4 · kubectl exec — shell into the pod, curl localhost, `nginx -T`
![kubectl exec](4.png)

### 5 · kubectl exec — nginx default.conf and non-interactive exec
![kubectl exec — nginx config](5.png)

### 6 · kubectl get events — sorted by timestamp
![kubectl get events](6.png)

### 7 · CrashLoopBackOff — container exits 1 and keeps restarting
![CrashLoopBackOff](7.png)

### 8 · ImagePullBackOff — image tag does not exist
![ImagePullBackOff](8.png)

### 9 · Pending pod — nodeSelector matches no node
![Pending pod](9.png)

### 10 · Service & DNS troubleshooting — endpoints, selectors
![Service and DNS troubleshooting](10.png)

### 11 · Mini project — deployment, service, endpoints, broken pod
![Mini project — setup](11.png)

### 12 · Mini project — describe project-broken-pod
![Mini project — describe broken pod](12.png)

---

## Questions

**Question 1: What is the Pod status?**
`Pending` / `0/1 ImagePullBackOff` — the container state is `Waiting` with reason `ErrImagePull`, then `ImagePullBackOff`.

**Question 2: What is the actual error?**
`Failed to pull image "nginx:this-tag-does-not-exist": Error response from daemon: manifest for nginx:this-tag-does-not-exist not found: manifest unknown`

**Question 3: Which command helped you find the reason?**
`kubectl describe pod project-broken-pod` — the **Events** section at the bottom shows the real pull error (`kubectl get pod` only shows `ImagePullBackOff`).

**Question 4: What is wrong with the image?**
The tag doesn't exist in the registry. The repository `nginx` is valid, but `this-tag-does-not-exist` is not a published tag, so the manifest can't be resolved.

**Question 5: How would you fix it?**
Use a real tag, then recreate the pod:

```bash
kubectl delete pod project-broken-pod
# image: nginx:1.27   (valid tag)
kubectl apply -f fixed-pod.yaml
kubectl get pod project-broken-pod
```
