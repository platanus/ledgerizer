require "spec_helper"

describe Ledgerizer::Execution::Entry do
  subject(:execution_entry) do
    build(
      :executable_entry,
      config: ledgerizer_config,
      tenant: tenant_instance,
      document: document_instance,
      entry_code: entry_code,
      entry_date: entry_date
    )
  end

  let(:ledgerizer_config) { LedgerizerTestDefinition.definition }
  let(:tenant_instance) { create(:portfolio) }
  let(:document) { :deposit }
  let(:document_instance) { create(:deposit) }
  let(:entry_code) { :deposit }
  let(:entry_date) { "1984-06-04" }

  let(:entry) do
    create(
      :ledgerizer_entry,
      tenant: tenant_instance,
      document: document_instance,
      code: entry_code,
      entry_date: entry_date
    )
  end

  let_definition_class do
    tenant('portfolio', currency: :clp) do
      asset(:account1)
      liability(:account2)

      entry(:deposit, document: :deposit) do
        debit(account: :account1, accountable: :user)
        credit(account: :account2, accountable: :user)
      end
    end
  end

  it { expect(execution_entry.entry_date).to eq(entry_date.to_date) }
  it { expect(execution_entry.document).to eq(document_instance) }

  context "with invalid tenant type" do
    let(:tenant_instance) { "tenant" }

    it { expect { execution_entry }.to raise_error("tenant must be an ActiveRecord model") }
  end

  context "with invalid AR tenant" do
    let(:tenant_instance) { create(:user) }

    it { expect { execution_entry }.to raise_error("can't find tenant for given User model") }
  end

  context "with non AR document" do
    let(:document_instance) { LedgerizerTest.new }

    it { expect { execution_entry }.to raise_error("document must be an ActiveRecord model") }
  end

  context "with invalid AR document" do
    let(:document_instance) { create(:portfolio) }

    it { expect { execution_entry }.to raise_error(/invalid document Portfolio for given deposit/) }
  end

  context "with not valid entry code for given tenant" do
    let(:entry_code) { "buy" }

    it { expect { execution_entry }.to raise_error("invalid entry code buy for given tenant") }
  end

  context "with invalid date" do
    let(:entry_date) { "1984-06-32" }

    it { expect { execution_entry }.to raise_error("invalid date given") }
  end

  describe "#add_new_movement" do
    let(:movement_type) { :debit }
    let(:amount) { clp(1000) }
    let(:account_name) { :account1 }
    let(:accountable_instance) { create(:user) }

    def perform
      execution_entry.add_new_movement(
        movement_type: movement_type,
        account_name: account_name,
        accountable: accountable_instance,
        amount: amount
      )
    end

    it { expect { perform }.to change { execution_entry.new_movements.count }.from(0).to(1) }

    context "with non AR document" do
      let(:accountable_instance) { LedgerizerTest.new }

      it { expect { perform }.to raise_error("accountable must be an ActiveRecord model") }
    end

    context "with invalid AR document" do
      let(:accountable_instance) { create(:portfolio) }

      it { expect { perform }.to raise_error(/accountable Portfolio for given deposit/) }
    end

    context "with no definition for matching given movement type" do
      let(:movement_type) { :credit }

      let(:error_msg) do
        'invalid movement account1 with accountable User for given deposit entry in credits'
      end

      it { expect { perform }.to raise_error(error_msg) }
    end

    context "with no definition for matching given account name" do
      let(:account_name) { :account2 }

      let(:error_msg) do
        'invalid movement account2 with accountable User for given deposit entry in debits'
      end

      it { expect { perform }.to raise_error(error_msg) }
    end

    context "with no definition matching given accountable" do
      let(:accountable_instance) { create(:portfolio) }

      let(:error_msg) do
        'invalid movement account1 with accountable Portfolio for given deposit entry in debits'
      end

      it { expect { perform }.to raise_error(error_msg) }
    end
  end

  describe "#old_movements" do
    let(:account_name) { :account1 }
    let(:accountable_instance) { create(:user) }

    def perform
      execution_entry.old_movements
    end

    it { expect(perform.count).to eq(0) }

    context "with a single line matching entry and movement definition" do
      before do
        create(
          :ledgerizer_line,
          entry: entry,
          force_accountable: accountable_instance,
          force_account_name: account_name,
          amount: clp(333)
        )
      end

      it { expect(perform.count).to eq(1) }
      it { expect(perform.first.amount).to eq(clp(333)) }

      context "with another line matching the same entry en movement definition" do
        before do
          create(
            :ledgerizer_line,
            entry: entry,
            force_accountable: accountable_instance,
            force_account_name: account_name,
            amount: clp(333)
          )
        end

        it { expect(perform.count).to eq(1) }
        it { expect(perform.first.amount).to eq(clp(666)) }
      end

      context "with line with negative amount" do
        before do
          create(
            :ledgerizer_line,
            entry: entry,
            force_accountable: accountable_instance,
            force_account_name: account_name,
            amount: -clp(666)
          )
        end

        it { expect(perform.count).to eq(1) }
        it { expect(perform.first.amount).to eq(-clp(333)) }
      end

      context "with another line with different accountable" do
        before do
          create(
            :ledgerizer_line,
            entry: entry,
            force_account_name: account_name,
            amount: clp(222)
          )
        end

        it { expect(perform.count).to eq(2) }
        it { expect(perform.first.amount).to eq(clp(333)) }
        it { expect(perform.last.amount).to eq(clp(222)) }
      end

      context "with line entry not matching entry param" do
        before do
          create(
            :ledgerizer_line,
            entry: create(:ledgerizer_entry),
            force_accountable: accountable_instance,
            force_account_name: account_name,
            amount: clp(222)
          )
        end

        it { expect(perform.count).to eq(1) }
        it { expect(perform.first.amount).to eq(clp(333)) }
      end

      context "with line with another entry having same sensible attributes as entry param" do
        let(:another_entry) do
          create(
            :ledgerizer_entry,
            tenant: tenant_instance,
            document: document_instance,
            code: entry_code,
            entry_date: entry_date.to_date + 1.day
          )
        end

        before do
          create(
            :ledgerizer_line,
            entry: another_entry,
            force_accountable: accountable_instance,
            force_account_name: account_name,
            amount: clp(222)
          )
        end

        it { expect(perform.count).to eq(1) }
        it { expect(perform.first.amount).to eq(clp(555)) }
      end
    end
  end
end
