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
