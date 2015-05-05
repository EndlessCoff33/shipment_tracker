require 'git_repository'

class FeatureAuditProjection
  def initialize(app_name:, from:, to:, git_repository: GitRepository)
    @app_name = app_name
    @from = from
    @to = to
    @git_repository = git_repository
  end

  def authors
    commits.map(&:author_name).uniq
  end

  def deploys
    deploys_for_app.map(&:details).map do |deploy|
      {
        server: deploy['server'],
        version: deploy['version'],
        deployed_at: Time.at(deploy['deployed_at']).strftime("%F %H:%M"),
        deployed_by: deploy['deployed_by']
      }
    end
  end

  # Scans for JIRA tickets that have the format:
  # two or more uppercase letters, followed by a hyphen and the issue number,
  # for example BAM-123
  def tickets
    commits.map { |commit| commit.message.scan(/(?<=\b)[A-Z]{2,}-\d+(?=\b)/) }.flatten
  end

  private

  attr_reader :app_name, :from, :to, :git_repository

  def commits
    @commits ||= git_repository.commits_for(
      repository_name: app_name,
      from: from,
      to: to
    )
  end

  def shas
    commits.map(&:id)
  end

  def deploys_for_app
    Deploy.deploys_for_app(app_name).select { |deploy|
      shas.include?(deploy.details['version'])
    }
  end
end
