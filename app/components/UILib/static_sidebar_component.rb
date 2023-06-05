class UILib::StaticSidebarComponent < ViewComponent::Base
    # TODO Toto nie je pekne, volat logiku do kniznicneho komponentu, prerobit
    def initialize(folders:)
        @folders = folders
    end
end
