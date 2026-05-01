# Kubernetes (KAAS) Interview Questions & Answers

A comprehensive guide covering common Kubernetes interview questions with detailed explanations.

---

## Table of Contents

1. [Network Policies](#1-network-policies-in-kubernetes)
2. [Multi-Application Isolation](#2-single-cluster-hosting-multiple-applications)
3. [Pod High Availability](#3-ensuring-pods-never-go-down)
4. [Persistent Volumes](#4-persistent-volumes-pv)
5. [Persistent Volume Claims (PVC)](#5-persistent-volume-claims-pvc)
6. [Autoscaling Options](#6-autoscaling-in-kubernetes)
7. [Rollback Deployments](#7-rollback-updates-and-deployments)
8. [Zero Downtime Deployment](#8-zero-downtime-deployment-strategies)
9. [ConfigMaps & Secrets](#9-configs-and-secrets-storage)

---

## 1. Network Policies in Kubernetes

### What are Network Policies?

Network Policies are Kubernetes resources that control traffic flow between pods, namespaces, and external endpoints. They act as a **firewall** for your cluster.

### Types of Network Policies

| Policy Type | Description | Use Case |
|-------------|-------------|----------|
| **Ingress** | Controls incoming traffic TO a pod | Restrict which pods can connect to your app |
| **Egress** | Controls outgoing traffic FROM a pod | Restrict which external services a pod can reach |
| **Ingress + Egress** | Controls both directions | Full network isolation |

### Policy Options When Deploying a Cluster

| Option | Description |
|--------|-------------|
| **Calico** | Most popular, supports full network policy features, BGP routing |
| **Cilium** | eBPF-based, high performance, L7 policies |
| **Azure CNI** | Native Azure networking, integrates with Azure NSGs |
| **Weave Net** | Simple setup, encrypted traffic |
| **Flannel** | Basic networking, limited policy support |

### Difference Between Policies

```
┌─────────────────────────────────────────────────────────────────┐
│  Default: Allow All                                              │
│  ─────────────────                                               │
│  All pods can communicate with all other pods (no isolation)    │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  With Network Policy: Deny by Default                           │
│  ────────────────────────────────────                           │
│  Only explicitly allowed traffic is permitted                   │
└─────────────────────────────────────────────────────────────────┘
```

### Example Network Policy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 8080
```

**This policy says:** Only pods with label `app: frontend` can access `app: backend` on port 8080.

---

## 2. Single Cluster Hosting Multiple Applications

### Is it possible?

**Yes!** A single Kubernetes cluster can host multiple applications and environments. This is achieved through **isolation mechanisms**.

### Isolation Methods

| Method | Level | Description |
|--------|-------|-------------|
| **Namespaces** | Logical | Separate resources logically (dev, staging, prod) |
| **Network Policies** | Network | Isolate network traffic between namespaces |
| **Resource Quotas** | Resource | Limit CPU/memory per namespace |
| **RBAC** | Access | Control who can access what |
| **Node Pools** | Physical | Dedicate nodes to specific workloads |

### Architecture Example

```
┌─────────────────────────────────────────────────────────────────┐
│                     SINGLE KUBERNETES CLUSTER                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  namespace:     │  │  namespace:     │  │  namespace:     │ │
│  │  app-1-dev      │  │  app-1-prod     │  │  app-2-prod     │ │
│  │                 │  │                 │  │                 │ │
│  │  • frontend     │  │  • frontend     │  │  • api-service  │ │
│  │  • backend      │  │  • backend      │  │  • worker       │ │
│  │  • database     │  │  • database     │  │  • database     │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│         ▲                    ▲                    ▲             │
│         │     Network Policies block traffic      │             │
│         └────────────────────┴────────────────────┘             │
└─────────────────────────────────────────────────────────────────┘
```

### Best Practices for Isolation

```yaml
# 1. Create separate namespaces
apiVersion: v1
kind: Namespace
metadata:
  name: app-1-production
  labels:
    environment: production
    app: app-1

---
# 2. Apply Resource Quotas
apiVersion: v1
kind: ResourceQuota
metadata:
  name: production-quota
  namespace: app-1-production
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi

---
# 3. Deny all traffic by default, then allow specific
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all
  namespace: app-1-production
spec:
  podSelector: {}
  policyTypes:
    - Ingress
    - Egress
```

---

## 3. Ensuring Pods Never Go Down

### What should be set?

To ensure high availability and that pods stay running:

| Configuration | Purpose |
|---------------|---------|
| **ReplicaSet/Deployment** | Run multiple pod copies |
| **PodDisruptionBudget** | Minimum available pods during disruptions |
| **Liveness Probe** | Restart unhealthy pods |
| **Readiness Probe** | Remove unhealthy pods from service |
| **Resource Limits** | Prevent OOM kills |
| **Pod Anti-Affinity** | Spread pods across nodes |

### Complete High Availability Configuration

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-app
spec:
  replicas: 3                    # Multiple replicas
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  selector:
    matchLabels:
      app: critical-app
  template:
    metadata:
      labels:
        app: critical-app
    spec:
      # Spread pods across nodes
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchLabels:
                  app: critical-app
              topologyKey: kubernetes.io/hostname
      
      containers:
        - name: app
          image: myapp:latest
          
          # Resource limits prevent OOM
          resources:
            requests:
              cpu: "500m"
              memory: "512Mi"
            limits:
              cpu: "1000m"
              memory: "1Gi"
          
          # Liveness probe - restarts if unhealthy
          livenessProbe:
            httpGet:
              path: /health
              port: 8080
            initialDelaySeconds: 30
            periodSeconds: 10
            failureThreshold: 3
          
          # Readiness probe - removes from service if not ready
          readinessProbe:
            httpGet:
              path: /ready
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5

---
# PodDisruptionBudget - minimum pods during maintenance
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: critical-app-pdb
spec:
  minAvailable: 2               # At least 2 pods must be running
  selector:
    matchLabels:
      app: critical-app
```

### Probe Types Explained

```
┌─────────────────────────────────────────────────────────────────┐
│  LIVENESS PROBE                                                  │
│  ──────────────                                                  │
│  "Is the container alive?"                                       │
│  If fails → Kubernetes RESTARTS the container                   │
│  Use for: Detecting deadlocks, infinite loops                   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  READINESS PROBE                                                 │
│  ───────────────                                                 │
│  "Is the container ready to receive traffic?"                   │
│  If fails → Kubernetes REMOVES pod from Service endpoints       │
│  Use for: Warming up, loading cache, DB connections             │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  STARTUP PROBE                                                   │
│  ─────────────                                                   │
│  "Has the container started successfully?"                      │
│  Disables liveness/readiness until it succeeds                  │
│  Use for: Slow-starting legacy applications                     │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Persistent Volumes (PV)

### What is a Persistent Volume?

A **Persistent Volume (PV)** is a piece of storage in the cluster that has been provisioned by an administrator or dynamically provisioned. It **persists data beyond the lifecycle of a pod**.

### Purpose of Persistent Volumes

| Purpose | Description |
|---------|-------------|
| **Data Persistence** | Data survives pod restarts/deletions |
| **Decoupling** | Separates storage from pod lifecycle |
| **Shared Storage** | Multiple pods can access same data |
| **Portability** | Storage can be moved between pods |

### Types of Persistent Volumes

| Type | Provider | Use Case |
|------|----------|----------|
| **Azure Disk** | Azure | Single pod, high performance |
| **Azure Files** | Azure | Multiple pods, shared access |
| **AWS EBS** | AWS | Single pod block storage |
| **AWS EFS** | AWS | Multiple pods, NFS |
| **NFS** | On-prem | Shared file storage |
| **Local** | Node | High performance, no portability |

### Configuration for Application with Persistent Volume

```yaml
# Step 1: Create StorageClass (usually pre-configured)
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azure-managed-premium
provisioner: kubernetes.io/azure-disk
parameters:
  storageaccounttype: Premium_LRS
  kind: Managed
reclaimPolicy: Retain
allowVolumeExpansion: true

---
# Step 2: Create Persistent Volume Claim (PVC)
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-storage
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: azure-managed-premium
  resources:
    requests:
      storage: 100Gi

---
# Step 3: Use PVC in Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
        - name: postgres
          image: postgres:15
          ports:
            - containerPort: 5432
          
          # Mount the persistent volume
          volumeMounts:
            - name: postgres-data
              mountPath: /var/lib/postgresql/data
          
          env:
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: password
      
      # Reference the PVC
      volumes:
        - name: postgres-data
          persistentVolumeClaim:
            claimName: database-storage
```

### Visual Flow

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  StorageClass   │────▶│      PVC        │────▶│       PV        │
│                 │     │                 │     │                 │
│  Defines HOW    │     │  REQUEST for    │     │  ACTUAL         │
│  storage is     │     │  storage        │     │  storage        │
│  provisioned    │     │  (100Gi)        │     │  (Azure Disk)   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                │
                                ▼
                        ┌─────────────────┐
                        │      POD        │
                        │                 │
                        │  Mounts PVC at  │
                        │  /var/lib/data  │
                        └─────────────────┘
```

---

## 5. Persistent Volume Claims (PVC)

### What is PVC?

A **Persistent Volume Claim (PVC)** is a **request for storage** by a user. It's like a "ticket" that requests a specific amount and type of storage.

### PV vs PVC

| Aspect | PV (Persistent Volume) | PVC (Persistent Volume Claim) |
|--------|------------------------|-------------------------------|
| **Created by** | Admin or dynamically | Developer/User |
| **Purpose** | Actual storage resource | Request for storage |
| **Analogy** | Actual disk in datacenter | Order form for disk |
| **Scope** | Cluster-wide | Namespace-scoped |

### Access Modes

| Mode | Short | Description |
|------|-------|-------------|
| **ReadWriteOnce** | RWO | Single node can mount read-write |
| **ReadOnlyMany** | ROX | Many nodes can mount read-only |
| **ReadWriteMany** | RWX | Many nodes can mount read-write |

### PVC Example

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-app-storage
  namespace: production
spec:
  accessModes:
    - ReadWriteOnce           # Single pod access
  storageClassName: standard  # Which StorageClass to use
  resources:
    requests:
      storage: 50Gi           # How much storage needed
```

### Lifecycle

```
┌──────────────────────────────────────────────────────────────────┐
│  PVC LIFECYCLE                                                    │
│                                                                   │
│  1. PENDING   → PVC created, waiting for PV                      │
│  2. BOUND     → PVC matched with PV, ready to use                │
│  3. RELEASED  → Pod deleted, PV released (data may persist)      │
│  4. DELETED   → PVC deleted based on reclaim policy              │
└──────────────────────────────────────────────────────────────────┘
```

---

## 6. Autoscaling in Kubernetes

### Autoscaling Options

| Type | Scales | Based On | Use Case |
|------|--------|----------|----------|
| **HPA** (Horizontal Pod Autoscaler) | Pod replicas | CPU, Memory, Custom metrics | Stateless apps |
| **VPA** (Vertical Pod Autoscaler) | Pod resources | Historical usage | Right-sizing |
| **Cluster Autoscaler** | Nodes | Pending pods | Infrastructure |
| **KEDA** | Pod replicas | Event-driven metrics | Queue-based workloads |

### HPA - Horizontal Pod Autoscaler

Scales the **number of pods** based on metrics.

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
    # Scale based on CPU
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    
    # Scale based on Memory
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
    
    # Scale based on custom metric (requests per second)
    - type: Pods
      pods:
        metric:
          name: http_requests_per_second
        target:
          type: AverageValue
          averageValue: 1000
```

### VPA - Vertical Pod Autoscaler

Adjusts **CPU and memory requests** for containers.

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: myapp-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  updatePolicy:
    updateMode: "Auto"        # Auto, Recreate, Initial, Off
  resourcePolicy:
    containerPolicies:
      - containerName: app
        minAllowed:
          cpu: 100m
          memory: 128Mi
        maxAllowed:
          cpu: 4
          memory: 8Gi
```

### Cluster Autoscaler

Scales **nodes** when pods can't be scheduled.

```yaml
# Azure AKS example - enabled via CLI
az aks update \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --enable-cluster-autoscaler \
  --min-count 2 \
  --max-count 10
```

### Scaling Decision Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    AUTOSCALING DECISION                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  CPU > 70%?  ─────YES────▶  HPA scales OUT (more pods)          │
│       │                                                          │
│       NO                                                         │
│       │                                                          │
│       ▼                                                          │
│  Pods pending? ───YES────▶  Cluster Autoscaler adds NODES       │
│       │                                                          │
│       NO                                                         │
│       │                                                          │
│       ▼                                                          │
│  Under-utilized? ─YES────▶  Scale IN (fewer pods/nodes)         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. Rollback Updates and Deployments

### How Rollbacks Work

Kubernetes keeps a **history of deployments** (ReplicaSets) that you can roll back to.

### Rollback Commands

```bash
# View rollout history
kubectl rollout history deployment/myapp

# View specific revision details
kubectl rollout history deployment/myapp --revision=2

# Rollback to previous version
kubectl rollout undo deployment/myapp

# Rollback to specific revision
kubectl rollout undo deployment/myapp --to-revision=3

# Check rollout status
kubectl rollout status deployment/myapp

# Pause a rollout (for canary testing)
kubectl rollout pause deployment/myapp

# Resume a rollout
kubectl rollout resume deployment/myapp
```

### Deployment Configuration for Rollbacks

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 5
  revisionHistoryLimit: 10        # Keep 10 previous versions
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1           # Max pods that can be unavailable
      maxSurge: 1                 # Max extra pods during update
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
      annotations:
        kubernetes.io/change-cause: "Updated to v2.0.0"  # Shows in history
    spec:
      containers:
        - name: myapp
          image: myapp:v2.0.0
```

### Rollback Visual

```
┌─────────────────────────────────────────────────────────────────┐
│  DEPLOYMENT HISTORY                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Revision 1: myapp:v1.0.0  (ReplicaSet: myapp-abc123)          │
│       │                                                          │
│       ▼                                                          │
│  Revision 2: myapp:v1.5.0  (ReplicaSet: myapp-def456)          │
│       │                                                          │
│       ▼                                                          │
│  Revision 3: myapp:v2.0.0  (ReplicaSet: myapp-ghi789) ← CURRENT│
│       │                                                          │
│       │  kubectl rollout undo --to-revision=2                   │
│       ▼                                                          │
│  Revision 4: myapp:v1.5.0  (ReplicaSet: myapp-def456) ← NEW    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. Zero Downtime Deployment Strategies

### Available Strategies

| Strategy | Description | Zero Downtime | Rollback Speed |
|----------|-------------|---------------|----------------|
| **Rolling Update** | Gradually replace pods | ✅ Yes | Medium |
| **Blue-Green** | Two environments, switch traffic | ✅ Yes | Instant |
| **Canary** | Route small % to new version | ✅ Yes | Fast |
| **Recreate** | Kill all, then create new | ❌ No | N/A |

### 1. Rolling Update (Default)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1    # Never less than 3 pods
      maxSurge: 1          # Never more than 5 pods
```

```
Rolling Update Flow:
v1 v1 v1 v1     (Start: 4 pods v1)
v1 v1 v1 v2     (Create 1 v2, still have 4 running)
v1 v1 v2 v2     (Replace 1 v1 with v2)
v1 v2 v2 v2     (Continue...)
v2 v2 v2 v2     (End: 4 pods v2)
```

### 2. Blue-Green Deployment

```yaml
# Blue (current production)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
spec:
  replicas: 4
  selector:
    matchLabels:
      app: myapp
      version: blue
  template:
    metadata:
      labels:
        app: myapp
        version: blue

---
# Green (new version)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-green
spec:
  replicas: 4
  selector:
    matchLabels:
      app: myapp
      version: green
  template:
    metadata:
      labels:
        app: myapp
        version: green

---
# Service - switch selector to change traffic
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
    version: blue    # Change to 'green' to switch
  ports:
    - port: 80
```

```
Blue-Green Flow:
┌──────────────┐        ┌──────────────┐
│    BLUE      │◄──────┤   SERVICE    │  (Users hit Blue)
│    v1.0      │        └──────────────┘
└──────────────┘
┌──────────────┐
│    GREEN     │        (Green deployed, tested)
│    v2.0      │
└──────────────┘

After switch:
┌──────────────┐
│    BLUE      │        (Blue idle, kept for rollback)
│    v1.0      │
└──────────────┘
┌──────────────┐        ┌──────────────┐
│    GREEN     │◄──────┤   SERVICE    │  (Users hit Green)
│    v2.0      │        └──────────────┘
└──────────────┘
```

### 3. Canary Deployment

```yaml
# Stable deployment (90% traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-stable
spec:
  replicas: 9
  selector:
    matchLabels:
      app: myapp
      track: stable

---
# Canary deployment (10% traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
      track: canary

---
# Service selects both (traffic split by replica count)
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp    # Matches both stable and canary
  ports:
    - port: 80
```

### Best Practices for Zero Downtime

| Practice | Why |
|----------|-----|
| Use **Readiness Probes** | Don't send traffic until pod is ready |
| Configure **PodDisruptionBudget** | Maintain minimum available pods |
| Set **terminationGracePeriodSeconds** | Allow graceful shutdown |
| Use **preStop hooks** | Clean up before termination |
| **Health checks** | Verify new version works before full rollout |

---

## 9. Configs and Secrets Storage

### Where are ConfigMaps and Secrets stored?

| Component | Stored In | Encrypted |
|-----------|-----------|-----------|
| **ConfigMaps** | etcd | ❌ No (by default) |
| **Secrets** | etcd | ⚠️ Base64 encoded (not encrypted by default) |
| **With encryption at rest** | etcd | ✅ Yes |

### ConfigMaps

For **non-sensitive** configuration data.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: production
data:
  # Simple key-value
  DATABASE_HOST: "postgres.production.svc.cluster.local"
  LOG_LEVEL: "info"
  
  # File content
  app.properties: |
    server.port=8080
    spring.application.name=myapp
```

### Secrets

For **sensitive** data (passwords, API keys, certificates).

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secrets
  namespace: production
type: Opaque
data:
  # Base64 encoded (echo -n 'password' | base64)
  DB_PASSWORD: cGFzc3dvcmQ=
  API_KEY: c2VjcmV0a2V5MTIz
stringData:
  # Plain text (Kubernetes will encode it)
  ANOTHER_SECRET: "my-plain-secret"
```

### Using ConfigMaps and Secrets in Pods

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  template:
    spec:
      containers:
        - name: app
          image: myapp:latest
          
          # Method 1: Environment variables from ConfigMap
          envFrom:
            - configMapRef:
                name: app-config
          
          # Method 2: Environment variables from Secret
          env:
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: app-secrets
                  key: DB_PASSWORD
          
          # Method 3: Mount as files
          volumeMounts:
            - name: config-volume
              mountPath: /etc/config
            - name: secret-volume
              mountPath: /etc/secrets
              readOnly: true
      
      volumes:
        - name: config-volume
          configMap:
            name: app-config
        - name: secret-volume
          secret:
            secretName: app-secrets
```

### Secret Management Best Practices

| Practice | Tool/Method |
|----------|-------------|
| **Encrypt at rest** | Enable etcd encryption |
| **External secret manager** | Azure Key Vault, AWS Secrets Manager, HashiCorp Vault |
| **Sealed Secrets** | Bitnami Sealed Secrets (encrypted in Git) |
| **RBAC** | Limit who can read secrets |
| **Rotate secrets** | Regular rotation with tools |

### External Secrets Example (Azure Key Vault)

```yaml
# Using Azure Key Vault Provider for Secrets Store CSI Driver
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-keyvault-secrets
spec:
  provider: azure
  parameters:
    keyvaultName: "my-keyvault"
    objects: |
      array:
        - |
          objectName: db-password
          objectType: secret
        - |
          objectName: api-key
          objectType: secret
    tenantId: "your-tenant-id"
```

### Storage Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     KUBERNETES CLUSTER                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                         etcd                              │  │
│  │  ┌─────────────────┐    ┌─────────────────┐             │  │
│  │  │   ConfigMaps    │    │     Secrets     │             │  │
│  │  │   (plain text)  │    │   (base64 or    │             │  │
│  │  │                 │    │    encrypted)   │             │  │
│  │  └─────────────────┘    └─────────────────┘             │  │
│  └──────────────────────────────────────────────────────────┘  │
│           │                         │                           │
│           ▼                         ▼                           │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │                        PODS                               │  │
│  │                                                           │  │
│  │   Mounted as ENV vars or files at /etc/config, /secrets  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│              ┌─────────────────────────┐                        │
│              │  External Secret Store  │                        │
│              │  (Azure Key Vault,      │                        │
│              │   AWS Secrets Manager,  │                        │
│              │   HashiCorp Vault)      │                        │
│              └─────────────────────────┘                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Quick Reference

| Topic | Key Command/Config |
|-------|-------------------|
| Network Policy | `kubectl get networkpolicy` |
| Namespaces | `kubectl get namespaces` |
| Pod Health | `livenessProbe`, `readinessProbe` |
| PV/PVC | `kubectl get pv,pvc` |
| HPA | `kubectl get hpa` |
| Rollback | `kubectl rollout undo deployment/name` |
| Secrets | `kubectl get secrets` |
| ConfigMaps | `kubectl get configmaps` |

---

## Author

Rahul Nair

## Date

May 2026
