class Drafts::FinishImportJob < ApplicationJob
  def perform(batch, params)
    batch.properties[:drafts].each do |draft|
      if draft.valid?(:validate_data)
        draft.update(status: "loading_done")
      else
        draft.update(status: "invalid_data")
      end
    end

    Utils.delete_file(batch.properties[:zip_path])
    Utils.delete_file(batch.properties[:extracted_data_path])
  end
end
