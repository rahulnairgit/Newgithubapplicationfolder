// Azure Web App Infrastructure for Spring Boot Application
// Subscription: 931db222-3f2f-4181-8f9f-375729be7467

@description('Location for all resources')
param location string = resourceGroup().location

@description('Name of the App Service Plan')
param appServicePlanName string = 'asp-demo-app'

@description('Name of the Web App')
param webAppName string = 'webapp-springboot-demo-${uniqueString(resourceGroup().id)}'

@description('SKU of the App Service Plan')
@allowed([
  'F1'
  'B1'
  'B2'
  'S1'
  'P1V2'
])
param sku string = 'B1'

@description('Java version')
param javaVersion string = '17'

// App Service Plan
resource appServicePlan 'Microsoft.Web/serverfarms@2023-01-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: sku
    capacity: 1
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

// Web App
resource webApp 'Microsoft.Web/sites@2023-01-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'JAVA|${javaVersion}-java${javaVersion}'
      alwaysOn: sku != 'F1'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'JAVA_OPTS'
          value: '-Dserver.port=80'
        }
      ]
    }
  }
}

// Configure Java SE deployment
resource webAppConfig 'Microsoft.Web/sites/config@2023-01-01' = {
  parent: webApp
  name: 'web'
  properties: {
    linuxFxVersion: 'JAVA|${javaVersion}-java${javaVersion}'
    javaVersion: javaVersion
    javaContainer: 'JAVA'
    javaContainerVersion: 'SE'
    appCommandLine: ''
  }
}

// Output values
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
output webAppName string = webApp.name
output appServicePlanName string = appServicePlan.name
output resourceGroupLocation string = location
