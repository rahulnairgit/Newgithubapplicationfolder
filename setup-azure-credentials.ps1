# Setup Azure credentials for GitHub Actions
# Run this BEFORE pushing to GitHub

param(
    [string]$SubscriptionId = "931db222-3f2f-4181-8f9f-375729be7467",
    [string]$ServicePrincipalName = "sp-github-actions-springboot"
)

Write-Host "=== Azure Service Principal Setup for GitHub Actions ===" -ForegroundColor Cyan

# Step 1: Login to Azure
Write-Host "`n[1/3] Logging in to Azure..." -ForegroundColor Yellow
az login

# Step 2: Set subscription
Write-Host "`n[2/3] Setting subscription..." -ForegroundColor Yellow
az account set --subscription $SubscriptionId

# Step 3: Create Service Principal with Contributor role
Write-Host "`n[3/3] Creating Service Principal..." -ForegroundColor Yellow
$sp = az ad sp create-for-rbac `
    --name $ServicePrincipalName `
    --role contributor `
    --scopes /subscriptions/$SubscriptionId `
    --sdk-auth

Write-Host "`n=== IMPORTANT: Copy the JSON below ===" -ForegroundColor Green
Write-Host "Add this as a GitHub Secret named: AZURE_CREDENTIALS" -ForegroundColor Yellow
Write-Host "============================================" -ForegroundColor Green
Write-Host $sp
Write-Host "============================================" -ForegroundColor Green

Write-Host "`nAlso add these secrets to GitHub:" -ForegroundColor Yellow
Write-Host "  AZURE_SUBSCRIPTION_ID = $SubscriptionId" -ForegroundColor Cyan

Write-Host "`nGo to: GitHub Repo -> Settings -> Secrets and variables -> Actions -> New repository secret" -ForegroundColor Yellow
