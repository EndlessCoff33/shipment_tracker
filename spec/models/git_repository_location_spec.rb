require 'rails_helper'

RSpec.describe GitRepositoryLocation do
  describe 'validations' do
    it 'must have a valid uri' do
      valid = GitRepositoryLocation.new(name: 'some_repo', uri: 'ssh://git@github.com/some/other-repo.git')
      invalid = GitRepositoryLocation.new(name: 'some_repo', uri: 'git@github.com:some/other-repo.git')

      expect(valid).to be_valid
      expect(invalid).not_to be_valid
    end
  end

  describe '.uris' do
    let(:uris) { %w(ssh://git@github.com/some/some-repo.git ssh://git@github.com/some/some-repo.git) }
    it 'returns an array of uris' do
      uris.each do |uri|
        GitRepositoryLocation.create(uri: uri)
      end

      expect(GitRepositoryLocation.uris).to match_array(uris)
    end
  end

  describe '.from_github_notification' do
    let(:github_payload) {
      JSON.parse(<<-END)
        {
          "before": "abc123",
          "after": "def456",
          "repository": {
            "name": "repo",
            "full_name": "some/repo",
            "git_url": "git://github.com/some/repo.git",
            "ssh_url": "git@github.com:some/repo.git",
            "clone_url": "https://github.com/some/repo.git"
          }
        }
      END
    }

    before do
      GitRepositoryLocation.create(name: 'some_other_repo', uri: 'ssh://git@github.com/some/other-repo.git')
    end

    context 'when the GitRepositoryLocation has a regular URI' do
      before do
        GitRepositoryLocation.create(name: 'some_repo', uri: 'ssh://git@github.com/some/repo.git')
      end

      it 'updates remote_head for the correct GitRepositoryLocation' do
        GitRepositoryLocation.update_from_github_notification(github_payload)

        expect(GitRepositoryLocation.find_by_name('some_repo').remote_head).to eq('def456')
        expect(GitRepositoryLocation.find_by_name('some_other_repo').remote_head).to be(nil)
      end
    end

    context 'when no GitRepositoryLocation is found' do
      it 'fails silently' do
        expect { GitRepositoryLocation.update_from_github_notification(github_payload) }.to_not raise_error
      end
    end

    context 'when payload does not have a repository key' do
      let(:github_payload) {
        JSON.parse(<<-END)
          {
            "before": "abc123",
            "after": "def456"
          }
        END
      }
      it 'fails silently' do
        expect { GitRepositoryLocation.update_from_github_notification(github_payload) }.to_not raise_error
      end
    end
  end
end
