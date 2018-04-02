# frozen_string_literal: true

require 'rails_helper'
require 'support/shared_examples/test_build_examples'

RSpec.describe Events::CircleCiEvent do
  it_behaves_like 'a test build interface'
  it_behaves_like 'a test build subclass' do
    subject { described_class.new(details: payload) }

    let(:expected_source) { 'CircleCi' }

    let(:version) { '123' }
    let(:payload) { success_payload }
    let(:success_payload) {
      {
        'payload' => {
          'build_url' => 'http://example.com',
          'outcome' => 'success',
          'vcs_revision' => version,
        },
      }
    }
    let(:failure_payload) {
      {
        'payload' => {
          'app_name' => 'example',
          'build_type' => 'integration',
          'build_url' => 'http://example.com',
          'outcome' => 'failed',
          'vcs_revision' => version,
        },
      }
    }
    let(:invalid_payload) {
      { some: 'nonsense' }
    }
  end
end
