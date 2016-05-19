module Mimi
  module Messaging
    class ModelProvider < Mimi::Messaging::Provider
      abstract!

      def self.model(model_class, options = {})
        raise "#{self} already serves model #{@model_class}" if @model_class
        @model_class = model_class
        @model_options = options
        @model_methods_only = options[:only] ? [*(options[:only])] : nil
        @model_methods_except = options[:except] ? [*(options[:except])] : nil
      end

      def self.exposed_methods
        model_methods = Mimi::Messaging::ModelProvider.public_instance_methods(false).dup
        methods_hidden = []
        methods_hidden = model_methods - model_methods.only(*@model_methods_only) if @model_methods_only
        methods_hidden = model_methods.only(*@model_methods_except) if @model_methods_except
        m = super
        m - methods_hidden
      end

      def self.model_class
        @model_class || raise("#{self} has no defined model")
      end

      def self.serialize(method_name = nil, &block)
        if method_name && block_given?
          raise "Only one of method_name or block is accepted by #{self}.serialize"
        end
        @serialize = method_name.to_sym if method_name
        @serialize = block if block_given?
        @serialize || parent_property(:serialize) || :as_json
      end

      def self.scope(&block)
        @scope = block if block_given?
        @scope || -> (r) { r }
      end

      def self.permitted_params(*names)
        @permitted_params = names.map(&:to_sym) if names.size > 0
        @permitted_params || model_class.attribute_names.map(&:to_sym)
      end

      def create
        serialize model_class_scoped.create!(permitted_params)
      end

      def update(id:)
        model = model_class_scoped.find(id)
        model.update!(permitted_params)
        serialize model
      end

      def show(id:)
        serialize model_class_scoped.find(id)
      end

      def find
        serialize model_class_scoped.find_by!(params)
      end

      def destroy(id:)
        model_class_scoped.find(id)
        raise "#{self.class}#destroy is not implemented"
      end

      def list
        reply list: model_class_scoped.all.map { |v| serialize v }
      end

      private

      def permitted_params
        params.except('id').only(*self.class.permitted_params.map(&:to_s)).to_hash
      end

      def model_class
        self.class.model_class
      end

      def model_class_scoped
        scope_block = self.class.scope
        __execute(model_class, &scope_block)
      end

      def serialize(model_instance, opts = nil)
        opts ||= params
        if self.class.serialize.is_a?(Symbol)
          model_instance.send(self.class.serialize, opts)
        elsif self.class.serialize.is_a?(Proc)
          self.class.serialize.call(model_instance, opts)
        else
          raise "#{self.class}#serialize is neither a Symbol or Proc"
        end
      end
    end # class ModelProvider
  end # module Messaging
end # module Mimi
