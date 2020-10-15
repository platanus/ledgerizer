require "spec_helper"

describe Ledgerizer::Definition::Dsl do
  describe '#tenant' do
    context "with valid Active Record tenant" do
      let_definition_class do
        tenant(:portfolio)
      end

      it { expect(LedgerizerTestDefinition).to have_ledger_tenant_definition(:portfolio) }
      it { expect(LedgerizerTestDefinition).to have_ledger_tenant_currency(:portfolio, :clp) }
    end

    context "with different currency" do
      let_definition_class do
        tenant('portfolio', currency: :usd)
      end

      it { expect(LedgerizerTestDefinition).to have_ledger_tenant_currency(:portfolio, :usd) }
    end

    it "raises DSL error with nested tenants" do
      expect_error_in_definition_class("'tenant' can't run inside 'tenant' block") do
        tenant('portfolio') do
          tenant('portfolio')
        end
      end
    end

    it "raises DSL error with non Active Record tenant" do
      expect_error_in_definition_class(/tenant name must be a snake_case/) do
        tenant('noartenant')
      end
    end

    it "raises error with repeated tenant" do
      expect_error_in_definition_class("the tenant already exists") do
        tenant('portfolio')
        tenant('portfolio')
      end
    end
  end

  describe "#entry" do
    it "raises error with no tenant" do
      expect_error_in_definition_class("'entry' needs to run inside 'tenant' block") do
        entry(:deposit)
      end
    end

    it "raises error with repeated entries" do
      expect_error_in_definition_class("the deposit entry already exists in tenant") do
        tenant('portfolio') do
          entry(:deposit, document: 'deposit')
          entry(:deposit, document: 'deposit')
        end
      end
    end

    it "raises error with invalid document" do
      expect_error_in_definition_class(/entry's document must be a snake_case/) do
        tenant('portfolio') do
          entry(:deposit, document: 'invalid')
        end
      end
    end

    context "with valid entry" do
      let_definition_class do
        tenant('portfolio') do
          entry(:deposit, document: 'deposit')
        end
      end

      let(:expected) do
        {
          tenant_model_name: :portfolio,
          entry_code: :deposit,
          document: :deposit
        }
      end

      it { expect(LedgerizerTestDefinition).to have_ledger_entry_definition(expected) }
    end

    context "with more than one entry" do
      let_definition_class do
        tenant('portfolio') do
          entry(:deposit, document: 'deposit')
          entry(:distribute, document: 'withdrawal')
        end
      end

      let(:expected_deposit) do
        {
          tenant_model_name: :portfolio,
          entry_code: :deposit,
          document: :deposit
        }
      end

      let(:expected_distribute) do
        {
          tenant_model_name: :portfolio,
          entry_code: :distribute,
          document: :withdrawal
        }
      end

      it { expect(LedgerizerTestDefinition).to have_ledger_entry_definition(expected_deposit) }
      it { expect(LedgerizerTestDefinition).to have_ledger_entry_definition(expected_distribute) }
    end
  end

  describe "#revaluation" do
    it "raises error with no tenant" do
      expect_error_in_definition_class("'revaluation' needs to run inside 'tenant' block") do
        revaluation(:revaluation1)
      end
    end

    it "raises error with missing revaluation accounts" do
      expect_error_in_definition_class("missing revaluation accounts") do
        tenant('portfolio') do
          revaluation(:revaluation1)
        end
      end
    end

    it "raises error with undefined accounts" do
      expect_error_in_definition_class("undefined account1 account for revaluation1 revaluation") do
        tenant('portfolio') do
          revaluation(:revaluation1) do
            account(:account1, accountable: :deposit)
          end
        end
      end
    end

    it "raises error with defined account having tenant currency only" do
      error = "only accounts with a currency other than the tenant can be revalued. " +
        "account1 account currencies: usd. tenant currency: usd"
      expect_error_in_definition_class(error) do
        tenant('portfolio', currency: :usd) do
          asset(:account1, currencies: [:usd])

          revaluation(:revaluation1) do
            account(:account1, accountable: :user)
          end
        end
      end
    end

    context "with valid asset revaluation" do
      let_definition_class do
        tenant('portfolio') do
          asset(:account1, currencies: [:ars])

          revaluation(:revaluation1) do
            account(:account1, accountable: :user)
          end
        end
      end

      let(:expected_entry1) do
        {
          tenant_model_name: :portfolio,
          entry_code: :positive_revaluation1_asset_revaluation,
          document: :"ledgerizer/revaluation"
        }
      end

      let(:expected_mov1) do
        {
          tenant_class: :portfolio,
          entry_code: :positive_revaluation1_asset_revaluation,
          movement_type: :credit,
          account_name: :positive_revaluation1,
          account_currency: :clp,
          mirror_currency: :ars,
          accountable: nil
        }
      end

      let(:expected_mov2) do
        {
          tenant_class: :portfolio,
          entry_code: :positive_revaluation1_asset_revaluation,
          movement_type: :debit,
          account_name: :account1,
          account_currency: :clp,
          mirror_currency: :ars,
          accountable: :user
        }
      end

      let(:expected_entry2) do
        {
          tenant_model_name: :portfolio,
          entry_code: :negative_revaluation1_asset_revaluation,
          document: :"ledgerizer/revaluation"
        }
      end

      let(:expected_mov3) do
        {
          tenant_class: :portfolio,
          entry_code: :negative_revaluation1_asset_revaluation,
          movement_type: :debit,
          account_name: :negative_revaluation1,
          account_currency: :clp,
          mirror_currency: :ars,
          accountable: nil
        }
      end

      let(:expected_mov4) do
        {
          tenant_class: :portfolio,
          entry_code: :negative_revaluation1_asset_revaluation,
          movement_type: :credit,
          account_name: :account1,
          account_currency: :clp,
          mirror_currency: :ars,
          accountable: :user
        }
      end

      it { expect(LedgerizerTestDefinition).to have_ledger_entry_definition(expected_entry1) }
      it { expect(LedgerizerTestDefinition).to have_ledger_movement_definition(expected_mov1) }
      it { expect(LedgerizerTestDefinition).to have_ledger_movement_definition(expected_mov2) }
      it { expect(LedgerizerTestDefinition).to have_ledger_entry_definition(expected_entry2) }
      it { expect(LedgerizerTestDefinition).to have_ledger_movement_definition(expected_mov3) }
      it { expect(LedgerizerTestDefinition).to have_ledger_movement_definition(expected_mov4) }
    end
  end

  Ledgerizer::Definition::Account::TYPES.each do |account_type|
    it_behaves_like 'definition dsl account', account_type
  end

  it_behaves_like 'definition dsl movement', :debit
  it_behaves_like 'definition dsl movement', :credit
end
