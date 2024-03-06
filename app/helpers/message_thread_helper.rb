module MessageThreadHelper
  def filtered_message_threads_path(filter: nil, query: nil)
    args = {
      filter_id: filter&.id,
      q: query
    }.compact

    message_threads_path(args)
  end
end
