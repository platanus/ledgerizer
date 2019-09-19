shared_examples 'add entry account' do |type|
  describe "#add_#{type}" do
    let(:entry_code) { :deposit }
    let(:account) { Ledgerizer::Definition::Account.new(name: :cash, type: :asset) }
    let(:accountable) { 'user' }

    def perform(account_entry_type)
      entry.send("add_#{account_entry_type}", account: account, accountable: accountable)
    end

    def account_entries_count(account_entry_type)
      entry.send(account_entry_type.to_s.pluralize)
    end

    it { expect { perform(type) }.to change { account_entries_count(type).count }.from(0).to(1) }
    it { expect(perform(type).account_name).to eq(:cash) }
    it { expect(perform(type).accountable).to eq(:user) }
    it { expect(perform(type).movement_type).to eq(type) }

    context "with existent debit" do
      before { perform(type) }

      it { expect { perform(type) }.to raise_error(/cash with accountable user already/) }
    end

    context "with invalid accountable" do
      let(:accountable) { :invalid }

      it { expect { perform(type) }.to raise_error(/must be an ActiveRecord model name/) }
    end
  end
end
