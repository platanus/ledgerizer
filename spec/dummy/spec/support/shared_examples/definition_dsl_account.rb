shared_examples 'definition dsl account' do |acc_type|
  describe "##{acc_type}" do
    it "raises error with no tenant" do
      expect_error_in_class_definition("'#{acc_type}' needs to run inside 'tenant' block") do
        include Ledgerizer::Definition::Dsl

        send(acc_type, :account1)
      end
    end

    it "raises error with repeated accounts" do
      expect_error_in_class_definition("the account1 account already exists in tenant") do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          send(acc_type, :account1)
          send(acc_type, :account1)
        end
      end
    end

    context "with valid account" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          send(acc_type, :account1)
        end
      end

      let(:expected) do
        {
          tenanat_model_name: :portfolio,
          account_name: :account1,
          account_type: acc_type,
          contra: false
        }
      end

      it { expect(LedgerizerTest).to have_tenant_account(expected) }
    end

    context "with contra account" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          send(acc_type, :account1, contra: true)
        end
      end

      let(:expected) do
        {
          tenanat_model_name: :portfolio,
          account_name: :account1,
          account_type: acc_type,
          contra: true
        }
      end

      it { expect(LedgerizerTest).to have_tenant_account(expected) }
    end

    context "with string account name" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          send(acc_type, "account1")
        end
      end

      let(:expected) do
        {
          tenanat_model_name: :portfolio,
          account_name: :account1,
          account_type: acc_type,
          contra: false
        }
      end

      it { expect(LedgerizerTest).to have_tenant_account(expected) }
    end

    context "with more than one account" do
      define_test_class do
        include Ledgerizer::Definition::Dsl

        tenant('portfolio') do
          send(acc_type, :account1)
          send(acc_type, :account2, contra: true)
        end
      end

      let(:expected_account1) do
        {
          tenanat_model_name: :portfolio,
          account_name: :account1,
          account_type: acc_type,
          contra: false
        }
      end

      let(:expected_account2) do
        {
          tenanat_model_name: :portfolio,
          account_name: :account2,
          account_type: acc_type,
          contra: true
        }
      end

      it { expect(LedgerizerTest).to have_tenant_account(expected_account1) }
      it { expect(LedgerizerTest).to have_tenant_account(expected_account2) }
    end
  end
end
