class Drafts::FinishImportJob < ApplicationJob
  def perform(batch, params)
    batch.properties[:import].message_drafts.find_each do |message_draft|
      if message_draft.valid?(:validate_data)
        message_draft.metadata["status"] = "created"
      else
        message_draft.metadata["status"] = "invalid"
      end

      message_draft.save
    end

    Utils.delete_file(batch.properties[:zip_path])
    Utils.delete_file(batch.properties[:extracted_data_path])
  end
end
