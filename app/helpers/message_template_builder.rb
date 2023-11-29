class MessageTemplateBuilder < ActionView::Helpers::FormBuilder
  ALLOWED_TEMPLATE_FIELD_TYPES = %w[text_field email_field text_area date_field]

  def template_field(template_item, data: ,editable:, is_last: false)
    raise "Disallowed template field: #{template_item[:type]}" unless ALLOWED_TEMPLATE_FIELD_TYPES.include?(template_item[:type])

    send(template_item[:type], template_item[:name], value: data&.dig(template_item[:name]) || template_item[:default_value], editable: editable, is_last: is_last)
  end

  def text_field(name, value: , editable:, **args)
    super(name, {
      placeholder: name,
      value: value,
      disabled: !editable,
      'data-action': 'change->message-drafts#update',
      class: 'mb-3 px-3 py-4 placeholder-slate-300 text-slate-900 relative bg-white bg-white rounded-lg text-base border-0 shadow outline-none focus:outline-none focus:ring w-full'
    })
  end

  def email_field(name, value: , editable:, **args)
    super(name, {
      placeholder: name,
      value: value,
      disabled: !editable,
      'data-action': 'change->message-drafts#update',
      class: 'mb-3 px-3 py-4 placeholder-slate-300 text-slate-900 relative bg-white bg-white rounded-lg text-base border-0 shadow outline-none focus:outline-none focus:ring w-full'
    })
  end

  def text_area(name, value: , editable:, is_last:)
    super(name, {
      placeholder: name,
      value: value,
      disabled: !editable,
      autofocus: is_last,
      'data-action': 'change->message-drafts#update',
      rows: 10,
      class: 'px-3 py-4 placeholder-slate-300 text-slate-900 relative bg-white rounded-lg text-base border-0 shadow outline-none focus:outline-none focus:ring w-full h-full'
    })
  end

  def date_field(name, value: , editable:, **args)
    label(:label, name) +
    super(name, {
      placeholder: Date.today,
      value: value,
      disabled: !editable,
      'data-action': 'change->message-drafts#update',
      rows: 10,
      class: 'mb-3 px-3 py-4 placeholder-slate-300 text-slate-900 relative bg-white bg-white rounded-lg text-base border-0 shadow outline-none focus:outline-none focus:ring w-full'
    })
  end
end
