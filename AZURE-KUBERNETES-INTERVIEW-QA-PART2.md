# Azure & Kubernetes Interview Questions - Part 2

Advanced interview questions covering Azure hosting options, storage, app registrations, Kubernetes networking, and CI/CD pipelines.

---

## Table of Contents

1. [Application Hosting Stack Comparison](#1-application-hosting-stack-comparison)
2. [Blob Storage vs Data Lake Storage](#2-blob-storage-vs-data-lake-storage)
3. [App Registration vs Enterprise Registration](#3-app-registration-vs-enterprise-registration)
4. [Multiple Secrets in App Registration](#4-multiple-secrets-in-app-registration)
5. [Service Bus Queue vs Storage Queue](#5-service-bus-queue-vs-storage-queue)
6. [Internal Pod Communication](#6-internal-pod-communication-in-kubernetes)
7. [Network Policies and CNI Options](#7-network-policies-and-cni-options)
8. [Stateful Applications with Storage](#8-stateful-applications-with-persistent-storage)
9. [Hosting Multiple Apps in Same Cluster](#9-hosting-multiple-applications-in-same-cluster)
10. [Custom Metrics Autoscaling](#10-custom-metrics-autoscaling)
11. [Deployment Strategies](#11-deployment-strategies-in-kubernetes)
12. [Resource Limits and Container Behavior](#12-resource-limits-and-container-behavior)
13. [Cluster Upgrade Failure Troubleshooting](#13-cluster-upgrade-failure-troubleshooting)
14. [External Database Connection Issues](#14-external-database-connection-troubleshooting)
15. [Azure DevOps to Azure Resources Connection](#15-azure-devops-to-azure-resources-connection)
16. [Multi-App Repo CI Pipeline Configuration](#16-multi-app-repo-ci-pipeline-configuration)

---

## 1. Application Hosting Stack Comparison

### Question: How does the comparison stack work for hosting applications (VMs, Azure Web App, Container Apps, Kubernetes)?

### The Hosting Spectrum

Think of it as a **spectrum from "You manage everything" to "Azure manages everything"**:

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        CONTROL vs CONVENIENCE                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   MORE CONTROL                                           MORE CONVENIENCE   │
│   (More work)                                            (Less work)        │
│                                                                              │
│   ◄──────────────────────────────────────────────────────────────────────►  │
│                                                                              │
│   Virtual      Azure          Container       Azure         Azure           │
│   Machines     Kubernetes     Apps            Web App       Functions       │
│   (IaaS)       (AKS)          (PaaS)          (PaaS)        (Serverless)   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Detailed Comparison

| Aspect | Virtual Machines | AKS (Kubernetes) | Container Apps | Azure Web App |
|--------|------------------|------------------|----------------|---------------|
| **What you manage** | Everything (OS, patches, runtime) | Containers, scaling rules | Just containers | Just your code |
| **What Azure manages** | Hardware only | Control plane, node updates | Infrastructure, scaling | Everything else |
| **Scaling** | Manual or VM Scale Sets | HPA, Cluster Autoscaler | Automatic (KEDA-based) | Automatic |
| **Best for** | Legacy apps, full control | Microservices, complex apps | Simple containers | Web apps, APIs |
| **Cost** | Pay for VMs 24/7 | Pay for nodes | Pay per usage | Pay per plan |
| **Learning curve** | Medium | High | Low | Very Low |

### When to Use What?

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  DECISION TREE: Where should I host my application?                          │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Is it a legacy app that can't be containerized?                            │
│       │                                                                      │
│       YES ──────► VIRTUAL MACHINES                                          │
│       │                                                                      │
│       NO                                                                     │
│       │                                                                      │
│       ▼                                                                      │
│  Do you need fine-grained control over orchestration?                       │
│       │                                                                      │
│       YES ──────► AZURE KUBERNETES SERVICE (AKS)                            │
│       │           • Multiple microservices                                   │
│       │           • Custom networking                                        │
│       │           • Service mesh                                             │
│       │                                                                      │
│       NO                                                                     │
│       │                                                                      │
│       ▼                                                                      │
│  Is it a containerized app but you don't want K8s complexity?              │
│       │                                                                      │
│       YES ──────► AZURE CONTAINER APPS                                      │
│       │           • Simpler than K8s                                         │
│       │           • Event-driven scaling                                     │
│       │           • Microservices without complexity                         │
│       │                                                                      │
│       NO                                                                     │
│       │                                                                      │
│       ▼                                                                      │
│  Is it a standard web app (Java, .NET, Node, Python)?                       │
│       │                                                                      │
│       YES ──────► AZURE WEB APP (App Service)                               │
│                   • Easiest option                                           │
│                   • Built-in CI/CD                                           │
│                   • Auto-scaling                                             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Real-World Examples

| Scenario | Best Choice | Why |
|----------|-------------|-----|
| E-commerce with 50 microservices | **AKS** | Complex orchestration, service mesh |
| Simple REST API | **Web App** | Quick deployment, managed |
| Legacy Windows app | **VM** | Can't containerize |
| Event-driven processing | **Container Apps** | KEDA scaling, simple |
| Startup MVP | **Web App** | Fast, cheap, easy |

---

## 2. Blob Storage vs Data Lake Storage

### Question: What is the primary difference between Blob Storage and Data Lake Storage?

### Simple Explanation

Think of it like this:
- **Blob Storage** = A filing cabinet (stores files/objects)
- **Data Lake Storage** = A smart filing cabinet with analytics built-in

### Key Differences

| Feature | Blob Storage | Data Lake Storage Gen2 |
|---------|--------------|------------------------|
| **Primary Use** | General file storage | Big data analytics |
| **File System** | Flat (containers/blobs) | Hierarchical (folders/files) |
| **Analytics** | Basic | Optimized for Spark, Databricks, HDInsight |
| **Access Control** | Container/blob level | File & folder level (ACLs) |
| **Performance** | Good | Better for large files & analytics |
| **Cost** | Lower | Slightly higher |
| **Protocol** | REST API | REST API + HDFS compatible |

### Visual Comparison

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  BLOB STORAGE (Flat Structure)                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Container: "images"                                                         │
│      │                                                                       │
│      ├── photo1.jpg                                                          │
│      ├── photo2.jpg                                                          │
│      ├── documents/report.pdf     ← This is just a blob NAME, not a folder │
│      └── documents/invoice.pdf                                               │
│                                                                              │
│  Note: "documents/" is part of the blob name, not a real directory          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  DATA LAKE STORAGE GEN2 (Hierarchical Structure)                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Container: "datalake"                                                       │
│      │                                                                       │
│      ├── raw/                        ← Real directory                       │
│      │   ├── 2024/                                                          │
│      │   │   ├── january/                                                   │
│      │   │   │   └── sales_data.parquet                                    │
│      │   │   └── february/                                                  │
│      │   │       └── sales_data.parquet                                    │
│      │                                                                       │
│      ├── processed/                  ← Real directory with ACLs            │
│      │   └── aggregated_sales.parquet                                       │
│      │                                                                       │
│      └── curated/                                                            │
│          └── final_report.parquet                                           │
│                                                                              │
│  Note: True hierarchical namespace with directory-level permissions         │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### When to Use What?

| Use Case | Choice | Reason |
|----------|--------|--------|
| Store website images | **Blob Storage** | Simple, cheap |
| Store application logs | **Blob Storage** | Just need storage |
| Data warehouse ingestion | **Data Lake Gen2** | Analytics optimized |
| Spark/Databricks workloads | **Data Lake Gen2** | HDFS compatible |
| Machine learning datasets | **Data Lake Gen2** | Hierarchical organization |
| Backup files | **Blob Storage** | Cost effective |

### Access Control Difference

```
BLOB STORAGE:
├── Container Level: Read/Write/Delete for entire container
└── Blob Level: SAS tokens for individual blobs

DATA LAKE GEN2:
├── Container Level: Same as Blob
├── Directory Level: ACLs (like Linux permissions)
│   └── /raw/ ─ Data Engineers: Read/Write
│   └── /curated/ ─ Data Scientists: Read Only
└── File Level: ACLs per file
```

---

## 3. App Registration vs Enterprise Registration

### Question: What is the difference between App Registration and Enterprise Application?

### Simple Explanation

Think of it like a **job application**:
- **App Registration** = Your resume/CV (defines who you are, what you can do)
- **Enterprise Application** = Your employee badge (allows you into buildings)

### The Relationship

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│   APP REGISTRATION                    ENTERPRISE APPLICATION                │
│   (Identity Definition)               (Service Principal)                   │
│                                                                              │
│   ┌─────────────────────┐            ┌─────────────────────┐               │
│   │                     │            │                     │               │
│   │  "Who is this app?" │───────────▶│ "What can it do     │               │
│   │                     │  Creates   │  in MY tenant?"     │               │
│   │  • App ID           │            │                     │               │
│   │  • Credentials      │            │  • Permissions      │               │
│   │  • API permissions  │            │  • User assignments │               │
│   │  • Redirect URIs    │            │  • Conditional      │               │
│   │                     │            │    Access           │               │
│   └─────────────────────┘            └─────────────────────┘               │
│                                                                              │
│   Created ONCE by developer          Created in EACH tenant that uses app  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Key Differences

| Aspect | App Registration | Enterprise Application |
|--------|------------------|------------------------|
| **What it is** | Identity definition (template) | Instance in a tenant (service principal) |
| **Created by** | Developer | Automatically (or admin consent) |
| **Where it lives** | Developer's tenant | Each tenant using the app |
| **Purpose** | Define app identity & capabilities | Control app access in your tenant |
| **Manage** | API permissions, secrets, URIs | User assignments, permissions granted |
| **Object ID** | Application Object ID | Service Principal Object ID |

### Real-World Analogy

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  ANALOGY: A Franchise Restaurant                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  APP REGISTRATION = The Franchise Brand (McDonald's Corporate)              │
│  ─────────────────                                                           │
│  • Defines the menu                                                          │
│  • Sets the recipes                                                          │
│  • Creates the brand identity                                                │
│  • ONE definition                                                            │
│                                                                              │
│  ENTERPRISE APPLICATION = Individual Restaurant Location                    │
│  ────────────────────────                                                    │
│  • Operates in a specific city                                               │
│  • Has local employees (user assignments)                                    │
│  • Follows local health regulations (conditional access)                    │
│  • MANY instances                                                            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### When You Use Each

| Task | Where to Do It |
|------|----------------|
| Create client ID & secret | App Registration |
| Define what APIs app needs | App Registration |
| Set redirect URIs | App Registration |
| Grant admin consent | Enterprise Application |
| Assign users to app | Enterprise Application |
| Apply conditional access | Enterprise Application |
| View sign-in logs | Enterprise Application |

### The Two Services Connection

When you create an App Registration, Azure **automatically** creates an Enterprise Application (Service Principal) in your tenant:

```
Developer Tenant:
┌──────────────────────────┐
│  App Registration        │──────┐
│  (Application Object)    │      │
│  ID: abc-123             │      │
└──────────────────────────┘      │
         │                        │
         │ Creates                │
         ▼                        │
┌──────────────────────────┐      │
│  Enterprise Application  │      │
│  (Service Principal)     │      │ Multi-tenant app?
│  ID: xyz-789             │      │ Same App ID appears
└──────────────────────────┘      │ in other tenants
                                  │
Customer Tenant:                  │
┌──────────────────────────┐      │
│  Enterprise Application  │◄─────┘
│  (Service Principal)     │
│  Same App ID: abc-123    │
│  Different Object ID     │
└──────────────────────────┘
```

---

## 4. Multiple Secrets in App Registration

### Question: Can we generate 2 different secrets for app registration and enterprise registration? Is Object ID different or same?

### Answer: Secrets

**Yes, you can create multiple secrets for an App Registration!**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  APP REGISTRATION: my-app                                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Secrets (Client Secrets):                                                   │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Secret 1: "Production"                                              │   │
│  │  Value: ****************************                                 │   │
│  │  Expires: 2027-01-01                                                 │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │  Secret 2: "Development"                                             │   │
│  │  Value: ****************************                                 │   │
│  │  Expires: 2026-06-01                                                 │   │
│  ├─────────────────────────────────────────────────────────────────────┤   │
│  │  Secret 3: "CI/CD Pipeline"                                          │   │
│  │  Value: ****************************                                 │   │
│  │  Expires: 2026-12-01                                                 │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Why Multiple Secrets?

| Use Case | Benefit |
|----------|---------|
| **Secret rotation** | Create new secret before old expires, smooth transition |
| **Different environments** | Separate secrets for dev, staging, prod |
| **Different teams** | Each team has their own secret |
| **Audit trail** | Know which secret was used where |

### Answer: Object IDs

**The Object IDs are DIFFERENT!**

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                              │
│  App Registration                    Enterprise Application                 │
│  ─────────────────                   ──────────────────────                 │
│                                                                              │
│  Application (client) ID: abc-123-def    ◄─── SAME (identifies the app)    │
│                                                                              │
│  Object ID: 11111-aaaa-22222             Object ID: 99999-zzzz-88888        │
│             ▲                                       ▲                        │
│             │                                       │                        │
│             └─── DIFFERENT ─────────────────────────┘                       │
│                                                                              │
│  Directory (tenant) ID: same-tenant-id   Directory (tenant) ID: same or    │
│                                          different (if multi-tenant)        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Important Clarification

- **Secrets are ONLY on App Registration**, not on Enterprise Application
- Enterprise Application uses the same credentials defined in App Registration
- You manage secrets in **App Registration** blade in Azure Portal

### Secret Rotation Best Practice

```bash
# Step 1: Create new secret (while old still valid)
New Secret created: expires in 1 year

# Step 2: Update applications to use new secret
Update Key Vault / GitHub Secrets / Environment variables

# Step 3: Verify new secret works
Test authentication with new secret

# Step 4: Delete old secret
Remove expired/old secret from App Registration
```

---

## 5. Service Bus Queue vs Storage Queue

### Question: What is the difference between Service Bus Queue and Storage Queue?

### Simple Explanation

- **Storage Queue** = Simple mailbox (basic, cheap, just delivers messages)
- **Service Bus Queue** = Enterprise mail room (advanced features, guarantees, routing)

### Comparison Table

| Feature | Storage Queue | Service Bus Queue |
|---------|---------------|-------------------|
| **Max message size** | 64 KB | 256 KB (Standard) / 100 MB (Premium) |
| **Max queue size** | 500 TB | 1-80 GB |
| **Message ordering** | No guarantee (FIFO best effort) | **Guaranteed FIFO** (with sessions) |
| **Duplicate detection** | No | **Yes** |
| **Dead-letter queue** | No | **Yes** |
| **Transactions** | No | **Yes** |
| **Sessions** | No | **Yes** (grouped messages) |
| **Scheduled delivery** | No | **Yes** |
| **At-least-once delivery** | Yes | Yes |
| **At-most-once delivery** | No | **Yes** (with sessions) |
| **Cost** | **Very cheap** | More expensive |
| **Protocol** | REST/HTTP | AMQP, REST, .NET SDK |

### Visual Comparison

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  STORAGE QUEUE - Simple & Cheap                                              │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Producer ────► [Message Queue] ────► Consumer                              │
│                 │ │ │ │ │ │                                                  │
│                 └─┴─┴─┴─┴─┘                                                  │
│                                                                              │
│  • Messages might be delivered out of order                                 │
│  • No dead-letter queue (failed messages disappear)                         │
│  • Best for: High volume, simple scenarios, cost-sensitive                  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  SERVICE BUS QUEUE - Enterprise Features                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Producer ────► [Message Queue] ────► Consumer                              │
│                 │1│2│3│4│5│6│  (FIFO guaranteed)                            │
│                 └─┴─┴─┴─┴─┴─┘                                                │
│                       │                                                      │
│                       ▼ (if processing fails)                               │
│                 [Dead Letter Queue]                                         │
│                 │✗│✗│✗│                                                     │
│                 └─┴─┴─┘                                                      │
│                                                                              │
│  • Guaranteed order with sessions                                           │
│  • Failed messages go to dead-letter for investigation                      │
│  • Best for: Financial transactions, order processing, enterprise apps      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### When to Use What?

| Scenario | Choice | Reason |
|----------|--------|--------|
| Simple task queue | **Storage Queue** | Cheap, simple |
| Background job processing | **Storage Queue** | Cost effective |
| Order processing | **Service Bus** | Need FIFO guarantee |
| Financial transactions | **Service Bus** | Need transactions, dead-letter |
| IoT device messages (millions) | **Storage Queue** | Scale, cost |
| Workflow orchestration | **Service Bus** | Sessions, scheduling |
| Integration with legacy systems | **Service Bus** | AMQP support |

### Service Bus Exclusive Features Explained

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  DEAD-LETTER QUEUE                                                           │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Main Queue                          Dead-Letter Queue                       │
│  ┌─────────────┐                    ┌─────────────┐                         │
│  │ Message A ✓ │──► Processed       │ Message X ✗ │ ← Failed 10 times       │
│  │ Message B ✓ │──► Processed       │ Message Y ✗ │ ← Expired              │
│  │ Message C   │    Pending         │ Message Z ✗ │ ← Invalid format       │
│  └─────────────┘                    └─────────────┘                         │
│                                           │                                  │
│                                           ▼                                  │
│                                     Investigate & fix                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  SESSIONS (Message Grouping)                                                 │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Order #123 (Session ID: "order-123")                                       │
│  ┌─────────────────────────────────┐                                        │
│  │ 1. Order Created                │ ─┐                                     │
│  │ 2. Payment Received             │  ├─► Same consumer processes all      │
│  │ 3. Order Shipped                │  │   in order                          │
│  │ 4. Order Delivered              │ ─┘                                     │
│  └─────────────────────────────────┘                                        │
│                                                                              │
│  Order #456 (Session ID: "order-456")                                       │
│  ┌─────────────────────────────────┐                                        │
│  │ 1. Order Created                │ ─┐                                     │
│  │ 2. Payment Received             │  ├─► Different consumer               │
│  └─────────────────────────────────┘                                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 6. Internal Pod Communication in Kubernetes

### Question: How do pods communicate internally? How do different services talk to each other?

### The Answer: Kubernetes Services & DNS

Pods communicate through **Services** which provide stable endpoints and DNS names.

### Communication Methods

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  POD-TO-POD COMMUNICATION OPTIONS                                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  1. DIRECT POD IP (Not recommended)                                         │
│     Pod A (10.0.0.5) ────────────────► Pod B (10.0.0.10)                   │
│     Problem: Pod IPs change when pods restart!                              │
│                                                                              │
│  2. CLUSTERIP SERVICE (Recommended)                                         │
│     Pod A ────► Service (frontend-svc) ────► Pod B                         │
│                 (stable IP & DNS name)                                       │
│                                                                              │
│  3. DNS NAME (Best Practice)                                                │
│     Pod A ────► "backend-svc.namespace.svc.cluster.local" ────► Pod B      │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### How DNS Works in Kubernetes

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  KUBERNETES DNS NAMING                                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Full DNS name:                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  backend-svc.production.svc.cluster.local                           │   │
│  │  ───────────  ──────────  ───  ─────────────                        │   │
│  │       │           │        │         │                               │   │
│  │  Service      Namespace   Fixed   Cluster domain                    │   │
│  │  name         name        "svc"   (configurable)                    │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  Shortcuts (from same namespace):                                           │
│  • backend-svc                         ← Just service name                  │
│  • backend-svc.production              ← Service.namespace                  │
│  • backend-svc.production.svc          ← Service.namespace.svc              │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Complete Example: Frontend → Backend → Database

```yaml
# Backend Service (exposes backend pods)
apiVersion: v1
kind: Service
metadata:
  name: backend-api
  namespace: production
spec:
  selector:
    app: backend
  ports:
    - port: 8080        # Service port (what others connect to)
      targetPort: 8080  # Pod port (where container listens)
  type: ClusterIP       # Only accessible inside cluster

---
# Database Service
apiVersion: v1
kind: Service
metadata:
  name: postgres-db
  namespace: production
spec:
  selector:
    app: postgres
  ports:
    - port: 5432
      targetPort: 5432
  type: ClusterIP

---
# Frontend Deployment (connects to backend)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: production
spec:
  template:
    spec:
      containers:
        - name: frontend
          image: frontend:latest
          env:
            # Connect to backend using DNS name
            - name: BACKEND_URL
              value: "http://backend-api:8080"
            # Or full DNS name
            # value: "http://backend-api.production.svc.cluster.local:8080"

---
# Backend Deployment (connects to database)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
  namespace: production
spec:
  template:
    spec:
      containers:
        - name: backend
          image: backend:latest
          env:
            # Connect to database using DNS name
            - name: DATABASE_HOST
              value: "postgres-db"
            - name: DATABASE_PORT
              value: "5432"
```

### Visual Communication Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  NAMESPACE: production                                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐              │
│  │   FRONTEND   │      │   BACKEND    │      │   DATABASE   │              │
│  │    Pods      │      │    Pods      │      │    Pods      │              │
│  │  ┌────┐      │      │  ┌────┐      │      │  ┌────┐      │              │
│  │  │Pod1│      │      │  │Pod1│      │      │  │Pod1│      │              │
│  │  └────┘      │      │  └────┘      │      │  └────┘      │              │
│  │  ┌────┐      │      │  ┌────┐      │      │              │              │
│  │  │Pod2│      │      │  │Pod2│      │      │              │              │
│  │  └────┘      │      │  └────┘      │      │              │              │
│  └──────┬───────┘      └──────┬───────┘      └──────┬───────┘              │
│         │                     │                     │                       │
│         │                     │                     │                       │
│  ┌──────▼───────┐      ┌──────▼───────┐      ┌──────▼───────┐              │
│  │   Service    │      │   Service    │      │   Service    │              │
│  │ frontend-svc │─────▶│ backend-api  │─────▶│ postgres-db  │              │
│  │  :80         │      │  :8080       │      │  :5432       │              │
│  └──────────────┘      └──────────────┘      └──────────────┘              │
│                                                                              │
│  DNS: frontend-svc     DNS: backend-api      DNS: postgres-db              │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Service Types for Different Needs

| Service Type | Use Case | Accessible From |
|--------------|----------|-----------------|
| **ClusterIP** | Internal communication | Only inside cluster |
| **NodePort** | Development/testing | Outside via node IP:port |
| **LoadBalancer** | Production external | Internet via Azure LB |
| **Headless** | StatefulSets, direct pod access | Inside cluster, returns pod IPs |

---

## 7. Network Policies and CNI Options

### Question: How do you configure network policies (like CNI) on a K8s cluster? What are the differences?

### What is CNI?

**CNI (Container Network Interface)** is a plugin that handles pod networking - assigning IPs, setting up routes, and implementing network policies.

### CNI Options Comparison

| CNI Plugin | Provider | Network Policy | Performance | Best For |
|------------|----------|----------------|-------------|----------|
| **Azure CNI** | Azure | Basic (with Calico) | Good | AKS native integration |
| **Kubenet** | Kubernetes | No (needs Calico) | Basic | Simple, small clusters |
| **Calico** | Tigera | **Full support** | Good | Network security focus |
| **Cilium** | Isovalent | **Advanced (L7)** | Excellent | High performance, eBPF |
| **Weave Net** | Weaveworks | Basic | Good | Simple setup |

### Azure CNI vs Kubenet

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  KUBENET (Basic)                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Azure VNet: 10.0.0.0/16                                                    │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Node 1: 10.0.1.4              Node 2: 10.0.1.5                     │   │
│  │  ┌─────────────────────┐       ┌─────────────────────┐             │   │
│  │  │  Pod Network:       │       │  Pod Network:       │             │   │
│  │  │  10.244.0.0/24     │       │  10.244.1.0/24     │             │   │
│  │  │  (NAT to node IP)   │       │  (NAT to node IP)   │             │   │
│  │  │  ┌────┐ ┌────┐     │       │  ┌────┐ ┌────┐     │             │   │
│  │  │  │Pod │ │Pod │     │       │  │Pod │ │Pod │     │             │   │
│  │  │  └────┘ └────┘     │       │  └────┘ └────┘     │             │   │
│  │  └─────────────────────┘       └─────────────────────┘             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  • Pods get IPs from a separate range (not VNet)                           │
│  • Uses NAT for external communication                                      │
│  • Fewer IPs needed from Azure VNet                                         │
│  • Cannot use Azure Network Policies directly                               │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  AZURE CNI (Advanced)                                                        │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Azure VNet: 10.0.0.0/16                                                    │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Node 1: 10.0.1.4              Node 2: 10.0.1.5                     │   │
│  │  ┌─────────────────────┐       ┌─────────────────────┐             │   │
│  │  │  Pod IPs from VNet: │       │  Pod IPs from VNet: │             │   │
│  │  │  ┌────┐ ┌────┐     │       │  ┌────┐ ┌────┐     │             │   │
│  │  │  │10.0│ │10.0│     │       │  │10.0│ │10.0│     │             │   │
│  │  │  │.1.6│ │.1.7│     │       │  │.1.8│ │.1.9│     │             │   │
│  │  │  └────┘ └────┘     │       │  └────┘ └────┘     │             │   │
│  │  └─────────────────────┘       └─────────────────────┘             │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  • Pods get IPs directly from Azure VNet                                    │
│  • No NAT needed - direct routing                                           │
│  • Needs more IPs (plan subnet size carefully!)                            │
│  • Can use Azure NSGs and Network Policies                                  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Setting Up Network Policy with Calico on AKS

```bash
# Create AKS cluster with Calico network policy
az aks create \
  --resource-group myResourceGroup \
  --name myAKSCluster \
  --network-plugin azure \
  --network-policy calico \
  --node-count 3
```

### Example Network Policy

```yaml
# Deny all ingress traffic by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: production
spec:
  podSelector: {}           # Applies to all pods
  policyTypes:
    - Ingress               # Block all incoming traffic

---
# Allow frontend to talk to backend only
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

### Calico vs Cilium

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  CALICO                                                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│  • Uses iptables for policy enforcement                                     │
│  • Layer 3/4 network policies (IP, port)                                   │
│  • Mature, widely used                                                       │
│  • Good for: Standard network security                                       │
│                                                                              │
│  Example: "Allow TCP port 8080 from app=frontend"                          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  CILIUM                                                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│  • Uses eBPF (faster than iptables)                                         │
│  • Layer 3/4 AND Layer 7 policies (HTTP, gRPC)                             │
│  • API-aware security                                                        │
│  • Good for: Microservices, API security                                    │
│                                                                              │
│  Example: "Allow only GET /api/users from app=frontend"                     │
│           (Can inspect HTTP methods and paths!)                             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 8. Stateful Applications with Persistent Storage

### Question: How to achieve a stateful application with connection to storage account in Kubernetes?

### The Solution: StatefulSets + Persistent Volumes

For stateful apps (databases, etc.), you need:
1. **StatefulSet** (instead of Deployment)
2. **Persistent Volume Claims** (storage)
3. **Headless Service** (stable network identity)

### StatefulSet vs Deployment

| Feature | Deployment | StatefulSet |
|---------|------------|-------------|
| Pod naming | Random (app-xyz123) | Ordered (app-0, app-1, app-2) |
| Scaling order | Random | Ordered (0→1→2 up, 2→1→0 down) |
| Storage | Shared or none | **Each pod gets its own PVC** |
| Network identity | Random | Stable DNS per pod |
| Use case | Stateless apps | Databases, Kafka, etc. |

### Complete Example: PostgreSQL with Azure Disk

```yaml
# 1. Storage Class for Azure Managed Disk
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azure-managed-premium
provisioner: disk.csi.azure.com
parameters:
  skuName: Premium_LRS
reclaimPolicy: Retain
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true

---
# 2. Headless Service (required for StatefulSet)
apiVersion: v1
kind: Service
metadata:
  name: postgres
  namespace: production
spec:
  ports:
    - port: 5432
      name: postgres
  clusterIP: None          # Headless - no load balancing
  selector:
    app: postgres

---
# 3. StatefulSet with Volume Claim Template
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: production
spec:
  serviceName: postgres    # Must match headless service
  replicas: 3
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
          env:
            - name: POSTGRES_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: password
            - name: PGDATA
              value: /var/lib/postgresql/data/pgdata
          volumeMounts:
            - name: postgres-data
              mountPath: /var/lib/postgresql/data
          resources:
            requests:
              cpu: "500m"
              memory: "1Gi"
            limits:
              cpu: "2"
              memory: "4Gi"
  
  # Each replica gets its own PVC
  volumeClaimTemplates:
    - metadata:
        name: postgres-data
      spec:
        accessModes: ["ReadWriteOnce"]
        storageClassName: azure-managed-premium
        resources:
          requests:
            storage: 100Gi
```

### How StatefulSet Creates Storage

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  STATEFULSET: postgres (replicas: 3)                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Pod: postgres-0                  Pod: postgres-1                           │
│  ┌─────────────────────┐          ┌─────────────────────┐                  │
│  │ Container           │          │ Container           │                  │
│  │ /var/lib/postgres   │          │ /var/lib/postgres   │                  │
│  │        │            │          │        │            │                  │
│  └────────┼────────────┘          └────────┼────────────┘                  │
│           │                                │                                │
│  ┌────────▼────────────┐          ┌────────▼────────────┐                  │
│  │ PVC:                │          │ PVC:                │                  │
│  │ postgres-data-      │          │ postgres-data-      │                  │
│  │ postgres-0          │          │ postgres-1          │                  │
│  │ (100Gi)             │          │ (100Gi)             │                  │
│  └────────┬────────────┘          └────────┬────────────┘                  │
│           │                                │                                │
│  ┌────────▼────────────┐          ┌────────▼────────────┐                  │
│  │ Azure Managed Disk  │          │ Azure Managed Disk  │                  │
│  │ (Premium SSD)       │          │ (Premium SSD)       │                  │
│  └─────────────────────┘          └─────────────────────┘                  │
│                                                                              │
│  DNS Names:                                                                 │
│  • postgres-0.postgres.production.svc.cluster.local                        │
│  • postgres-1.postgres.production.svc.cluster.local                        │
│  • postgres-2.postgres.production.svc.cluster.local                        │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Connecting to Azure Storage Account (Files)

For shared storage across multiple pods, use Azure Files:

```yaml
# Storage Class for Azure Files
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: azure-files-premium
provisioner: file.csi.azure.com
parameters:
  skuName: Premium_LRS
reclaimPolicy: Retain
volumeBindingMode: Immediate
allowVolumeExpansion: true

---
# PVC for shared storage
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: shared-files
spec:
  accessModes:
    - ReadWriteMany          # Multiple pods can write
  storageClassName: azure-files-premium
  resources:
    requests:
      storage: 100Gi
```

---

## 9. Hosting Multiple Applications in Same Cluster

### Question: How to host 2 different applications in the same cluster?

### Answer: Namespaces + Resource Isolation

```yaml
# 1. Create namespaces for each application
apiVersion: v1
kind: Namespace
metadata:
  name: app-1
  labels:
    app: app-1
    team: team-alpha

---
apiVersion: v1
kind: Namespace
metadata:
  name: app-2
  labels:
    app: app-2
    team: team-beta

---
# 2. Resource Quotas (prevent one app from consuming all resources)
apiVersion: v1
kind: ResourceQuota
metadata:
  name: app-1-quota
  namespace: app-1
spec:
  hard:
    requests.cpu: "10"
    requests.memory: "20Gi"
    limits.cpu: "20"
    limits.memory: "40Gi"
    persistentvolumeclaims: "10"
    pods: "50"

---
# 3. Limit Ranges (default limits for pods)
apiVersion: v1
kind: LimitRange
metadata:
  name: app-1-limits
  namespace: app-1
spec:
  limits:
    - default:
        cpu: "500m"
        memory: "512Mi"
      defaultRequest:
        cpu: "100m"
        memory: "128Mi"
      type: Container

---
# 4. Network Policy (isolate namespaces)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-from-other-namespaces
  namespace: app-1
spec:
  podSelector: {}
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector: {}    # Allow from same namespace only
```

### Visual: Multi-App Cluster

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                        KUBERNETES CLUSTER                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌────────────────────────────┐    ┌────────────────────────────┐          │
│  │  NAMESPACE: app-1          │    │  NAMESPACE: app-2          │          │
│  │  (Team Alpha)              │    │  (Team Beta)               │          │
│  │                            │    │                            │          │
│  │  ┌────────┐  ┌────────┐   │    │  ┌────────┐  ┌────────┐   │          │
│  │  │Frontend│  │Backend │   │    │  │ API    │  │Worker  │   │          │
│  │  │        │  │        │   │    │  │ Server │  │        │   │          │
│  │  └────────┘  └────────┘   │    │  └────────┘  └────────┘   │          │
│  │       │           │       │    │       │           │       │          │
│  │       └─────┬─────┘       │    │       └─────┬─────┘       │          │
│  │             │             │    │             │             │          │
│  │  ┌──────────▼──────────┐  │    │  ┌──────────▼──────────┐  │          │
│  │  │     Database        │  │    │  │     Database        │  │          │
│  │  └─────────────────────┘  │    │  └─────────────────────┘  │          │
│  │                            │    │                            │          │
│  │  Quota: 10 CPU, 20Gi RAM  │    │  Quota: 8 CPU, 16Gi RAM   │          │
│  │  ─────────────────────────│    │  ─────────────────────────│          │
│  │                            │    │                            │          │
│  │  ████████░░ (80% used)    │    │  ██████░░░░ (60% used)    │          │
│  │                            │    │                            │          │
│  └────────────────────────────┘    └────────────────────────────┘          │
│              │                                  │                           │
│              │    Network Policy blocks         │                           │
│              └──────────────X───────────────────┘                           │
│                    (No cross-namespace traffic)                             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 10. Custom Metrics Autoscaling

### Question: Can I have autoscaling that doesn't use predefined metrics (CPU), something automatic?

### Answer: Yes! Use KEDA or Custom Metrics

### Option 1: KEDA (Kubernetes Event-Driven Autoscaling)

KEDA can scale based on **any metric**: queue length, HTTP requests, custom Prometheus metrics, etc.

```yaml
# Install KEDA first: helm install keda kedacore/keda

# Scale based on Azure Service Bus Queue length
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: order-processor-scaler
  namespace: production
spec:
  scaleTargetRef:
    name: order-processor         # Deployment name
  minReplicaCount: 1
  maxReplicaCount: 50
  triggers:
    - type: azure-servicebus
      metadata:
        queueName: orders
        messageCount: "5"         # Scale when 5+ messages per pod
        connectionFromEnv: AzureServiceBusConnection

---
# Scale based on HTTP requests (Prometheus metrics)
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: api-scaler
spec:
  scaleTargetRef:
    name: api-server
  minReplicaCount: 2
  maxReplicaCount: 100
  triggers:
    - type: prometheus
      metadata:
        serverAddress: http://prometheus:9090
        metricName: http_requests_total
        query: sum(rate(http_requests_total{app="api-server"}[2m]))
        threshold: "100"          # Scale when >100 req/s per pod
```

### Option 2: HPA with Custom Metrics

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: api-custom-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: api-server
  minReplicas: 2
  maxReplicas: 50
  metrics:
    # Custom metric: requests per second
    - type: Pods
      pods:
        metric:
          name: requests_per_second
        target:
          type: AverageValue
          averageValue: "1000"
    
    # External metric: Queue depth from Azure
    - type: External
      external:
        metric:
          name: azure_queue_depth
          selector:
            matchLabels:
              queue: orders
        target:
          type: AverageValue
          averageValue: "30"
```

### KEDA Triggers Available

| Trigger | Source | Use Case |
|---------|--------|----------|
| **azure-servicebus** | Service Bus Queue | Message processing |
| **azure-queue** | Storage Queue | Background jobs |
| **prometheus** | Prometheus | Any custom metric |
| **kafka** | Kafka topics | Event streaming |
| **rabbitmq** | RabbitMQ | Message queues |
| **cron** | Time-based | Scheduled scaling |
| **cpu/memory** | Standard metrics | Fallback |

### Visual: KEDA Scaling Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  KEDA AUTOSCALING FLOW                                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Azure Service Bus Queue                                                    │
│  ┌─────────────────────────────────────┐                                   │
│  │ Messages: 500                        │                                   │
│  │ ████████████████████████████████    │                                   │
│  └─────────────────────────────────────┘                                   │
│                    │                                                         │
│                    │ KEDA checks every 30s                                  │
│                    ▼                                                         │
│  ┌─────────────────────────────────────┐                                   │
│  │ KEDA Operator                        │                                   │
│  │                                      │                                   │
│  │ "500 messages / 5 per pod = 100     │                                   │
│  │  pods needed"                        │                                   │
│  └─────────────────────────────────────┘                                   │
│                    │                                                         │
│                    │ Scales deployment                                      │
│                    ▼                                                         │
│  ┌─────────────────────────────────────┐                                   │
│  │ Deployment: order-processor          │                                   │
│  │                                      │                                   │
│  │ Replicas: 2 ──────────► 100         │                                   │
│  │                                      │                                   │
│  └─────────────────────────────────────┘                                   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 11. Deployment Strategies in Kubernetes

### Question: What strategies are followed when deploying something in K8s (like single deployment)?

### Available Strategies

| Strategy | Description | Downtime | Risk |
|----------|-------------|----------|------|
| **Recreate** | Kill all old, create new | Yes | High |
| **RollingUpdate** | Gradual replacement | No | Low |
| **Blue-Green** | Two environments, switch | No | Very Low |
| **Canary** | Small % gets new version | No | Very Low |
| **A/B Testing** | Route by user attributes | No | Low |

### 1. Recreate Strategy

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 5
  strategy:
    type: Recreate    # Kill all pods, then create new ones
```

```
Recreate Flow:
v1 v1 v1 v1 v1   (Running)
   ↓ Stop all
-  -  -  -  -    (Downtime!)
   ↓ Start all
v2 v2 v2 v2 v2   (New version)

Use when: Major database migrations, incompatible versions
```

### 2. Rolling Update (Default)

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1    # At most 1 pod down during update
      maxSurge: 1          # At most 1 extra pod during update
```

```
Rolling Update Flow:
v1 v1 v1 v1 v1     (Start)
v1 v1 v1 v1 v2     (Create 1 new, remove 1 old)
v1 v1 v1 v2 v2     (Continue...)
v1 v1 v2 v2 v2
v1 v2 v2 v2 v2
v2 v2 v2 v2 v2     (Done - zero downtime!)
```

### 3. Blue-Green Deployment

```yaml
# Blue deployment (current)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-blue
spec:
  replicas: 5
  selector:
    matchLabels:
      app: myapp
      version: blue

---
# Green deployment (new)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-green
spec:
  replicas: 5
  selector:
    matchLabels:
      app: myapp
      version: green

---
# Service - change selector to switch
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp
    version: blue    # Change to 'green' to switch instantly
```

### 4. Canary Deployment

```yaml
# Stable (90% traffic)
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
# Canary (10% traffic)
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
# Service routes to both based on replica ratio
apiVersion: v1
kind: Service
metadata:
  name: myapp
spec:
  selector:
    app: myapp    # Selects both stable and canary
```

---

## 12. Resource Limits and Container Behavior

### Question: If a pod is going to cross the resource limit (memory or CPU), how does the container behave?

### Memory vs CPU - Different Behavior!

| Resource | What happens when exceeded |
|----------|---------------------------|
| **Memory** | Container gets **OOMKilled** (terminated) |
| **CPU** | Container gets **throttled** (slowed down) |

### Memory Limit Exceeded

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  MEMORY LIMIT EXCEEDED                                                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Container Memory Limit: 512Mi                                              │
│                                                                              │
│  Memory Usage:                                                              │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  200Mi ──► 350Mi ──► 450Mi ──► 510Mi ──► 520Mi (EXCEEDS!)          │   │
│  │  ░░░░░    ░░░░░░░    ░░░░░░░░░  ░░░░░░░░░░░  💀 OOMKilled          │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  What happens:                                                               │
│  1. Container is terminated immediately                                     │
│  2. Exit code: 137 (OOMKilled)                                             │
│  3. Kubernetes restarts container (if restartPolicy allows)                │
│  4. If keeps happening → CrashLoopBackOff                                  │
│                                                                              │
│  kubectl describe pod myapp                                                 │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  Last State:     Terminated                                         │   │
│  │    Reason:       OOMKilled                                          │   │
│  │    Exit Code:    137                                                │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### CPU Limit Exceeded

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  CPU LIMIT EXCEEDED (THROTTLING)                                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Container CPU Limit: 500m (0.5 cores)                                      │
│                                                                              │
│  CPU Usage:                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────┐   │
│  │  200m ──► 400m ──► 500m ──► Tries 800m ──► Throttled to 500m       │   │
│  │  ░░░░     ░░░░░░░   ░░░░░░░░░  ⏳⏳⏳⏳⏳⏳⏳   (slower, but alive)     │   │
│  └─────────────────────────────────────────────────────────────────────┘   │
│                                                                              │
│  What happens:                                                               │
│  1. Container is NOT killed                                                 │
│  2. Container runs slower (requests take longer)                           │
│  3. Application might timeout                                               │
│  4. No restart, just degraded performance                                   │
│                                                                              │
│  Symptom: Slow response times, high latency                                 │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Best Practices

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  template:
    spec:
      containers:
        - name: app
          resources:
            # Requests: Guaranteed minimum (used for scheduling)
            requests:
              cpu: "250m"      # 0.25 cores minimum
              memory: "256Mi"  # 256 MB minimum
            
            # Limits: Maximum allowed (enforced)
            limits:
              cpu: "1000m"     # 1 core maximum (throttled if exceeded)
              memory: "512Mi"  # 512 MB maximum (OOMKilled if exceeded)
```

### Rule of Thumb

```
MEMORY: Set limit close to what app actually needs
        (Too low = OOMKilled, Too high = waste)

CPU:    Set limit higher than request
        (Being throttled is better than being killed)

Ratio:  limits.memory ≈ 1.5x requests.memory
        limits.cpu ≈ 2-4x requests.cpu
```

---

## 13. Cluster Upgrade Failure Troubleshooting

### Question: If a cluster upgrade fails, how do you check what went wrong and handle it?

### Step-by-Step Troubleshooting

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  CLUSTER UPGRADE FAILURE TROUBLESHOOTING                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Step 1: Check upgrade status                                               │
│  ─────────────────────────────                                               │
│  az aks show -g myRG -n myCluster --query "provisioningState"               │
│  # Output: "Failed" or "Upgrading"                                          │
│                                                                              │
│  Step 2: View detailed error                                                │
│  ─────────────────────────────                                               │
│  az aks show -g myRG -n myCluster --query "powerState"                      │
│  az aks show -g myRG -n myCluster -o json | jq '.agentPoolProfiles'         │
│                                                                              │
│  Step 3: Check Activity Log (Azure Portal)                                  │
│  ─────────────────────────────────────────                                   │
│  Portal → AKS Cluster → Activity Log → Filter by "Failed"                   │
│                                                                              │
│  Step 4: Check node status                                                  │
│  ─────────────────────────────                                               │
│  kubectl get nodes                                                          │
│  kubectl describe node <node-name>                                          │
│                                                                              │
│  Step 5: Check system pods                                                  │
│  ─────────────────────────────                                               │
│  kubectl get pods -n kube-system                                            │
│  kubectl describe pod <failing-pod> -n kube-system                          │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Common Upgrade Failure Causes

| Cause | Symptom | Solution |
|-------|---------|----------|
| **Pod Disruption Budget** | Pods can't be evicted | Adjust PDB or delete temporarily |
| **Insufficient quota** | Can't create new nodes | Increase Azure quota |
| **Node stuck draining** | Pods won't terminate | Force delete stuck pods |
| **Incompatible workloads** | Deprecated APIs | Update manifests before upgrade |
| **Network issues** | Nodes can't communicate | Check NSG, firewall rules |

### Commands for Investigation

```bash
# 1. Get cluster upgrade status
az aks show -g myResourceGroup -n myCluster \
  --query "provisioningState"

# 2. Get node pool status
az aks nodepool list -g myResourceGroup --cluster-name myCluster \
  --query "[].{name:name, status:provisioningState, version:orchestratorVersion}"

# 3. Check nodes
kubectl get nodes -o wide
kubectl describe node <problematic-node>

# 4. Check for stuck pods
kubectl get pods --all-namespaces --field-selector=status.phase!=Running

# 5. Check events
kubectl get events --sort-by='.lastTimestamp' | tail -50

# 6. Check PDB blocking evictions
kubectl get pdb --all-namespaces

# 7. Force delete stuck pod (last resort)
kubectl delete pod <pod-name> -n <namespace> --force --grace-period=0
```

### Recovery Steps

```bash
# If upgrade is stuck, try to resume/reconcile
az aks update -g myResourceGroup -n myCluster

# If node pool failed, try upgrading just that pool
az aks nodepool upgrade \
  -g myResourceGroup \
  --cluster-name myCluster \
  -n problematicNodePool \
  --kubernetes-version 1.28.0
```

---

## 14. External Database Connection Troubleshooting

### Question: Application failing to connect to external DB from K8s cluster - what would be the troubleshooting approach?

### Troubleshooting Checklist

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  DATABASE CONNECTION TROUBLESHOOTING                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Layer 1: NETWORK CONNECTIVITY                                              │
│  ─────────────────────────────────                                           │
│  □ Can pods reach the database IP/hostname?                                 │
│  □ Is the database port open?                                               │
│  □ Are NSG/firewall rules allowing traffic?                                 │
│  □ Is VNet peering configured (if different VNets)?                         │
│  □ Is Private Endpoint set up correctly?                                    │
│                                                                              │
│  Layer 2: DNS RESOLUTION                                                    │
│  ─────────────────────────                                                   │
│  □ Can pods resolve the database hostname?                                  │
│  □ Is Private DNS Zone linked to cluster VNet?                              │
│                                                                              │
│  Layer 3: AUTHENTICATION                                                    │
│  ─────────────────────────                                                   │
│  □ Are credentials correct in Secret?                                       │
│  □ Is the database user allowed from pod IPs?                               │
│  □ Is SSL/TLS configured correctly?                                         │
│                                                                              │
│  Layer 4: APPLICATION                                                       │
│  ────────────────────                                                        │
│  □ Is connection string formatted correctly?                                │
│  □ Is the database driver compatible?                                       │
│  □ Are connection pool settings correct?                                    │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Step-by-Step Debugging

```bash
# 1. Test network connectivity from a pod
kubectl run debug --rm -it --image=busybox -- sh

# Inside the pod:
# Test DNS resolution
nslookup mydb.database.windows.net

# Test TCP connectivity
nc -zv mydb.database.windows.net 1433
# or
telnet mydb.database.windows.net 1433

# 2. Check if pod can reach internet/database
kubectl exec -it <your-app-pod> -- curl -v telnet://mydb.database.windows.net:1433

# 3. Check egress network policy
kubectl get networkpolicy -n <namespace>

# 4. Verify secret is mounted correctly
kubectl exec -it <pod> -- env | grep DB
kubectl exec -it <pod> -- cat /etc/secrets/db-password

# 5. Check pod logs for connection errors
kubectl logs <pod-name> -f

# 6. Check events for the pod
kubectl describe pod <pod-name>
```

### Common Issues & Solutions

| Issue | Symptom | Solution |
|-------|---------|----------|
| **NSG blocking** | Connection timeout | Add inbound rule for AKS subnet |
| **Private endpoint DNS** | Name not resolved | Link Private DNS Zone to AKS VNet |
| **DB firewall** | Connection refused | Add AKS outbound IPs to DB firewall |
| **Wrong credentials** | Authentication failed | Update Kubernetes Secret |
| **SSL required** | Handshake error | Add `sslmode=require` to connection string |
| **Network policy** | Timeout | Allow egress to database in NetworkPolicy |

### Network Policy for Database Access

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-database-egress
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Egress
  egress:
    # Allow DNS
    - to: []
      ports:
        - port: 53
          protocol: UDP
    # Allow database (Azure SQL)
    - to:
        - ipBlock:
            cidr: 10.0.2.0/24    # Database subnet
      ports:
        - port: 1433
          protocol: TCP
```

---

## 15. Azure DevOps to Azure Resources Connection

### Question: How do you establish connection between Azure DevOps and Azure resources?

### The Solution: Service Connection

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  AZURE DEVOPS → AZURE CONNECTION                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  ┌───────────────────┐         ┌───────────────────┐                       │
│  │   Azure DevOps    │         │      Azure        │                       │
│  │   ─────────────   │         │      ─────        │                       │
│  │                   │         │                   │                       │
│  │   Pipeline        │◄───────▶│   Subscription    │                       │
│  │                   │ Service │                   │                       │
│  │                   │Connection│   ┌───────────┐  │                       │
│  │   Tasks:          │         │   │    AKS    │  │                       │
│  │   • Deploy to AKS │         │   └───────────┘  │                       │
│  │   • Deploy to     │         │   ┌───────────┐  │                       │
│  │     Web App       │         │   │  Web App  │  │                       │
│  │                   │         │   └───────────┘  │                       │
│  └───────────────────┘         └───────────────────┘                       │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Methods to Create Service Connection

| Method | Security | Setup Effort | Best For |
|--------|----------|--------------|----------|
| **Automatic (Recommended)** | Good | Easy | Most cases |
| **Service Principal (Manual)** | Good | Medium | Specific permissions |
| **Managed Identity** | Best | Medium | Azure-hosted agents |
| **Workload Identity Federation** | Best | Medium | No secrets needed |

### Method 1: Automatic Service Connection (Easiest)

```
Azure DevOps Portal:
1. Project Settings → Service Connections
2. New Service Connection → Azure Resource Manager
3. Select "Service principal (automatic)"
4. Choose Subscription
5. Choose Resource Group (optional)
6. Give it a name: "Azure-Production-Connection"
7. Grant access to all pipelines (or specific)
8. Save

Azure DevOps creates an App Registration automatically with Contributor role.
```

### Method 2: Manual Service Principal

```bash
# 1. Create Service Principal in Azure
az ad sp create-for-rbac \
  --name "AzureDevOps-Deployment-SP" \
  --role Contributor \
  --scopes /subscriptions/<subscription-id>/resourceGroups/<rg-name>

# Output:
# {
#   "appId": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",      ← Client ID
#   "displayName": "AzureDevOps-Deployment-SP",
#   "password": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",       ← Client Secret
#   "tenant": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"      ← Tenant ID
# }

# 2. In Azure DevOps:
#    - Service Connection → New → Azure Resource Manager
#    - Select "Service principal (manual)"
#    - Enter: Subscription ID, Subscription Name, Client ID, Client Secret, Tenant ID
```

### Method 3: Workload Identity Federation (No Secrets!)

```bash
# 1. Create App Registration
az ad app create --display-name "AzureDevOps-Federation"

# 2. Add Federated Credential
az ad app federated-credential create \
  --id <app-id> \
  --parameters '{
    "name": "AzureDevOpsFederation",
    "issuer": "https://vstoken.dev.azure.com/<org-id>",
    "subject": "sc://<org>/<project>/<service-connection-name>",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# 3. In Azure DevOps:
#    - Service Connection → Azure Resource Manager
#    - Select "Workload Identity federation (manual)"
#    - Enter details (no secret needed!)
```

### Using Service Connection in Pipeline

```yaml
# Azure Pipelines YAML
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

stages:
  - stage: Deploy
    jobs:
      - job: DeployToAKS
        steps:
          - task: AzureCLI@2
            inputs:
              azureSubscription: 'Azure-Production-Connection'  # Service Connection name
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                az aks get-credentials -g myRG -n myCluster
                kubectl apply -f manifests/
          
          - task: KubernetesManifest@0
            inputs:
              action: 'deploy'
              kubernetesServiceConnection: 'AKS-Connection'
              manifests: 'manifests/*.yaml'
```

---

## 16. Multi-App Repo CI Pipeline Configuration

### Question: We have a repo hosting multiple applications in separate folders. How to configure CI pipeline to run for only one application?

### Solution: Path Filters + Parameterized Pipelines

### Repo Structure Example

```
my-monorepo/
├── app-1/
│   ├── src/
│   ├── Dockerfile
│   └── pom.xml
├── app-2/
│   ├── src/
│   ├── Dockerfile
│   └── package.json
├── app-3/
│   ├── src/
│   ├── Dockerfile
│   └── go.mod
├── shared/
│   └── libraries/
└── azure-pipelines.yml
```

### Option 1: Path Filters (Automatic - Build what changed)

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
      - develop
  paths:
    include:
      - app-1/**    # Only trigger when app-1 changes

# Or separate pipeline files per app:

# app-1-pipeline.yml
trigger:
  paths:
    include:
      - app-1/**
    exclude:
      - app-1/README.md

pool:
  vmImage: 'ubuntu-latest'

steps:
  - script: |
      cd app-1
      mvn clean package
    displayName: 'Build App 1'
```

### Option 2: Parameters (Manual - Choose which app to build)

```yaml
# azure-pipelines.yml
parameters:
  - name: application
    displayName: 'Which application to build?'
    type: string
    default: 'app-1'
    values:
      - app-1
      - app-2
      - app-3
      - all

trigger: none  # Manual trigger only

pool:
  vmImage: 'ubuntu-latest'

stages:
  - stage: Build
    jobs:
      - job: BuildApp
        steps:
          - ${{ if or(eq(parameters.application, 'app-1'), eq(parameters.application, 'all')) }}:
            - script: |
                cd app-1
                mvn clean package
              displayName: 'Build App 1'
          
          - ${{ if or(eq(parameters.application, 'app-2'), eq(parameters.application, 'all')) }}:
            - script: |
                cd app-2
                npm install && npm run build
              displayName: 'Build App 2'
          
          - ${{ if or(eq(parameters.application, 'app-3'), eq(parameters.application, 'all')) }}:
            - script: |
                cd app-3
                go build -o app
              displayName: 'Build App 3'
```

### Option 3: Template-Based (Reusable)

```yaml
# templates/build-app.yml
parameters:
  - name: appName
    type: string
  - name: appPath
    type: string
  - name: buildCommand
    type: string

steps:
  - script: |
      cd ${{ parameters.appPath }}
      ${{ parameters.buildCommand }}
    displayName: 'Build ${{ parameters.appName }}'

  - task: Docker@2
    inputs:
      command: buildAndPush
      dockerfile: '${{ parameters.appPath }}/Dockerfile'
      repository: 'myregistry/${{ parameters.appName }}'

---
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main

pool:
  vmImage: 'ubuntu-latest'

stages:
  - stage: Build
    jobs:
      - job: DetectChanges
        steps:
          - bash: |
              # Detect which apps changed
              CHANGED_FILES=$(git diff --name-only HEAD~1)
              echo "Changed files: $CHANGED_FILES"
              
              if echo "$CHANGED_FILES" | grep -q "^app-1/"; then
                echo "##vso[task.setvariable variable=buildApp1;isOutput=true]true"
              fi
              if echo "$CHANGED_FILES" | grep -q "^app-2/"; then
                echo "##vso[task.setvariable variable=buildApp2;isOutput=true]true"
              fi
            name: detectChanges
      
      - job: BuildApp1
        dependsOn: DetectChanges
        condition: eq(dependencies.DetectChanges.outputs['detectChanges.buildApp1'], 'true')
        steps:
          - template: templates/build-app.yml
            parameters:
              appName: 'app-1'
              appPath: 'app-1'
              buildCommand: 'mvn clean package'
      
      - job: BuildApp2
        dependsOn: DetectChanges
        condition: eq(dependencies.DetectChanges.outputs['detectChanges.buildApp2'], 'true')
        steps:
          - template: templates/build-app.yml
            parameters:
              appName: 'app-2'
              appPath: 'app-2'
              buildCommand: 'npm install && npm run build'
```

### Visual: Multi-App Pipeline Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  MONOREPO CI/CD FLOW                                                         │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  Git Push to main                                                           │
│       │                                                                      │
│       ▼                                                                      │
│  ┌─────────────────────────┐                                                │
│  │  Detect Changed Folders │                                                │
│  └─────────────────────────┘                                                │
│       │                                                                      │
│       ├─── app-1 changed? ───► Build & Deploy App 1                        │
│       │                                                                      │
│       ├─── app-2 changed? ───► Build & Deploy App 2                        │
│       │                                                                      │
│       ├─── app-3 changed? ───► Build & Deploy App 3                        │
│       │                                                                      │
│       └─── shared changed? ──► Build & Deploy ALL apps                     │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Summary Table

| Approach | When to Use | Pros | Cons |
|----------|-------------|------|------|
| **Path filters** | Auto-build on change | Simple, automatic | Less control |
| **Parameters** | Manual selection | Full control | Manual trigger |
| **Change detection** | Smart auto-build | Efficient, automatic | More complex |
| **Separate pipelines** | Independent apps | Complete isolation | More files |

---

## Quick Reference

| Topic | Key Point |
|-------|-----------|
| Hosting options | VM → AKS → Container Apps → Web App (control → convenience) |
| Blob vs Data Lake | Blob = files, Data Lake = analytics + hierarchical |
| App vs Enterprise Reg | App = definition, Enterprise = instance per tenant |
| Storage vs Service Bus Queue | Storage = simple/cheap, Service Bus = enterprise features |
| Pod communication | Use Services + DNS names |
| CNI options | Kubenet (simple) vs Azure CNI (VNet IPs) + Calico/Cilium for policies |
| StatefulSet | Ordered pods + individual storage per replica |
| Custom autoscaling | KEDA for event-driven scaling |
| Memory limit | OOMKilled (container dies) |
| CPU limit | Throttled (container slows) |
| DevOps → Azure | Service Connection (automatic or service principal) |
| Monorepo CI | Path filters + change detection |

---

## Author

Rahul Nair

## Date

May 2026
