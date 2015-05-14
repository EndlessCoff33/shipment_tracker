require 'rails_helper'
require 'issue_audit_projection'

RSpec.describe IssueAuditProjection do
  let(:git_repository) { instance_double(GitRepository) }

  subject(:projection) do
    IssueAuditProjection.new(
      app_name: 'hello_world_rails',
      issue_name: 'JIRA-1',
      git_repository: git_repository,
    )
  end

  describe 'ticket projection' do
    it 'builds the ticket status' do
      events = [
        build(:jira_event, key: 'JIRA-1', summary: 'Start', status: 'To Do', user_email: 'bob@foo.io'),
        build(:jira_event, key: 'JIRA-2', summary: 'Start too', status: 'To Do', user_email: 'alice@foo.io'),
      ]

      projection.apply_all(events)

      expect(projection.ticket)
        .to eq(Ticket.new(key: 'JIRA-1', summary: 'Start', status: 'To Do', approver_email: nil))
    end

    context 'as the state of a ticket changes' do
      let(:commit_messages) { ['JIRA-1 first'] }

      it 'tracks the current status' do
        projection.apply(build(:jira_event, key: 'JIRA-1'))
        expect(projection.ticket.status).to eq('To Do')

        projection.apply(build(:jira_event, :in_progress, key: 'JIRA-1'))
        expect(projection.ticket.status).to eq('In Progress')

        projection.apply(build(:jira_event, :ready_for_review, key: 'JIRA-1'))
        expect(projection.ticket.status).to eq('Ready For Review')

        projection.apply(build(:jira_event, :done, key: 'JIRA-1'))
        expect(projection.ticket.status).to eq('Done')
      end

      it 'records the approver' do
        projection.apply(build(:jira_event, key: 'JIRA-1'))
        projection.apply(build(:jira_event, :done, key: 'JIRA-1',
                                                   user_email: 'approver@foo.io',
                                                   updated: '2015-06-07T15:24:34.957+0100'))
        projection.apply(build(:jira_event, :done, key: 'JIRA-1', changelog_details: {}))

        expect(projection.ticket.status).to eq('Done')
        expect(projection.ticket.approver_email).to eq('approver@foo.io')
        expect(projection.ticket.approved_at).to eq(Time.parse('2015-06-07T15:24:34.957+0100'))

        projection.apply(build(:jira_event, :done, key: 'JIRA-1',
                                                   user_email: 'user_who_changed_description@foo.io',
                                                   updated: '2015-07-08T16:14:38.123+0100',
                                                   changelog_details: {}))

        expect(projection.ticket.approver_email).to eq('approver@foo.io')
        expect(projection.ticket.approved_at).to eq(Time.parse('2015-06-07T15:24:34.957+0100'))
      end

      context 'when the ticket is unapproved' do
        it 'removes the approver information' do
          projection.apply(build(:jira_event, key: 'JIRA-1'))
          projection.apply(build(:jira_event, :done, key: 'JIRA-1'))
          projection.apply(build(:jira_event, :to_do, key: 'JIRA-1'))

          expect(projection.ticket.approver_email).to be nil
          expect(projection.ticket.approved_at).to be nil
        end
      end
    end
  end
end
