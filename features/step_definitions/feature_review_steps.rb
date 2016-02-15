Given 'I prepare a feature review for:' do |table|
  prepare_feature_review_page.visit
  step 'I fill in the data for a feature review:', table
end

Given 'I fill in the data for a feature review:' do |table|
  table.hashes.each do |row|
    prepare_feature_review_page.add(
      field_name: row.fetch('field name'),
      content: scenario_context.resolve_version(row.fetch('content')),
    )
  end

  prepare_feature_review_page.submit
end

Then 'I should see the feature review page with the applications:' do |table|
  expected_app_info = table.hashes.map { |hash|
    version, link = hash.fetch('version').match(/\A\[(.*)\]\((.*)\)\z/).try(:captures)
    real_version = scenario_context.resolve_version(version)
    mock_path = scenario_context.repository_for(hash.fetch('app_name')).mock_remote_path
    link = link.sub('...', "#{mock_path}/commit/#{real_version}")

    hash.merge('version' => "[#{real_version.slice(0..6)}](#{link})")
  }

  expect(feature_review_page.app_info).to match_array(expected_app_info)
end

Given 'developer prepares review known as "$a" for UAT "$b" with apps' do |known_as, uat_url, apps_table|
  scenario_context.prepare_review(apps_table.hashes, uat_url, known_as)
end

When 'I visit the feature review known as "$known_as"' do |known_as|
  visit scenario_context.review_path(feature_review_nickname: known_as)
end

When 'I visit feature review "$known_as" as at "$time"' do |known_as, time|
  visit scenario_context.review_path(feature_review_nickname: known_as, time: time)
end

Then 'I should see the builds with heading "$status" and content' do |status, builds_table|
  expected_builds = builds_table.hashes
  expect(feature_review_page.panel_heading_status('builds')).to eq(status)
  expect(feature_review_page.builds).to match_array(expected_builds)
end

Then 'I can see the UAT environment "$uat"' do |uat|
  expect(feature_review_page.uat_url).to eq(uat)
end

Then 'I should see the deploys to UAT with heading "$status" and content' do |status, deploys_table|
  expected_deploys = deploys_table.hashes.map {|ticket|
    ticket.merge('Version' => scenario_context.resolve_version(ticket['Version']).slice(0..6))
  }

  expect(feature_review_page.panel_heading_status('deploys')).to eq(status)
  expect(feature_review_page.deploys).to match_array(expected_deploys)
end

Then 'I should see the tickets' do |ticket_table|
  expected_tickets = ticket_table.hashes
  expect(feature_review_page.tickets).to match_array(expected_tickets)
end

Then(/^(I should see )?a summary with heading "([^\"]*)" and content$/) do |_, status, summary_table|
  expected_summary = summary_table.hashes

  panel = feature_review_page.summary_panel
  expect(panel.status).to eq(status)
  expect(panel.items).to match_array(expected_summary)
end

Then 'I should see a summary that includes' do |summary_table|
  expected_summary = summary_table.hashes

  panel = feature_review_page.summary_panel
  expect(panel.items).to include(*expected_summary)
end

When 'I "$action" the feature with comment "$comment"' do |action, comment|
  feature_review_page.create_qa_submission(
    comment: comment,
    status: action,
  )
end

Then 'I should see the QA acceptance with heading "$status"' do |status|
  expect(feature_review_page.panel_heading_status('qa-submission')).to eq(status)
end

Then 'I should see the QA acceptance' do |table|
  expected_qa_submission = table.hashes.first
  status = expected_qa_submission.delete('status')
  panel = feature_review_page.qa_submission_panel

  expect(panel.status).to eq(status)
  expect(panel.items.first).to eq(expected_qa_submission)
end

Then 'I should see the results of the User Acceptance Tests with heading "$s" and version "$v"' do |s, v|
  panel = feature_review_page.uatest_panel

  expect(panel.status).to eq(s)
  expect(panel.items.first).to eq('test_suite_version' => v)
end

Then 'I should see the time "$time" for the Feature Review' do |time|
  expect(feature_review_page.time).to be_present
  expect(Time.zone.parse(feature_review_page.time)).to eq(Time.zone.parse(time))
end

Then 'I should see that the Feature Review was approved at "$time"' do |time|
  expected_time = Time.zone.parse(time).utc
  expect(feature_review_page.feature_status).to eq("Feature Status: Approved at #{expected_time}")
end

Then 'I should see that the Feature Review was not approved' do
  expect(feature_review_page.feature_status).to eq('Feature Status: Not approved')
end

Then 'I should see that the Feature Review requires reapproval' do
  expect(feature_review_page.feature_status).to eq('Feature Status: Requires reapproval')
end

When 'I reload the page after a while' do
  Repositories::Updater.from_rails_config.run
  page.visit(page.current_url)
end

When 'I click modify button on review panel' do
  page.click_link_or_button('Modify')
end
