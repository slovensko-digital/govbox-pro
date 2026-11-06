require "test_helper"

class FsFormsStorageCspTest < ActionDispatch::IntegrationTest
  test "allows FS form styles and images from forms storage, but not its scripts" do
    with_forms_storage_url("https://forms.example.com/storage") do
      get auth_path
    end

    policy = response.headers.fetch("Content-Security-Policy")
    assert_includes policy[/style-src [^;]*/].split, "https://forms.example.com"
    assert_includes policy[/img-src [^;]*/].split, "https://forms.example.com"
    assert_not_includes policy[/script-src [^;]*/].split, "https://forms.example.com"
  end

  private

  def with_forms_storage_url(url)
    original_url = ENV.fetch("FS_FORMS_STORAGE_API_URL", nil)
    ENV["FS_FORMS_STORAGE_API_URL"] = url
    yield
  ensure
    ENV["FS_FORMS_STORAGE_API_URL"] = original_url
  end
end
