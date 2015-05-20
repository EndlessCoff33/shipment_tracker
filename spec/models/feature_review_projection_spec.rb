require 'rails_helper'
require 'feature_review_projection'

RSpec.describe FeatureReviewProjection do
  let(:apps) { { 'frontend' => 'abc', 'backend' => 'def' } }

  subject(:projection) { FeatureReviewProjection.new(apps) }

  describe 'builds projection' do
    let(:events) {
      [
        build(:circle_ci_event, success?: false, version: 'abc'),
        build(:jenkins_event, success?: true, version: 'abc'), # Build retriggered.
        build(:circle_ci_event, success?: true, version: 'def'),
        build(:jenkins_event, success?: true, version: 'ghi'),
        build(:jira_event),
      ]
    }

    it 'projects the last build' do
      projection.apply_all(events)

      expect(projection.builds).to eq(
        'frontend' => [
          Build.new(source: 'CircleCi', status: 'failed', version: 'abc'),
          Build.new(source: 'Jenkins', status: 'success', version: 'abc'),
        ],
        'backend'  => [
          Build.new(source: 'CircleCi', status: 'success', version: 'def'),
        ],
      )
    end
  end
end
