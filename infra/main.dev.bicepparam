using './main.bicep'

param env = 'dev'
param entraAdminLogin = readEnvironmentVariable('ENTRA_ADMIN_LOGIN')
param entraAdminObjectId = readEnvironmentVariable('ENTRA_ADMIN_OBJECT_ID')
param alertWebhookKey = readEnvironmentVariable('ALERT_WEBHOOK_KEY')
param containerImage = readEnvironmentVariable('CONTAINER_IMAGE', '')
