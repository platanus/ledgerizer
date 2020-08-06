shared_examples 'definition dsl account' do |acc_type|
  describe "##{acc_type}" do
    it "raises error with no tenant" do
      expect_error_in_definition_class("'#{acc_type}' needs to run inside 'tenant' block") do
        send(acc_type, :account1)
      end
    end

    it "raises error with repeated accounts" do
      expect_error_in_definition_class(/the account1 account with clp currency already exist/) do
        tenant('portfolio') do
          send(acc_type, :account1)
          send(acc_type, :account1)
        end
      end
    end

    context "with valid account" do
      let_definition_class do
        tenant('portfolio') do
          send(acc_type, :account1)
        end
      end

      let(:expected) do
        {
          tenanat_model_name: :portfolio,
          account_name: :account1,
          account_type: acc_type,
          contra: false,
          account_currency: :clp
        }
      end

      it { expect(LedgerizerTestDefinition).to have_ledger_account_definition(expected) }
    end

    context "with contra account" do
      let_definition_class do
        tenant('portfolio') do
          send(acc_type, :account1, contra: true)
        end
      end

      let(:expected) do
        {
          tenanat_model_name: :portfolio,
          account_name: :account1,
          account_type: acc_type,
          contra: true,
          account_currency: :clp
        }
      end

      it { expect(LedgerizerTestDefinition).to have_ledger_account_definition(expected) }
    end

    context "with string account name" do
      let_definition_class do
        tenant('portfolio') do
          send(acc_type, "account1")
        end
      end

      let(:expected) do
        {
          tenanat_model_name: :portfolio,
          account_name: :account1,
          account_type: acc_type,
          contra: false,
          account_currency: :clp
        }
      end

      it { expect(LedgerizerTestDefinition).to have_ledger_account_definition(expected) }
    end

    context "with more than one account" do
      let_definition_class do
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
          contra: false,
          account_currency: :clp
        }
      end

      let(:expected_account2) do
        {
          tenanat_model_name: :portfolio,
          account_name: :account2,
          account_type: acc_type,
          contra: true,
          account_currency: :clp
        }
      end

      it { expect(LedgerizerTestDefinition).to have_ledger_account_definition(expected_account1) }
      it { expect(LedgerizerTestDefinition).to have_ledger_account_definition(expected_account2) }
    end
  end
end
