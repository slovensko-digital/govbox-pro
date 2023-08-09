module Settings
  module Rules
    class RuleForm
      include ActiveModel::Model
      include ActiveModel::Serializers::JSON

      attr_accessor :id, :name, :trigger_event, :condition_forms, :action_forms

      validates_presence_of :name, message: 'Zadajte', on: :name
      validates_presence_of :trigger_event, message: 'Zadajte', on: :trigger_event
      def attributes=(hash)
        hash.each { |key, value| send("#{key}=", value) }
      end

      def initialize(attributes = {})
        super
        @condition_forms ||= []
        @action_forms ||= []
      end

      def persisted?
        @id ? true : false
      end

      def attributes
        { id: nil, name: nil, trigger_event: nil, condition_forms: nil, action_forms: nil }
      end
    end
  end
end
