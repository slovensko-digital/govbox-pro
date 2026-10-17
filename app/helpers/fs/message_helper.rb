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

  def self.humanize_diff(diff_text)
    changes = diff_hunks(diff_text).flat_map do |hunk|
      field_changes(diff_lines(hunk, "< "), diff_lines(hunk, "> "))
    end
    changes.any? ? changes : ["Niektoré údaje sa zmenili, pred odoslaním ich skontrolujte vo formulári."]
  end

  def self.diff_hunks(diff_text)
    diff_text.to_s.split(/^(?=\d+(?:,\d+)?[acd]\d+(?:,\d+)?$)/)
  end

  def self.diff_lines(diff_text, prefix)
    diff_text.to_s.split("\n").select { |line| line.start_with?(prefix) }.map { |line| line[prefix.length..].strip }
  end

  def self.field_changes(removed, added)
    removed.zip(added).filter_map do |old_line, new_line|
      old_field = leaf_element(old_line)
      new_field = leaf_element(new_line)
      next unless old_field && new_field
      next unless old_field[:name] == new_field[:name] && old_field[:value] != new_field[:value]

      "#{field_label(old_field[:name])}: pôvodne #{old_field[:value]} → opravené #{new_field[:value]}"
    end
  end

  def self.leaf_element(line)
    match = line&.match(%r{\A<(?:[\w.-]+:)?([\w.-]+)(?:\s[^>]*)?>([^<]*)</[^>]+>\z})
    return unless match

    { name: match[1], value: match[2].strip }
  end

  def self.field_label(name)
    {
      "ico" => "IČO",
      "dic" => "DIČ",
      "icdph" => "IČ DPH",
      "icDph" => "IČ DPH",
      "rodneCislo" => "Rodné číslo",
      "meno" => "Meno",
      "priezvisko" => "Priezvisko",
      "obchMeno" => "Obchodné meno",
      "ulica" => "Ulica",
      "obec" => "Obec",
      "psc" => "PSČ",
      "stat" => "Štát"
    }.fetch(name, name)
  end
end
