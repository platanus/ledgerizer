require "spec_helper"

# rubocop:disable RSpec/FilePath, RSpec/DescribedClass
RSpec.describe Ledgerizer::Definition::Dsl do
  describe '#tenant' do
    context "with valid Active Record tenant" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio')
      end

      it { expect(LedgerizerTest).to have_tenant(Portfolio) }
    end

    context "with symbol name" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant(:portfolio)
      end

      it { expect(LedgerizerTest).to have_tenant(Portfolio) }
    end

    context "with camel name" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant("Portfolio")
      end

      it { expect(LedgerizerTest).to have_tenant(Portfolio) }
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
      expect_error_in_class_definition("tenant name must be an ActiveRecord model name") do
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

  describe "#accounts" do
    it "raises error with no tenant" do
      expect_error_in_class_definition("'accounts' needs to run inside 'tenant' block") do
        include Ledgerizer::Definition::Dsl

        accounts
      end
    end

    context "with default currency" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          accounts do
          end
        end
      end

      it { expect(LedgerizerTest).to have_tenant_base_currency(Portfolio, :usd) }
    end

    context "with different valid currency" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          accounts(currency: 'clp') do
          end
        end
      end

      it { expect(LedgerizerTest).to have_tenant_base_currency(Portfolio, :clp) }
    end

    it "raises invalid currency" do
      expect_error_in_class_definition("invalid currency 'petro-del-mal' given") do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          accounts(currency: 'petro-del-mal') do
          end
        end
      end
    end
  end

  it_behaves_like 'definition dsl account', :asset
  it_behaves_like 'definition dsl account', :liability
  it_behaves_like 'definition dsl account', :expense
  it_behaves_like 'definition dsl account', :income
  it_behaves_like 'definition dsl account', :equity
end
# rubocop:enable RSpec/FilePath, RSpec/DescribedClass
