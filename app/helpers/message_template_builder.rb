class MessageTemplateBuilder < ActionView::Helpers::FormBuilder
  ALLOWED_TEMPLATE_FIELD_TYPES = %w[text_field email_field text_area date_field]

  DEFAULT_CLASSES = 'bg-white border-0 text-base focus:ring'
  ERROR_CLASSES = 'bg-red-50 border border-red-500 text-red-900 placeholder-red-700 focus:ring-red-500 focus:border-red-500'

  def template_field(template_item, data:, errors: nil, editable:, is_last: false)
    raise "Disallowed template field: #{template_item[:type]}" unless ALLOWED_TEMPLATE_FIELD_TYPES.include?(template_item[:type])

    send(
      template_item[:type],
      template_item[:name],
      value: data&.dig(template_item[:name]).presence || template_item[:default_value],
      errors: errors,
      editable: editable,
      is_last: is_last
    )
  end

  def text_field(name, value:, errors:, editable:, **args)
    @template.content_tag(:div, class: 'mb-3') do
      label(:label, name, class: 'font-semibold') +
      super(name, {
        value: value,
        disabled: !editable,
        'data-action': 'change->message-drafts#update',
        class: "#{errors[name].present? ? ERROR_CLASSES : DEFAULT_CLASSES} px-3 py-4 placeholder-slate-300 text-slate-900 relative rounded-lg shadow outline-none focus:outline-none w-full"
      }) +
      (
        @template.content_tag(:p, nil, class: 'mt-2 text-sm text-red-600 dark:text-red-500') do
          @template.content_tag(:span, errors[name], class: 'font-medium')
        end if errors.present?
      )
    end
  end

  def email_field(name, value:, errors:, editable:, **args)
    @template.content_tag(:div, class: 'mb-3') do
      label(:label, name, class: 'font-semibold') +
      super(name, {
        value: value,
        disabled: !editable,
        'data-action': 'change->message-drafts#update',
        class: "#{errors[name].present? ? ERROR_CLASSES : DEFAULT_CLASSES} px-3 py-4 placeholder-slate-300 text-slate-900 relative bg-white rounded-lg text-base border-0 shadow outline-none focus:outline-none focus:ring w-full"
      }) +
      (
        @template.content_tag(:p, nil, class: 'mt-2 text-sm text-red-600 dark:text-red-500') do
          @template.content_tag(:span, errors[name], class: 'font-medium')
        end if errors.present?
      )
    end
  end

  def text_area(name, value:, errors:, editable:, is_last:)
    @template.content_tag(:div, class: 'mb-3') do
      label(:label, name, class: 'font-semibold') +
      super(name, {
        value: value,
        disabled: !editable,
        autofocus: is_last,
        'data-action': 'change->message-drafts#update',
        rows: 10,
        class: "#{errors[name].present? ? ERROR_CLASSES : DEFAULT_CLASSES} px-3 py-4 placeholder-slate-300 text-slate-900 relative bg-white rounded-lg text-base border-0 shadow outline-none focus:outline-none focus:ring w-full h-full"
      }) +
      (
        @template.content_tag(:p, nil, class: 'mt-2 text-sm text-red-600 dark:text-red-500') do
          @template.content_tag(:span, errors[name], class: 'font-medium')
        end if errors.present?
      )
    end
  end

  def date_field(name, value:, errors:, editable:, **args)
    @template.content_tag(:div, class: 'mb-3') do
      label(:label, name, class: 'font-semibold') +
      super(name, {
        value: value,
        disabled: !editable,
        'data-action': 'change->message-drafts#update',
        rows: 10,
        class: "#{errors[name].present? ? ERROR_CLASSES : DEFAULT_CLASSES} px-3 py-4 placeholder-slate-300 text-slate-900 relative bg-white rounded-lg text-base border-0 shadow outline-none focus:outline-none focus:ring w-full"
      }) +
      (
        @template.content_tag(:p, nil, class: 'mt-2 text-sm text-red-600 dark:text-red-500') do
          @template.content_tag(:span, errors[name], class: 'font-medium')
        end if errors.present?
      )
    end
  end
end