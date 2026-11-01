require "test_helper"
require "helpers/auth_helper"
require "helpers/page_parts_helper"
require "helpers/tenant_helper"

# Chrome raises UnknownError (instead of StaleElementReferenceError) when a node
# has been detached from the document (e.g. during a Turbo Drive navigation or
# a Turbo Stream update). Capybara retries on StaleElementReferenceError but not
# on UnknownError, so we translate it at the Selenium response layer so that
# Capybara's built-in retry loop kicks in regardless of which code path triggered it.
module StaleNodeFix
  STALE_NODE_MESSAGE = "Node with given id does not belong to the document"

  def assert_ok
    super
  rescue Selenium::WebDriver::Error::UnknownError => e
    raise unless e.message.include?(STALE_NODE_MESSAGE)

    raise Selenium::WebDriver::Error::StaleElementReferenceError, e.message
  end
end
Selenium::WebDriver::Remote::Response.prepend(StaleNodeFix)

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driver = ENV['DRIVER'] ? ENV['DRIVER'].to_sym : :headless_chrome
  driven_by :selenium, using: driver, screen_size: [1400, 1400]

  Capybara.default_max_wait_time = 5

  def after_teardown
    # Stop Turbo prefetch/navigation and drain responses before clearing cookies.
    # Otherwise an in-flight response can restore the previous test's session.
    visit "about:blank"
    page.server&.wait_for_pending_requests
  ensure
    super
  end

  # After rendering a Turbo Stream, Turbo waits for an animation frame and focuses again the element
  # that had focus before the render. Keys typed into another field in between end up in that element.
  def wait_for_turbo_focus_restore
    evaluate_async_script("requestAnimationFrame(() => requestAnimationFrame(arguments[0]))")
  end

  include AuthHelper
  include PagePartsHelper
  include TenantHelper
end
