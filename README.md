I am testing few things here
# Spring Boot Azure CI/CD Learning Project

A hands-on learning project demonstrating end-to-end CI/CD pipeline with GitHub Actions, Azure OIDC authentication, and Infrastructure as Code.

---

## What I Learned

### 1. GitHub Actions Fundamentals

| Concept | Description |
|---------|-------------|
| **Workflow** | YAML file (`.github/workflows/*.yml`) that defines automation |
| **Jobs** | Groups of tasks that run on a runner (e.g., `build`, `deploy`) |
| **Steps** | Individual actions within a job |
| **Triggers** | Events that start the workflow (`push`, `pull_request`, `workflow_dispatch`) |

**Key syntax:**
```yaml
on:
  push:
    branches: [main]      # Triggers on push to main
  workflow_dispatch:      # Manual trigger button
```

### 2. Pipeline Flow

```
┌─────────────┐     ┌──────────────────────┐     ┌─────────────┐
│   BUILD     │────▶│ DEPLOY INFRASTRUCTURE│────▶│ DEPLOY APP  │
│             │     │                      │     │             │
│ • Checkout  │     │ • Azure Login        │     │ • Download  │
│ • Setup Java│     │ • Create RG          │     │   artifact  │
│ • Maven     │     │ • Deploy Bicep       │     │ • Azure     │
│ • Test      │     │                      │     │   Login     │
│ • Upload JAR│     │                      │     │ • Deploy    │
└─────────────┘     └──────────────────────┘     └─────────────┘
```

### 3. Artifacts

- **Purpose**: Pass files between jobs (jobs run on different machines)
- **Upload**: `actions/upload-artifact@v4` — saves build output
- **Download**: `actions/download-artifact@v4` — retrieves in another job

```yaml
- uses: actions/upload-artifact@v4
  with:
    name: java-app
    path: target/*.jar
```

### 4. Job Dependencies

```yaml
deploy-app:
  needs: [build, deploy-infrastructure]  # Waits for both jobs
```

### 5. Azure OIDC Authentication (Passwordless)

**Traditional way**: Store client secret in GitHub (security risk)

**OIDC way**: GitHub proves its identity to Azure without secrets

**Flow:**
```
GitHub Actions                    Azure
     │                              │
     │ 1. "I'm workflow X from     │
     │    repo Y, branch main"     │
     │─────────────────────────────▶│
     │                              │
     │ 2. Checks federated         │
     │    credential matches       │
     │◀─────────────────────────────│
     │                              │
     │ 3. Returns temporary token  │
     │◀─────────────────────────────│
```

**Requirements:**
- App Registration in Azure AD
- Federated Credential configured for repo/branch/environment
- `permissions: id-token: write` in workflow

### 6. Secrets Management

| Type | Scope | Approval Gates | Use Case |
|------|-------|----------------|----------|
| **Repository Secrets** | All workflows | No | Development/testing |
| **Environment Secrets** | Specific environment | Yes (optional) | Production with controls |

**Environment benefits:**
- Required reviewers (approval before deploy)
- Wait timers
- Branch restrictions

### 7. Federated Credentials

Different GitHub contexts need different credentials:

| Entity Type | Subject Identifier |
|-------------|-------------------|
| Branch | `repo:owner/repo:ref:refs/heads/main` |
| Environment | `repo:owner/repo:environment:Dev` |
| Pull Request | `repo:owner/repo:pull_request` |

When using `environment: Dev` in workflow, must create matching federated credential.

### 8. Infrastructure as Code (Bicep)

**What**: Azure's native language to define infrastructure

**Benefits:**
- Version controlled
- Repeatable deployments
- No manual portal clicking

**Example:**
```bicep
resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
  }
}
```

### 9. Spring Boot Basics

**Endpoints** (defined in code):
```java
@RestController
public class HelloController {
    @GetMapping("/hello")
    public Map<String, String> hello(@RequestParam String name) {
        // handles GET /hello?name=xxx
    }
}
```

**Configuration** (`application.properties`):
```properties
server.port=8080
spring.application.name=demo-app
management.endpoints.web.exposure.include=health,info
```

| Annotation | Purpose |
|------------|---------|
| `@RestController` | Handles HTTP requests, returns JSON |
| `@GetMapping("/path")` | Maps GET requests to this method |
| `@RequestParam` | Reads query parameters from URL |

