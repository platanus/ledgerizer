shared_examples "ledgerizer accountable" do |entity_name|
  let(:entity) { create(entity_name) }

  it { expect(entity).to have_many(:ledgerizer_accounts) }

  describe "#ledger_[account_name]_account_[balance|lines]" do
    let_definition_class do
      tenant('portfolio', currency: :clp) do
        asset(:account1)
        liability(:account2)

        entry(:entry1, document: :deposit) do
          debit(account: :account1, accountable: entity_name)
          credit(account: :account2, accountable: entity_name)
        end
      end
    end

    def lines
      entity.ledger_account1_account_lines(filters)
    end

    def balance
      entity.ledger_account1_account_balance(filters)
    end

    let(:tenant) { create(:portfolio) }
    let(:entry_date) { "1984-06-04" }

    let(:filters) do
      {
        tenant: tenant
      }
    end

    before do
      create_list(
        :ledgerizer_line, 5,
        force_tenant: tenant,
        force_accountable: entity,
        force_account_name: :account1,
        amount: clp(10)
      )

      create_list(
        :ledgerizer_line, 3,
        force_tenant: tenant,
        force_accountable: entity,
        force_account_name: :account1,
        force_entry_date: entry_date,
        amount: clp(5)
      )
    end

    it { expect(entity).to respond_to(:ledger_account1_account_balance) }
    it { expect(entity).to respond_to(:ledger_account1_account_lines) }
    it { expect(entity).to respond_to(:ledger_account2_account_balance) }
    it { expect(entity).to respond_to(:ledger_account2_account_lines) }

    it { expect(lines.count).to eq(8) }
    it { expect(balance).to eq(clp(65)) }

    context "with valid filters" do
      let(:filters) do
        {
          tenant: tenant,
          entry_date: entry_date
        }
      end

      it { expect(lines.count).to eq(3) }
      it { expect(balance).to eq(clp(15)) }
    end

    context "with missing tenant filters" do
      let(:filters) { {} }

      it { expect { lines }.to raise_error('tenant is required') }
    end

    context "with forbidden filter" do
      let(:filters) do
        {
          tenant: tenant,
          tenants: [tenant]
        }
      end

      it { expect { lines }.to raise_error('tenants is forbidden') }
    end
  end
end
