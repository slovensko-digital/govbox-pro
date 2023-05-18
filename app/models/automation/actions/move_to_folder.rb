module Automation
  module Actions
    class MoveToFolder
      def initialize(folder)
        @folder = folder
      end

      def run!(thing)
        thing.folder = @folder # TODO security
        thing.save!
      end
    end
  end
end
