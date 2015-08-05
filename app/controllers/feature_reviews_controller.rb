class FeatureReviewsController < ApplicationController
  def new
    @app_names = RepositoryLocation.app_names
    @feature_review_form = feature_review_form
  end

  def create
    @feature_review_form = feature_review_form
    if @feature_review_form.valid?
      redirect_to @feature_review_form.url
    else
      @app_names = RepositoryLocation.app_names
      render :new
    end
  end

  def show
    @return_to = request.original_fullpath
    @presenter = FeatureReviewPresenter.new(
      Projections::FeatureReviewProjection.load(
        request.original_url,
        at: time,
      ),
    )
  end

  def search
    @links = []
    @applications = RepositoryLocation.app_names
    @version = params[:version]
    @application = params[:application]

    return unless @version && @application

    versions = VersionResolver.new(git_repository_for(@application)).related_versions(@version)
    projection = Projections::FeatureReviewSearchProjection.load(versions: versions)
    @links = projection.feature_reviews
    flash[:error] = 'No Feature Reviews found.' if @links.empty?
  end

  private

  def time
    params.fetch(:time, nil).try { |t| Time.zone.parse(t) }
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
end
