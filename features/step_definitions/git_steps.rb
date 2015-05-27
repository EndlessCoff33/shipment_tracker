require 'support/git_test_repository'
require 'time'

Given 'an application called "$name"' do |name|
  scenario_context.setup_application(name)
end

Given 'an application with some commits' do
  scenario_context.setup_application('my_app')
  scenario_context.last_repository.create_commit(author_name: 'Adam', pretend_version: '#1')
  scenario_context.last_repository.create_commit(author_name: 'Eve', pretend_version: '#2')
end

Given 'a commit "$version" by "$name" is created' do |version, name|
  scenario_context.last_repository.create_commit(author_name: name, pretend_version: version)
end

Given 'a commit "$version" by "$name" is created for app "$app"' do |version, name, app|
  scenario_context.repository_for(app).create_commit(author_name: name, pretend_version: version)
end

Given(/^a commit "(.*?)" by "(.*?)" is created for ticket "([^\"]+)"$/) do |version, author, jira_key|
  scenario_context.last_repository.create_commit(
    author_name: author,
    pretend_version: version,
    message: "#{jira_key} work",
  )
end

Given 'a commit "$version" with message "$message" is created at "$time"' do |version, message, time|
  scenario_context.last_repository.create_commit(
    author_name: 'Alice',
    pretend_version: version,
    message: message,
    time: Time.parse(time),
  )
end
