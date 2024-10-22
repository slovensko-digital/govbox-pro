module Fs::MessageHelper
  def self.build_html_visualization(message)
    return [ActionController::Base.new.render_to_string('fs/_html_visualization_submission', layout: false, locals: { message: message }), build_html_visualization_from_form(message)].compact.join('<hr>') if message.outbox?

    if message.title.in?(['Informácia o podaní', 'Informácia o odmietnutí podania'])
      ActionController::Base.new.render_to_string('fs/_html_visualization_delivery_report', layout: false, locals: { message: message })
    else
      ActionController::Base.new.render_to_string('fs/_html_visualization_generic', layout: false, locals: { message: message })
    end
  end

  def self.build_html_visualization_from_form(message)
    return unless message.form&.xslt_txt
    return unless message.form_object&.unsigned_content

    template = Nokogiri::XSLT(message.form.xslt_txt)
    ActionController::Base.helpers.simple_format(template.transform(message.form_object.xml_unsigned_content).to_s)
  end
end
