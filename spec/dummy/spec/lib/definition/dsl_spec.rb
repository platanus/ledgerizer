require "spec_helper"

# rubocop:disable RSpec/FilePath, RSpec/DescribedClass
RSpec.describe Ledgerizer::Definition::Dsl do
  describe '#tenant' do
    context "with valid Active Record tenant" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant(:portfolio)
      end

      it { expect(LedgerizerTest).to have_tenant(Portfolio) }
      it { expect(LedgerizerTest).to have_tenant_base_currency(Portfolio, :usd) }
    end

    context "with different currency" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio', currency: :clp)
      end

      it { expect(LedgerizerTest).to have_tenant_base_currency(Portfolio, :clp) }
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
      expect_error_in_class_definition("name must be an ActiveRecord model name") do
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

  it_behaves_like 'definition dsl account', :asset
  it_behaves_like 'definition dsl account', :liability
  it_behaves_like 'definition dsl account', :expense
  it_behaves_like 'definition dsl account', :income
  it_behaves_like 'definition dsl account', :equity
end
# rubocop:enable RSpec/FilePath, RSpec/DescribedClass
