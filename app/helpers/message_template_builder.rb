class MessageTemplateBuilder < ActionView::Helpers::FormBuilder
  ALLOWED_TEMPLATE_FIELD_TYPES = %w[text_field email_field text_area date_field]

  DEFAULT_CLASSES = 'basis-1/2 rounded-md shadow-sm ring-0 ring-inset ring-gray-400 focus-within:ring-1 focus-within:ring-inset focus-within:ring-blue-500 sm:max-w-md text-gray-900 placeholder:text-gray-400 sm:text-sm sm:leading-6'
  DEFAULT_CONTENT_TAG_CLASSES = 'flex flex-col text-left gap-2 mb-3'
  DEFAULT_LABEL_CLASSES = 'block text-base font-medium leading-6 text-gray-900'
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
    @template.content_tag(:div, class: DEFAULT_CONTENT_TAG_CLASSES) do
      label(:label, name, class: DEFAULT_LABEL_CLASSES) +
      super(name, {
        value: value,
        disabled: !editable,
        'data-action': 'change->message-drafts#update',
        class: "#{errors[name].present? ? ERROR_CLASSES : DEFAULT_CLASSES}"
      }) +
      (
        @template.content_tag(:p, nil, class: 'mt-2 text-sm text-red-600 dark:text-red-500') do
          @template.content_tag(:span, errors[name], class: 'font-medium')
        end if errors.present?
      )
    end
  end

  def email_field(name, value:, errors:, editable:, **args)
    @template.content_tag(:div, class: DEFAULT_CONTENT_TAG_CLASSES) do
      label(:label, name, class: DEFAULT_LABEL_CLASSES) +
      super(name, {
        value: value,
        disabled: !editable,
        'data-action': 'change->message-drafts#update',
        class: "#{errors[name].present? ? ERROR_CLASSES : DEFAULT_CLASSES}"
      }) +
      (
        @template.content_tag(:p, nil, class: 'mt-2 text-sm text-red-600 dark:text-red-500') do
          @template.content_tag(:span, errors[name], class: 'font-medium')
        end if errors.present?
      )
    end
  end

  def text_area(name, value:, errors:, editable:, is_last:)
    @template.content_tag(:div, class: DEFAULT_CONTENT_TAG_CLASSES) do
      label(:label, name, class: DEFAULT_LABEL_CLASSES) +
      super(name, {
        value: value,
        disabled: !editable,
        autofocus: is_last,
        'data-action': 'change->message-drafts#update',
        rows: 10,
        class: "#{errors[name].present? ? ERROR_CLASSES : ""} block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-400 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-blue-500 sm:text-sm sm:leading-6"
      }) +
      (
        @template.content_tag(:p, nil, class: 'mt-2 text-sm text-red-600 dark:text-red-500') do
          @template.content_tag(:span, errors[name], class: 'font-medium')
        end if errors.present?
      )
    end
  end

  def date_field(name, value:, errors:, editable:, **args)
    @template.content_tag(:div, class: DEFAULT_CONTENT_TAG_CLASSES) do
      label(:label, name, class: DEFAULT_LABEL_CLASSES) +
      super(name, {
        value: value,
        disabled: !editable,
        'data-action': 'change->message-drafts#update',
        rows: 10,
        class: "#{errors[name].present? ? ERROR_CLASSES : DEFAULT_CLASSES}"
      }) +
      (
        @template.content_tag(:p, nil, class: 'mt-2 text-sm text-red-600 dark:text-red-500') do
          @template.content_tag(:span, errors[name], class: 'font-medium')
        end if errors.present?
      )
    end
  end
end
