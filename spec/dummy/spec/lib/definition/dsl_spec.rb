require "spec_helper"

RSpec.describe Ledgerizer::Definition::Dsl do
  describe '#tenant' do
    context "with valid Active Record tenant" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant(:portfolio)
      end

      it { expect(LedgerizerTest).to have_tenant(:portfolio) }
      it { expect(LedgerizerTest).to have_tenant_base_currency(:portfolio, :usd) }
    end

    context "with different currency" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio', currency: :clp)
      end

      it { expect(LedgerizerTest).to have_tenant_base_currency(:portfolio, :clp) }
    end

    it "raises DSL error with nested tenants" do
      expect_error_in_class_definition("'tenant' can't run inside 'tenant' block") do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          tenant('portfolio')
        end
      end
    end

    it "raises DSL error with non Active Record tenant" do
      expect_error_in_class_definition(/must be an ActiveRecord model name/) do
        include Ledgerizer::Definition::Dsl

        tenant('noartenant')
      end
    end

    it "raises error with repeated tenant" do
      expect_error_in_class_definition("the tenant already exists") do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio')
        tenant('portfolio')
      end
    end
  end

  describe "#entry" do
    it "raises error with no tenant" do
      expect_error_in_class_definition("'entry' needs to run inside 'tenant' block") do
        include Ledgerizer::Definition::Dsl

        entry(:deposit)
      end
    end

    it "raises error with repeated entries" do
      expect_error_in_class_definition("the deposit entry already exists in tenant") do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          entry(:deposit, document: 'portfolio')
          entry(:deposit, document: 'portfolio')
        end
      end
    end

    it "raises error with invalid document" do
      expect_error_in_class_definition(/must be an ActiveRecord model name/) do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          entry(:deposit, document: 'invalid')
        end
      end
    end

    context "with valid entry" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          entry(:deposit, document: 'user')
        end
      end

      let(:expected) do
        {
          tenant_model_name: :portfolio,
          entry_code: :deposit,
          document: :user
        }
      end

      it { expect(LedgerizerTest).to have_tenant_entry(expected) }
    end

    context "with more than one entry" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          entry(:deposit, document: 'user')
          entry(:distribute, document: 'portfolio')
        end
      end

      let(:expected_deposit) do
        {
          tenant_model_name: :portfolio,
          entry_code: :deposit,
          document: :user
        }
      end

      let(:expected_distribute) do
        {
          tenant_model_name: :portfolio,
          entry_code: :distribute,
          document: :portfolio
        }
      end

      it { expect(LedgerizerTest).to have_tenant_entry(expected_deposit) }
      it { expect(LedgerizerTest).to have_tenant_entry(expected_distribute) }
    end
  end

  Ledgerizer::Definition::Account::TYPES.each do |account_type|
    it_behaves_like 'definition dsl account', account_type
  end

  it_behaves_like 'definition dsl movement', :debit
  it_behaves_like 'definition dsl movement', :credit
end
