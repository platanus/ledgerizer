require "spec_helper"

RSpec.describe Ledgerizer::Execution::Entry do
  subject(:execution_entry) do
    build(
      :executable_entry,
      entry_definition: entry_definition,
      document: document_instance,
      entry_date: entry_date
    )
  end

  let(:document) { :user }
  let(:document_instance) { create(:user) }
  let(:entry_code) { :deposit }
  let(:entry_date) { "1984-06-04" }

  let(:entry_definition) do
    build(:entry_definition, code: entry_code, document: document)
  end

  let(:account_name) { :cash }
  let(:account_type) { :asset }
  let(:base_currency) { :clp }
  let(:contra) { false }

  let(:account) do
    build(
      :account_definition,
      name: account_name,
      type: account_type,
      base_currency: base_currency,
      contra: contra
    )
  end

  let(:tenant_instance) { create(:portfolio) }

  let(:entry) do
    create(
      :ledgerizer_entry,
      tenant: tenant_instance,
      document: document_instance,
      code: entry_code,
      entry_date: entry_date
    )
  end

  let(:accountable_instance) { create(:user) }
  let(:accountable) { :user }

  it { expect(execution_entry.entry_date).to eq(entry_date.to_date) }
  it { expect(execution_entry.document).to eq(document_instance) }

  context "with non AR document" do
    let(:document_instance) { LedgerizerTest.new }

    it { expect { execution_entry }.to raise_error("document must be an ActiveRecord model") }
  end

  context "with invalid AR document" do
    let(:document_instance) { create(:portfolio) }

    it { expect { execution_entry }.to raise_error(/invalid document Portfolio for given deposit/) }
  end

  context "with invalid date" do
    let(:entry_date) { "1984-06-32" }

    it { expect { execution_entry }.to raise_error("invalid date given") }
  end

  describe "#add_movement" do
    let(:movement_type) { :debit }
    let(:amount) { clp(1000) }

    let(:account) do
      build(
        :account_definition,
        name: account_name,
        type: account_type,
        base_currency: base_currency,
        contra: contra
      )
    end

    def perform
      execution_entry.add_movement(
        movement_type: movement_type,
        account_name: account_name,
        accountable: accountable_instance,
        amount: amount
      )
    end

    context "with no definition movement" do
      let(:error_msg) do
        'invalid movement cash with accountable User for given deposit entry in debits'
      end

      it { expect { perform }.to raise_error(error_msg) }
    end

    context "with existent definition movement" do
      before do
        entry_definition.add_movement(
          movement_type: movement_type,
          account: account,
          accountable: accountable
        )
      end

      it { expect { perform }.to change { execution_entry.movements.count }.from(0).to(1) }

      context "with non AR document" do
        let(:accountable_instance) { LedgerizerTest.new }

        it { expect { perform }.to raise_error("accountable must be an ActiveRecord model") }
      end

      context "with invalid AR document" do
        let(:accountable_instance) { create(:portfolio) }

        it { expect { perform }.to raise_error(/accountable Portfolio for given deposit/) }
      end
    end

    describe "#old_movements" do
      def perform
        execution_entry.old_movements(entry)
      end

      before do
        entry_definition.add_movement(
          movement_type: movement_type,
          account: account,
          accountable: accountable
        )
      end

      it { expect(perform.count).to eq(0) }

      context "with a single line matching entry and movement definition" do
        before do
          create(
            :ledgerizer_line,
            entry: entry,
            force_accountable: accountable_instance,
            account_name: account_name,
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
              account_name: account_name,
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
              account_name: account_name,
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
              account_name: account_name,
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
              account_name: account_name,
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
              account_name: account_name,
              amount: clp(222)
            )
          end

          it { expect(perform.count).to eq(1) }
          it { expect(perform.first.amount).to eq(clp(555)) }
        end
      end
    end
  end
end
