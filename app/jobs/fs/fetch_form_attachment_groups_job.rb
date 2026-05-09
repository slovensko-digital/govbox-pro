class Fs::FetchFormAttachmentGroupsJob < ApplicationJob
  def perform(fs_client: FsEnvironment.fs_client)
    Fs::FormAttachmentGroup.find_each do |group|
      attachment_data = fs_client.api.get_form_attachment(group.identifier)[:body]
      group.update!(
        name: attachment_data['name'],
        mime_types: attachment_data['mime_types'].map { |mime_type| Utils.from_fs_mimetype(mime_type) }
      )
    end
  end
end
