module Fs::MessageHelper
  RELATIVE_ASSET_URL = %r{(<(?:script|img)\b[^>]*?\ssrc="|<link\b[^>]*?\shref=")(?!http|//|data:)(?:\.\.?/)?}

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

    xslt = if !message.tenant.feature_enabled?(:fs_html_visualization) || message.form_object.unsigned_content.size > 250.kilobytes
             message.form&.xslt_txt
           else
             message.form&.xslt_html || message.form&.xslt_txt
           end

    raise 'Missing Fs::Form XSLT (HTML and TXT both unavailable)' unless xslt

    template = Nokogiri::XSLT(xslt)
    transformed_document = template.transform(message.form_object.xml_unsigned_content)

    if xslt == message.form&.xslt_txt
      transformed_content = ActionController::Base.helpers.simple_format(transformed_document.to_s)
    else
      forms_storage_url = ENV['FS_FORMS_STORAGE_API_URL']
      form_path = "#{message.form.slug}/1.0/Content"
      base_url = "#{forms_storage_url}/#{form_path}"

      transformed_content = transformed_document.to_html(encoding: 'UTF-8').gsub(RELATIVE_ASSET_URL) { "#{$1}#{base_url}/" }.html_safe
    end

    ActionController::Base.new.render_to_string('fs/messages/_style', layout: false, locals: { message: message }) + transformed_content
  end
end
