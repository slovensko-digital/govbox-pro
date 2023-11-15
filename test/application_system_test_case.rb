require "test_helper"
require "helpers/auth_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driver = ENV['DRIVER'] ? ENV['DRIVER'].to_sym : :headless_chrome
  driven_by :selenium, using: driver, screen_size: [1400, 1400]

  include AuthHelper
end
