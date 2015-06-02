module FeatureReviewsHelper
  def summary_panel_class(success_state)
    success_state ? 'panel-success' : 'panel-danger'
  end

  def summary_panel_icon_class(success_state)
    success_state ? 'glyphicon-ok' : 'glyphicon-alert'
  end

  def panel_class(status)
    if status == 'success'
      'panel-success'
    elsif status == 'failed'
      'panel-danger'
    else
      'panel-warning'
    end
  end

  def panel_icon_class(status)
    if status == 'success'
      'glyphicon-ok'
    elsif status == 'failed'
      'glyphicon-remove'
    else
      'glyphicon-alert'
    end
  end

  def deploy_status_icon_class(status)
    case status
    when :yes
      'text-success glyphicon-ok'
    when :no
      'text-danger glyphicon-remove'
    when :ignore
      'text-warning glyphicon-alert'
    end
  end

  def summary_item_classes(status)
    if status == 'success'
      'text-success glyphicon-ok'
    elsif status == 'failed'
      'text-danger glyphicon-remove'
    else
      'text-warning glyphicon-alert'
    end
  end

  def short_sha(full_sha)
    full_sha[0...7]
  end

  def to_link(url, options = {})
    link_to url, Addressable::URI.heuristic_parse(url).to_s, options
  end
end
