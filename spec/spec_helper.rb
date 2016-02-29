# This file was initially generated by the `rails generate rspec:install` command.
# Keep this file as light-weight as possible as dependencies increase the boot time on EVERY test run.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start('rails') do
    add_filter 'lib/tasks/'
  end
end

require 'pathname'
root = Pathname.new('..').expand_path(File.dirname(__FILE__))
[
  root.join('app', 'models'),
  root.join('app', 'decorators'),
  root.join('app', 'use_cases'),
].each do |path|
  $LOAD_PATH.unshift path.to_s
end

require 'webmock/rspec'
require 'solid_use_case'
require 'solid_use_case/rspec_matchers'

require 'clients/github'
require 'support/feature_review_helpers'

RSpec.configure do |config|
  config.include Support::FeatureReviewHelpers
  config.include SolidUseCase::RSpecMatchers

  config.before(:each, :disable_repo_verification) do
    allow_any_instance_of(GithubClient).to receive(:repo_accessible?).and_return(true)
  end

  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4.
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # This option will default to `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random # Use `--seed` to deterministically reproduce test failures related to randomization.

  config.color = true

  # By default `let` and `subject` are threadsafe, which adds overhead and slows down tests not using threads.
  config.threadsafe = false
end
