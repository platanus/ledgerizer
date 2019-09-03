shared_examples 'add executor entry item' do |type|
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
        "add_#{item_type}", account_name: account_name, accountable: accountable, amount: amount
      )
    end

    it { expect(perform).to eq(expected_item) }
    it { expect { perform }.to change { executor.send(item_type.pluralize).count }.from(0).to(1) }

    context "with amount with currency that is not the tenant's currency" do
      let(:amount) { usd(1000) }

      it { expect { perform }.to raise_error("USD is not the tenant's currency") }
    end

    context "with not money amount" do
      let(:amount) { 1000 }

      it { expect { perform }.to raise_error("invalid money") }
    end

    context "with negative money amount" do
      let(:amount) { -clp(1) }

      it { expect { perform }.to raise_error("value needs to be greater than 0") }
    end

    context "with negative money amount" do
      let(:amount) { clp(0) }

      it { expect { perform }.to raise_error("value needs to be greater than 0") }
    end

    context "with invalid account name" do
      let(:account_name) { :bank }

      it { expect { perform }.to raise_error(/invalid entry account bank with accountable/) }
    end

    context "with invalid accountable" do
      let(:accountable) { create(:portfolio) }

      it { expect { perform }.to raise_error(/invalid entry account cash with accountable Port/) }
    end

    context "with non AR accountable" do
      let(:accountable) { "not active record model" }

      it { expect { perform }.to raise_error("accountable must be an ActiveRecord model") }
    end
  end
end
