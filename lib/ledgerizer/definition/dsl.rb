module Ledgerizer
  module Definition
    module Dsl
      extend ActiveSupport::Concern

      class_methods do
        def tenant(model_name, currency: nil, &block)
          in_context do
            @current_tenant = definition.add_tenant(
              model_name: model_name,
              currency: currency
            )
            block&.call
          end
        ensure
          @current_tenant = nil
        end

        Ledgerizer::Definition::Account::TYPES.each do |account_type|
          define_method(account_type) do |account_name, contra: false|
            account(account_name, account_type, contra)
          end
        end

        def account(account_name, account_type, contra)
          in_context(account_type) do
            @current_account = @current_tenant.add_account(
              name: account_name,
              type: account_type,
              contra: contra
            )
          end
        ensure
          @current_account = nil
        end

        def entry(entry_code, document: nil, &block)
          in_context do
            @current_entry = @current_tenant.add_entry(
              code: entry_code,
              document: document
            )
            block&.call
          end
        ensure
          @current_entry = nil
        end

        def debit(account:, accountable:)
          in_context do
            @current_tenant.add_movement(
              movement_type: :debit,
              entry_code: @current_entry.code,
              account_name: account,
              accountable: accountable
            )
          end
        end

        def credit(account: nil, accountable: nil)
          in_context do
            @current_tenant.add_movement(
              movement_type: :credit,
              entry_code: @current_entry.code,
              account_name: account,
              accountable: accountable
            )
          end
        end

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
              raise_error("'#{current_method}' needs to run inside '#{dependencies.last}' block")
            else
              raise_error("'#{current_method}' can't run inside '#{current_context.last}' block")
            end
          end
        end

        def ctx_dependencies_map
          {
            tenant: [],
            asset: [:tenant],
            liability: [:tenant],
            income: [:tenant],
            expense: [:tenant],
            equity: [:tenant],
            entry: [:tenant],
            debit: [:tenant, :entry],
            credit: [:tenant, :entry]
          }
        end

        def current_context
          @current_context ||= []
        end

        def raise_error(msg)
          raise Ledgerizer::DslError.new(msg)
        end

        def definition
          @definition ||= Ledgerizer::Definition::Config.new
        end
      end
    end
  end
end