---

## Project Structure

```
├── .github/
│   └── workflows/
│       └── deploy.yml          # CI/CD pipeline
├── src/
│   └── main/
│       ├── java/
│       │   └── com/example/demoapp/
│       │       ├── DemoApplication.java
│       │       └── controller/
│       │           └── HelloController.java
│       └── resources/
│           └── application.properties
├── infra/
│   ├── main.bicep              # Azure infrastructure
│   └── parameters.json         # Deployment parameters
├── pom.xml                     # Maven configuration
└── README.md
```

---

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Homepage with deployment info |
| `/hello` | GET | Greeting (use `?name=xxx` for custom name) |
| `/api/info` | GET | Application metadata |
| `/actuator/health` | GET | Health check (built-in) |

---

## Prerequisites

1. **Java 17+**
2. **Maven 3.8+**
3. **Azure CLI**
4. **Azure Subscription**
5. **GitHub Account**

---

## Azure Setup Requirements

1. **App Registration** with federated credentials for:
   - Branch: `refs/heads/main`
   - Environment: `Dev` (or your environment name)

2. **Required permissions** on App Registration:
   - Reader at subscription level (or higher)
   - Contributor on resource group

3. **GitHub Secrets** (in environment):
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

---

## Local Development

```bash
# Build
mvn clean package

# Run locally
mvn spring-boot:run

# Access at http://localhost:8080
```

---

## Key Learnings Summary

- CI/CD automates build, test, and deployment
- OIDC is more secure than storing secrets
- GitHub Environments provide deployment controls
- Infrastructure as Code makes deployments repeatable
- Different federated credentials needed for branches vs environments
- Spring Boot annotations define API endpoints
- Configuration and code serve different purposes

---

## Author

Rahul Nair

## Date

April 2026
| `GET /hello?name={name}` | Personalized greeting |
| `GET /api/info` | Application information |
| `GET /actuator/health` | Health check endpoint |

## Azure Deployment

### Quick Deploy (PowerShell)

```powershell
.\deploy.ps1
```

This script will:
1. Login to Azure (if needed)
2. Set the subscription to `931db222-3f2f-4181-8f9f-375729be7467`
3. Create a resource group
4. Deploy the Bicep infrastructure
5. Build the Spring Boot application
6. Deploy the JAR to Azure Web App

### Manual Deployment Steps

#### 1. Login to Azure
```bash
az login
az account set --subscription "931db222-3f2f-4181-8f9f-375729be7467"
```

#### 2. Create Resource Group
```bash
az group create --name rg-springboot-demo --location eastus
```

#### 3. Deploy Infrastructure with Bicep
```bash
az deployment group create \
  --resource-group rg-springboot-demo \
  --template-file ./infra/main.bicep \
  --parameters ./infra/parameters.json
```

#### 4. Build the Application
```bash
mvn clean package -DskipTests
```

#### 5. Deploy to Azure Web App
```bash
az webapp deploy \
  --resource-group rg-springboot-demo \
  --name <your-webapp-name> \
  --src-path ./target/demo-app-1.0.0.jar \
  --type jar
```

## Configuration

### Bicep Parameters

Edit `infra/parameters.json` to customize:

| Parameter | Description | Default |
|-----------|-------------|---------|
| `location` | Azure region | eastus |
| `appServicePlanName` | App Service Plan name | asp-springboot-demo |
| `webAppName` | Web App name | webapp-springboot-demo |
| `sku` | Pricing tier (F1, B1, B2, S1, P1V2) | B1 |
| `javaVersion` | Java version | 17 |

## Cleanup

To delete all deployed resources:

```bash
az group delete --name rg-springboot-demo --yes --no-wait
```

## Troubleshooting

### View Application Logs
```bash
az webapp log tail --name <webapp-name> --resource-group rg-springboot-demo
```

### Check Deployment Status
```bash
az webapp show --name <webapp-name> --resource-group rg-springboot-demo --query state
```

### Restart Web App
```bash
az webapp restart --name <webapp-name> --resource-group rg-springboot-demo
```

## Cost Considerations

- **F1 (Free)**: Limited to 60 minutes/day, no custom domain, no always-on
- **B1 (Basic)**: Recommended for development/testing, ~$13/month
- **S1 (Standard)**: Production workloads with auto-scale, ~$73/month

## License

This is a demo application for learning purposes.
