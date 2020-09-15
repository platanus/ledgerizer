shared_examples 'definition dsl movement' do |type|
  describe "##{type}" do
    it "raises error with no tenant" do
      expect_error_in_definition_class("'#{type}' needs to run inside 'entry' block") do
        send(type, account: nil, accountable: nil)
      end
    end

    it "raises error with no entry" do
      expect_error_in_definition_class("'#{type}' needs to run inside 'entry' block") do
        tenant('portfolio') do
          send(type, account: nil, accountable: nil)
        end
      end
    end

    it "raises error with no defined account" do
      expect_error_in_definition_class("the cash account does not exist in tenant") do
        tenant('portfolio') do
          entry(:deposit, document: 'deposit') do
            send(type, account: :cash, accountable: nil)
          end
        end
      end
    end

    it "raises error with invalid accountable" do
      expect_error_in_definition_class(/accountable must be a snake_case/) do
        tenant('portfolio') do
          asset(:cash)

          entry(:deposit, document: 'deposit') do
            send(type, account: :cash, accountable: 'invalid')
          end
        end
      end
    end

    context "with valid #{type}" do
      let_definition_class do
        tenant('portfolio') do
          asset(:cash)

          entry(:deposit, document: :deposit) do
            send(type, account: :cash, accountable: :user)
          end
        end
      end

      let(:expected) do
        {
          tenant_class: :portfolio,
          entry_code: :deposit,
          movement_type: type,
          account_name: :cash,
          account_currency: :clp,
          mirror_currency: nil,
          accountable: :user
        }
      end

      it { expect(LedgerizerTestDefinition).to have_ledger_movement_definition(expected) }
    end

    context "with no accountable" do
      let_definition_class do
        tenant('portfolio') do
          asset(:cash)

          entry(:deposit, document: :deposit) do
            send(type, account: :cash)
          end
        end
      end

      let(:expected) do
        {
          tenant_class: :portfolio,
          entry_code: :deposit,
          movement_type: type,
          account_name: :cash,
          account_currency: :clp,
          mirror_currency: nil,
          accountable: nil
        }
      end

      it { expect(LedgerizerTestDefinition).to have_ledger_movement_definition(expected) }
    end

    context "with multiple movements" do
      let_definition_class do
        tenant('portfolio') do
          asset(:cash)
          asset(:bank)

          entry(:deposit, document: :deposit) do
            send(type, account: :cash, accountable: :user)
            send(type, account: :bank, accountable: :user)
          end
        end
      end

      let(:expected_cash) do
        {
          tenant_class: :portfolio,
          entry_code: :deposit,
          movement_type: type,
          account_name: :cash,
          account_currency: :clp,
          mirror_currency: nil,
          accountable: :user
        }
      end

      let(:expected_bank) do
        {
          tenant_class: :portfolio,
          entry_code: :deposit,
          movement_type: type,
          account_name: :bank,
          account_currency: :clp,
          mirror_currency: nil,
          accountable: :user
        }
      end

      it { expect(LedgerizerTestDefinition).to have_ledger_movement_definition(expected_cash) }
      it { expect(LedgerizerTestDefinition).to have_ledger_movement_definition(expected_bank) }
    end

    context "with movements in multiple entries" do
      let_definition_class do
        tenant('portfolio') do
          asset(:cash)
          asset(:bank)

          entry(:deposit, document: :deposit) do
            send(type, account: :cash, accountable: :user)
            send(type, account: :bank, accountable: :user)
          end

          entry(:distribute, document: :deposit) do
            send(type, account: :cash, accountable: :user)
          end
        end
      end

      let(:expected_cash) do
        {
          tenant_class: :portfolio,
          entry_code: :deposit,
          movement_type: type,
          account_name: :cash,
          account_currency: :clp,
          mirror_currency: nil,
          accountable: :user
        }
      end

      let(:expected_bank) do
        {
          tenant_class: :portfolio,
          entry_code: :deposit,
          movement_type: type,
          account_name: :bank,
          account_currency: :clp,
          mirror_currency: nil,
          accountable: :user
        }
      end

      let(:expected_cash1) do
        {
          tenant_class: :portfolio,
          entry_code: :distribute,
          movement_type: type,
          account_name: :cash,
          account_currency: :clp,
          mirror_currency: nil,
          accountable: :user
        }
      end

      it { expect(LedgerizerTestDefinition).to have_ledger_movement_definition(expected_cash) }
      it { expect(LedgerizerTestDefinition).to have_ledger_movement_definition(expected_bank) }
      it { expect(LedgerizerTestDefinition).to have_ledger_movement_definition(expected_cash1) }
    end

    context "with entries working with currencies different than tenant's currency" do
      let_definition_class do
        tenant('portfolio', currency: :clp) do
          asset(:cash, currencies: [:clp, :usd])
          asset(:bank, currencies: [:clp, :usd])

          entry(:deposit, document: :deposit) do
            send(type, account: :cash, accountable: :user)
            send(type, account: :bank, accountable: :user)
          end
        end
      end

      let(:cash_clp) do
        {
          tenant_class: :portfolio,
          entry_code: :deposit,
          movement_type: type,
          account_name: :cash,
          account_currency: :clp,
          mirror_currency: nil,
          accountable: :user
        }
      end

      let(:bank_clp) do
        {
          tenant_class: :portfolio,
          entry_code: :deposit,
          movement_type: type,
          account_name: :bank,
          account_currency: :clp,
          mirror_currency: nil,
          accountable: :user
        }
      end

      let(:cash_usd) do
        {
          tenant_class: :portfolio,
          entry_code: :deposit,
          movement_type: type,
          account_name: :cash,
          account_currency: :usd,
          mirror_currency: nil,
          accountable: :user
        }
      end

      let(:bank_usd) do
        {
          tenant_class: :portfolio,
          entry_code: :deposit,
          movement_type: type,
          account_name: :bank,
          account_currency: :usd,
          mirror_currency: nil,
          accountable: :user
        }
      end

      let(:cash_mirror) do
        {
          tenant_class: :portfolio,
          entry_code: :deposit,
          movement_type: type,
          account_name: :cash,
          account_currency: :clp,
          mirror_currency: :usd,
          accountable: :user
        }
      end

      let(:bank_mirror) do
        {
          tenant_class: :portfolio,
          entry_code: :deposit,
          movement_type: type,
          account_name: :bank,
          account_currency: :clp,
          mirror_currency: :usd,
          accountable: :user
        }
      end

      it { expect(LedgerizerTestDefinition).to have_ledger_movement_definition(cash_clp) }
      it { expect(LedgerizerTestDefinition).to have_ledger_movement_definition(bank_clp) }
      it { expect(LedgerizerTestDefinition).to have_ledger_movement_definition(cash_usd) }
      it { expect(LedgerizerTestDefinition).to have_ledger_movement_definition(bank_usd) }
      it { expect(LedgerizerTestDefinition).to have_ledger_movement_definition(cash_mirror) }
      it { expect(LedgerizerTestDefinition).to have_ledger_movement_definition(bank_mirror) }
    end
  end
end
