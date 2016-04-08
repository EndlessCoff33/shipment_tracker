# frozen_string_literal: true
require 'events/base_event'

module Events
  class JiraEvent < Events::BaseEvent
    def key
      details.dig('issue', 'key')
    end

    def issue?
      details.fetch('webhookEvent', '').start_with?('jira:issue_')
    end

    def issue_id
      details.dig('issue', 'id')
    end

    def summary
      details.dig('issue', 'fields', 'summary')
    end

    def description
      details.dig('issue', 'fields', 'description')
    end

    def status
      details.dig('issue', 'fields', 'status', 'name')
    end

    def comment
      details.dig('comment', 'body') || ''
    end

    def approval?
      status_item &&
        !approved_status?(status_item['fromString']) &&
        approved_status?(status_item['toString'])
    end

    def unapproval?
      status_item &&
        approved_status?(status_item['fromString']) &&
        !approved_status?(status_item['toString'])
    end

    private

    def status_item
      @status_item ||= changelog_items.find { |item| item['field'] == 'status' }
    end

    def changelog_items
      details.dig('changelog', 'items') || []
    end

    def approved_status?(status)
      Rails.application.config.approved_statuses.include?(status)
    end
  end
end
