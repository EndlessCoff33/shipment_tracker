require 'rails_helper'

describe EventsController do
  describe "POST #create" do
    context "/deploy with valid JSON" do
      let(:route_params) { { type: 'deploy' } }

      it { should route(:post, '/events/deploy').to(action: :create, type: 'deploy') }

      it "saves an event object with correct details" do
        post :create, route_params.merge('deployed_by' => 'alice'), format: :json

        expect(Deploy.last.details).to eql('deployed_by' => 'alice')
        expect(response).to have_http_status(:success)
      end
    end
    context "/circle with valid JSON" do
      let(:route_params) { { type: 'circleci' } }

      it { should route(:post, '/events/circleci').to(action: :create, type: 'circleci') }

      it "saves an event object with correct details" do
        post :create, route_params.merge('status' => 'success'), format: :json

        expect(CircleCi.last.details).to eql('status' => 'success')
        expect(response).to have_http_status(:success)
      end
    end
    context "/other with valid JSON" do
      let(:route_params) { { type: 'other' } }

      it { should route(:post, '/events/other').to(action: :create, type: 'other') }

      it "throws an error" do
        expect {
          post :create, route_params.merge('any' => 'message'), format: :json
        }.to raise_error
      end
    end
  end
end
