module Ledgerizer
  module Definition
    module Dsl
      extend ActiveSupport::Concern

      class_methods do
        def tenant(model_name, currency: nil, &block)
          in_context do
            @current_tenant = definition.add_tenant(model_name, currency)
            block&.call
          end
        ensure
          @current_tenant = nil
        end

        def asset(account_name)
          account(account_name, :asset)
        end

        def liability(account_name)
          account(account_name, :liability)
        end

        def income(account_name)
          account(account_name, :income)
        end

        def expense(account_name)
          account(account_name, :expense)
        end

        def equity(account_name)
          account(account_name, :equity)
        end

        def account(account_name, account_type)
          in_context(account_type) do
            @current_account = @current_tenant.add_account(account_name, account_type)
          end
        ensure
          @current_account = nil
        end

        def entry(entry_code, document: nil)
          in_context do
            @current_entry = @current_tenant.add_entry(entry_code, document)
          end
        ensure
          @current_entry = nil
        end

        def in_context(current_method = nil)
          current_method ||= caller_locations(1, 1)[0].label.to_sym
          validate_context!(current_method)
          current_context << current_method
          yield
        ensure
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
            entry: [:tenant]
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
