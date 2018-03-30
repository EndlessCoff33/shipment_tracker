# frozen_string_literal: true

When 'I view the releases for "$app"' do |app|
  releases_page.visit(app)
end

Then 'I should see the "$deploy_status" releases' do |deploy_status, releases_table|
  expected_releases = releases_table.hashes.map { |release_line|
    version = release_line.fetch('version')
    real_version = scenario_context.resolve_version(version)

    release = {
      'approved' => release_line.fetch('approved') == 'yes',
      'version' => real_version.slice(0..6),
      'subject' => release_line.fetch('subject'),
      'feature_reviews' => release_line.fetch('review statuses'),
    }

    nicknames = release_line.fetch('feature reviews').split(',').map(&:strip)
    times = release_line.fetch('review times').split(',').map(&:strip)
    release['feature_review_paths'] = nicknames.zip(times).map { |nickname, time|
      scenario_context.review_path(
        feature_review_nickname: nickname,
        time: time ? Time.zone.parse(time) : nil,
      )
    }

    if release['feature_review_paths'].blank?
      release['feature_review_paths'] << scenario_context.new_review_path(real_version)
    end

    if deploy_status == 'deployed'
      time = release_line.fetch('last deployed at')
      release['time'] = time.empty? ? nil : Time.zone.parse(time)
    end

    release
  }

  actual_releases = releases_page.public_send("#{deploy_status}_releases".to_sym)
  expect(actual_releases).to match_array(expected_releases)
end
