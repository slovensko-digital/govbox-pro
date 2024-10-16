module Fs::MessageHelper
  def self.build_html_visualization(message)
    return message.html_visualization if message.html_visualization.present?

    return unless message.form&.xslt_txt
    return unless message.form_object&.unsigned_content

    template = Nokogiri::XSLT(message.form.xslt_txt)
    ActionController::Base.helpers.simple_format(template.transform(message.form_object.xml_unsigned_content).to_s)
  end
end
