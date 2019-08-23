shared_examples 'definition dsl account' do |account_type|
  describe "##{account_type}" do
    it "raises error with no tenant" do
      expect_error_in_class_definition("'#{account_type}' needs to run inside 'tenant' block") do
        include Ledgerizer::Definition::Dsl

        send(account_type, :account1)
      end
    end

    it "raises error with repeated accounts" do
      expect_error_in_class_definition("the account1 account already exists in tenant") do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          send(account_type, :account1)
          send(account_type, :account1)
        end
      end
    end

    context "with valid account" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          send(account_type, :account1)
        end
      end

      it { expect(LedgerizerTest).to have_tenant_account(Portfolio, :account1, account_type) }
    end

    context "with more than one account" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          send(account_type, :account1)
          send(account_type, :account2)
        end
      end

      it { expect(LedgerizerTest).to have_tenant_account(Portfolio, :account1, account_type) }
      it { expect(LedgerizerTest).to have_tenant_account(Portfolio, :account2, account_type) }
    end
  end
end
