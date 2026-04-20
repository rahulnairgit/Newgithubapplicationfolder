# Spring Boot Demo App - Azure Deployment

A simple Spring Boot application with Azure Web App deployment using Bicep infrastructure as code.

## Project Structure

```
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
│   ├── main.bicep          # Azure infrastructure definition
│   └── parameters.json     # Deployment parameters
├── pom.xml                 # Maven configuration
├── deploy.ps1              # PowerShell deployment script
└── README.md
```

## Prerequisites

1. **Java 17** or later
2. **Maven 3.8+** (or use the provided Maven wrapper)
3. **Azure CLI** - [Install Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
4. **Azure Subscription** - Visual Studio subscription configured

## Local Development

### Build the application
```bash
mvn clean package
```

### Run locally
```bash
mvn spring-boot:run
```

The application will start at `http://localhost:8080`

### API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /` | Welcome message with timestamp |
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
