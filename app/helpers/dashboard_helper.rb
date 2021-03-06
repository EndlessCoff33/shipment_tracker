# frozen_string_literal: true

module DashboardHelper
  def result_message_for(query: nil, from_date: nil, to_date: nil, found: false)
    today_string = Time.zone.today.to_s
    if query.blank? && from_date == today_string && to_date == today_string
      'Results for tickets deployed today'
    elsif found
      "Results for #{query_combined_message(query, from_date, to_date)}"
    else
      "No results found for #{query_combined_message(query, from_date, to_date)}"
    end
  end

  # rubocop:disable all
  def query_combined_message(query, from_date, to_date)
    if query.present? && from_date.present? && to_date.present?
      "<b>'#{query}'</b> in tickets deployed between <b>'#{from_date}'</b> and <b>'#{to_date}'</b>"
    elsif query.present? && from_date.present?
      "<b>'#{query}'</b> in tickets deployed since <b>'#{from_date}'</b>"
    elsif query.present? && to_date.present?
      "<b>'#{query}'</b> in tickets deployed until <b>'#{to_date}'</b>"
    elsif query.present?
      "<b>'#{query}'</b>"
    elsif from_date.present? && to_date.present?
      "tickets deployed between <b>'#{from_date}'</b> and <b>'#{to_date}'</b>"
    elsif from_date.present?
      "tickets deployed since <b>'#{from_date}'</b>"
    elsif to_date.present?
      "tickets deployed until <b>'#{to_date}'</b>"
    else
      'all tickets'
    end
  end
  # rubocop:enable all
end
