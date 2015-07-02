require 'rails_helper'

RSpec.describe FeatureReviewProjection do
  let(:builds_projection) {
    instance_double(
      BuildsProjection,
      builds: double(:builds),
    )
  }
  let(:deploys_projection) {
    instance_double(
      DeploysProjection,
      deploys: double(:deploys),
    )
  }
  let(:manual_tests_projection) {
    instance_double(
      ManualTestsProjection,
      qa_submission: double(:qa_submission),
    )
  }
  let(:tickets_projection) {
    instance_double(
      FeatureReviewTicketsProjection,
      tickets: double(:tickets),
      approved?: false,
    )
  }
  let(:uatests_projection) {
    instance_double(
      UatestsProjection,
      uatest: double(:uatest),
    )
  }
  let(:uat_url) { 'http://uat.example.com' }

  subject(:projection) {
    FeatureReviewProjection.new(
      uat_url: uat_url,
      builds_projection: builds_projection,
      deploys_projection: deploys_projection,
      manual_tests_projection: manual_tests_projection,
      tickets_projection: tickets_projection,
      uatests_projection: uatests_projection,
    )
  }

  let(:event) { build(:jira_event) }

  it 'applies events to its subprojections' do
    expect(builds_projection).to receive(:apply).with(event)
    expect(deploys_projection).to receive(:apply).with(event)
    expect(manual_tests_projection).to receive(:apply).with(event)
    expect(tickets_projection).to receive(:apply).with(event)
    expect(uatests_projection).to receive(:apply).with(event)

    projection.apply(event)
  end

  context 'when the tickets projection is approved' do
    let(:tickets_projection) { instance_double(FeatureReviewTicketsProjection, approved?: true) }

    it 'becomes locked' do
      expect(projection).to be_locked
    end

    it 'rejects events' do
      expect(builds_projection).to_not receive(:apply)
      expect(deploys_projection).to_not receive(:apply)
      expect(manual_tests_projection).to_not receive(:apply)
      expect(tickets_projection).to_not receive(:apply)
      expect(uatests_projection).to_not receive(:apply)

      projection.apply(event)
    end

    context 'and then unapproved' do
      let(:event_before_unapproval) { build(:deploy_event) }
      let(:unapproval_event) { build(:jira_event, :rejected) }
      let(:event_after_unapproval) { build(:circle_ci_event) }

      before do
        allow(builds_projection).to receive(:apply)
        allow(deploys_projection).to receive(:apply)
        allow(manual_tests_projection).to receive(:apply)
        allow(tickets_projection).to receive(:apply)
        allow(uatests_projection).to receive(:apply)
      end

      it 'stops rejecting events and also applies the previously rejected ones' do
        projection.apply(event_before_unapproval)

        allow(tickets_projection).to receive(:apply).with(unapproval_event) do
          allow(tickets_projection).to receive(:approved?).and_return(false)
        end

        projection.apply(unapproval_event)

        expect(projection).not_to be_locked

        expect(tickets_projection).to have_received(:apply).with(event_before_unapproval).ordered
        expect(tickets_projection).to have_received(:apply).with(unapproval_event).ordered

        projection.apply(event_after_unapproval)

        expect(tickets_projection).to have_received(:apply).with(event_after_unapproval).ordered
      end
    end
  end

  describe '.build' do
    let(:apps) { { 'app1' => 'abc' } }
    let(:projection_url) { 'http://shipment-tracker.example.com/feature_reviews?app1=abc' }

    shared_examples_for 'a wired up builder' do
      it 'passes the correct values' do
        allow(BuildsProjection).to receive(:new)
          .with(apps: apps).and_return(builds_projection)
        allow(DeploysProjection).to receive(:new)
          .with(apps: apps, server: server).and_return(deploys_projection)
        allow(ManualTestsProjection).to receive(:new)
          .with(apps: apps).and_return(manual_tests_projection)
        allow(FeatureReviewTicketsProjection).to receive(:new)
          .with(projection_url: projection_url).and_return(tickets_projection)
        allow(UatestsProjection).to receive(:new)
          .with(apps: apps, server: server).and_return(uatests_projection)

        expect(FeatureReviewProjection).to receive(:new).with(
          uat_url: uat_url,
          builds_projection: builds_projection,
          deploys_projection: deploys_projection,
          manual_tests_projection: manual_tests_projection,
          tickets_projection: tickets_projection,
          uatests_projection: uatests_projection,
        )

        FeatureReviewProjection.build(apps: apps, uat_url: uat_url, projection_url: projection_url)
      end
    end

    context 'when uat_url is a url' do
      let(:uat_url) { 'http://uat.example.com/some/path' }
      let(:server) { 'uat.example.com' }

      it_behaves_like 'a wired up builder'
    end

    context 'when uat_url is a domain' do
      let(:uat_url) { 'uat.example.com' }
      let(:server) { 'uat.example.com' }

      it_behaves_like 'a wired up builder'
    end

    context 'when uat_url is missing scheme' do
      let(:uat_url) { 'uat.example.com/foo/bar' }
      let(:server) { 'uat.example.com' }

      it_behaves_like 'a wired up builder'
    end
  end

  describe '#tickets' do
    it 'delegates to the tickets projection' do
      expect(projection.tickets).to eq(tickets_projection.tickets)
    end
  end

  describe '#deploys' do
    it 'delegates to the deploys projection' do
      expect(projection.deploys).to eq(deploys_projection.deploys)
    end
  end

  describe '#builds' do
    it 'delegates to the builds projection' do
      expect(projection.builds).to eq(builds_projection.builds)
    end
  end

  describe '#qa_submission' do
    it 'delegates to the manual tests projection' do
      expect(projection.qa_submission).to eq(manual_tests_projection.qa_submission)
    end
  end

  describe '#uatest' do
    it 'delegates to the uatests projection' do
      expect(projection.uatest).to eq(uatests_projection.uatest)
    end
  end

  describe '#uat_url' do
    subject { projection.uat_url }

    context 'when not given a domain' do
      let(:uat_url) { nil }
      it { is_expected.to be nil }
    end

    context 'when given a domain' do
      let(:uat_url) { 'https://uat.example.com' }
      it { is_expected.to eq('https://uat.example.com') }
    end

    context 'when given a URL with no scheme' do
      let(:uat_url) { 'uat.example.com' }
      it { is_expected.to eq('http://uat.example.com') }
    end

    context 'when given a URL' do
      let(:uat_url) { 'http://uat.example.com/bish/bosh' }
      it { is_expected.to eq('http://uat.example.com/bish/bosh') }
    end
  end
end
