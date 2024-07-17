class UpdateFsBoxesSettingsAndUri < ActiveRecord::Migration[7.1]
  def up
    Fs::Box.find_each do |box|
      box.settings['message_drafts_import_enabled'] = Fs::Box::DISABLED_MESSAGE_DRAFTS_IMPORT_KEYWORDS.none? { |keyword| box.name.include?(keyword) }
      box.uri = "dic://sk/#{box.settings_dic}_#{box.name}"

      box.save
    end
  end
end
