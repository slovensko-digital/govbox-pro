class MessageDraftBodyComponent < ViewComponent::Base
  FIELD_LABELS = {
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
  }.freeze

  GENERIC_DIFF_DESCRIPTION = "Finančná správa upravila obsah správy, pred odoslaním skontrolujte údaje vo formulári."

  def initialize(message:, is_last:)
    @message = message
    @is_last = is_last
  end

  def humanize_diff(diff_text)
    removed = diff_lines(diff_text, "< ")
    added = diff_lines(diff_text, "> ")

    changes = field_changes(removed, added)
    changes.any? ? changes : [GENERIC_DIFF_DESCRIPTION]
  end

  private

  def diff_lines(diff_text, prefix)
    diff_text.to_s.split("\n").select { |line| line.start_with?(prefix) }.map { |line| line[prefix.length..].strip }
  end

  def field_changes(removed, added)
    removed.zip(added).filter_map do |old_line, new_line|
      old_field = leaf_element(old_line)
      new_field = leaf_element(new_line)
      next unless old_field && new_field
      next unless old_field[:name] == new_field[:name] && old_field[:value] != new_field[:value]

      "#{field_label(old_field[:name])}: #{old_field[:value]} → #{new_field[:value]}"
    end
  end

  def leaf_element(line)
    match = line&.match(%r{\A<(?:[\w.-]+:)?([\w.-]+)(?:\s[^>]*)?>([^<]*)</[^>]+>\z})
    return unless match

    { name: match[1], value: match[2].strip }
  end

  def field_label(name)
    FIELD_LABELS.fetch(name, name)
  end
end
