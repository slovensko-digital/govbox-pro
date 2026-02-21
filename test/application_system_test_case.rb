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

  include AuthHelper
  include PagePartsHelper
  include TenantHelper
end
