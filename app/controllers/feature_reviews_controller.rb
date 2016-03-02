require 'clients/jira'

class FeatureReviewsController < ApplicationController
  def new
    @app_names = GitRepositoryLocation.app_names
    @feature_review_form = feature_review_form
  end

  def create
    @feature_review_form = feature_review_form
    if @feature_review_form.valid?
      redirect_to @feature_review_form.path
    else
      @app_names = GitRepositoryLocation.app_names
      render :new
    end
  end

  def show
    @return_to = request.original_fullpath

    feature_review = factory.create_from_url_string(request.original_url)
    @feature_review_with_statuses = Queries::FeatureReviewQuery.new(feature_review, at: time)
                                                               .feature_review_with_statuses
  end

  def search
    @links = []
    @applications = GitRepositoryLocation.app_names
    @version = params[:version]
    @application = params[:application]

    return unless @version && @application

    versions = VersionResolver.new(git_repository_for(@application)).related_versions(@version)
    tickets = Repositories::TicketRepository.new.tickets_for_versions(versions)

    @links = factory.create_from_tickets(tickets).map(&:path)
    flash.now[:error] = 'No Feature Reviews found.' if @links.empty?
  end

  def link_ticket
    post_jira_comment

    redirect_to redirect_path
  end

  private

  def time
    # Add fraction of a second to work around microsecond time difference.
    # The "time" query value in the Feature Review URL has no microseconds (i.e. 0 usec),
    # whereas the times records are persisted to the DB have higher precision which includes microseconds.
    params.fetch(:time, nil).try { |t| Time.zone.parse(t).change(usec: 999_999.999) }
  end

  def factory
    Factories::FeatureReviewFactory.new
  end

  def feature_review_form
    form_input = params.fetch(:forms_feature_review_form, {})
    Forms::FeatureReviewForm.new(
      apps: form_input[:apps],
      uat_url: form_input[:uat_url],
      git_repository_loader: git_repository_loader,
    )
  end

  def git_repository_for(app_name)
    git_repository_loader.load(app_name)
  end

  def redirect_path
    @redirect_path ||= path_from_url(params[:return_to])
  end

  def post_jira_comment
    JiraClient.post_comment(jira_key, jira_comment)
    flash[:success] = "Feature Review was linked to #{jira_key}."\
    ' Refresh this page in a moment and the ticket will appear.'
  rescue StandardError => error
    flash[:error] = "Failed to link to #{jira_key}. Please check that the ticket ID is correct."
    Honeybadger.notify(error)
  end

  def jira_comment
    "[Feature ready for review|#{feature_review_url}]"
  end

  def jira_key
    request.request_parameters['jira_key']
  end

  def feature_review_url
    "#{root_url.chomp('/')}#{redirect_path}"
  end
end
