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
          entry(:deposit, document: 'portfolio')
        end
      end

      it { expect(LedgerizerTest).to have_tenant_entry(:portfolio, :deposit, :portfolio) }
    end

    context "with more than one entry" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          entry(:deposit, document: 'portfolio')
          entry(:distribute, document: 'portfolio')
        end
      end

      it { expect(LedgerizerTest).to have_tenant_entry(:portfolio, :deposit, :portfolio) }
      it { expect(LedgerizerTest).to have_tenant_entry(:portfolio, :distribute, :portfolio) }
    end
  end

  it_behaves_like 'definition dsl account', :asset
  it_behaves_like 'definition dsl account', :liability
  it_behaves_like 'definition dsl account', :expense
  it_behaves_like 'definition dsl account', :income
  it_behaves_like 'definition dsl account', :equity

  it_behaves_like 'definition dsl entry account', :debit
  it_behaves_like 'definition dsl entry account', :credit
end
