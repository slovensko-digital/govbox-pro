module Common
  class BlankResultsComponent < ViewComponent::Base
    def initialize(reason = :not_found)
      case reason
      when :empty
        @text1 = "Žiadne záznamy"
        @text2 = "Zatiaľ nie sú vytvorené žiadne záznamy"
        @icon = "hand-thumb-up"
      when :not_found
        @text1 = "Žiadne výsledky"
        @text2 = "Skúste zmeniť filter alebo vyhľadávané slová"
        @icon = "magnifying-glass"
      when :all_done
        @text1 = "Všetko je hotové"
        @text2 = "Nemáte žiadnu novú správu"
        @icon = "hand-thumb-up"
      end
    end
  end
end
