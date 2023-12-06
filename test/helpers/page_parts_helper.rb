module PagePartsHelper
  def within_sidebar
    within("[data-test='sidebar']") do
      yield
    end
  end

  def within_filters
    within("[data-test='filters']") do
      yield
    end
  end

  def within_thread_in_listing(thread)
    within(thread_in_listing_selector(thread)) do
      yield
    end
  end

  def thread_in_listing_selector(thread)
    "[data-test=\"message_thread_#{thread.id}\"]"
  end

  def within_tags
    within("[data-test='tags']") do
      yield
    end
  end

  def within_message_in_thread(message)
    within("\##{dom_id(message)}") do
      yield
    end
  end
end
