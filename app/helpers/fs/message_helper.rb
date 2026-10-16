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

    xslt = message.form&.xslt_txt

    raise 'Missing Fs::Form TXT XSLT' unless xslt

    template = Nokogiri::XSLT(xslt)
    transformed_content = template.transform(message.form_object.xml_unsigned_content).to_s
    transformed_content = ActionController::Base.helpers.simple_format(transformed_content)

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
