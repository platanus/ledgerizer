shared_examples 'definition dsl account' do |acc_type|
  describe "##{acc_type}" do
    it "raises error with no tenant" do
      expect_error_in_definition_class("'#{acc_type}' needs to run inside 'tenant' block") do
        send(acc_type, :account1)
      end
    end

    it "raises error with repeated accounts" do
      expect_error_in_definition_class(
        /the account1 account with clp currency and no mirror currency already exists in tenant/
      ) do
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

    context "with account working with another currencies" do
      let_definition_class do
        tenant('portfolio') do
          send(acc_type, :account1, currencies: [:usd, :ars])
        end
      end

      let(:expected_account) do
        {
          tenanat_model_name: :portfolio,
          account_name: :account1,
          account_type: acc_type,
          contra: false
        }
      end

      let(:expected_clp) do
        expected_account.merge(account_currency: :clp, mirror_currency: nil)
      end

      let(:expected_usd) do
        expected_account.merge(account_currency: :usd, mirror_currency: nil)
      end

      let(:expected_ars) do
        expected_account.merge(account_currency: :ars, mirror_currency: nil)
      end

      let(:expected_usd_mirror) do
        expected_account.merge(account_currency: :clp, mirror_currency: :usd)
      end

      let(:expected_ars_mirror) do
        expected_account.merge(account_currency: :clp, mirror_currency: :ars)
      end

      it { expect(LedgerizerTestDefinition).to have_ledger_account_definition(expected_clp) }
      it { expect(LedgerizerTestDefinition).to have_ledger_account_definition(expected_usd) }
      it { expect(LedgerizerTestDefinition).to have_ledger_account_definition(expected_ars) }
      it { expect(LedgerizerTestDefinition).to have_ledger_account_definition(expected_usd_mirror) }
      it { expect(LedgerizerTestDefinition).to have_ledger_account_definition(expected_ars_mirror) }
    end

    context "with account with another currency and explicit tenant's currency" do
      let_definition_class do
        tenant('portfolio') do
          send(acc_type, :account1, currencies: [:usd, :clp])
        end
      end

      let(:expected_account) do
        {
          tenanat_model_name: :portfolio,
          account_name: :account1,
          account_type: acc_type,
          contra: false
        }
      end

      let(:expected_clp) do
        expected_account.merge(account_currency: :clp)
      end

      let(:expected_usd) do
        expected_account.merge(account_currency: :usd)
      end

      it { expect(LedgerizerTestDefinition).to have_ledger_account_definition(expected_clp) }
      it { expect(LedgerizerTestDefinition).to have_ledger_account_definition(expected_usd) }
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
