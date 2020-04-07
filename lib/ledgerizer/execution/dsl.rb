module Ledgerizer
  module Execution
    module Dsl
      extend ActiveSupport::Concern

      EXECUTE_ENTRY_METHOD_REG_EXP = /\A(execute)_([^\-]*)_(entry)\z/
      EXECUTE_ENTRY_METHOD_PARTS = 3

      included do
        include Ledgerizer::DslBase

        def method_missing(method_name, *arguments, &block)
          entry_code = entry_code_from_method(method_name)
          return execute_entry(entry_code, *arguments, &block) if entry_code

          super
        end

        def respond_to_missing?(method_name, include_private = false)
          entry_code_from_method(method_name) || super
        end

        def execute_entry(entry_code, tenant:, document:, date:, &block)
          in_context(:execute_entry) do
            @executor = Ledgerizer::EntryExecutor.new(
              config: definition,
              tenant: tenant,
              document: document,
              entry_code: entry_code,
              entry_date: date
            )

            instance_eval(&block) if block
            @executor.execute
          end
          nil
        ensure
          @executor = nil
        end

        def debit(account:, amount:, accountable: nil)
          in_context do
            @executor.add_new_movement(
              movement_type: :debit,
              account_name: account,
              accountable: accountable,
              amount: amount
            )
          end
        end

        def credit(account:, amount:, accountable: nil)
          in_context do
            @executor.add_new_movement(
              movement_type: :credit,
              account_name: account,
              accountable: accountable,
              amount: amount
            )
          end
        end

        def entry_code_from_method(method_name)
          method_parts = method_name.to_s.match(EXECUTE_ENTRY_METHOD_REG_EXP)&.captures || []
          return if method_parts.count != EXECUTE_ENTRY_METHOD_PARTS
          return if method_parts.first != 'execute' || method_parts.last != 'entry'

          method_parts[1].to_sym
        end

        def definition
          Ledgerizer.definition
        end

        def ctx_dependencies_map
          {
            execute_entry: [],
            debit: [:execute_entry],
            credit: [:execute_entry]
          }
        end
      end
    end
  end
end
