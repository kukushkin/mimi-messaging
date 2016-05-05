module Mimi
  module Messaging
    class RequestProcessor
      module DSL
        attr_accessor :parent

        # Returns the property of the parent class
        #
        def parent_property(*args)
          return nil unless @parent
          return nil unless @parent.respond_to?(args.first)
          @parent.send(*args)
        end

        # Sets queue name and options
        #
        def queue(name, options = {})
          queue_name name
          queue_options options
          true
        end

        # Sets or gets queue name
        #
        def queue_name(name = nil)
          raise "#{self} has already registered '#{@queue_name}' as queue name" if name && @queue_name
          (@queue_name ||= name) || default_queue_name
        end

        # Default (inferred) queue name
        #
        def default_queue_name
          nil
        end

        # Sets or gets queue options
        #
        def queue_options(opts = {})
          @queue_options ||= {}
          @queue_options = @queue_options.merge(opts.dup)
          (parent_property(:queue_options) || {}).merge(@queue_options)
        end

        # Sets provider options
        #
        def options(opts = {})
          @options ||= {}
          @options = @options.merge(opts.dup)
          (parent_property(:options) || {}).merge(@options)
        end

        def exposed_methods
          m = public_instance_methods(false)
          m += parent.exposed_methods if parent
          m
        end

        # Explicitly registers this request processor as abstract
        #
        def abstract!
          @abstract = true
        end

        # Is this provider abstract or configured to process requests?
        #
        def abstract?
          @abstract
        end

        #
        #
        def before(*args, &block)
          register_filter(:before, args, block)
        end

        #
        #
        def around(*args, &block)
          register_filter(:around, args, block)
        end

        #
        #
        def after(*args, &block)
          register_filter(:after, args, block)
        end

        #
        #
        def error(*args, &block)
          register_filter(:error, args, block)
        end

        def register_filter(type, args, block)
          @filters ||= { before: [], around: [], after: [], error: [] }
          @filters[type] << { args: args, block: block }
        end

        def filters(type, parent_first = true)
          @filters ||= { before: [], around: [], after: [], error: [] }
          if parent_first
            (parent_property(:filters, type) || []) + @filters[type]
          else
            @filters[type] + (parent_property(:filters, type, false) || [])
          end
        end

        # Converts class name to a resource name (camelize with dots).
        #
        # @example
        #   "ModuleA::ClassB" #=> "module_a.class_b"
        #
        def class_name_to_resource_name(v, suffix = nil)
          v = v.to_s.gsub('::', '.').gsub(/([^\.])([A-Z])/, '\1_\2').downcase
          v = v.sub(/_?#{suffix}\z/, '') if suffix
          v
        end
      end # module DSL
    end # class RequestProcessor
  end # module Messaging
end # module Mimi
