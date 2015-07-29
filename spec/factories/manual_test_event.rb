# rubocop:disable Style/BlockDelimiters
FactoryGirl.define do
  factory :manual_test_event do
    transient do
      accepted true
      email 'alice@example.com'
      comment 'LGTM'
      apps('frontend' => 'abc')
    end

    details {
      {
        status: accepted ? 'success' : 'failed',
        email: email,
        comment: comment,
        apps: apps.map { |name, version| { name: name, version: version } },
      }
    }

    initialize_with { new(attributes) }
  end
end
# rubocop:enable Style/BlockDelimiters
