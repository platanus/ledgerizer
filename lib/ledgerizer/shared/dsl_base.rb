module Ledgerizer
  module DslBase
    include Ledgerizer::Errors

    def in_context(current_method = nil)
      current_method ||= caller_locations(1, 1)[0].label.to_sym
      validate_context!(current_method)
      current_context << current_method
      yield
      current_context.pop
    end

    def validate_context!(current_method)
      dependencies = ctx_dependencies_map[current_method]

      if current_context != dependencies
        if dependencies.any?
          raise_dsl_definition_error(
            "'#{current_method}' needs to run inside '#{dependencies.last}' block"
          )
        else
          raise_dsl_definition_error(
            "'#{current_method}' can't run inside '#{current_context.last}' block"
          )
        end
      end
    end

    def ctx_dependencies_map
      raise "Not implemented ctx_dependencies_map"
    end

    def current_context
      @current_context ||= []
    end
  end
end
