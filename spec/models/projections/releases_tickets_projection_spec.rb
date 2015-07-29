require 'rails_helper'

RSpec.describe Projections::ReleasesTicketsProjection do
  subject(:projection) { described_class.new }

  describe '#apply' do
    it 'tracks the current status' do
      projection.apply(build(:jira_event, key: 'JIRA-1'))
      expect(projection.tickets.first.status).to eq('To Do')

      projection.apply(build(:jira_event, :started, key: 'JIRA-1'))
      expect(projection.tickets.first.status).to eq('In Progress')

      projection.apply(build(:jira_event, :development_completed, key: 'JIRA-1'))
      expect(projection.tickets.first.status).to eq('Ready For Review')

      projection.apply(build(:jira_event, :deployed, key: 'JIRA-1'))
      expect(projection.tickets.first.status).to eq('Done')

      expect(projection.tickets.size).to eq(1)
    end

    it 'records the approver' do
      projection.apply(build(:jira_event, key: 'JIRA-1'))
      projection.apply(build(:jira_event, :approved, key: 'JIRA-1',
                                                     user_email: 'approver@foo.io',
                                                     updated: '2015-06-07T15:24:34.957+0100'))
      projection.apply(build(:jira_event, :deployed, key: 'JIRA-1', changelog_details: {}))

      expect(projection.tickets.first.status).to eq('Done')
      expect(projection.tickets.first.approver_email).to eq('approver@foo.io')
      expect(projection.tickets.first.approved_at).to eq(Time.parse('2015-06-07T15:24:34.957+0100'))

      projection.apply(build(:jira_event, key: 'JIRA-1',
                                          user_email: 'user_who_changed_description@foo.io',
                                          updated: '2015-07-08T16:14:38.123+0100',
                                          status: 'Done',
                                          changelog_details: {}))

      expect(projection.tickets.first.approver_email).to eq('approver@foo.io')
      expect(projection.tickets.first.approved_at).to eq(Time.parse('2015-06-07T15:24:34.957+0100'))
    end

    context 'when the ticket is unapproved' do
      it 'removes the approver information' do
        projection.apply(build(:jira_event, key: 'JIRA-1'))
        projection.apply(build(:jira_event, :approved, key: 'JIRA-1'))
        projection.apply(build(:jira_event, :rejected, key: 'JIRA-1'))

        expect(projection.tickets.first.approver_email).to be nil
        expect(projection.tickets.first.approved_at).to be nil
      end
    end

    it 'ignores other events' do
      projection.apply(build(:jenkins_event))

      expect(projection.tickets).to be_empty
    end

    it 'ignores non jira issue events' do
      expect { projection.apply(build(:jira_event_user_created)) }.to_not raise_error
    end
  end

  describe '#ticket_for' do
    it 'returns a ticket that matches the jira key' do
      projection.apply(build(:jira_event, key: 'JIRA-1'))
      projection.apply(build(:jira_event, key: 'JIRA-12'))
      projection.apply(build(:jira_event, key: 'JIRA-123'))

      expect(projection.ticket_for('JIRA-123')).to eq(Ticket.new(key: 'JIRA-123'))
    end
  end
end
