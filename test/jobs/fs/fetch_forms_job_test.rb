# frozen_string_literal: true

require "test_helper"

class Fs::FetchFormsJobTest < ActiveJob::TestCase
  test "persists pdf_supported flag from the fetched form payload" do
    perform_with_form_data('pdf_supported' => true)

    assert Fs::Form.find_by(identifier: '9999_999').pdf_supported?
  end

  test "persists pdf_supported as false when the fetched form payload omits it" do
    perform_with_form_data

    assert_not Fs::Form.find_by(identifier: '9999_999').pdf_supported?
  end

  private

  def perform_with_form_data(overrides = {})
    fs_form_data = {
      'identifier' => '9999_999',
      'submission_type_identifier' => '9999',
      'name' => 'Test form',
      'form_group_name' => 'Test group',
      'subtype_name' => 'Riadny',
      'form_group_slug' => 'TESTv1',
      'signature_required' => true,
      'ez_signature' => true,
      'form_group_number_identifier' => 111,
      'attachments' => []
    }.merge(overrides)

    fs_api = Minitest::Mock.new
    fs_api.expect :fetch_forms, { body: [fs_form_data] }

    fs_client = Minitest::Mock.new
    fs_client.expect :api, fs_api

    download_related_documents_job = Class.new do
      def self.perform_later(*); end
    end

    Fs::FetchFormsJob.new.perform(fs_client: fs_client, download_related_documents_job: download_related_documents_job)
  end
end
