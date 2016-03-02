require 'rails_helper'

RSpec.describe FeatureReviewsController do
  context 'when logged out' do
    it { is_expected.to require_authentication_on(:get, :new) }
    it { is_expected.to require_authentication_on(:get, :show) }
    it { is_expected.to require_authentication_on(:post, :create) }
    it { is_expected.to require_authentication_on(:get, :search) }
    it { is_expected.to require_authentication_on(:post, :link_ticket) }
  end

  describe 'GET #new', :logged_in do
    let(:feature_review_form) { instance_double(Forms::FeatureReviewForm) }

    before do
      allow(GitRepositoryLocation).to receive(:app_names).and_return(%w(frontend backend))
      allow(Forms::FeatureReviewForm).to receive(:new).with(
        hash_including(
          apps: nil,
          uat_url: nil,
        ),
      ).and_return(feature_review_form)
    end

    it 'renders the form' do
      get :new
      is_expected.to render_template('new')
      expect(assigns(:feature_review_form)).to eq(feature_review_form)
      expect(assigns(:app_names)).to eq(%w(frontend backend))
    end
  end

  describe 'POST #create', :logged_in do
    let(:git_repository_loader) { instance_double(GitRepositoryLoader) }
    let(:feature_review_form) { instance_double(Forms::FeatureReviewForm) }
    let(:repo) { instance_double(GitRepository) }

    before do
      allow(Forms::FeatureReviewForm).to receive(:new).with(
        apps: { frontend: 'abc' },
        uat_url: 'http://uat.example.com',
        git_repository_loader: git_repository_loader,
      ).and_return(feature_review_form)
      allow(GitRepositoryLoader).to receive(:new).and_return(git_repository_loader)
    end

    context 'when the params are invalid' do
      it 'renders the new page' do
        allow(Forms::FeatureReviewForm).to receive(:new).and_return(feature_review_form)
        allow(feature_review_form).to receive(:valid?).and_return(false)

        post :create

        is_expected.to render_template('new')
        expect(assigns(:feature_review_form)).to eql(feature_review_form)
      end
    end

    context 'when the feature review form is invalid' do
      before do
        allow(feature_review_form).to receive(:valid?).and_return(false)
        allow(GitRepositoryLocation).to receive(:app_names).and_return(%w(frontend backend))
      end

      it 'renders the new page' do
        post :create, forms_feature_review_form: {
          apps: { frontend: 'abc' }, uat_url: 'http://uat.example.com'
        }

        is_expected.to render_template('new')
        expect(assigns(:feature_review_form)).to eql(feature_review_form)
        expect(assigns(:app_names)).to eql(%w(frontend backend))
      end
    end

    context 'when the feature review form is valid' do
      before do
        allow(feature_review_form).to receive(:valid?).and_return(true)
        allow(feature_review_form).to receive(:path).and_return('/the/url')
      end

      it 'redirects to #show' do
        post :create, forms_feature_review_form: {
          apps: { frontend: 'abc' }, uat_url: 'http://uat.example.com'
        }

        is_expected.to redirect_to('/the/url')
      end
    end
  end

  describe 'GET #show', :logged_in do
    let(:uat_url) { 'http://uat.fundingcircle.com' }
    let(:apps_with_versions) { { 'frontend' => 'abc', 'backend' => 'def' } }
    let(:feature_review) {
      instance_double(FeatureReview)
    }
    let(:feature_review_query) { instance_double(Queries::FeatureReviewQuery) }
    let(:feature_review_factory) { instance_double(Factories::FeatureReviewFactory) }
    let(:feature_review_with_statuses) { instance_double(FeatureReviewWithStatuses) }
    let(:host) { 'www.example.com' }

    before do
      request.host = host

      allow(Queries::FeatureReviewQuery).to receive(:new).and_return(feature_review_query)
      allow(feature_review_query).to receive(:feature_review_with_statuses)
        .and_return(feature_review_with_statuses)

      allow(Factories::FeatureReviewFactory).to receive(:new).and_return(feature_review_factory)
      allow(feature_review_factory)
        .to receive(:create_from_url_string)
        .with("http://#{host}#{whitelisted_path}")
        .and_return(feature_review)
    end

    context 'when time is NOT specified' do
      let(:whitelisted_path) { feature_review_path(apps_with_versions, uat_url) }

      it 'sets up the correct query parameters' do
        expect(Queries::FeatureReviewQuery).to receive(:new)
          .with(feature_review, at: nil)
          .and_return(feature_review_query)

        get :show, apps: apps_with_versions, uat_url: uat_url

        expect(assigns(:feature_review_with_statuses)).to eq(feature_review_with_statuses)
      end
    end

    context 'when time is specified' do
      let(:whitelisted_path) { feature_review_path(apps_with_versions, uat_url, time) }
      let(:time) { Time.parse('2015-09-09 12:00:00 UTC') }
      let(:precise_time) { time.change(usec: 999_999.999) }

      it 'sets up the correct query parameters' do
        expect(Queries::FeatureReviewQuery).to receive(:new)
          .with(feature_review, at: precise_time)
          .and_return(feature_review_query)

        get :show, apps: apps_with_versions, uat_url: uat_url, time: time

        expect(assigns(:feature_review_with_statuses)).to eq(feature_review_with_statuses)
      end
    end
  end

  describe 'GET #search', :logged_in do
    let(:applications) { %w(frontend backend mobile) }

    let(:version_resolver) { instance_double(VersionResolver) }
    let(:repository) { instance_double(Repositories::TicketRepository) }
    let(:git_repository_loader) { instance_double(GitRepositoryLoader) }
    let(:repo) { instance_double(GitRepository) }
    let(:related_versions) { %w(abc def ghi) }
    let(:expected_links) { ['/feature_reviews?apps%5Bapp1%5D=a&apps%5Bapp2%5D=b'] }
    let(:expected_tickets) { [instance_double(Ticket, paths: expected_links)] }
    let(:version) { 'abc123' }

    before do
      allow(VersionResolver).to receive(:new).with(repo).and_return(version_resolver)
      allow(version_resolver).to receive(:related_versions).with(version).and_return(related_versions)
      allow(GitRepositoryLocation).to receive(:app_names).and_return(applications)
      allow(GitRepositoryLoader).to receive(:new).and_return(git_repository_loader)
      allow(Repositories::TicketRepository).to receive(:new).and_return(repository)
      allow(repository).to receive(:tickets_for_versions)
        .with(related_versions)
        .and_return(expected_tickets)

      allow(git_repository_loader).to receive(:load).with('frontend').and_return(repo)
    end

    it 'assigns links for found Feature Reviews' do
      get :search, version: version, application: 'frontend'

      expect(assigns(:links)).to eq(expected_links)
      expect(assigns(:applications)).to eq(applications)
    end
  end

  describe 'POST #link_ticket', :logged_in do
    subject(:link_ticket) { post :link_ticket, return_to: feature_review_path, jira_key: 'JIRA-123' }

    let(:expected_comment) { "[Feature ready for review|http://test.host#{feature_review_path}]" }
    let(:feature_review_path) { '/feature_reviews?some=app' }
    before do
      allow(JiraClient).to receive(:post_comment)
    end

    it 'posts a comment to Jira' do
      expect(JiraClient).to receive(:post_comment).with('JIRA-123', expected_comment)
      link_ticket
    end

    it 'redirects to the return path' do
      link_ticket
      expect(response).to redirect_to(feature_review_path)
    end

    context 'when posting to Jira fails' do
      let(:error) { JIRA::HTTPError.new(response) }

      before do
        allow(JiraClient).to receive(:post_comment).and_raise(error)
      end

      context 'because of HTTP not found' do
        let(:response) { double('response', message: 'Not found', code: '404') }
        let(:expected_flash_error) {
          'Failed to link to JIRA-123. Please check that the ticket ID is correct.'
        }

        it 'shows a flash error asking the user to check the ticket ID' do
          link_ticket

          expect(flash[:error]).to eq(expected_flash_error)
          expect(response).to redirect_to(feature_review_path)
        end
      end

      context 'because of an other error' do
        let(:response) { double('response', message: 'Bad request', code: '400') }
        let(:expected_flash_error) { 'Failed to link to JIRA-123. Something went wrong.' }

        it 'shows a basic flash error' do
          link_ticket
          expect(flash[:error]).to eq(expected_flash_error)
          expect(response).to redirect_to(feature_review_path)
        end
      end
    end
  end
end
