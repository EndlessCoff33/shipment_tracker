require 'rails_helper'

RSpec.describe Forms::FeatureReviewForm do
  let(:git_repository_loader) { instance_double(GitRepositoryLoader) }
  let(:uat_url) { '' }
  let(:apps) { {} }

  subject(:feature_review_form) {
    Forms::FeatureReviewForm.new(
      apps: apps,
      uat_url: uat_url,
      git_repository_loader: git_repository_loader,
    )
  }

  describe '.new' do
    context 'with a git_repository_loader' do
      it 'should work' do
        expect(
          Forms::FeatureReviewForm.new(
            apps: {},
            uat_url: '',
            git_repository_loader: double,
          ),
        ).to be_a(Forms::FeatureReviewForm)
      end
    end

    context 'without a git_repository_loader' do
      it 'should work' do
        expect(
          Forms::FeatureReviewForm.new(
            apps: {},
            uat_url: '',
          ),
        ).to be_a(Forms::FeatureReviewForm)
      end
    end
  end

  describe '#apps' do
    context 'when there are no app versions' do
      let(:apps) { nil }
      it 'return an empty hash' do
        expect(feature_review_form.apps).to eql({})
      end
    end

    context 'when there are no app versions' do
      let(:apps) { { 'app1' => 'a', 'app2' => 'b', 'app3' => '' } }
      it 'returns the apps with empty ones filtered out' do
        expect(feature_review_form.apps).to eql('app1' => 'a', 'app2' => 'b')
      end
    end
  end

  describe '#uat_url' do
    let(:uat_url) { double }
    it 'returns the uat_url' do
      expect(feature_review_form.uat_url).to eql(uat_url)
    end
  end

  describe '#valid?' do
    context 'when one of the app versions does not exist' do
      let(:apps) { { frontend: 'abc', backend: 'def' } }
      let(:frontend_repo) { instance_double(GitRepository) }
      let(:backend_repo) { instance_double(GitRepository) }

      before do
        allow(git_repository_loader).to receive(:load).with('frontend').and_return(frontend_repo)
        allow(git_repository_loader).to receive(:load).with('backend').and_return(backend_repo)

        allow(frontend_repo).to receive(:exists?).with('abc').and_return(false)
        allow(backend_repo).to receive(:exists?).with('def').and_return(true)
      end

      it 'returns false' do
        expect(feature_review_form.valid?).to be false
      end

      it 'adds errors' do
        feature_review_form.valid?
        expect(feature_review_form.errors[:frontend]).to eq(['version abc does not exist'])
      end
    end

    context 'when an app does not exist' do
      let(:apps) { { frontend: 'abc' } }
      let(:frontend_repo) { instance_double(GitRepository) }

      before do
        allow(git_repository_loader).to receive(:load)
          .with('frontend')
          .and_raise(GitRepositoryLoader::NotFound)
      end

      it 'returns false' do
        expect(feature_review_form.valid?).to be false
      end

      it 'adds errors' do
        feature_review_form.valid?
        expect(feature_review_form.errors[:frontend]).to eq(['does not exist'])
      end
    end

    context 'when all the app versions exist' do
      let(:apps) { { frontend: 'abc', backend: 'def' } }
      let(:frontend_repo) { instance_double(GitRepository) }
      let(:backend_repo) { instance_double(GitRepository) }

      before do
        allow(git_repository_loader).to receive(:load).with('frontend').and_return(frontend_repo)
        allow(git_repository_loader).to receive(:load).with('backend').and_return(backend_repo)

        allow(frontend_repo).to receive(:exists?).with('abc').and_return(true)
        allow(backend_repo).to receive(:exists?).with('def').and_return(true)
      end

      it 'returns true' do
        expect(feature_review_form.valid?).to be true
      end

      it 'does not add errors' do
        feature_review_form.valid?
        expect(feature_review_form.errors).to be_empty
      end
    end

    context 'when an app version is not filled in' do
      let(:apps) { { frontend: 'abc', backend: '' } }
      let(:frontend_repo) { instance_double(GitRepository) }

      before do
        allow(git_repository_loader).to receive(:load).with('frontend').and_return(frontend_repo)
        allow(frontend_repo).to receive(:exists?).with('abc').and_return(true)
      end

      it 'returns true' do
        expect(feature_review_form.valid?).to be true
      end
    end
  end

  describe '#url' do
    let(:apps) { { frontend: 'abc', backend: 'def' } }
    let(:uat_url) { 'http://foobar.com/blah/blah' }

    subject { feature_review_form.url }

    it do
      is_expected.to eq(
        '/feature_reviews?'\
        'apps%5Bbackend%5D=def&'\
        'apps%5Bfrontend%5D=abc&'\
        'uat_url=http%3A%2F%2Ffoobar.com%2Fblah%2Fblah',
      )
    end

    context 'without uat_url' do
      let(:apps) { { frontend: 'abc', backend: 'def' } }
      let(:uat_url) { '' }

      it { is_expected.to eq('/feature_reviews?apps%5Bbackend%5D=def&apps%5Bfrontend%5D=abc') }
    end

    context 'with empty app version' do
      let(:apps) { { frontend: 'abc', backend: '' } }
      let(:uat_url) { 'http://foobar.com' }

      it { is_expected.to eq('/feature_reviews?apps%5Bfrontend%5D=abc&uat_url=http%3A%2F%2Ffoobar.com') }
    end

    context 'with lots of apps' do
      let(:apps) { { a: 1, c: 3, b: 2, e: 5, d: 4 } }
      let(:uat_url) { '' }

      it 'orders apps alphabetically' do
        is_expected.to eq(
          '/feature_reviews?'\
          'apps%5Ba%5D=1&'\
          'apps%5Bb%5D=2&'\
          'apps%5Bc%5D=3&'\
          'apps%5Bd%5D=4&'\
          'apps%5Be%5D=5',
        )
      end
    end
  end
end
