module ColorizedHelper
  def color_select_options
    [""] + Colorized.colors.map { |color| [color, { class: "bg-#{color}-100 text-#{color}-600" }] }
  end
end

# NOTE: Tailwind cannot detect dynamically composed class names. When changing
# colour utilities here, update the `@source inline(...)` safelist in
# app/assets/tailwind/application.css.
