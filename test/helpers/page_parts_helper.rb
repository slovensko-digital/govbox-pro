module PagePartsHelper
  def within_sidebar
    assert_selector "[data-test='sidebar']"
    within("[data-test='sidebar']") do
      yield
    end
  end

  def within_filters
    assert_selector "[data-test='filters']"
    within("[data-test='filters']") do
      yield
    end
  end

  def within_thread_in_listing(thread)
    selector = thread_in_listing_selector(thread)
    assert_selector selector
    within(selector) do
      yield
    end
  end

  def thread_in_listing_selector(thread)
    "[data-test=\"message_thread_#{thread.id}\"]"
  end

  def within_tags
    assert_selector "[data-test='tags']"
    within("[data-test='tags']") do
      yield
    end
  end

  def within_message_in_thread(message)
    selector = "\##{dom_id(message)}"
    assert_selector selector
    within(selector) do
      yield
    end
  end
end
