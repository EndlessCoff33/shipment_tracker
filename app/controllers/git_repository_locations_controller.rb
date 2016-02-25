class GitRepositoryLocationsController < ApplicationController
  def index
    @repo_location_form = repo_location_form
    @git_repository_locations = GitRepositoryLocation.all.order(:name)
    @token_types = Forms::RepositoryLocationsForm.default_token_types
  end

  def create
    @repo_location_form = repo_location_form
    @token_types = Forms::RepositoryLocationsForm.default_token_types

    AddRepositoryLocation.run(git_repo_location_params).match do
      success do |repo_name|
        flash[:success] = "Successfuly added #{repo_name} repository. " \
                              'Selected tokens were generated and can be found on Tokens page.'
        redirect_to :git_repository_locations
      end

      failure do |errors|
        @git_repository_locations = GitRepositoryLocation.all.order(:name)
        flash.now[:error] = errors.errors if errors
        render :index
      end
    end
  end

  private

  def repo_location_form
    Forms::RepositoryLocationsForm.new(
      params.dig(:forms_repository_locations_form, :uri),
      params[:token_types],
    )
  end

  def git_repo_location_params
    permitted = params.require(:forms_repository_locations_form).permit(:uri)
    permitted[:token_types] = params[:token_types] if params[:token_types].present?
    permitted[:validation_form] = @repo_location_form
    permitted
  end
end
