module Ledgerizer
  module Definition
    module Dsl
      extend ActiveSupport::Concern

      class_methods do
        include Ledgerizer::DslBase
        include Ledgerizer::Formatters

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
          define_method(account_type) do |account_name, currencies: [], contra: false|
            add_accounts(account_name, account_type, currencies.dup, contra)
          end
        end

        def add_accounts(account_name, account_type, currencies, contra)
          in_context(account_type) do
            available_currencies(currencies).each do |currency|
              add_account(account_name, account_type, currency, contra)
            end
          end
        end

        def add_account(account_name, account_type, currency, contra)
          @current_tenant.add_account(
            name: account_name,
            type: account_type,
            contra: contra,
            account_currency: currency
          )
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

        def debit(account:, accountable: nil)
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

        def revaluation(revaluation_name, &block)
          in_context do
            @current_revaluation = @current_tenant.add_revaluation(name: revaluation_name)
            block&.call
            @current_tenant.create_revaluation_entries(revaluation_name: revaluation_name)
          end
        ensure
          @current_revaluation = nil
        end

        def account(account_name, accountable: nil)
          in_context do
            @current_revaluation.add_account(
              account_name: account_name,
              accountable: accountable
            )
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
            revaluation: [:tenant],
            debit: [:tenant, :entry],
            credit: [:tenant, :entry],
            account: [:tenant, :revaluation]
          }
        end

        def available_currencies(currencies)
          currencies ||= []
          currencies << @current_tenant.currency

          currencies.map do |currency|
            format_currency(currency.to_s, strategy: :symbol)
          end.uniq
        end

        def definition
          @definition ||= Ledgerizer::Definition::Config.new
        end
      end
    end
  end
end
