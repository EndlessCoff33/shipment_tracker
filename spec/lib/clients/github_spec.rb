require 'spec_helper'
require 'clients/github'

RSpec.describe GithubClient do
  subject(:github) { GithubClient.new('token') }

  describe '#create_status' do
    it 'creates a commit status' do
      expect_any_instance_of(Octokit::Client).to receive(:create_status).with(
        'owner/repo', 'abc123', 'success', context: 'shipment-tracker', description: 'foo', target_url: 'url'
      )

      github.create_status(
        repo: 'owner/repo', sha: 'abc123', state: 'success', description: 'foo', target_url: 'url',
      )
    end
  end

  describe '#repo_accessible?' do
    context 'when repo is on GitHub' do
      it 'checks that the repo is accessible' do
        %w(git@github.com:owner/repo.git
           git://github.com/owner/repo.git
           ssh://github.com/owner/repo.git
           http://github.com/owner/repo
        ).each do |uri|
          expect_any_instance_of(Octokit::Client).to receive(:repository?).with('owner/repo')
          github.repo_accessible?(uri)
        end
      end
    end

    context 'when repo is not on GitHub' do
      it 'does not check GitHub and returns nil' do
        expect_any_instance_of(Octokit::Client).to_not receive(:repository?)
        expect(github.repo_accessible?('git@bitbucket.com:owner/repo.git')).to be_nil
      end
    end
  end
end
