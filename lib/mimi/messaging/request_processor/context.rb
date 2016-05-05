module Mimi
  module Messaging
    class RequestProcessor
      module Context
        attr_reader :self_before_instance_eval

        private

        #
        # Binds passed block and block parameters to the context
        #
        # @return [Proc] bound block
        #
        def __bind(*args, &block)
          proc { __execute(*args, &block) }
        end

        # Executes block within context
        #
        def __execute(*args, &block)
          @self_before_instance_eval ||= []
          block_self = eval 'self', block.binding
          @self_before_instance_eval.push(block_self)
          instance_exec(*args, &block)
        ensure
          @self_before_instance_eval.pop
        end

        def method_missing(method, *args, &block)
          if @self_before_instance_eval
            @self_before_instance_eval.last.send method, *args, &block
          else
            super
          end
        end
      end # module Context
    end # class RequestProcessor
  end # module Messaging
end # module Mimi
