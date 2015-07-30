require 'forwardable'

module Projections
  class UatestsProjection
    attr_reader :uatest

    def initialize(apps:, server:)
      @apps = apps
      @server = server
      @versions_on_uats = {}
      @uatest = nil
    end

    def apply(event)
      case event
      when DeployEvent
        return unless event.server == server
        versions_on_uats[event.app_name] = event.version
      when UatEvent
        return unless correct_versions_deployed? && event.server == server
        @uatest = Uatest.new(
          success: event.success,
          test_suite_version: event.test_suite_version,
        )
      end
    end

    private

    attr_reader :server, :apps, :versions_on_uats

    def correct_versions_deployed?
      apps.all? { |app_name, expected_version|
        versions_on_uats[app_name] == expected_version
      }
    end
  end

  class LockingUatestsProjection
    extend Forwardable

    def initialize(feature_review_location)
      @projection = LockingProjectionWrapper.new(
        UatestsProjection.new(
          apps: feature_review_location.app_versions,
          server: feature_review_location.uat_host,
        ),
        feature_review_location.url,
      )
    end

    def_delegators :@projection, :uatest, :apply
  end
end
