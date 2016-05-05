module Mimi
  module Messaging
    class Model < Mimi::Messaging::Message
      def self.default_queue_name
        Mimi::Messaging::RequestProcessor.class_name_to_resource_name(self, 'model')
      end

      methods :create, :update, :show, :destroy, :list

      def update(params = {})
        self.replace(self.class.update(params.merge(id: id)))
      end

      def save
        update(self)
      end

      def self.find(id)
        show(id: id)
      end

      def self.all
        list.list
      end
    end
  end # module Messaging
end # module Mimi
