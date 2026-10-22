require "application_system_test_case"

class FrontendAssetsTest < ApplicationSystemTestCase
  test "login loads the self-hosted Inter font including Slovak glyphs" do
    visit auth_path

    assert_includes page.evaluate_script("getComputedStyle(document.body).fontFamily"), "Inter var"
    loaded_fonts = page.evaluate_async_script(<<~JS)
      const done = arguments[0];
      document.fonts.load('400 16px "Inter var"', 'Príliš žltý kôň').then(fonts => done(fonts.length));
    JS
    assert_operator loaded_fonts, :>=, 2
    assert_no_selector 'link[href*="inter-font"]', visible: :all
  end

  test "desktop utilities and mobile sidebar survive the Tailwind upgrade" do
    Searchable::MessageThread.reindex_all
    sign_in_as(:basic)

    assert_no_button "Open sidebar"
    styles = page.evaluate_script(<<~JS)
      (() => {
        const probe = document.createElement('div');
        probe.className = 'rounded-sm shadow-xs ring-1 ring-black/5 bg-yellow-200 shrink-0';
        document.body.append(probe);
        const style = getComputedStyle(probe);
        const result = [style.borderRadius, style.backgroundColor, style.flexShrink, style.boxShadow];
        probe.remove();
        return result;
      })();
    JS
    assert_equal "4px", styles[0]
    assert_equal "rgb(254, 240, 138)", styles[1]
    assert_equal "0", styles[2]
    assert_not_equal "none", styles[3]

    page.driver.browser.manage.window.resize_to(800, 1000)
    click_button "Open sidebar"
    within "#sidebar-mobile" do
      assert_link "Všetky správy", visible: true
      find("button[aria-label='Close sidebar']").click
      assert_no_link "Všetky správy", visible: true
    end
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1400)
  end
end
