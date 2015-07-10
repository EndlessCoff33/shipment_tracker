# rubocop:disable Metrics/LineLength
Rails.application.config.event_types = [
  EventType.new(name: 'CircleCI', endpoint: 'circleci', event_class: CircleCiEvent),
  EventType.new(name: 'CircleCI (manual)', endpoint: 'circleci-manual', event_class: CircleCiManualWebhookEvent),
  EventType.new(name: 'Deployment', endpoint: 'deploy', event_class: DeployEvent),
  EventType.new(name: 'Jenkins', endpoint: 'jenkins', event_class: JenkinsEvent),
  EventType.new(name: 'JIRA', endpoint: 'jira', event_class: JiraEvent),
  EventType.new(name: 'UAT', endpoint: 'uat', event_class: UatEvent),
  EventType.new(name: 'Manual test', endpoint: 'manual_test', event_class: ManualTestEvent, internal: true),
]
# rubocop:enable Metrics/LineLength
