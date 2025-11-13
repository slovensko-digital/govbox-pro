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
    return unless message.form_object&.unsigned_content

    xslt = message.form&.xslt_html || message.form&.xslt_txt
    raise 'Missing Fs::Form XSLT (HTML and TXT both unavailable)' unless xslt

    template = Nokogiri::XSLT(xslt)
    transformed_content = template.transform(message.form_object.xml_unsigned_content).to_s

    if xslt == message.form&.xslt_txt
      transformed_content = ActionController::Base.helpers.simple_format(transformed_content)
    else
      forms_storage_url = ENV['FS_FORMS_STORAGE_API_URL']
      form_path = "#{message.form.slug}/1.0/Content"
      base_url = "#{forms_storage_url}/#{form_path}"

      doc = Nokogiri::HTML::DocumentFragment.parse(transformed_content)

      {
        'script[src]' => 'src',
        'link[rel="stylesheet"][href]' => 'href',
        'img[src]' => 'src'
      }.each do |selector, attr|
        doc.css(selector).each do |el|
          url = el[attr]
          next unless url
          next if url.start_with?('http', '//', 'data:')

          normalized_path = url.gsub(%r{^\.\.?/}, '')
          el[attr] = "#{base_url}/#{normalized_path}"
        end
      end

      transformed_content = doc.to_html.html_safe
    end

    ActionController::Base.new.render_to_string('fs/messages/_style', layout: false, locals: { message: message }) + transformed_content
  end
end
