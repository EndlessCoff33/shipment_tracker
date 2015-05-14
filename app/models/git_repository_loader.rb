require 'rugged'

require 'git_repository'

class GitRepositoryLoader
  def initialize(ssh_private_key:, ssh_public_key:, ssh_user:, cache_dir: Dir.tmpdir)
    @ssh_private_key = ssh_private_key
    @ssh_public_key = ssh_public_key
    @ssh_user = ssh_user
    @cache_dir = cache_dir
  end

  def load(repository_name)
    remote_repository = RepositoryLocation.find_by_name(repository_name)
    uri = remote_repository.uri
    dir = File.join(cache_dir, "#{remote_repository.id}-#{repository_name}")

    options_for(uri) do |options|
      repository = updated_rugged_repository(uri, dir, options)
      GitRepository.new(repository)
    end
  end

  private

  attr_reader :cache_dir, :ssh_user, :ssh_private_key, :ssh_public_key

  def updated_rugged_repository(uri, dir, options)
    Rugged::Repository.new(dir, options).tap do |r|
      r.fetch('origin', options)
    end
  rescue Rugged::OSError, Rugged::RepositoryError
    Rugged::Repository.clone_at(uri, dir, options)
  end

  def options_for(uri, &block)
    case URI.parse(uri).scheme
    when 'ssh'
      options_for_ssh(&block)
    else
      block.call({})
    end
  end

  def create_temporary_file(key)
    file = Tempfile.new('key', cache_dir)
    file.write(key)
    file.close
    file
  end

  def options_for_ssh(&block)
    fail 'ssh_user not set' unless ssh_user
    fail 'ssh_public_key not set' unless ssh_public_key
    fail 'ssh_private_key not set' unless ssh_private_key

    ssh_public_key_file = create_temporary_file(ssh_public_key)
    ssh_private_key_file = create_temporary_file(ssh_private_key)

    block.call(
      credentials: Rugged::Credentials::SshKey.new(
        username: ssh_user,
        privatekey: ssh_private_key_file.path,
        publickey: ssh_public_key_file.path,
      ),
    )
  ensure
    ssh_public_key_file.unlink if ssh_public_key_file
    ssh_private_key_file.unlink if ssh_private_key_file
  end
end
