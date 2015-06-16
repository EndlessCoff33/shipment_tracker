class ManualTestsProjection
  attr_reader :qa_submission

  def initialize(apps:)
    @apps = apps
  end

  def apply(event)
    return unless event.is_a?(ManualTestEvent)
    return unless apps_hash(event.apps) == @apps

    @qa_submission = QaSubmission.new(
      name: event.user_name,
      status: event.status == 'success' ? 'accepted' : 'rejected',
      created_at: event.created_at,
    )
  end

  private

  def apps_hash(apps_list)
    apps_list.map { |app| app.values_at('name', 'version') }.to_h
  end
end
