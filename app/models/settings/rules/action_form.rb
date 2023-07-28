module Settings
  module Rules
    class ActionForm
      include ActiveModel::Model
      include ActiveModel::Serializers::JSON

      attr_accessor :id, :type, :attr, :value, :rule_form

      validates_presence_of :id, message: 'Zadajte', on: :id
      validates_presence_of :type, message: 'Zadajte', on: :type
      validates_presence_of :attr, message: 'Zadajte', on: :attr
      validates_presence_of :value, message: 'Zadajte', on: :value
      def attributes=(hash)
        hash.each { |key, value| send("#{key}=", value) }
      end

      def persisted?
        @id ? true: false
      end

      def attributes
        { id: nil, attr: nil, type: nil, value: nil, rule_form: nil }
      end
    end
  end
end
