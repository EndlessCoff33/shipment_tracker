require 'events/jira_event'
require 'snapshots/feature_review'

module Repositories
  class FeatureReviewRepository
    def initialize(store = Snapshots::FeatureReview)
      @store = store
    end

    delegate :table_name, to: :store

    def feature_reviews_for(versions)
      store.where('versions && ARRAY[?]::varchar[]', versions).group_by(&:url).map { |_, snapshots|
        latest_snapshot = snapshots.max(&:event_created_at)
        Factories::FeatureReviewFactory.new.create(
          url: latest_snapshot.url,
          versions: latest_snapshot.versions,
        )
      }
    end

    def apply(event)
      return unless event.is_a?(Events::JiraEvent) && event.issue?

      Factories::FeatureReviewFactory.new.create_from_text(event.comment).each do |feature_review|
        store.create!(
          url: feature_review.url,
          versions: feature_review.versions,
          event_created_at: event.created_at,
        )
      end
    end

    private

    attr_reader :store
  end
end
