require 'rails_helper'

RSpec.describe FeatureReviewPresenter do
  let(:tickets) { [] }
  let(:builds) { {} }
  let(:deploys) { [] }
  let(:qa_submission) { nil }

  let(:projection) {
    instance_double(
      FeatureReviewProjection,
      tickets: tickets,
      builds: builds,
      deploys: deploys,
      qa_submission: qa_submission,
    )
  }

  subject(:presenter) { FeatureReviewPresenter.new(projection) }

  it 'delegates #tickets, #builds, #deploys and #qa_submission to the projection' do
    expect(presenter.tickets).to eq(projection.tickets)
    expect(presenter.builds).to eq(projection.builds)
    expect(presenter.deploys).to eq(projection.deploys)
    expect(presenter.qa_submission).to eq(projection.qa_submission)
  end

  describe '#build_status' do
    context 'when all builds pass' do
      let(:builds) do
        {
          'frontend' => Build.new(status: 'success'),
          'backend'  => Build.new(status: 'success'),
        }
      end

      it 'returns :success' do
        expect(presenter.build_status).to eq(:success)
      end
    end

    context 'when any of the builds fails' do
      let(:builds) do
        {
          'frontend' => Build.new(status: 'failed'),
          'backend'  => Build.new(status: 'success'),
        }
      end

      it 'returns :failure' do
        expect(presenter.build_status).to eq(:failure)
      end
    end

    context 'when there are no builds' do
      it 'returns nil' do
        expect(presenter.build_status).to be nil
      end
    end
  end

  describe '#deploy_status' do
    context 'when all deploys are correct or ignored' do
      let(:deploys) do
        [
          Deploy.new(correct: :yes),
          Deploy.new(correct: :ignore),
        ]
      end

      it 'returns :success' do
        expect(presenter.deploy_status).to eq(:success)
      end
    end

    context 'when any deploy is not correct' do
      let(:deploys) do
        [
          Deploy.new(correct: :yes),
          Deploy.new(correct: :no),
          Deploy.new(correct: :ignore),
        ]
      end

      it 'returns :failure' do
        expect(presenter.deploy_status).to eq(:failure)
      end
    end

    context 'when there are no deploys' do
      it 'returns nil' do
        expect(presenter.deploy_status).to be nil
      end
    end

    context 'when all deploys are ignored' do
      let(:deploys) {
        [
          Deploy.new(correct: :ignore),
        ]
      }

      it 'returns nil' do
        expect(presenter.deploy_status).to be nil
      end
    end
  end

  describe '#qa_status' do
    context 'when QA submission is accepted' do
      let(:qa_submission) { QaSubmission.new(status: 'accepted') }

      it 'returns :success' do
        expect(presenter.qa_status).to eq(:success)
      end
    end

    context 'when QA submission is rejected' do
      let(:qa_submission) { QaSubmission.new(status: 'rejected') }

      it 'returns :failure' do
        expect(presenter.qa_status).to eq(:failure)
      end
    end

    context 'when QA submission is missing' do
      it 'returns nil' do
        expect(presenter.qa_status).to be nil
      end
    end
  end

  describe '#summary_status' do
    context 'when status of deploys, builds, and QA submission are success' do
      let(:builds) { { 'frontend' => Build.new(status: 'success') } }
      let(:deploys) { [Deploy.new(correct: :yes)] }
      let(:qa_submission) { QaSubmission.new(status: 'accepted') }

      it 'returns :success' do
        expect(presenter.summary_status).to eq(:success)
      end
    end

    context 'when any status of deploys, builds, or QA submission is failed' do
      let(:builds) { { 'frontend' => Build.new(status: 'success') } }
      let(:deploys) { [Deploy.new(correct: :ignore)] }
      let(:qa_submission) { QaSubmission.new(status: 'rejected') }

      it 'returns :failure' do
        expect(presenter.summary_status).to eq(:failure)
      end
    end

    context 'when no status is a failure but at least one is a warning' do
      let(:builds) { { 'frontend' => Build.new(status: 'success') } }
      let(:deploys) { [Deploy.new(correct: :ignore)] }
      let(:qa_submission) { QaSubmission.new(status: 'accepted') }

      it 'returns nil' do
        expect(presenter.summary_status).to be(nil)
      end
    end
  end
end
