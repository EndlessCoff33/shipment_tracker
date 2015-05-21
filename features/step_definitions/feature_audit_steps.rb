When 'I compare commit "$ver1" with commit "$ver2" for "$application"' do |ver1, ver2, application|
  git_commit_1 = scenario_context.resolve_version(ver1)
  git_commit_2 = scenario_context.resolve_version(ver2)

  feature_audit_page.request(
    project_name: application,
    from: git_commit_1,
    to: git_commit_2,
  )
end

Given 'I am on the feature audit page for the last commit' do
  commits = scenario_context.last_repository.commits
  feature_audit_page.request(
    project_name: scenario_context.last_application,
    from: commits.first.version,
    to: commits.last.version,
  )
end

Then 'I should only see the authors' do |authors_table|
  authors = authors_table.hashes.map { |row| row['author'] }
  expect(feature_audit_page.authors).to match_array(authors)
end

Then 'I should see the comments' do |table|
  expected_comments = table.hashes.map { |comment|
    Sections::CommentSection.new(
      message: comment.fetch('message'),
      name: comment.fetch('name'),
    )
  }

  expect(feature_audit_page.comments).to match_array(expected_comments)
end

Then 'the deploys' do |table|
  expected_deploys = table.hashes.map { |deploy|
    Sections::DeploySection.new(
      server: deploy.fetch('server'),
      deployed_by: deploy.fetch('deployed_by'),
      version: scenario_context.resolve_version(deploy.fetch('commit')),
    )
  }

  expect(feature_audit_page.deploys).to match_array(expected_deploys)
end

Then 'the builds' do |table|
  expected_builds = table.hashes.map { |build|
    Sections::BuildSection.new(
      source: build.fetch('source'),
      status: build.fetch('status'),
      version: scenario_context.resolve_version(build.fetch('commit')),
    )
  }

  expect(feature_audit_page.builds).to match_array(expected_builds)
end

Then 'the tickets' do |table|
  expected_tickets = table.hashes.map { |ticket|
    Sections::TicketSection.new(
      key: ticket.fetch('key'),
      summary: ticket.fetch('summary'),
      description: ticket.fetch('description'),
      status: ticket.fetch('status'),
      approver_email: ticket.fetch('approver email'),
      approved_at: ticket.fetch('approved at'),
    )
  }

  expect(feature_audit_page.tickets).to match_array(expected_tickets)
end

When 'I submit a comment with message "$message" and name "$name"' do |message, name|
  feature_audit_page.comment(
    message: message,
    name: name,
  )
end
