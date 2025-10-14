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

    customized_xslt = Fs::XsltCustomizer.apply_customizations(message.form.xslt_txt)

    template = Nokogiri::XSLT(customized_xslt)

    ActionController::Base.new.render_to_string('fs/messages/_style', layout: false, locals: { message: message }) + ActionController::Base.helpers.simple_format(template.transform(message.form_object.xml_unsigned_content).to_s)
  end
end
