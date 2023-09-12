class MessageDraftsImportValidator < ActiveModel::Validator
  def validate(record)
    record.errors.add(:drafts, "No drafts found") if Utils.sub_folders(record.content_path).empty?

    Dir.each_child(record.content_path) do |package_entry_name|
      package_entry_path = File.join(record.content_path, package_entry_name)

      if File.directory?(package_entry_path)
        # check each draft directory structure
        Dir.each_child(package_entry_path) do |draft_subfolder_name|
          draft_subfolder_path = File.join(package_entry_path, draft_subfolder_name)

          if File.directory?(draft_subfolder_path)
            case(draft_subfolder_name)
            when 'podpisane', 'podpisat', 'nepodpisovat'
              contains_files_only?(record, draft_subfolder_path)
            else
              record.errors.add(:drafts, "Disallowed draft subfolder")
            end
          else
            record.errors.add(:drafts, "Unknown signature status, files must be inside a folder.")
          end
        end
      elsif Utils.csv?(package_entry_name)
        # noop
      else
        record.errors.add(:drafts, "Package contains extra file")
      end

      csv_paths = Dir[record.content_path + "/*.csv"]
      record.errors.add(:drafts, "Package must contain 1 CSV file") if csv_paths.size != 1
    end
  end

  private

  def contains_files_only?(record, path)
    Dir.each_child(path) do |entry_name|
      record.errors.add(:drafts, "Disallowed content subfolder") if File.directory?(entry_name)
    end
  end
end
