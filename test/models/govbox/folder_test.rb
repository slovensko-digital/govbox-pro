# == Schema Information
#
# Table name: govbox_folders
#
#  id               :bigint           not null, primary key
#  name             :string           not null
#  system           :boolean          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  box_id           :bigint           not null
#  edesk_folder_id  :integer          not null
#  parent_folder_id :bigint
#
require "test_helper"

class Govbox::FolderTest < ActiveSupport::TestCase
  test "drafts? returns true if Drafts folder" do
    drafts_folder = govbox_folders(:ssd_drafts)

    assert drafts_folder.drafts?
  end

  test "bin? returns true if Bin folder" do
    bin_folder = govbox_folders(:ssd_bin)

    assert bin_folder.bin?
  end
end
