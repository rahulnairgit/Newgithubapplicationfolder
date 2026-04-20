# Deploy Spring Boot App to Azure Web App
# Subscription ID: 931db222-3f2f-4181-8f9f-375729be7467

param(
    [string]$SubscriptionId = "931db222-3f2f-4181-8f9f-375729be7467",
    [string]$ResourceGroupName = "rg-springboot-demo",
    [string]$Location = "eastus",
    [string]$WebAppName = "webapp-springboot-demo"
)

Write-Host "=== Spring Boot Azure Deployment Script ===" -ForegroundColor Cyan

# Step 1: Login to Azure (if not already logged in)
Write-Host "`n[1/6] Checking Azure CLI login status..." -ForegroundColor Yellow
$account = az account show 2>$null | ConvertFrom-Json
if (-not $account) {
    Write-Host "Logging in to Azure..." -ForegroundColor Yellow
    az login
}

# Step 2: Set the subscription
Write-Host "`n[2/6] Setting Azure subscription..." -ForegroundColor Yellow
az account set --subscription $SubscriptionId
Write-Host "Subscription set to: $SubscriptionId" -ForegroundColor Green

# Step 3: Create Resource Group
Write-Host "`n[3/6] Creating Resource Group..." -ForegroundColor Yellow
az group create --name $ResourceGroupName --location $Location --output table

# Step 4: Deploy Bicep infrastructure
Write-Host "`n[4/6] Deploying Azure infrastructure with Bicep..." -ForegroundColor Yellow
$deploymentResult = az deployment group create `
    --resource-group $ResourceGroupName `
    --template-file ".\infra\main.bicep" `
    --parameters ".\infra\parameters.json" `
    --parameters webAppName=$WebAppName `
    --output json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    Write-Host "Infrastructure deployment failed!" -ForegroundColor Red
    exit 1
}

$webAppUrl = $deploymentResult.properties.outputs.webAppUrl.value
$deployedAppName = $deploymentResult.properties.outputs.webAppName.value
Write-Host "Infrastructure deployed successfully!" -ForegroundColor Green
Write-Host "Web App URL: $webAppUrl" -ForegroundColor Cyan

# Step 5: Build Spring Boot application
Write-Host "`n[5/6] Building Spring Boot application..." -ForegroundColor Yellow
if (Test-Path ".\mvnw") {
    .\mvnw clean package -DskipTests
} else {
    mvn clean package -DskipTests
}

if ($LASTEXITCODE -ne 0) {
    Write-Host "Maven build failed!" -ForegroundColor Red
    exit 1
}
Write-Host "Application built successfully!" -ForegroundColor Green

# Step 6: Deploy application to Azure Web App
Write-Host "`n[6/6] Deploying application to Azure Web App..." -ForegroundColor Yellow
$jarFile = Get-ChildItem -Path ".\target\*.jar" -Exclude "*-sources.jar" | Select-Object -First 1

if (-not $jarFile) {
    Write-Host "JAR file not found in target directory!" -ForegroundColor Red
    exit 1
}

Write-Host "Deploying JAR: $($jarFile.Name)" -ForegroundColor Cyan
az webapp deploy `
    --resource-group $ResourceGroupName `
    --name $deployedAppName `
    --src-path $jarFile.FullName `
    --type jar

if ($LASTEXITCODE -ne 0) {
    Write-Host "Application deployment failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Deployment Complete ===" -ForegroundColor Green
Write-Host "Web App URL: $webAppUrl" -ForegroundColor Cyan
Write-Host "Health Check: $webAppUrl/actuator/health" -ForegroundColor Cyan
Write-Host "API Info: $webAppUrl/api/info" -ForegroundColor Cyan

# Wait for app to start and test
Write-Host "`nWaiting for application to start (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "Testing application endpoint..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$webAppUrl/actuator/health" -UseBasicParsing
    Write-Host "Health Check Response: $($response.Content)" -ForegroundColor Green
} catch {
    Write-Host "Application may still be starting. Try manually: $webAppUrl" -ForegroundColor Yellow
}
