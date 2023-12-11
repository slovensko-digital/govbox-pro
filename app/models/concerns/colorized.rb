module Colorized
  extend ActiveSupport::Concern

  included do
    enum(:color,
      {
        slate: 'slate',
        gray: 'gray',
        zinc: 'zinc',
        neutral: 'neutral',
        stone: 'stone',
        red: 'red',
        orange: 'orange',
        amber: 'amber',
        yellow: 'yellow',
        lime: 'lime',
        green: 'green',
        emerald: 'emerald',
        teal: 'teal',
        cyan: 'cyan',
        sky: 'sky',
        blue: 'blue',
        indigo: 'indigo',
        violet: 'violet',
        purple: 'purple',
        fuchsia: 'fuchsia',
        pink: 'pink',
        rose: 'rose'
      }) if self.columns.map(&:name).include?('color')
  end

  def self.colors
    [
      :slate,
      :gray,
      :zinc,
      :neutral,
      :stone,
      :red,
      :orange,
      :amber,
      :yellow,
      :lime,
      :green,
      :emerald,
      :teal,
      :cyan,
      :sky,
      :blue,
      :indigo,
      :violet,
      :purple,
      :fuchsia,
      :pink,
      :rose
    ]
  end
end

