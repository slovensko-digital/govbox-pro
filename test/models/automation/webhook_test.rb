require "test_helper"

class Automation::WebhookTest < ActiveSupport::TestCase
  test "should POST the url with correct payload when fired" do
    message = messages(:ssd_main_draft)
    event = :event
    timestamp = DateTime.now
    data = {
      type: "#{message.class.name.underscore}.#{event}",
      timestamp: timestamp,
      data: {
        message_id: message.id,
        message_thread_id: message.thread.id
      }
    }.to_json
    webhook = automation_webhooks(:one)

    downloader = Minitest::Mock.new
    downloader.expect :post, true, [webhook.url, data], content_type: 'application/json'

    webhook.fire! message, event, timestamp, downloader: downloader

    assert_mock downloader
  end

  test "should be valid with a public https url" do
    assert build_webhook.valid?
  end

  test "should be invalid unless the url is a well formed https url" do
    urls = ["http://example.com/hook", "ftp://example.com/hook", "javascript:alert(1)", "https://", "https://[", "https://exa mple.com", "not a url"]

    urls.each do |url|
      webhook = build_webhook(url: url)

      assert_not webhook.valid?, "expected #{url.inspect} to be rejected"
      assert_includes webhook.errors[:url], "Musí byť verejná HTTPS adresa"
    end
  end

  test "should be invalid when the host resolves to a loopback, private, link local or unspecified address" do
    addresses = %w[127.0.0.1 ::1 ::ffff:127.0.0.1 10.1.2.3 172.16.0.1 192.168.1.1 fd00::1 169.254.169.254 fe80::1 ::ffff:169.254.169.254 0.0.0.0 ::]

    addresses.each do |address|
      in_production_resolving [address] do
        assert_not build_webhook.valid?, "expected #{address} to be rejected"
      end
    end
  end

  test "should be invalid when only one of several resolved addresses is blocked" do
    in_production_resolving ["93.184.216.34", "127.0.0.1"] do
      assert_not build_webhook.valid?
    end
  end

  test "should be invalid when the host does not resolve" do
    in_production_resolving [] do
      assert_not build_webhook.valid?
    end
  end

  test "should be valid when the host resolves to public addresses only" do
    in_production_resolving ["93.184.216.34", "2606:2800:220:1:248:1893:25c8:1946"] do
      assert build_webhook.valid?
    end
  end

  test "should raise and not POST when fired with a blocked url" do
    webhook = build_webhook(url: "http://127.0.0.1/hook")
    downloader = Minitest::Mock.new

    assert_raises Automation::Webhook::BlockedUrlError do
      webhook.fire! messages(:ssd_main_draft), :event, DateTime.now, downloader: downloader
    end

    assert_mock downloader
  end

  private

  def build_webhook(url: "https://example.com/hooks/123abc")
    Automation::Webhook.new(name: "Webhook", url: url, tenant: tenants(:ssd))
  end

  def in_production_resolving(addresses)
    Rails.stub(:env, ActiveSupport::EnvironmentInquirer.new("production")) do
      Resolv.stub(:getaddresses, addresses) do
        yield
      end
    end
  end
end
