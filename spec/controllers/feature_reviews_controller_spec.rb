require 'rails_helper'

RSpec.describe FeatureReviewsController do
  describe 'GET #index' do
    context 'when apps are submitted' do
      let(:projection) { instance_double(FeatureReviewProjection) }
      let(:events) { [Event.new, Event.new, Event.new] }
      let(:uat_url) { 'http://uat.fundingcircle.com' }
      let(:apps_with_versions) { { 'frontend' => 'abc', 'backend' => 'def' } }
      let(:apps_without_versions) { { 'irrelevant_app_without_version' => '' } }
      let(:all_apps) { apps_with_versions.merge(apps_without_versions) }

      let(:projection_url) {
        @routes.url_for host: 'www.example.com',
                        controller: 'feature_reviews',
                        action: 'index',
                        apps: all_apps,
                        uat_url: uat_url
      }

      before do
        request.host = 'www.example.com'

        allow(FeatureReviewProjection).to receive(:new).with(
          apps: apps_with_versions,
          uat_url: uat_url,
          projection_url: projection_url,
        ).and_return(projection)

        allow(Event).to receive(:in_order_of_creation).and_return(events)
      end

      it 'shows a report for each application' do
        expect(projection).to receive(:apply_all).with(events)

        get :index, apps: all_apps, uat_url: uat_url

        expect(assigns(:projection)).to eq(projection)
      end
    end

    context 'when no apps are submitted' do
      it 'shows an error' do
        get :index, apps: { 'frontend' => '', 'backend' => '' }

        expect(response).to redirect_to(new_feature_review_path)
        expect(flash[:error]).to include('Please specify at least one app')
      end
    end
  end
end
