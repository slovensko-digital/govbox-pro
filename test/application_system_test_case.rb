require "test_helper"
require "helpers/auth_helper"
require "helpers/page_parts_helper"
require "helpers/tenant_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driver = ENV['DRIVER'] ? ENV['DRIVER'].to_sym : :headless_chrome
  driven_by :selenium, using: driver, screen_size: [1400, 1400]

  include AuthHelper
  include PagePartsHelper
  include TenantHelper
end
