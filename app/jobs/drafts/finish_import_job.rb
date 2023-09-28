class Drafts::FinishImportJob < ApplicationJob
  def perform(batch, params)
    import = batch.properties[:import]

    import.message_drafts.find_each do |message_draft|
      next if message_draft.invalid?

      if message_draft.valid?(:validate_data)
        message_draft.metadata["status"] = "created"
      else
        message_draft.metadata["status"] = "invalid"
      end

      message_draft.save
    end

    Utils.delete_file(import.content_path)
    import.update(content_path: nil)
  end
end
