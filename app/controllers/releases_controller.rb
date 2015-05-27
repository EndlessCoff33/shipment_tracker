class ReleasesController < ApplicationController
  def index
    @app_names = RepositoryLocation.app_names
  end

  def show
    @app_name = params[:id]

    repo = GitRepositoryLoader.from_rails_config.load(@app_name)
    @commits = repo.recent_commits(50)
  end
end
