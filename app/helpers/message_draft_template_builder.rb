class MessageDraftTemplateBuilder < ActionView::Helpers::FormBuilder
  def template_field(template_item, data: ,editable:, is_last: false)
    case template_item[:type]
    when 'text_field'
      text_field(template_item[:name], value: data&.dig(template_item[:name]), editable: editable)
    when 'text_area'
      text_area(template_item[:name], value: data&.dig(template_item[:name]), editable: editable, is_last: is_last)
    end
  end

  def text_field(name, value: , editable:)
    super(name, {
      placeholder: name,
      value: value,
      disabled: !editable,
      'data-action': 'change->messageDrafts#update',
      class: 'mb-3 px-3 py-4 placeholder-slate-300 text-slate-900 relative bg-white bg-white rounded-lg text-base border-0 shadow outline-none focus:outline-none focus:ring w-full'
    })
  end

  def text_area(name, value: , editable:, is_last:)
    super(name, {
      placeholder: name,
      value: value,
      disabled: !editable,
      autofocus: is_last,
      'data-action': 'change->messageDrafts#update',
      rows: 10,
      class: 'px-3 py-4 placeholder-slate-300 text-slate-900 relative bg-white bg-white rounded-lg text-base border-0 shadow outline-none focus:outline-none focus:ring w-full h-full'
    })
  end
end
