require 'forwardable'

module Projections
  class BuildsProjection
    def initialize(apps:, builds_table: nil)
      @apps = apps
      @builds_table = builds_table || apps_hash_with_value(@apps, Build.new)
    end

    def apply(event)
      return unless event.is_a?(CircleCiEvent) || event.is_a?(JenkinsEvent)
      app = versions[event.version]
      return unless app

      build = Build.new(
        source: event.source,
        success: event.success,
        version: event.version,
      )
      @builds_table[app] = build
    end

    def builds
      @builds_table
    end

    def clone
      self.class.new(apps: @apps.clone, builds_table: @builds_table.clone)
    end

    private

    def versions
      @versions ||= @apps.invert
    end

    def apps_hash_with_value(apps, value)
      apps.map { |key, _| [key, value] }.to_h
    end
  end

  class LockingBuildsProjection
    extend Forwardable

    def initialize(feature_review_location)
      @projection = LockingProjectionWrapper.new(
        projection: BuildsProjection.new(apps: feature_review_location.app_versions),
        projection_url: feature_review_location.url,
      )
    end

    def_delegators :@projection, :apply, :builds
  end
end
