shared_examples 'add executor entry account' do |type|
  describe "#add_#{type}" do
    subject(:executor) do
      described_class.new(
        tenant: tenant,
        document: document,
        entry_code: entry_code,
        entry_date: entry_date
      )
    end

    let(:tenant) { create(:portfolio) }
    let(:document) { create(:user) }
    let(:entry_code) { :deposit }
    let(:entry_date) { "1984-06-04" }

    let(:item_type) { type.to_s }
    let(:account_name) { :cash }
    let(:accountable) { create(:user) }
    let(:amount) { clp(1000) }
    let(:expected_item) do
      {
        accountable: accountable,
        currency: "CLP",
        account_name: :cash,
        amount: amount
      }
    end

    define_test_class do
      include Ledgerizer::Definition::Dsl

      tenant(:portfolio, currency: :clp) do
        asset(:cash)

        entry(:deposit, document: :user) do
          send(type, account: :cash, accountable: :user)
        end
      end
    end

    def perform
      executor.send(
        "add_#{item_type}",
        account_name: account_name,
        accountable: accountable,
        amount: amount
      )
    end

    it { expect(perform.to_hash).to eq(expected_item) }
    it { expect { perform }.to change { executor.send(item_type.pluralize).count }.from(0).to(1) }

    context "with existent item" do
      before { perform }

      it { expect { perform }.to change { executor.send(item_type.pluralize).count }.from(1).to(2) }
    end
  end
end
