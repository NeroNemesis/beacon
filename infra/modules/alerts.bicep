// Groupe d'actions (webhook vers Beacon) + 2 règles d'alerte : le projet se surveille lui-même
param location string
param namePrefix string
param tags object = {}
param appInsightsId string
param sqlDatabaseId string
@secure()
param webhookUrl string

resource ag 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: 'ag-${namePrefix}-beacon'
  location: 'Global'
  tags: tags
  properties: {
    groupShortName: 'beacon'
    enabled: true
    webhookReceivers: [
      {
        name: 'beacon-webhook'
        serviceUri: webhookUrl
        useCommonAlertSchema: true
      }
    ]
  }
}

resource sqlCpu 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'alert-${namePrefix}-sql-cpu'
  location: 'global'
  tags: tags
  properties: {
    description: 'CPU de la base > 80 % pendant 5 minutes'
    severity: 2
    enabled: true
    scopes: [sqlDatabaseId]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: 'cpu'
          metricName: 'cpu_percent'
          operator: 'GreaterThan'
          threshold: 80
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [
      { actionGroupId: ag.id }
    ]
  }
}

resource api5xx 'Microsoft.Insights/scheduledQueryRules@2023-03-15-preview' = {
  name: 'alert-${namePrefix}-api-5xx'
  location: location
  tags: tags
  kind: 'LogAlert'
  properties: {
    displayName: 'Beacon API : erreurs 5xx'
    description: 'Plus de 5 réponses 5xx en 5 minutes'
    severity: 2
    enabled: true
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    scopes: [appInsightsId]
    criteria: {
      allOf: [
        {
          query: 'requests | where toint(resultCode) >= 500'
          timeAggregation: 'Count'
          operator: 'GreaterThan'
          threshold: 5
          failingPeriods: {
            numberOfEvaluationPeriods: 1
            minFailingPeriodsToAlert: 1
          }
        }
      ]
    }
    actions: {
      actionGroups: [ag.id]
    }
  }
}
