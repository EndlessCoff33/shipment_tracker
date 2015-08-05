class ManualTestEvent < Event
  def apps
    details.fetch('apps', [])
  end

  def versions
    apps.map { |app| app.fetch('version') }
  end

  def email
    details.fetch('email', nil)
  end

  def comment
    details.fetch('comment', '')
  end

  def accepted?
    details.fetch('status', nil) == 'success'
  end
end
