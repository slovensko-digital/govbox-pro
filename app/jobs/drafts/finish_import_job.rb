class Drafts::FinishImportJob < ApplicationJob
  def perform(batch, params)
    batch.properties[:import].drafts.find_each do |draft|
      if draft.valid?(:validate_data)
        draft.loading_done!
      else
        draft.invalid_data!
      end
    end

    Utils.delete_file(batch.properties[:zip_path])
    Utils.delete_file(batch.properties[:extracted_data_path])
  end
end
