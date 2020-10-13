module Ledgerizer
  module Execution
    module Dsl
      extend ActiveSupport::Concern

      EXECUTE_METHOD_REG_EXP = /\A(execute)_([^\-]*)_(entry|revaluation)\z/
      EXECUTE_METHOD_PARTS = 3
      EXECUTE_METHOD_ACTIONS = %i{entry revaluation}

      included do
        include Ledgerizer::DslBase

        def method_missing(method_name, *arguments, &block)
          dsl_action_config = get_dsl_action_config(method_name)

          case dsl_action_config[:action]
          when :entry
            execute_entry(dsl_action_config[:identifier], *arguments, &block)
          when :revaluation
            execute_revaluation(dsl_action_config[:identifier], *arguments, &block)
          else
            super
          end
        end

        def respond_to_missing?(method_name, include_private = false)
          get_dsl_action_config(method_name).blank? || super
        end

        def execute_entry(entry_code, tenant:, document:, datetime:, conversion_amount: nil, &block)
          in_context(:execute_entry) do
            executor_params = {
              config: definition, tenant: tenant,
              document: document, entry_code: entry_code, entry_time: datetime,
              conversion_amount: nil
            }

            create_entry(executor_params, &block)

            if conversion_amount
              executor_params[:conversion_amount] = conversion_amount
              create_entry(executor_params, &block)
            end
          end
          nil
        end

        def execute_revaluation(
          revaluation_name,
          tenant:, account_name:, accountable:, currency:, datetime:, conversion_amount:
        )
          in_context(:execute_revaluation) do
            executor_params = {
              config: definition, tenant: tenant,
              revaluation_name: revaluation_name, revaluation_time: datetime,
              account_name: account_name, accountable: accountable, currency: currency,
              conversion_amount: conversion_amount
            }

            Ledgerizer::RevaluationExecutor.new(executor_params).execute
          end
          nil
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

        def get_dsl_action_config(method_name)
          method_parts = method_name.to_s.match(EXECUTE_METHOD_REG_EXP)&.captures || []
          return {} if method_parts.count != EXECUTE_METHOD_PARTS

          first_part = method_parts[0].to_sym
          identifier = method_parts[1].to_sym
          action = method_parts[2].to_sym
          return {} if first_part != :execute || !EXECUTE_METHOD_ACTIONS.include?(action)

          { identifier: identifier, action: action }
        end

        def create_entry(executor_params, &block)
          @executor = Ledgerizer::EntryExecutor.new(executor_params)
          instance_eval(&block) if block
          @executor.execute
        ensure
          @executor = nil
        end

        def definition
          Ledgerizer.definition
        end

        def ctx_dependencies_map
          {
            execute_revaluation: [],
            execute_entry: [],
            debit: [:execute_entry],
            credit: [:execute_entry]
          }
        end
      end
    end
  end
end
