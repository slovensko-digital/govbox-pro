module Fs::MessageHelper
  def self.build_html_visualization(message)
    return [ActionController::Base.new.render_to_string('fs/messages/_submission', layout: false, locals: { message: message }), build_html_visualization_from_form(message)].compact.join('<hr>') if message.outbox?

    # TODO: Vieme aj lepsie identifikovat? Nejake dalsie typy v tejto kategorii neexistuju?
    template = if message.title.in?(['Informácia o podaní', 'Informácia o odmietnutí podania'])
                 'fs/messages/_delivery_report'
               else
                 'fs/messages/_generic_message'
               end

    ActionController::Base.new.render_to_string(template, layout: false, locals: { message: message })
  end

  def self.build_html_visualization_from_form(message)
    raise 'Missing Fs::Form XSLT' unless message.form&.xslt_txt
    return unless message.form_object&.unsigned_content

    template = Nokogiri::XSLT(message.form.xslt_html)
    transformed_html = template.transform(message.form_object.xml_unsigned_content).to_s

    forms_storage_url = ENV['FS_FORMS_STORAGE_API_URL']
    form_path = "#{message.form.slug}/1.0/Content"
    base_url = "#{forms_storage_url}/#{form_path}"

    doc = Nokogiri::HTML::DocumentFragment.parse(transformed_html)

    doc.css('script[src]').each do |script|
      src = script['src']
      if src && !src.start_with?('http') && !src.start_with?('//')
        clean_src = src.gsub(/^\.\.?\//, '')
        script['src'] = "#{base_url}/#{clean_src}"
      end
    end

    doc.css('link[rel="stylesheet"][href]').each do |link|
      href = link['href']
      if href && !href.start_with?('http') && !href.start_with?('//')
        clean_href = href.gsub(/^\.\.?\//, '')
        link['href'] = "#{base_url}/#{clean_href}"
      end
    end

    doc.css('img[src]').each do |img|
      src = img['src']
      if src && !src.start_with?('http') && !src.start_with?('data:') && !src.start_with?('//')
        clean_src = src.gsub(/^\.\.?\//, '')
        img['src'] = "#{base_url}/#{clean_src}"
      end
    end

    ActionController::Base.new.render_to_string('fs/messages/_style', layout: false, locals: { message: message }) + doc.to_html
  end
end
