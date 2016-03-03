require 'clients/jira'
require 'honeybadger'
require 'repositories/ticket_repository'

class RelinkTicketJob < ActiveJob::Base
  queue_as :default

  def perform(payload)
    before_sha = payload.delete(:before_sha)
    after_sha = payload.delete(:after_sha)

    ticket_repo = Repositories::TicketRepository.new
    linked_tickets = ticket_repo.tickets_for_versions(before_sha)

    linked_tickets.each do |ticket|
      ticket.paths.each do |feature_review_path|
        next unless feature_review_path.include?(before_sha)
        link_feature_review_to_ticket(ticket.key, feature_review_path, before_sha, after_sha)
      end
    end
  end

  private

  def link_feature_review_to_ticket(ticket_key, old_feature_review_path, before_sha, after_sha)
    new_feature_review_path = old_feature_review_path.sub(before_sha, after_sha)
    message = "[Feature ready for review|#{feature_review_url(new_feature_review_path)}]"
    JiraClient.post_comment(ticket_key, message)
  rescue JiraClient::InvalidKeyError
    Rails.logger.error "Failed to post comment to Jira ticket #{ticket_key}."\
      'The issue might have been deleted'
  rescue StandardError => error
    Honeybadger.notify(error)
  end

  def feature_review_url(feature_review_path)
    Rails.application.routes.url_helpers.root_url.chomp('/') + feature_review_path
  end
end
