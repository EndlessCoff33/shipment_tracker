require 'git_clone_url'
require 'git_repository'

require 'active_support/notifications'
require 'rugged'

class GitRepositoryLoader
  class NotFound < RuntimeError; end
  class BadLocation < RuntimeError; end

  def self.from_rails_config
    config = Rails.configuration
    new(
      ssh_private_key: config.ssh_private_key,
      ssh_public_key: config.ssh_public_key,
      ssh_user: config.ssh_user,
      cache_dir: config.git_repository_cache_dir,
    )
  end

  def initialize(ssh_private_key: nil, ssh_public_key: nil, ssh_user: nil, cache_dir: Dir.tmpdir)
    @ssh_private_key = ssh_private_key
    @ssh_public_key = ssh_public_key
    @ssh_user = ssh_user
    @cache_dir = cache_dir
  end

  def load_and_update(repository_name)
    git_repository_location = find_repo_location(repository_name)

    options_for(git_repository_location.uri) do |options|
      repository = updated_rugged_repository(git_repository_location, options)
      GitRepository.new(repository)
    end
  end

  def load(repository_name)
    if Rails.configuration.allow_git_fetch_on_request
      load_and_update(repository_name)
    else
      git_repository_location = find_repo_location(repository_name)
      repository = rugged_repository(git_repository_location)
      GitRepository.new(repository)
    end
  end

  private

  attr_reader :cache_dir, :ssh_user, :ssh_private_key, :ssh_public_key

  def find_repo_location(repository_name)
    git_repository_location = GitRepositoryLocation.find_by_name(repository_name)
    fail GitRepositoryLoader::NotFound unless git_repository_location
    git_repository_location
  end

  def updated_rugged_repository(git_repository_location, options)
    Rails.logger.info "Updating repository #{git_repository_location.name} (#{git_repository_location.uri})"
    dir = repository_dir_name(git_repository_location)
    Rugged::Repository.new(dir, options).tap do |repository|
      instrument('fetch') do
        repository.fetch('origin', options) unless up_to_date?(git_repository_location, repository)
      end
    end
  rescue Rugged::OSError, Rugged::RepositoryError, Rugged::InvalidError, Rugged::ReferenceError => error
    Rails.logger.warn "Exception while updating repository: #{error.message}"
    Rails.logger.info "Wiping directory #{dir} and re-cloning repository to the same location..."
    FileUtils.rmtree(dir)
    instrument('clone') do
      Rugged::Repository.clone_at(git_repository_location.uri, dir, options)
    end
  end

  def rugged_repository(git_repository_location)
    dir = repository_dir_name(git_repository_location)
    Rugged::Repository.new(dir)
  rescue Rugged::RepositoryError
    raise GitRepositoryLoader::BadLocation
  end

  def repository_dir_name(git_repository_location)
    File.join(cache_dir, "#{git_repository_location.id}-#{git_repository_location.name}")
  end

  def options_for(uri, &block)
    parsed_uri = GitCloneUrl.parse(uri)
    if ['ssh', 'git', nil].include?(parsed_uri.scheme) && parsed_uri.user == 'git'
      options_for_ssh(&block)
    else
      yield({})
    end
  end

  def up_to_date?(git_repository_location, rugged_repository)
    git_repository_location.remote_head == rugged_repository.head.target_id
  end

  def create_temporary_file(key)
    file = Tempfile.new('key', cache_dir)
    file.write(key.strip + "\n")
    file.close
    file
  end

  def options_for_ssh
    fail 'ssh_user not set' unless ssh_user
    fail 'ssh_public_key not set' unless ssh_public_key
    fail 'ssh_private_key not set' unless ssh_private_key

    ssh_public_key_file = create_temporary_file(ssh_public_key)
    ssh_private_key_file = create_temporary_file(ssh_private_key)

    yield credentials: Rugged::Credentials::SshKey.new(
      username: ssh_user,
      privatekey: ssh_private_key_file.path,
      publickey: ssh_public_key_file.path,
    )
  ensure
    ssh_public_key_file.unlink if ssh_public_key_file
    ssh_private_key_file.unlink if ssh_private_key_file
  end

  def instrument(name, &block)
    ActiveSupport::Notifications.instrument(
      "#{name}.git_repository_loader",
      &block
    )
  end
end
