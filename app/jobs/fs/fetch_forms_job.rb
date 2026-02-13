class Fs::FetchFormsJob < ApplicationJob
  def perform(fs_client: FsEnvironment.fs_client, download_related_documents_job: ::Fs::DownloadFormRelatedDocumentsJob)
    fs_forms_list = fs_client.api.fetch_forms[:body]

    fs_forms_list.each do |fs_form_data|
      fs_form = Fs::Form.find_or_initialize_by(
        identifier: fs_form_data['identifier'],
      ).tap do |form|
        form.update(
          submission_type_identifier: fs_form_data['submission_type_identifier'],
          name: fs_form_data['name'],
          group_name: fs_form_data['form_group_name'],
          subtype_name: fs_form_data['subtype_name'],
          slug: fs_form_data['form_group_slug'],
          signature_required: fs_form_data['signature_required'],
          ez_signature: fs_form_data['ez_signature'],
          number_identifier: fs_form_data['form_group_number_identifier']
        )
      end

      fs_form_data['attachments'].each do |attachment_data|
        Fs::FormAttachment.find_or_initialize_by(
          fs_form_id: fs_form.id,
          group: Fs::FormAttachmentGroup.find_or_create_by!(identifier: attachment_data['identifier'])
        ).tap do |attachment|
          attachment.update(
            min_occurrences: attachment_data['min_occurrences'],
            max_occurrences: attachment_data['max_occurrences'],
          )
        end
      end

      download_related_documents_job.perform_later(fs_form)
    end

    Fs::FetchFormAttachmentGroupsJob.perform_later
  end
end
