require 'rails_helper'

RSpec.describe GitRepositoryLocationsController do
  context 'when logged out' do
    let(:git_repository_location) {
      {
        'name' => 'shipment_tracker',
        'uri' => 'https://github.com/FundingCircle/shipment_tracker.git',
      }
    }

    it { is_expected.to require_authentication_on(:get, :index) }
    it {
      is_expected.to require_authentication_on(
        :post,
        :create,
        git_repository_location: git_repository_location)
    }
  end
end
